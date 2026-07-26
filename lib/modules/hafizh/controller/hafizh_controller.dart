import 'package:dilalquran/modules/data/models/juz_model.dart';
import 'package:dilalquran/modules/data/models/surah_model.dart';
import 'package:dilalquran/modules/data/sources/home_source.dart';
import 'package:dilalquran/modules/home/controller/home_controller.dart';
import 'package:dilalquran/services/notification_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HafizhController extends GetxController {
  static const _prefKey = 'hafizh_memorized';
  static const _prefActiveDays = 'hafizh_active_days';
  static const _prefReminderOn = 'hafizh_reminder_on';
  static const _prefReminderHour = 'hafizh_reminder_hour';
  static const _prefReminderMinute = 'hafizh_reminder_minute';
  static const int _reminderId = 5001;

  final NotificationService _notif = NotificationService();

  final _surahList = <Surah>[].obs;
  List<Surah> get surahList => _surahList;

  final _juzList = <JuzSummary>[].obs;
  List<JuzSummary> get juzList => _juzList;

  // 0 = tab Surah, 1 = tab Juz.
  final activeTab = 0.obs;
  void setTab(int index) => activeTab.value = index;

  // Pencarian surah/juz.
  final TextEditingController searchController = TextEditingController();
  final searchQuery = "".obs;
  void onSearch(String query) => searchQuery.value = query;
  void clearSearch() {
    searchController.clear();
    searchQuery.value = "";
  }

  List<Surah> get filteredSurah {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return _surahList;
    return _surahList.where((surah) {
      final name = (surah.namaLatin ?? "").toLowerCase();
      final arti = (surah.arti ?? "").toLowerCase();
      final nomor = (surah.nomor ?? 0).toString();
      return name.contains(query) || arti.contains(query) || nomor == query;
    }).toList();
  }

  List<JuzSummary> get filteredJuz {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) return _juzList;
    return _juzList.where((juz) {
      final nomor = juz.number.toString();
      final start = juz.startSurahName.toLowerCase();
      final end = juz.endSurahName.toLowerCase();
      return nomor == query || start.contains(query) || end.contains(query);
    }).toList();
  }

  final _isLoading = true.obs;
  bool get isLoading => _isLoading.value;

  // Kumpulan ayat yang sudah dihafal, format "surah:ayat" mis. "2:255".
  final RxSet<String> memorized = <String>{}.obs;

  // Hari-hari aktif (format "yyyy-mm-dd") untuk menghitung streak.
  final RxSet<String> _activeDays = <String>{}.obs;

  // Pengaturan pengingat muraja'ah harian.
  final RxBool reminderEnabled = false.obs;
  final RxInt reminderHour = 5.obs;
  final RxInt reminderMinute = 0.obs;

  SharedPreferences? _prefs;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> _bootstrap() async {
    _prefs = await SharedPreferences.getInstance();
    memorized.addAll(_prefs?.getStringList(_prefKey) ?? const []);
    _activeDays.addAll(_prefs?.getStringList(_prefActiveDays) ?? const []);
    reminderEnabled.value = _prefs?.getBool(_prefReminderOn) ?? false;
    reminderHour.value = _prefs?.getInt(_prefReminderHour) ?? 5;
    reminderMinute.value = _prefs?.getInt(_prefReminderMinute) ?? 0;
    await _loadSurah();
  }

  Future<void> _loadSurah() async {
    try {
      _isLoading.value = true;
      // Pakai ulang data dari HomeController bila sudah termuat.
      if (Get.isRegistered<HomeController>() &&
          Get.find<HomeController>().surahList.isNotEmpty) {
        _surahList.assignAll(Get.find<HomeController>().surahList);
      } else {
        _surahList.assignAll(await HomeSource.fetchSurah());
      }
      _juzList.assignAll(HomeSource.buildJuzSummaries(_surahList));
    } finally {
      _isLoading.value = false;
    }
  }

  // Muat ulang daftar surah & juz (untuk pull-to-refresh).
  Future<void> refreshData() => _loadSurah();

  String keyOf(int surah, int ayat) => "$surah:$ayat";

  bool isMemorized(int surah, int ayat) =>
      memorized.contains(keyOf(surah, ayat));

  Future<void> toggleAyat(int surah, int ayat) async {
    final key = keyOf(surah, ayat);
    if (memorized.contains(key)) {
      memorized.remove(key);
    } else {
      memorized.add(key);
      await recordActivity();
    }
    await _persist();
  }

  Future<void> setSurahMemorized(int surah, int jumlahAyat, bool value) async {
    for (var ayat = 1; ayat <= jumlahAyat; ayat++) {
      final key = keyOf(surah, ayat);
      if (value) {
        memorized.add(key);
      } else {
        memorized.remove(key);
      }
    }
    if (value) await recordActivity();
    await _persist();
  }

  // Tandai sekaligus banyak ayat (dipakai "tandai semua" surah/juz).
  Future<void> addMemorizedKeys(Iterable<String> keys) async {
    memorized.addAll(keys);
    await recordActivity();
    await _persist();
  }

  // Colon pada key mencegah "2:" ikut cocok dengan "20:..".
  int memorizedCountForSurah(int surah) {
    final prefix = "$surah:";
    return memorized.where((key) => key.startsWith(prefix)).length;
  }

  // ---- Progress per Juz (dihitung dari data hafalan yang sama) ----
  Surah? _findSurah(int number) {
    for (final surah in _surahList) {
      if (surah.nomor == number) return surah;
    }
    return null;
  }

  // Rentang (surah, ayat awal-akhir) yang membentuk sebuah juz.
  List<JuzRange> juzRanges(int juzNumber) {
    JuzBoundary? boundary;
    for (final b in juzBoundaries) {
      if (b.number == juzNumber) {
        boundary = b;
        break;
      }
    }
    if (boundary == null) return const [];

    final ranges = <JuzRange>[];
    for (var surahNo = boundary.startSurah;
        surahNo <= boundary.endSurah;
        surahNo++) {
      final maxAyat = _findSurah(surahNo)?.jumlahAyat ?? 0;
      if (maxAyat == 0) continue;
      final start = surahNo == boundary.startSurah ? boundary.startAyat : 1;
      final end = surahNo == boundary.endSurah ? boundary.endAyat : maxAyat;
      ranges.add(JuzRange(surahNumber: surahNo, startAyat: start, endAyat: end));
    }
    return ranges;
  }

  int totalAyatForJuz(int juzNumber) {
    var total = 0;
    for (final range in juzRanges(juzNumber)) {
      total += range.endAyat - range.startAyat + 1;
    }
    return total;
  }

  int memorizedCountForJuz(int juzNumber) {
    var count = 0;
    for (final range in juzRanges(juzNumber)) {
      for (var ayat = range.startAyat; ayat <= range.endAyat; ayat++) {
        if (memorized.contains(keyOf(range.surahNumber, ayat))) count++;
      }
    }
    return count;
  }

  int get totalMemorized => memorized.length;

  int get totalAyatQuran {
    final sum = _surahList.fold<int>(0, (total, s) => total + (s.jumlahAyat ?? 0));
    return sum > 0 ? sum : 6236;
  }

  int get completedSurahCount {
    var count = 0;
    for (final surah in _surahList) {
      final total = surah.jumlahAyat ?? 0;
      if (total > 0 && memorizedCountForSurah(surah.nomor ?? -1) >= total) {
        count++;
      }
    }
    return count;
  }

  double get overallProgress {
    final total = totalAyatQuran;
    return total == 0 ? 0 : totalMemorized / total;
  }

  Future<void> _persist() async {
    await _prefs?.setStringList(_prefKey, memorized.toList());
  }

  // ---- Statistik & streak ----
  String _dayKey(DateTime date) =>
      "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

  Future<void> recordActivity() async {
    final today = _dayKey(DateTime.now());
    if (!_activeDays.contains(today)) {
      _activeDays.add(today);
      await _prefs?.setStringList(_prefActiveDays, _activeDays.toList());
    }
  }

  int get totalActiveDays => _activeDays.length;

  int get currentStreak {
    if (_activeDays.isEmpty) return 0;
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day);

    // Bila hari ini belum aktif, beri masa tenggang: hitung dari kemarin.
    if (!_activeDays.contains(_dayKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
      if (!_activeDays.contains(_dayKey(cursor))) return 0;
    }

    var streak = 0;
    while (_activeDays.contains(_dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int get longestStreak {
    if (_activeDays.isEmpty) return 0;
    final days = _activeDays.map(DateTime.parse).toList()..sort();
    var longest = 1;
    var run = 1;
    for (var i = 1; i < days.length; i++) {
      final diff = days[i].difference(days[i - 1]).inDays;
      if (diff == 1) {
        run++;
      } else if (diff > 1) {
        run = 1;
      }
      if (run > longest) longest = run;
    }
    return longest;
  }

  // ---- Pengingat muraja'ah harian ----
  String get reminderTimeLabel =>
      "${reminderHour.value.toString().padLeft(2, '0')}:${reminderMinute.value.toString().padLeft(2, '0')}";

  Future<void> toggleReminder(bool value) async {
    reminderEnabled.value = value;
    await _prefs?.setBool(_prefReminderOn, value);
    if (value) {
      await _notif.requestPermissions();
      await _scheduleReminder();
    } else {
      await _notif.cancel(_reminderId);
    }
  }

  Future<void> setReminderTime(int hour, int minute) async {
    reminderHour.value = hour;
    reminderMinute.value = minute;
    await _prefs?.setInt(_prefReminderHour, hour);
    await _prefs?.setInt(_prefReminderMinute, minute);
    if (reminderEnabled.value) await _scheduleReminder();
  }

  Future<void> _scheduleReminder() async {
    await _notif.scheduleDailyReminder(
      id: _reminderId,
      hour: reminderHour.value,
      minute: reminderMinute.value,
      title: "Waktunya Muraja'ah",
      body: "Yuk jaga hafalanmu, ulangi ayat yang sudah dihafal hari ini.",
    );
  }
}
