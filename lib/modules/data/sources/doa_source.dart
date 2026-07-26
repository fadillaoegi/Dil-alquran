import 'package:dilalquran/config/api_config.dart';
import 'package:dilalquran/modules/doa/model/doa_model.dart';
import 'package:dilalquran/services/offline_store.dart';
import 'package:get/get.dart';

class DoaSource extends GetConnect {
  Future<List<DoaModel>?> fetchAllDoa() async {
    try {
      final response = await get(ApiConfig.doa);

      if (!response.status.hasError &&
          response.body != null &&
          response.body['data'] != null) {
        List<dynamic> data = response.body['data'];
        List<DoaModel> doasList =
            data.map((json) => DoaModel.fromJson(json)).toList();
        await OfflineStore().saveDoa(doasList); // cache untuk offline
        return doasList;
      }
    } catch (e) {
      // ignore
    }
    // Fallback: doa yang tersimpan offline.
    return OfflineStore().readDoa();
  }
}
