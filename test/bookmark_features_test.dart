import 'package:dilalquran/modules/doa/controller/doa_controller.dart';
import 'package:dilalquran/modules/dzikir/controller/dzikir_controller.dart';
import 'package:dilalquran/services/bookmark_store.dart';
import 'package:dilalquran/services/quran_reading_progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('QuranReadingProgressStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('membuat key terpisah untuk juz dan surah', () {
      expect(
        QuranReadingProgressStore.contentKey(category: 'juz', number: 1),
        'juz:1',
      );
      expect(
        QuranReadingProgressStore.contentKey(category: 'surah', number: 1),
        'surah:1',
      );
    });

    test('menyimpan dan memuat halaman terakhir setiap konten', () async {
      const store = QuranReadingProgressStore();
      await store.save({'juz:1': 4, 'juz:2': 8, 'surah:36': 2});

      final restored = await store.load();

      expect(restored['juz:1'], 4);
      expect(restored['juz:2'], 8);
      expect(restored['surah:36'], 2);
    });

    test('mengabaikan data rusak dan nomor halaman negatif', () async {
      SharedPreferences.setMockInitialValues({
        QuranReadingProgressStore.preferenceKey:
            '{"juz:1":3,"juz:2":-1,"surah:2":"5","rusak":"x"}',
      });

      const store = QuranReadingProgressStore();
      final restored = await store.load();

      expect(restored, {'juz:1': 3, 'surah:2': 5});
    });
  });

  group('BookmarkStore', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('menyimpan ID unik secara terurut dan memuatnya kembali', () async {
      const store = BookmarkStore('test_bookmarks');
      await store.save([5, 2, 5, 1]);

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getStringList('test_bookmarks'),
        ['1', '2', '5'],
      );
      expect(await store.load(), {1, 2, 5});
    });

    test('mengabaikan ID tersimpan yang tidak valid', () async {
      SharedPreferences.setMockInitialValues({
        'test_bookmarks': ['1', 'abc', '-2', '7'],
      });
      const store = BookmarkStore('test_bookmarks');

      expect(await store.load(), {1, 7});
    });
  });

  group('Filter bookmark bacaan', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Doa hanya menampilkan item favorit dan tetap mendukung pencarian',
        () async {
      final controller = DoaController();
      await controller.fetchDoa();
      expect(controller.allDoa, isNotEmpty);

      final favorite = controller.allDoa.first;
      await controller.toggleBookmark(favorite.id);
      controller.setShowBookmarkedOnly(true);

      expect(controller.displayedDoasList, hasLength(1));
      expect(controller.displayedDoasList.single.id, favorite.id);

      controller.onSearch('kata-yang-tidak-ada');
      expect(controller.displayedDoasList, isEmpty);
    });

    test('Dzikir hanya menampilkan item favorit dan bisa dihapus', () async {
      final controller = DzikirController();
      await controller.fetchDzikir();
      expect(controller.allDzikir, isNotEmpty);

      final favorite = controller.allDzikir.first;
      await controller.toggleBookmark(favorite.id);
      controller.setShowBookmarkedOnly(true);

      expect(controller.displayedDzikirList, hasLength(1));
      expect(controller.displayedDzikirList.single.id, favorite.id);

      await controller.toggleBookmark(favorite.id);
      expect(controller.displayedDzikirList, isEmpty);
    });
  });
}
