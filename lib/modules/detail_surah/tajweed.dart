import 'package:flutter/material.dart';

/// Hukum tajwid yang dapat dikenali langsung dari huruf dan harakat teks Arab.
enum TajweedRule {
  mad,
  ghunnah,
  ikhfa,
  idghamWithGhunnah,
  idghamWithoutGhunnah,
  iqlab,
  qalqalah,
  izhar,
}

extension TajweedRulePresentation on TajweedRule {
  String get label => switch (this) {
        TajweedRule.mad => 'Mad',
        TajweedRule.ghunnah => 'Ghunnah',
        TajweedRule.ikhfa => 'Ikhfa',
        TajweedRule.idghamWithGhunnah => 'Idgham bighunnah',
        TajweedRule.idghamWithoutGhunnah => 'Idgham bilaghunnah',
        TajweedRule.iqlab => 'Iqlab',
        TajweedRule.qalqalah => 'Qalqalah',
        TajweedRule.izhar => 'Izhar halqi',
      };

  String get description => switch (this) {
        TajweedRule.mad => 'Bacaan dipanjangkan',
        TajweedRule.ghunnah => 'Dibaca dengung',
        TajweedRule.ikhfa => 'Dibaca samar dengan dengung',
        TajweedRule.idghamWithGhunnah => 'Dilebur dengan dengung',
        TajweedRule.idghamWithoutGhunnah => 'Dilebur tanpa dengung',
        TajweedRule.iqlab => 'Nun atau tanwin berubah menjadi bunyi mim',
        TajweedRule.qalqalah => 'Huruf sukun dibaca memantul',
        TajweedRule.izhar => 'Dibaca jelas dari tenggorokan',
      };

  Color get color => switch (this) {
        TajweedRule.mad => const Color(0xFFD32F2F),
        TajweedRule.ghunnah => const Color(0xFFEF6C00),
        TajweedRule.ikhfa => const Color(0xFF2E7D32),
        TajweedRule.idghamWithGhunnah => const Color(0xFF1565C0),
        TajweedRule.idghamWithoutGhunnah => const Color(0xFF00838F),
        TajweedRule.iqlab => const Color(0xFF7B1FA2),
        TajweedRule.qalqalah => const Color(0xFFC2185B),
        TajweedRule.izhar => const Color(0xFF5D4037),
      };
}

/// Potongan teks yang memiliki satu hukum tajwid yang sama.
class TajweedSegment {
  const TajweedSegment(this.text, this.rule);

  final String text;
  final TajweedRule? rule;
}

/// Mengenali hukum tajwid yang dapat disimpulkan dari teks Arab berharakat.
///
/// Parser tidak mengubah atau membuang karakter apa pun. Hasil seluruh segmen
/// bila digabung selalu sama persis dengan [text].
class TajweedParser {
  const TajweedParser._();

  static const _shadda = '\u0651';
  static const _sukun = '\u0652';
  static const _quranicSukun = '\u06E1';
  static const _fathatan = '\u064B';
  static const _dammatan = '\u064C';
  static const _kasratan = '\u064D';
  static const _fatha = '\u064E';
  static const _damma = '\u064F';
  static const _kasra = '\u0650';
  static const _maddah = '\u0653';
  static const _daggerAlif = '\u0670';

  static const _ikhfaLetters = 'تثجدذزسشصضطظفقك';
  static const _idghamWithGhunnahLetters = 'ينمو';
  static const _idghamWithoutGhunnahLetters = 'لر';
  static const _izharLetters = 'ءأإؤئهعحغخ';
  static const _qalqalahLetters = 'قطبجد';

  static List<TajweedSegment> parse(String text) {
    if (text.isEmpty) return const [];

    final clusters = _clusters(text);
    final rules = List<TajweedRule?>.filled(clusters.length, null);

    for (var i = 0; i < clusters.length; i++) {
      final cluster = clusters[i];
      final base = _baseCharacter(cluster);
      if (base == null) continue;

      final nextIndex = _nextArabicLetterIndex(clusters, i);
      final nextBase =
          nextIndex == null ? null : _baseCharacter(clusters[nextIndex]);

      if ((base == 'ن' || base == 'م') && cluster.contains(_shadda)) {
        rules[i] = TajweedRule.ghunnah;
        continue;
      }

      final hasNoonSukun = base == 'ن' && _hasSukun(cluster);
      final hasTanwin = _hasTanwin(cluster);
      if (nextBase != null && (hasNoonSukun || hasTanwin)) {
        if (nextBase == 'ب') {
          rules[i] = TajweedRule.iqlab;
        } else if (_ikhfaLetters.contains(nextBase)) {
          rules[i] = TajweedRule.ikhfa;
        } else if (_idghamWithGhunnahLetters.contains(nextBase)) {
          rules[i] = TajweedRule.idghamWithGhunnah;
        } else if (_idghamWithoutGhunnahLetters.contains(nextBase)) {
          rules[i] = TajweedRule.idghamWithoutGhunnah;
        } else if (_izharLetters.contains(nextBase)) {
          rules[i] = TajweedRule.izhar;
        }
        if (rules[i] != null) continue;
      }

      // Ikhfa syafawi dan idgham mimi.
      if (base == 'م' && _hasSukun(cluster) && nextBase != null) {
        if (nextBase == 'ب') {
          rules[i] = TajweedRule.ikhfa;
          continue;
        }
        if (nextBase == 'م') {
          rules[i] = TajweedRule.ghunnah;
          continue;
        }
      }

      if (_qalqalahLetters.contains(base) && _hasSukun(cluster)) {
        rules[i] = TajweedRule.qalqalah;
        continue;
      }

      if (_isMadCluster(clusters, i, base, cluster)) {
        rules[i] = TajweedRule.mad;
      }
    }

    return _mergeSegments(clusters, rules);
  }

  static bool _hasSukun(String cluster) =>
      cluster.contains(_sukun) || cluster.contains(_quranicSukun);

  static bool _hasTanwin(String cluster) =>
      cluster.contains(_fathatan) ||
      cluster.contains(_dammatan) ||
      cluster.contains(_kasratan);

  static bool _isMadCluster(
    List<String> clusters,
    int index,
    String base,
    String cluster,
  ) {
    if (cluster.contains(_maddah) || cluster.contains(_daggerAlif)) return true;
    if (base == 'آ') return true;

    final previousIndex = _previousArabicLetterIndex(clusters, index);
    if (previousIndex == null) return false;
    final previous = clusters[previousIndex];

    if (base == 'ا' && previous.contains(_fatha)) return true;
    if ((base == 'و' || base == 'ي') &&
        !_hasShortVowel(cluster) &&
        !cluster.contains(_shadda) &&
        !_hasSukun(cluster)) {
      if (base == 'و' && previous.contains(_damma)) return true;
      if (base == 'ي' && previous.contains(_kasra)) return true;
    }
    return false;
  }

  static bool _hasShortVowel(String cluster) =>
      cluster.contains(_fatha) ||
      cluster.contains(_damma) ||
      cluster.contains(_kasra) ||
      _hasTanwin(cluster);

  static List<TajweedSegment> _mergeSegments(
    List<String> clusters,
    List<TajweedRule?> rules,
  ) {
    final result = <TajweedSegment>[];
    var buffer = StringBuffer();
    TajweedRule? currentRule = rules.first;

    for (var i = 0; i < clusters.length; i++) {
      if (rules[i] != currentRule) {
        result.add(TajweedSegment(buffer.toString(), currentRule));
        buffer = StringBuffer();
        currentRule = rules[i];
      }
      buffer.write(clusters[i]);
    }
    if (buffer.isNotEmpty) {
      result.add(TajweedSegment(buffer.toString(), currentRule));
    }
    return result;
  }

  static List<String> _clusters(String text) {
    final result = <String>[];
    for (final rune in text.runes) {
      final character = String.fromCharCode(rune);
      if (_isCombiningMark(rune) && result.isNotEmpty) {
        result[result.length - 1] = '${result.last}$character';
      } else {
        result.add(character);
      }
    }
    return result;
  }

  static bool _isCombiningMark(int rune) =>
      (rune >= 0x0610 && rune <= 0x061A) ||
      (rune >= 0x064B && rune <= 0x065F) ||
      rune == 0x0670 ||
      (rune >= 0x06D6 && rune <= 0x06ED);

  static String? _baseCharacter(String cluster) {
    if (cluster.isEmpty) return null;
    final rune = cluster.runes.first;
    return _isArabicLetter(rune) ? String.fromCharCode(rune) : null;
  }

  static bool _isArabicLetter(int rune) =>
      (rune >= 0x0621 && rune <= 0x063A) ||
      (rune >= 0x0641 && rune <= 0x064A) ||
      (rune >= 0x066E && rune <= 0x06D3);

  static int? _nextArabicLetterIndex(List<String> clusters, int index) {
    for (var i = index + 1; i < clusters.length; i++) {
      if (_baseCharacter(clusters[i]) != null) return i;
      if (_isAyahBoundary(clusters[i])) return null;
    }
    return null;
  }

  static int? _previousArabicLetterIndex(List<String> clusters, int index) {
    for (var i = index - 1; i >= 0; i--) {
      if (_baseCharacter(clusters[i]) != null) return i;
      if (_isAyahBoundary(clusters[i])) return null;
    }
    return null;
  }

  static bool _isAyahBoundary(String cluster) =>
      cluster.contains('۝') || cluster.contains('۞') || cluster.contains('۩');
}

/// Teks Arab yang menerapkan warna tajwid tanpa mengubah tata letak dasarnya.
class TajweedText extends StatelessWidget {
  const TajweedText(
    this.text, {
    super.key,
    required this.style,
    this.enabled = true,
    this.textAlign = TextAlign.right,
    this.textDirection = TextDirection.rtl,
  });

  final String text;
  final TextStyle style;
  final bool enabled;
  final TextAlign textAlign;
  final TextDirection textDirection;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Text(
        text,
        style: style,
        textAlign: textAlign,
        textDirection: textDirection,
      );
    }

    final segments = TajweedParser.parse(text);
    return Text.rich(
      TextSpan(
        style: style,
        children: segments
            .map(
              (segment) => TextSpan(
                text: segment.text,
                style: segment.rule == null
                    ? null
                    : TextStyle(color: segment.rule!.color),
              ),
            )
            .toList(growable: false),
      ),
      textAlign: textAlign,
      textDirection: textDirection,
    );
  }
}
