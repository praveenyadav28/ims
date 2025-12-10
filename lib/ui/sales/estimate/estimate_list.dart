import 'package:flutter/material.dart';
import 'package:ims/ui/sales/data/transection_list.dart';
import 'package:ims/ui/sales/estimate/widgets/estimate_pdf.dart';
import '../models/estimate_data.dart';
import '../estimate/estimate_screen.dart';
import '../data/global_repository.dart';
import '../../../utils/navigation.dart';

class EstimateListScreen extends StatelessWidget {
  final repo = GLobalRepository();

  EstimateListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TransactionListScreen<EstimateData>(
      title: "Estimate",

      /// API Call
      fetchData: repo.getEstimates,

      /// ACTIONS
      onView: generateEstimatePdf,
      onEdit: (e) => pushTo(CreateEstimateFullScreen(estimateData: e)),
      onDelete: repo.deleteEstimate,
      onCreate: () => pushTo(CreateEstimateFullScreen()),

      /// EXTRACTORS — REQUIRED
      idGetter: (e) => e.id,
      dateGetter: (e) => e.estimateDate,
      numberGetter: (e) => "${e.prefix}-${e.no}",
      customerGetter: (e) => e.customerName,
      amountGetter: (e) => e.totalAmount,
    );
  }
}
