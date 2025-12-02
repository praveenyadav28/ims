import 'package:ims/ui/sales/estimate/models/estimate_models.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';

class EstimateRepository {
  Future<List<CustomerModel>> fetchCustomers() async {
    final res = await ApiService.fetchData(
      'get/customer',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['data'] as List?) ?? [];
    return data
        .map((e) => CustomerModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<ItemServiceModel>> fetchCatalogue() async {
    final items = await ApiService.fetchData(
      'get/item',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final services = await ApiService.fetchData(
      'get/service',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final itemList = (items?['data'] as List?) ?? [];
    final serviceList = (services?['data'] as List?) ?? [];
    final combined = <ItemServiceModel>[];
    for (var it in itemList) {
      combined.add(ItemServiceModel.fromItem(Map<String, dynamic>.from(it)));
    }
    for (var s in serviceList) {
      combined.add(ItemServiceModel.fromService(Map<String, dynamic>.from(s)));
    }
    return combined;
  }

  Future<Map<String, dynamic>?> saveEstimate(
    Map<String, dynamic> payload,
  ) async {
    return await ApiService.postData(
      'estimate',
      payload,
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
  }

  Future<List<HsnModel>> fetchHsnList() async {
    final res = await ApiService.fetchData(
      "get/hsn",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final data = (res?['data'] as List?) ?? [];

    return data
        .map((e) => HsnModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }
}
