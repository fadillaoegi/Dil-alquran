import 'package:dilalquran/modules/scan_ayat/model/ayat_recognition_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Jumlah ayat sebagian surah, dipakai sebagai patokan validasi.
  const ayatCounts = <int, int>{
    1: 7, // Al-Fatihah
    2: 286, // Al-Baqarah
    112: 4, // Al-Ikhlas
    114: 6, // An-Nas
  };

  group('extractJsonObject', () {
    test('mengambil objek JSON dari teks polos', () {
      expect(extractJsonObject('{"a":1}'), '{"a":1}');
    });

    test('mengambil objek JSON di dalam pagar markdown', () {
      const raw = '''
Berikut hasilnya:
```json
{"is_quran_page": true, "candidates": []}
```
Semoga membantu.
''';
      expect(
        extractJsonObject(raw),
        '{"is_quran_page": true, "candidates": []}',
      );
    });

    test('menjaga objek bersarang tetap utuh', () {
      const raw = 'x {"a": {"b": 2}, "c": 3} y';
      expect(extractJsonObject(raw), '{"a": {"b": 2}, "c": 3}');
    });

    test('mengabaikan kurung kurawal yang berada di dalam string', () {
      const raw = '{"note": "kurung } di dalam teks", "ok": true}';
      expect(extractJsonObject(raw), raw);
    });

    test('mengembalikan null bila tidak ada objek JSON', () {
      expect(extractJsonObject('tidak ada json di sini'), isNull);
      expect(extractJsonObject(''), isNull);
    });
  });

  group('parseAyatRecognition', () {
    test('mengurai hasil lengkap', () {
      const raw = '''
{
  "is_quran_page": true,
  "note": "",
  "candidates": [
    {"surah": 2, "surah_name": "Al-Baqarah", "ayat_start": 255,
     "ayat_end": 255, "confidence": 0.92}
  ]
}
''';
      final result = parseAyatRecognition(raw);

      expect(result.isQuranPage, isTrue);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.first.surahNumber, 2);
      expect(result.candidates.first.ayatStart, 255);
      expect(result.candidates.first.surahNameGuess, 'Al-Baqarah');
      expect(result.isConfident, isTrue);
    });

    test('menandai bukan halaman Al-Quran', () {
      const raw = '{"is_quran_page": false, "candidates": [], '
          '"note": "Foto berisi pemandangan."}';
      final result = parseAyatRecognition(raw);

      expect(result.isQuranPage, isFalse);
      expect(result.hasCandidates, isFalse);
      expect(result.note, 'Foto berisi pemandangan.');
    });

    test('tidak melempar galat pada balasan yang rusak', () {
      final result = parseAyatRecognition('{"candidates": [oops}');
      expect(result.hasCandidates, isFalse);
      expect(result.note, isNotEmpty);
    });

    test('tidak melempar galat pada balasan kosong', () {
      final result = parseAyatRecognition('');
      expect(result.isQuranPage, isFalse);
      expect(result.hasCandidates, isFalse);
    });

    test('ayat_end yang hilang disamakan dengan ayat_start', () {
      const raw = '{"is_quran_page": true, "candidates": ['
          '{"surah": 112, "ayat_start": 1, "confidence": 0.5}]}';
      final candidate = parseAyatRecognition(raw).candidates.first;

      expect(candidate.ayatStart, 1);
      expect(candidate.ayatEnd, 1);
      expect(candidate.isRange, isFalse);
    });

    test('menerima nomor yang dikirim sebagai string', () {
      const raw = '{"is_quran_page": true, "candidates": ['
          '{"surah": "2", "ayat_start": "1", "ayat_end": "3",'
          ' "confidence": "0.7"}]}';
      final candidate = parseAyatRecognition(raw).candidates.first;

      expect(candidate.surahNumber, 2);
      expect(candidate.ayatEnd, 3);
      expect(candidate.confidence, closeTo(0.7, 0.001));
    });
  });

  group('validateCandidates', () {
    test('menerima dugaan yang benar', () {
      const candidates = [
        AyatCandidate(surahNumber: 112, ayatStart: 1, ayatEnd: 4),
      ];
      expect(validateCandidates(candidates, ayatCounts), hasLength(1));
    });

    test('menolak nomor surah di luar 1..114', () {
      const candidates = [
        AyatCandidate(surahNumber: 0, ayatStart: 1, ayatEnd: 1),
        AyatCandidate(surahNumber: 115, ayatStart: 1, ayatEnd: 1),
        AyatCandidate(surahNumber: -3, ayatStart: 1, ayatEnd: 1),
      ];
      expect(validateCandidates(candidates, ayatCounts), isEmpty);
    });

    test('menolak nomor ayat melebihi jumlah ayat surah', () {
      // Al-Ikhlas hanya 4 ayat.
      const candidates = [
        AyatCandidate(surahNumber: 112, ayatStart: 1, ayatEnd: 5),
      ];
      expect(validateCandidates(candidates, ayatCounts), isEmpty);
    });

    test('menolak ayat mulai dari nol atau negatif', () {
      const candidates = [
        AyatCandidate(surahNumber: 1, ayatStart: 0, ayatEnd: 2),
        AyatCandidate(surahNumber: 1, ayatStart: -1, ayatEnd: 2),
      ];
      expect(validateCandidates(candidates, ayatCounts), isEmpty);
    });

    test('menolak rentang terbalik', () {
      const candidates = [
        AyatCandidate(surahNumber: 2, ayatStart: 10, ayatEnd: 5),
      ];
      expect(validateCandidates(candidates, ayatCounts), isEmpty);
    });

    test('menolak surah yang jumlah ayatnya belum diketahui', () {
      // Surah 3 tidak ada pada peta, jadi tidak bisa diverifikasi.
      const candidates = [
        AyatCandidate(surahNumber: 3, ayatStart: 1, ayatEnd: 1),
      ];
      expect(validateCandidates(candidates, ayatCounts), isEmpty);
    });

    test('membuang duplikat', () {
      const candidates = [
        AyatCandidate(surahNumber: 1, ayatStart: 1, ayatEnd: 1),
        AyatCandidate(surahNumber: 1, ayatStart: 1, ayatEnd: 1),
      ];
      expect(validateCandidates(candidates, ayatCounts), hasLength(1));
    });

    test('mengurutkan dari keyakinan tertinggi', () {
      const candidates = [
        AyatCandidate(
          surahNumber: 1,
          ayatStart: 1,
          ayatEnd: 1,
          confidence: 0.3,
        ),
        AyatCandidate(
          surahNumber: 112,
          ayatStart: 1,
          ayatEnd: 1,
          confidence: 0.9,
        ),
      ];
      final result = validateCandidates(candidates, ayatCounts);

      expect(result.first.surahNumber, 112);
      expect(result.last.surahNumber, 1);
    });

    test('memotong sesuai batas maksimum', () {
      const candidates = [
        AyatCandidate(surahNumber: 1, ayatStart: 1, ayatEnd: 1),
        AyatCandidate(surahNumber: 1, ayatStart: 2, ayatEnd: 2),
        AyatCandidate(surahNumber: 1, ayatStart: 3, ayatEnd: 3),
        AyatCandidate(surahNumber: 1, ayatStart: 4, ayatEnd: 4),
      ];
      expect(
        validateCandidates(candidates, ayatCounts),
        hasLength(maxAyatCandidates),
      );
    });

    test('peta jumlah ayat kosong menolak semuanya', () {
      const candidates = [
        AyatCandidate(surahNumber: 1, ayatStart: 1, ayatEnd: 1),
      ];
      expect(validateCandidates(candidates, const {}), isEmpty);
    });
  });

  group('AyatCandidate', () {
    test('label menyesuaikan ayat tunggal dan rentang', () {
      const single = AyatCandidate(surahNumber: 2, ayatStart: 255, ayatEnd: 255);
      const range = AyatCandidate(surahNumber: 2, ayatStart: 1, ayatEnd: 5);

      expect(single.label, '2:255');
      expect(single.ayatCount, 1);
      expect(range.label, '2:1-5');
      expect(range.ayatCount, 5);
    });

    test('confidence dijaga pada rentang 0..1', () {
      final tooHigh = AyatCandidate.fromJson({
        'surah': 1,
        'ayat_start': 1,
        'confidence': 5,
      });
      final negative = AyatCandidate.fromJson({
        'surah': 1,
        'ayat_start': 1,
        'confidence': -2,
      });

      expect(tooHigh.confidence, 1.0);
      expect(negative.confidence, 0.0);
    });
  });
}
