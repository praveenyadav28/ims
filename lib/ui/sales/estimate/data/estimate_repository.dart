import 'package:image_picker/image_picker.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/sales/estimate/models/estimate_models.dart';
import 'package:ims/ui/sales/estimate/models/estimateget_model.dart';
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

  Future<String> fetchEstimateNo() async {
    final res = await ApiService.fetchData(
      'get/estimate_no',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['next_no'].toString()) ?? '';
    print(data);
    return data;
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

  Future<List<MiscChargeModelList>> fetchMiscMaster() async {
    final res = await ApiService.fetchData(
      "get/misccharge",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res["status"] == true) {
      return (res["data"] as List)
          .map((e) => MiscChargeModelList.fromJson(e))
          .toList();
    } else {
      return [];
    }
  }

  Future<Map<String, dynamic>?> saveEstimate({
    required Map<String, dynamic> payload,
    XFile? signatureFile,
    String? updateId,
  }) async {
    return await ApiService.uploadMultipart(
      endpoint: updateId != null ? "estimate/$updateId" : "estimate",
      fields: payload,
      file: signatureFile,
      fileKey: "signature",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
      updateStatus: updateId != null,
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

  Future<List<EstimateData>> getEstimates() async {
    final res = await ApiService.fetchData(
      "get/estimate",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res == null) return [];

    final parsed = EstimateListResponse.fromJson(res);
    return parsed.data;
  }

  Future<bool> deleteEstimate(String id) async {
    final res = await ApiService.deleteData(
      "estimate/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    return (res?["status"] == true);
  }
}
