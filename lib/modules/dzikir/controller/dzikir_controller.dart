import 'package:dilalquran/modules/data/sources/dzikir_source.dart';
import 'package:dilalquran/modules/dzikir/model/dzikir_model.dart';
import 'package:dilalquran/services/bookmark_store.dart';
import 'package:get/get.dart';

class DzikirController extends GetxController {
  final DzikirSource _dzikirSource = DzikirSource();
  static const String bookmarkPreferenceKey = 'dilalquran_dzikir_bookmarks';
  final BookmarkStore _bookmarkStore =
      const BookmarkStore(bookmarkPreferenceKey);

  final RxSet<int> bookmarkedIds = <int>{}.obs;
  final RxBool showBookmarkedOnly = false.obs;

  int get bookmarkCount => bookmarkedIds.length;

  bool isBookmarked(int? id) => id != null && bookmarkedIds.contains(id);

  Future<void> toggleBookmark(int? id) async {
    if (id == null) return;
    if (bookmarkedIds.contains(id)) {
      bookmarkedIds.remove(id);
    } else {
      bookmarkedIds.add(id);
    }
    bookmarkedIds.refresh();
    _updateDisplayedData();
    await _bookmarkStore.save(bookmarkedIds);
  }

  void setShowBookmarkedOnly(bool value) {
    if (showBookmarkedOnly.value == value) return;
    showBookmarkedOnly.value = value;
    _itemsToDisplay.value = _perPage;
    _updateDisplayedData();
  }

  final RxList<DzikirModel> _allDzikirList = <DzikirModel>[].obs;
  List<DzikirModel> get allDzikir => _allDzikirList;
  final RxList<DzikirModel> displayedDzikirList = <DzikirModel>[].obs;

  final RxBool isLoading = true.obs;
  final RxBool isError = false.obs;

  final RxString searchQuery = "".obs;
  final int _perPage = 20;
  final RxInt _itemsToDisplay = 20.obs;

  final RxBool isLoadMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final savedBookmarks = await _bookmarkStore.load();
    bookmarkedIds
      ..clear()
      ..addAll(savedBookmarks);
    bookmarkedIds.refresh();
    await fetchDzikir();
  }

  Future<void> fetchDzikir() async {
    isLoading.value = true;
    isError.value = false;

    try {
      final List<DzikirModel>? result = await _dzikirSource.fetchLocalDzikir();

      if (result != null) {
        _allDzikirList.assignAll(result);
        _updateDisplayedData();
      } else {
        isError.value = true;
      }
    } catch (e) {
      isError.value = true;
    } finally {
      isLoading.value = false;
    }
  }

  void onSearch(String query) {
    searchQuery.value = query;
    _itemsToDisplay.value = _perPage; // reset pagination when searching
    _updateDisplayedData();
  }

  void loadMore() {
    if (!showBookmarkedOnly.value &&
        searchQuery.isEmpty &&
        _itemsToDisplay.value < _allDzikirList.length) {
      isLoadMore.value = true;

      Future.delayed(const Duration(milliseconds: 300), () {
        _itemsToDisplay.value += _perPage;
        _updateDisplayedData();
        isLoadMore.value = false;
      });
    }
  }

  void _updateDisplayedData() {
    final query = searchQuery.value.toLowerCase().trim();
    final filteredList = _allDzikirList.where((dzikir) {
      final matchesBookmark =
          !showBookmarkedOnly.value || isBookmarked(dzikir.id);
      if (!matchesBookmark) return false;
      if (query.isEmpty) return true;

      return (dzikir.nama?.toLowerCase().contains(query) ?? false) ||
          (dzikir.grup?.toLowerCase().contains(query) ?? false) ||
          (dzikir.ar?.toLowerCase().contains(query) ?? false) ||
          (dzikir.tr?.toLowerCase().contains(query) ?? false) ||
          (dzikir.idn?.toLowerCase().contains(query) ?? false);
    }).toList();

    if (query.isNotEmpty || showBookmarkedOnly.value) {
      displayedDzikirList.assignAll(filteredList);
    } else {
      final takeCount = _itemsToDisplay.value < filteredList.length
          ? _itemsToDisplay.value
          : filteredList.length;
      displayedDzikirList.assignAll(filteredList.take(takeCount).toList());
    }
  }
}
