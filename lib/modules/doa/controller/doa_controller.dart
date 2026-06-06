import 'package:dilalquran/modules/data/sources/doa_source.dart';
import 'package:dilalquran/modules/doa/model/doa_model.dart';
import 'package:get/get.dart';

class DoaController extends GetxController {
  final DoaSource _doaSource = DoaSource();

  final RxList<DoaModel> _allDoaList = <DoaModel>[].obs;
  final RxList<DoaModel> displayedDoasList = <DoaModel>[].obs;
  
  final RxBool isLoading = true.obs;
  final RxBool isError = false.obs;

  final RxString searchQuery = "".obs;
  final int _perPage = 20;
  final RxInt _itemsToDisplay = 20.obs;

  final RxBool isLoadMore = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDoa();
  }

  void fetchDoa() async {
    isLoading.value = true;
    isError.value = false;

    try {
      final List<DoaModel>? result = await _doaSource.fetchAllDoa();
      
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
    // Hanya load more jika tidak sedang mencari dan data yang ditampilkan masih kurang dari total data
    if (searchQuery.isEmpty && _itemsToDisplay.value < _allDoaList.length) {
      isLoadMore.value = true;
      
      // Delay sedikit agar terasa natural seperti mengambil data (meskipun lokal)
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
      final filteredList = _allDoaList.where((doa) {
        return (doa.nama?.toLowerCase().contains(query) ?? false) ||
               (doa.ar?.toLowerCase().contains(query) ?? false) ||
               (doa.tr?.toLowerCase().contains(query) ?? false) ||
               (doa.idn?.toLowerCase().contains(query) ?? false);
      }).toList();
      displayedDoasList.assignAll(filteredList);
    } else {
      final int takeCount = _itemsToDisplay.value < _allDoaList.length ? _itemsToDisplay.value : _allDoaList.length;
      displayedDoasList.assignAll(_allDoaList.take(takeCount).toList());
    }
  }
}
