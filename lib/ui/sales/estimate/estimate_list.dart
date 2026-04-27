import 'package:flutter/material.dart';
import 'package:ims/ui/master/company/company_api.dart';
import 'package:ims/ui/sales/data/reuse_print.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/utils/print_mapper.dart';
import '../models/estimate_data.dart';
import '../estimate/estimate_screen.dart';
import '../data/global_repository.dart';
import '../../../utils/navigation.dart';

class EstimateListScreen extends StatefulWidget {
  const EstimateListScreen({super.key});

  @override
  State<EstimateListScreen> createState() => _EstimateListScreenState();
}

class _EstimateListScreenState extends State<EstimateListScreen> {
  final repo = GLobalRepository();

  /// 🔑 Use PUBLIC state type (no underscore)
  final GlobalKey<TransactionListScreenState<EstimateData>> listKey =
      GlobalKey<TransactionListScreenState<EstimateData>>();

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<EstimateData>(
      key: listKey, // 👈 VERY IMPORTANT
      title: "Estimate",
      module: "Estimate",

      /// API Call
      fetchData: repo.getEstimates,

      /// ACTIONS
      onView: (e) async {
        try {
          FocusManager.instance.primaryFocus?.unfocus(); // 🔥 FIX

          final doc = e.toPrintModel();

          final companyApi = await CompanyProfileAPi.getCompanyProfile();
          final company = CompanyPrintProfile.fromApi(companyApi["data"][0]);

          await PdfEngine.printPremiumInvoice(doc: doc, company: company);
        } catch (err) {
          print("ERROR: $err");
        }
      },

      onEdit: (e) async {
        final result = await pushTo(CreateEstimateFullScreen(estimateData: e));

        if (result == true) {
          listKey.currentState?.load(); // ✅ reload list
        }
      },

      onDelete: repo.deleteEstimate,

      onCreate: () async {
        final result = await pushTo(CreateEstimateFullScreen());

        if (result == true) {
          listKey.currentState?.load(); // ✅ reload list
        }
      },

      /// EXTRACTORS — REQUIRED
      idGetter: (e) => e.id,
      dateGetter: (e) => e.estimateDate,
      numberGetter: (e) =>
          "${e.prefix}${e.prefix.isNotEmpty ? '/' : ''}${e.no}",
      customerGetter: (e) => e.customerName,
      amountGetter: (e) => e.totalAmount,
      mobile: (e) => e.mobile,
      gstGetter: (e) => e.subGst,
      basicGetter: (e) => e.subTotal,
      placeOfSupply: (e) => e.placeOfSupply,
    );
  }
}
