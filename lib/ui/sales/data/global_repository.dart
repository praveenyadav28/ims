import 'dart:typed_data';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/ui/sales/models/common_data.dart';
import 'package:ims/ui/sales/models/credit_note_data.dart';
import 'package:ims/ui/sales/models/debitnote_model.dart';
import 'package:ims/ui/sales/models/dilivery_data.dart';
import 'package:ims/ui/sales/models/estimate_data.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/sales/models/performa_data.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/ui/sales/models/purchase_return_data.dart';
import 'package:ims/ui/sales/models/purchaseorder_model.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/ui/sales/models/sale_return_data.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';

class GLobalRepository {
  Future<List<LedgerModelDrop>> fetchLedger(bool isCustomer) async {
    final res = await ApiService.fetchData(
      'get/ledger',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['data'] as List?) ?? [];
    return data
        .where(
          (e) =>
              e['ledger_group'] ==
              (isCustomer ? 'Sundry Debtor' : 'Sundry Creditor'),
        )
        .map((e) => LedgerModelDrop.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  //
  //Get Auto no
  Future<String> fetchEstimateNo() async {
    final res = await ApiService.fetchData(
      'get/estimate_no',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['next_no'].toString()) ?? '';
    print(data);
    return data;
  }

  Future<String> fetchPerformaNo() async {
    final res = await ApiService.fetchData(
      'get/proforma_no',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['next_no'].toString()) ?? '';
    print(data);
    return data;
  }

  Future<String> fetchSaleInvoiceNo() async {
    final res = await ApiService.fetchData(
      'get/invoice_no',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['next_no'].toString()) ?? '';
    print(data);
    return data;
  }

  Future<String> fetchSaleReturnNo() async {
    final res = await ApiService.fetchData(
      'get/returnsale_no',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['next_no'].toString()) ?? '';
    print(data);
    return data;
  }

  Future<String> fetchDiliveryChallanNo() async {
    final res = await ApiService.fetchData(
      'get/dilverychallan_no',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['next_no'].toString()) ?? '';
    print(data);
    return data;
  }

  Future<String> fetchDebitNoteNo() async {
    final res = await ApiService.fetchData(
      'get/debitnote_no',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['next_no'].toString()) ?? '';
    print(data);
    return data;
  }

  Future<String> fetchPurchaseOrderNo() async {
    final res = await ApiService.fetchData(
      'get/purchaseoder_no',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['next_no'].toString()) ?? '';
    print(data);
    return data;
  }

  Future<String> fetchPurchaseInvoiceNo() async {
    final res = await ApiService.fetchData(
      'get/purchaseinvoice_no',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['next_no'].toString()) ?? '';
    print(data);
    return data;
  }

  Future<String> fetchPurchaseReturnNo() async {
    final res = await ApiService.fetchData(
      'get/purchasereturn_no',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['next_no'].toString()) ?? '';
    print(data);
    return data;
  }

  Future<String> fetchCreditNoteNo() async {
    final res = await ApiService.fetchData(
      'get/purchasenote_no',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    final data = (res?['next_no'].toString()) ?? '';
    print(data);
    return data;
  }

  //
  //Get Item/Service/Misc
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

  Future<List<ItemServiceModel>> fetchOnyItem() async {
    final items = await ApiService.fetchData(
      'get/item',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final itemList = (items?['data'] as List?) ?? [];
    final combined = <ItemServiceModel>[];
    for (var it in itemList) {
      combined.add(ItemServiceModel.fromItem(Map<String, dynamic>.from(it)));
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

  //
  //Save Trans
  Future<Map<String, dynamic>?> saveEstimate({
    required Map<String, dynamic> payload,
    Uint8List? signatureFile,
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

  Future<Map<String, dynamic>?> savePerfroma({
    required Map<String, dynamic> payload,
    Uint8List? signatureFile,
    String? updateId,
  }) async {
    return await ApiService.uploadMultipart(
      endpoint: updateId != null ? "proforma/$updateId" : "proforma",
      fields: payload,
      file: signatureFile,
      fileKey: "signature",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
      updateStatus: updateId != null,
    );
  }

  Future<Map<String, dynamic>?> saveSaleInvoice({
    required Map<String, dynamic> payload,
    Uint8List? signatureFile,
    String? updateId,
  }) async {
    return await ApiService.uploadMultipart(
      endpoint: updateId != null ? "invoice/$updateId" : "invoice",
      fields: payload,
      file: signatureFile,
      fileKey: "signature",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
      updateStatus: updateId != null,
    );
  }

  Future<Map<String, dynamic>?> saveSaleReturn({
    required Map<String, dynamic> payload,
    Uint8List? signatureFile,
    String? updateId,
  }) async {
    return await ApiService.uploadMultipart(
      endpoint: updateId != null ? "returnsale/$updateId" : "returnsale",
      fields: payload,
      file: signatureFile,
      fileKey: "signature",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
      updateStatus: updateId != null,
    );
  }

  Future<Map<String, dynamic>?> saveDiliveryChallan({
    required Map<String, dynamic> payload,
    Uint8List? signatureFile,
    String? updateId,
  }) async {
    return await ApiService.uploadMultipart(
      endpoint: updateId != null
          ? "dilverychallan/$updateId"
          : "dilverychallan",
      fields: payload,
      file: signatureFile,
      fileKey: "signature",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
      updateStatus: updateId != null,
    );
  }

  Future<Map<String, dynamic>?> saveDebitNote({
    required Map<String, dynamic> payload,
    Uint8List? signatureFile,
    String? updateId,
  }) async {
    return await ApiService.uploadMultipart(
      endpoint: updateId != null ? "debitnote/$updateId" : "debitnote",
      fields: payload,
      file: signatureFile,
      fileKey: "signature",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
      updateStatus: updateId != null,
    );
  }

  Future<Map<String, dynamic>?> savePurchaseOrder({
    required Map<String, dynamic> payload,
    Uint8List? signatureFile,
    String? updateId,
  }) async {
    return await ApiService.uploadMultipart(
      endpoint: updateId != null ? "purchaseoder/$updateId" : "purchaseoder",
      fields: payload,
      file: signatureFile,
      fileKey: "signature",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
      updateStatus: updateId != null,
    );
  }

  Future<Map<String, dynamic>?> savePurchaseInvoice({
    required Map<String, dynamic> payload,
    Uint8List? signatureFile,
    String? updateId,
  }) async {
    return await ApiService.uploadMultipart(
      endpoint: updateId != null
          ? "purchaseinvoice/$updateId"
          : "purchaseinvoice",
      fields: payload,
      file: signatureFile,
      fileKey: "signature",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
      updateStatus: updateId != null,
    );
  }

  Future<Map<String, dynamic>?> savePurchaseReturn({
    required Map<String, dynamic> payload,
    Uint8List? signatureFile,
    String? updateId,
  }) async {
    return await ApiService.uploadMultipart(
      endpoint: updateId != null
          ? "purchasereturn/$updateId"
          : "purchasereturn",
      fields: payload,
      file: signatureFile,
      fileKey: "signature",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
      updateStatus: updateId != null,
    );
  }

  Future<Map<String, dynamic>?> saveCreditNote({
    required Map<String, dynamic> payload,
    Uint8List? signatureFile,
    String? updateId,
  }) async {
    return await ApiService.uploadMultipart(
      endpoint: updateId != null ? "purchasenote/$updateId" : "purchasenote",
      fields: payload,
      file: signatureFile,
      fileKey: "signature",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
      updateStatus: updateId != null,
    );
  }

  //
  //Gst HSN
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

  //
  //Get List
  Future<List<EstimateData>> getEstimates() async {
    final res = await ApiService.fetchData(
      "get/estimate",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res == null) return [];

    final parsed = EstimateListResponse.fromJson(res);
    return parsed.data;
  }

  Future<List<SaleInvoiceData>> getSaleInvoice() async {
    final res = await ApiService.fetchData(
      "get/invoice",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res == null) return [];

    final parsed = SaleInvoiceListResponse.fromJson(res);
    return parsed.data;
  }

  Future<List<SaleReturnData>> getSaleReturn() async {
    final res = await ApiService.fetchData(
      "get/returnsale",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res == null) return [];

    final parsed = SaleReturnListResponse.fromJson(res);
    return parsed.data;
  }

  Future<List<PerformaData>> getPerforma() async {
    final res = await ApiService.fetchData(
      "get/proforma",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final parsed = PerformaListResponse.fromJson(res);
    return parsed.data;
  }

  Future<List<DiliveryChallanData>> getDiliveryChallan() async {
    final res = await ApiService.fetchData(
      "get/dilverychallan",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final parsed = DiliveryChallanListResponse.fromJson(res);
    return parsed.data;
  }

  Future<List<DebitNoteData>> getDebitNote() async {
    final res = await ApiService.fetchData(
      "get/debitnote",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final parsed = DebitNoteListResponse.fromJson(res);
    return parsed.data;
  }

  Future<List<PurchaseOrderData>> getPurchaseOrder() async {
    final res = await ApiService.fetchData(
      "get/purchaseoder",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final parsed = PurchaseOrderListResponse.fromJson(res);
    return parsed.data;
  }

  Future<List<PurchaseInvoiceData>> getPurchaseInvoice() async {
    final res = await ApiService.fetchData(
      "get/purchaseinvoice",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final parsed = PurchaseInvoiceListResponse.fromJson(res);
    return parsed.data;
  }

  Future<List<PurchaseReturnData>> getPurchaseReturn() async {
    final res = await ApiService.fetchData(
      "get/purchasereturn",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final parsed = PurchaseReturnListResponse.fromJson(res);
    return parsed.data;
  }

  Future<List<CreditNoteData>> getCreditNote() async {
    final res = await ApiService.fetchData(
      "get/purchasenote",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final parsed = CreditNoteListResponse.fromJson(res);
    return parsed.data;
  }

  //
  //Get By number
  Future<GlobalDataAll> getTransByNumber({
    required int transNo,
    required String transType,
  }) async {
    final res = await ApiService.postData("get/getreletedrecode", {
      "trans_no": transNo,
      "trans_type": transType,
      "licence_no": Preference.getint(PrefKeys.licenseNo),
    }, licenceNo: Preference.getint(PrefKeys.licenseNo));
    return GlobalDataAll.fromJson(res['data']);
  }

  Future<GlobalDataAllPurchase> getTransByNumberPurchase({
    required int transNo,
    required String transType,
  }) async {
    print(transType);
    final res = await ApiService.postData("get/getreletedrecode", {
      "trans_no": transNo,
      "trans_type": transType,
      "licence_no": Preference.getint(PrefKeys.licenseNo),
    }, licenceNo: Preference.getint(PrefKeys.licenseNo));
    return GlobalDataAllPurchase.fromJson(res['data']);
  }

  //
  //Delete
  Future<bool> deleteEstimate(String id) async {
    final res = await ApiService.deleteData(
      "estimate/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    return (res?["status"] == true);
  }

  Future<bool> deleteSaleInvoice(String id) async {
    final res = await ApiService.deleteData(
      "invoice/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    return (res?["status"] == true);
  }

  Future<bool> deleteSaleReturn(String id) async {
    final res = await ApiService.deleteData(
      "returnsale/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    return (res?["status"] == true);
  }

  Future<bool> deletePerforma(String id) async {
    final res = await ApiService.deleteData(
      "proforma/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    return (res?["status"] == true);
  }

  Future<bool> deleteDiliveryChallan(String id) async {
    final res = await ApiService.deleteData(
      "dilverychallan/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    return (res?["status"] == true);
  }

  Future<bool> deleteDebitNote(String id) async {
    final res = await ApiService.deleteData(
      "debitnote/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    return (res?["status"] == true);
  }

  Future<bool> deletePurchaseOrder(String id) async {
    final res = await ApiService.deleteData(
      "purchaseoder/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    return (res?["status"] == true);
  }

  Future<bool> deletePurchaseInvoice(String id) async {
    final res = await ApiService.deleteData(
      "purchaseinvoice/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    return (res?["status"] == true);
  }

  Future<bool> deletePurchaseReturn(String id) async {
    final res = await ApiService.deleteData(
      "purchasereturn/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    return (res?["status"] == true);
  }

  Future<bool> deleteCreditNote(String id) async {
    final res = await ApiService.deleteData(
      "purchasenote/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    return (res?["status"] == true);
  }
}
