import 'package:dilalquran/modules/data/sources/dzikir_source.dart';
import 'package:dilalquran/modules/dzikir/model/dzikir_model.dart';
import 'package:get/get.dart';

class DzikirController extends GetxController {
  final DzikirSource _dzikirSource = DzikirSource();

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
    fetchDzikir();
  }

  Future<void> fetchDzikir() async {
    isLoading.value = true;
    isError.value = false;

    try {
      final List<DzikirModel>? result =
          await _dzikirSource.fetchLocalDzikir();

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
    if (searchQuery.isEmpty && _itemsToDisplay.value < _allDzikirList.length) {
      isLoadMore.value = true;

      Future.delayed(const Duration(milliseconds: 300), () {
        _itemsToDisplay.value += _perPage;
        _updateDisplayedData();
        isLoadMore.value = false;
      });
    }
  }

  void _updateDisplayedData() {
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      final filteredList = _allDzikirList.where((dzikir) {
        return (dzikir.nama?.toLowerCase().contains(query) ?? false) ||
            (dzikir.grup?.toLowerCase().contains(query) ?? false) ||
            (dzikir.ar?.toLowerCase().contains(query) ?? false) ||
            (dzikir.tr?.toLowerCase().contains(query) ?? false) ||
            (dzikir.idn?.toLowerCase().contains(query) ?? false);
      }).toList();
      displayedDzikirList.assignAll(filteredList);
    } else {
      final int takeCount = _itemsToDisplay.value < _allDzikirList.length
          ? _itemsToDisplay.value
          : _allDzikirList.length;
      displayedDzikirList.assignAll(_allDzikirList.take(takeCount).toList());
    }
  }
}
