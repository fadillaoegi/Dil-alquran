import 'package:dilalquran/modules/data/sources/doa_source.dart';
import 'package:dilalquran/modules/doa/model/doa_model.dart';
import 'package:dilalquran/services/bookmark_store.dart';
import 'package:get/get.dart';

class DoaController extends GetxController {
  final DoaSource _doaSource = DoaSource();
  static const String allCategory = 'Semua';
  static const String bookmarkPreferenceKey = 'dilalquran_doa_bookmarks';
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

  final RxList<DoaModel> _allDoaList = <DoaModel>[].obs;
  List<DoaModel> get allDoa => _allDoaList;
  final RxList<DoaModel> displayedDoasList = <DoaModel>[].obs;

  final RxBool isLoading = true.obs;
  final RxBool isError = false.obs;

  final RxString searchQuery = "".obs;
  final RxString selectedCategory = allCategory.obs;
  final int _perPage = 20;
  final RxInt _itemsToDisplay = 20.obs;

  final RxBool isLoadMore = false.obs;

  List<String> get localCategories {
    final categories = _allDoaList
        .map((doa) => (doa.grup ?? '').trim())
        .where((grup) => grup.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return [allCategory, ...categories];
  }

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
    await fetchDoa();
  }

  void selectCategory(String category) {
    if (selectedCategory.value == category) return;
    selectedCategory.value = category;
    _itemsToDisplay.value = _perPage;
    _updateDisplayedData();
  }

  Future<void> fetchDoa() async {
    isLoading.value = true;
    isError.value = false;

    try {
      final List<DoaModel>? result = await _doaSource.fetchLocalDoa();

      if (result != null) {
        _allDoaList.assignAll(result);
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
    final hasCategoryFilter = selectedCategory.value != allCategory;
    if (!hasCategoryFilter &&
        !showBookmarkedOnly.value &&
        searchQuery.isEmpty &&
        _itemsToDisplay.value < _allDoaList.length) {
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
    final category = selectedCategory.value;

    final filteredList = _allDoaList.where((doa) {
      final matchesBookmark = !showBookmarkedOnly.value || isBookmarked(doa.id);
      if (!matchesBookmark) return false;

      final matchesCategory = category == allCategory ||
          (doa.grup ?? '').trim().toLowerCase() == category.toLowerCase();
      if (!matchesCategory) return false;

      if (query.isEmpty) return true;

      return (doa.nama?.toLowerCase().contains(query) ?? false) ||
          (doa.ar?.toLowerCase().contains(query) ?? false) ||
          (doa.tr?.toLowerCase().contains(query) ?? false) ||
          (doa.idn?.toLowerCase().contains(query) ?? false);
    }).toList();

    final hasFilter =
        query.isNotEmpty || category != allCategory || showBookmarkedOnly.value;
    if (hasFilter) {
      displayedDoasList.assignAll(filteredList);
    } else {
      final takeCount = _itemsToDisplay.value < filteredList.length
          ? _itemsToDisplay.value
          : filteredList.length;
      displayedDoasList.assignAll(filteredList.take(takeCount).toList());
    }
  }
}
