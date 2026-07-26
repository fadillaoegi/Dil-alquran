import 'package:dilalquran/modules/data/sources/home_source.dart';
import 'package:dilalquran/modules/hafizh/controller/hafizh_controller.dart';
import 'package:dilalquran/modules/hafizh/controller/hafizh_detail_controller.dart';
import 'package:get/get.dart';

// Satu kata dengan id unik agar kata yang berulang tetap bisa dibedakan.
class PracticeWord {
  final int id;
  final String text;
  const PracticeWord(this.id, this.text);
}

class HafizhPracticeController extends GetxController {
  final HafizhController hafizh = Get.find<HafizhController>();

  bool isJuz = false;
  int number = 1;
  int? startAyat;
  int? endAyat;

  final _isLoading = true.obs;
  bool get isLoading => _isLoading.value;

  final roundIndex = 0.obs;
  final score = 0.obs;
  final finished = false.obs;

  final shuffled = <PracticeWord>[].obs;
  final answer = <PracticeWord>[].obs;

  // null = belum diperiksa, true = benar, false = salah.
  final result = Rxn<bool>();

  final List<HafizhVerse> _pool = [];
  List<String> _correctWords = [];
  int _currentAyatNumber = 0;
  String _currentSurahName = "";

  static const int _maxRounds = 12;

  int get totalRounds => _pool.length;
  int get currentAyatNumber => _currentAyatNumber;
  String get currentSurahName => _currentSurahName;
  String get correctAnswer => _correctWords.join(" ");
  bool get canCheck =>
      result.value == null && answer.length == _correctWords.length;

  @override
  void onInit() {
    super.onInit();
    _parseArgs(Get.arguments);
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

      final all = <HafizhVerse>[];
      if (isJuz) {
        var surahList = hafizh.surahList;
        if (surahList.isEmpty) surahList = await HomeSource.fetchSurah();
        final detail = await HomeSource.fetchDetailJuz(
          juzNumber: number,
          surahList: surahList,
        );
        all.addAll(detail.verses.map((v) => HafizhVerse(
              surahNumber: v.surahNumber,
              surahNameLatin: v.surahNameLatin,
              ayat: v.ayat,
            )));
      } else {
        final detail = await HomeSource.fetchDetailSurah(number.toString());
        final surahAyat = detail.ayat ?? [];
        all.addAll(surahAyat.map((a) => HafizhVerse(
              surahNumber: number,
              surahNameLatin: detail.namaLatin ?? "",
              ayat: a,
            )));
      }

      final filteredAll = _filterSelectedRange(all);

      // Utamakan ayat yang sudah ditandai hafal; jika belum ada, pakai semua.
      final memorized = filteredAll
          .where((v) => hafizh.isMemorized(v.surahNumber, v.ayatNumber))
          .toList();
      final source = memorized.isNotEmpty ? memorized : filteredAll;

      _pool
        ..clear()
        ..addAll(source.take(_maxRounds));

      if (_pool.isNotEmpty) _setupRound();
    } finally {
      _isLoading.value = false;
    }
  }

  void _setupRound() {
    final verse = _pool[roundIndex.value];
    _currentAyatNumber = verse.ayatNumber;
    _currentSurahName = verse.surahNameLatin;

    final words = (verse.ayat.teksArab ?? "").trim().split(RegExp(r'\s+'))
      ..removeWhere((w) => w.isEmpty);
    _correctWords = words;

    final chips = <PracticeWord>[
      for (var i = 0; i < words.length; i++) PracticeWord(i, words[i]),
    ]..shuffle();

    shuffled.assignAll(chips);
    answer.clear();
    result.value = null;
  }

  void pick(PracticeWord word) {
    if (result.value != null) return;
    shuffled.remove(word);
    answer.add(word);
  }

  void unpick(PracticeWord word) {
    if (result.value != null) return;
    answer.remove(word);
    shuffled.add(word);
  }

  void resetRound() {
    if (result.value != null) return;
    final all = [...shuffled, ...answer]..shuffle();
    shuffled.assignAll(all);
    answer.clear();
  }

  Future<void> check() async {
    if (answer.length != _correctWords.length) return;

    var correct = true;
    for (var i = 0; i < _correctWords.length; i++) {
      if (answer[i].text != _correctWords[i]) {
        correct = false;
        break;
      }
    }

    result.value = correct;
    if (correct) {
      score.value++;
      await hafizh.recordActivity();
    }
  }

  void next() {
    if (roundIndex.value >= _pool.length - 1) {
      finished.value = true;
    } else {
      roundIndex.value++;
      _setupRound();
    }
  }

  void restart() {
    roundIndex.value = 0;
    score.value = 0;
    finished.value = false;
    if (_pool.isNotEmpty) _setupRound();
  }

  bool get hasCustomRange =>
      startAyat != null && endAyat != null && startAyat! <= endAyat!;

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
