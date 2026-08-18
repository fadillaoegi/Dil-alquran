import 'package:dilalquran/modules/detail_surah/tajweed.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

TajweedRule? _ruleForText(String text, String fragment) {
  final segments = TajweedParser.parse(text);
  return segments.firstWhere((segment) => segment.text.contains(fragment)).rule;
}

void main() {
  group('TajweedParser', () {
    test('menjaga teks Arab tetap persis sama', () {
      const text = 'مِنْ بَعْدِ مَا جَاءَهُمْ';
      final parsed = TajweedParser.parse(text);

      expect(parsed.map((segment) => segment.text).join(), text);
    });

    test('mengenali iqlab nun sukun sebelum ba', () {
      expect(_ruleForText('مِنْ بَعْدِ', 'نْ'), TajweedRule.iqlab);
    });

    test('mengenali ikhfa nun sukun', () {
      expect(_ruleForText('مِنْ شَرِّ', 'نْ'), TajweedRule.ikhfa);
    });

    test('mengenali dua jenis idgham', () {
      expect(
        _ruleForText('مِنْ وَالٍ', 'نْ'),
        TajweedRule.idghamWithGhunnah,
      );
      expect(
        _ruleForText('مِنْ رَبِّهِمْ', 'نْ'),
        TajweedRule.idghamWithoutGhunnah,
      );
    });

    test('mengenali izhar halqi', () {
      expect(_ruleForText('مِنْ هَادٍ', 'نْ'), TajweedRule.izhar);
    });

    test('mengenali ghunnah pada nun tasydid', () {
      expect(_ruleForText('إِنَّ', 'نَّ'), TajweedRule.ghunnah);
    });

    test('mengenali qalqalah pada huruf sukun', () {
      expect(_ruleForText('يَقْطَعُونَ', 'قْ'), TajweedRule.qalqalah);
    });

    test('mengenali mad dari alif setelah fathah', () {
      expect(_ruleForText('قَالَ', 'ا'), TajweedRule.mad);
    });

    test('teks kosong menghasilkan daftar kosong', () {
      expect(TajweedParser.parse(''), isEmpty);
    });
  });

  group('TajweedText', () {
    testWidgets('merender RichText berwarna ketika aktif', (tester) async {
      const text = 'مِنْ بَعْدِ';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TajweedText(
              text,
              style: TextStyle(fontSize: 24.0, color: Colors.black),
            ),
          ),
        ),
      );

      final richText = tester.widget<RichText>(find.byType(RichText));
      final rootSpan = richText.text as TextSpan;
      final coloredSpans = rootSpan.children!
          .whereType<TextSpan>()
          .where((span) => span.style?.color != null);

      expect(rootSpan.toPlainText(), text);
      expect(coloredSpans, isNotEmpty);
    });

    testWidgets('merender teks polos ketika dinonaktifkan', (tester) async {
      const text = 'مِنْ بَعْدِ';
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TajweedText(
              text,
              enabled: false,
              style: TextStyle(fontSize: 24.0),
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text(text));
      expect(textWidget.data, text);
    });
  });
}
