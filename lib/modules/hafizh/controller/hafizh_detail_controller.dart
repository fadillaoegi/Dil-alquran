import 'package:audioplayers/audioplayers.dart';
import 'package:dilalquran/modules/data/models/surah_detail_model.dart';
import 'package:dilalquran/modules/data/sources/home_source.dart';
import 'package:dilalquran/modules/hafizh/controller/hafizh_controller.dart';
import 'package:dilalquran/widgets/app_notify.dart';
import 'package:get/get.dart';

// Satu ayat berikut identitas surahnya — agar daftar bisa memuat ayat
// lintas surah (untuk mode juz).
class HafizhVerse {
  final int surahNumber;
  final String surahNameLatin;
  final Ayat ayat;

  const HafizhVerse({
    required this.surahNumber,
    required this.surahNameLatin,
    required this.ayat,
  });

  int get ayatNumber => ayat.nomorAyat ?? 0;
}

class HafizhDetailController extends GetxController {
  final HafizhController hafizh = Get.find<HafizhController>();

  bool isJuz = false;
  int number = 1; // nomor surah atau nomor juz
  int? startAyat;
  int? endAyat;
  final _title = "Hafalan".obs;
  String get title => _title.value;

  final _isLoading = true.obs;
  bool get isLoading => _isLoading.value;

  final verses = <HafizhVerse>[].obs;

  // Mode sembunyi teks (uji hafalan).
  final RxBool hideText = false.obs;
  final RxSet<String> revealed = <String>{}.obs; // key "surah:ayat"

  // Muraja'ah audio.
  final RxInt repeatCount = 3.obs;
  final RxDouble speed = 1.0.obs;
  final RxString activeVerseKey = ''.obs; // "surah:ayat"
  final RxBool isPlaying = false.obs;

  static const List<int> repeatOptions = [3, 5, 10];
  static const List<double> speedOptions = [0.75, 1.0, 1.5, 2.0];

  // Daftar ayat lengkap (belum difilter rentang) — untuk ganti rentang in-place.
  final List<HafizhVerse> _allVerses = [];
  int get totalAyat => _allVerses.length;

  final AudioPlayer _player = AudioPlayer();
  static const String _qari = '05';

  List<HafizhVerse> _queue = [];
  int _index = 0;
  int _currentRepeat = 0;

  @override
  void onInit() {
    super.onInit();
    _parseArgs(Get.arguments);
    _listen();
    _load();
  }

  void _parseArgs(dynamic args) {
    if (args is Map) {
      isJuz = args['category']?.toString().toLowerCase() == 'juz';
      number = int.tryParse(args['number'].toString()) ?? 1;
      startAyat = _parseAyatValue(args['startAyat']);
      endAyat = _parseAyatValue(args['endAyat']);
      _normalizeRange();
    } else {
      isJuz = false;
      number = int.tryParse(args?.toString() ?? '1') ?? 1;
    }
  }

  Future<void> _load() async {
    try {
      _isLoading.value = true;
      if (isJuz) {
        _title.value = "Juz $number";
        var surahList = hafizh.surahList;
        if (surahList.isEmpty) surahList = await HomeSource.fetchSurah();
        final detail = await HomeSource.fetchDetailJuz(
          juzNumber: number,
          surahList: surahList,
        );
        final juzVerses = detail.verses
            .map(
              (v) => HafizhVerse(
                surahNumber: v.surahNumber,
                surahNameLatin: v.surahNameLatin,
                ayat: v.ayat,
              ),
            )
            .toList();
        _allVerses
          ..clear()
          ..addAll(juzVerses);
        verses.assignAll(_filterSelectedRange(_allVerses));
      } else {
        final detail = await HomeSource.fetchDetailSurah(number.toString());
        _title.value = detail.namaLatin ?? "Hafalan";
        final allAyat = (detail.ayat ?? [])
            .map(
              (a) => HafizhVerse(
                surahNumber: number,
                surahNameLatin: detail.namaLatin ?? "",
                ayat: a,
              ),
            )
            .toList();
        _allVerses
          ..clear()
          ..addAll(allAyat);
        verses.assignAll(_filterSelectedRange(_allVerses));
      }
    } finally {
      _isLoading.value = false;
    }
  }

  // Muat ulang ayat (untuk pull-to-refresh).
  Future<void> reload() => _load();

  // Terapkan rentang ayat baru tanpa fetch ulang (dari panel muraja'ah).
  Future<void> applyRange(int start, int end) async {
    startAyat = start;
    endAyat = end;
    _normalizeRange();
    await stop();
    verses.assignAll(_filterSelectedRange(_allVerses));
  }

  // Kembalikan ke seluruh ayat.
  Future<void> clearRange() async {
    startAyat = null;
    endAyat = null;
    await stop();
    verses.assignAll(_filterSelectedRange(_allVerses));
  }

  void _listen() {
    _player.onPlayerComplete.listen((_) => _onComplete());
    _player.onPlayerStateChanged.listen((state) {
      isPlaying.value = state == PlayerState.playing;
    });
  }

  String _key(HafizhVerse verse) =>
      hafizh.keyOf(verse.surahNumber, verse.ayatNumber);

  bool get hasCustomRange =>
      startAyat != null && endAyat != null && startAyat! <= endAyat!;

  String get rangeLabel {
    if (!hasCustomRange) return '';
    if (isJuz) {
      return "Ayat juz ${startAyat!} - ${endAyat!}";
    }
    return "Ayat ${startAyat!} - ${endAyat!}";
  }

  // ---- Mode sembunyi teks ----
  void toggleHideText() {
    hideText.value = !hideText.value;
    revealed.clear();
  }

  bool isRevealed(HafizhVerse verse) => revealed.contains(_key(verse));
  void reveal(HafizhVerse verse) => revealed.add(_key(verse));

  // ---- Progress hafalan ----
  bool isMemorized(HafizhVerse verse) =>
      hafizh.isMemorized(verse.surahNumber, verse.ayatNumber);

  Future<void> toggleMemorized(HafizhVerse verse) =>
      hafizh.toggleAyat(verse.surahNumber, verse.ayatNumber);

  Future<void> markAllMemorized() async {
    await hafizh.addMemorizedKeys(verses.map(_key));
  }

  // ---- Muraja'ah audio ----
  String _audioUrl(HafizhVerse verse) {
    final map = verse.ayat.audio;
    if (map == null || map.isEmpty) return '';
    return map[_qari] ?? map.values.first;
  }

  bool isVerseActive(HafizhVerse verse) => activeVerseKey.value == _key(verse);

  bool get hasActive => activeVerseKey.value.isNotEmpty;

  // Tombol utama: putar dari awal / jeda / lanjut.
  Future<void> togglePlayPause() async {
    if (!hasActive) {
      if (verses.isNotEmpty) await startFrom(verses.first);
    } else if (isPlaying.value) {
      await _player.pause();
    } else {
      await _player.resume();
    }
  }

  // Tombol per-ayat: jika ayat ini aktif -> jeda/lanjut; jika bukan -> mulai.
  Future<void> toggleVerse(HafizhVerse verse) async {
    if (isVerseActive(verse)) {
      if (isPlaying.value) {
        await _player.pause();
      } else {
        await _player.resume();
      }
    } else {
      await startFrom(verse);
    }
  }

  Future<void> startFrom(HafizhVerse verse) async {
    if (verses.isEmpty) return;
    final startIndex = verses.indexOf(verse);
    _queue = verses.toList();
    _index = startIndex < 0 ? 0 : startIndex;
    _currentRepeat = 0;
    hafizh.recordActivity(); // muraja'ah dihitung sebagai aktivitas
    await _playCurrent();
  }

  Future<void> _playCurrent() async {
    if (_index < 0 || _index >= _queue.length) {
      await stop();
      return;
    }

    final verse = _queue[_index];
    final url = _audioUrl(verse);
    if (url.isEmpty) {
      _advance();
      return;
    }

    activeVerseKey.value = _key(verse);
    try {
      await _player.stop();
      await _player.play(UrlSource(url));
      await _player.setPlaybackRate(speed.value);
    } catch (_) {
      await stop();
      showAppSnackbar(
        'Gagal Memutar Audio',
        'Periksa koneksi internet lalu coba lagi.',
        isError: true,
      );
    }
  }

  void _onComplete() {
    _currentRepeat++;
    if (_currentRepeat < repeatCount.value) {
      _playCurrent();
    } else {
      _currentRepeat = 0;
      _advance();
    }
  }

  void _advance() {
    _index++;
    if (_index >= _queue.length) {
      stop();
    } else {
      _playCurrent();
    }
  }

  Future<void> stop() async {
    await _player.stop();
    activeVerseKey.value = '';
    isPlaying.value = false;
  }

  void setRepeat(int value) => repeatCount.value = value;

  Future<void> setSpeed(double value) async {
    speed.value = value;
    if (isPlaying.value) {
      await _player.setPlaybackRate(value);
    }
  }

  @override
  void onClose() {
    _player.dispose();
    super.onClose();
  }

  int? _parseAyatValue(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  void _normalizeRange() {
    if (startAyat == null || endAyat == null) return;
    if (startAyat! <= 0 || endAyat! <= 0) {
      startAyat = null;
      endAyat = null;
      return;
    }
    if (startAyat! > endAyat!) {
      final temp = startAyat;
      startAyat = endAyat;
      endAyat = temp;
    }
  }

  List<HafizhVerse> _filterSelectedRange(List<HafizhVerse> allVerses) {
    if (!hasCustomRange) return allVerses;

    if (isJuz) {
      return allVerses
          .asMap()
          .entries
          .where((entry) {
            final juzAyatIndex = entry.key + 1;
            return juzAyatIndex >= (startAyat ?? 1) &&
                juzAyatIndex <= (endAyat ?? juzAyatIndex);
          })
          .map((entry) => entry.value)
          .toList();
    }

    return allVerses.where((verse) {
      final nomorAyat = verse.ayatNumber;
      return nomorAyat >= (startAyat ?? 1) &&
          nomorAyat <= (endAyat ?? nomorAyat);
    }).toList();
  }
}
