// import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:ims/ui/sales/models/sale_invoice_data.dart';
// import 'package:ims/ui/sales/models/sale_return_data.dart';
// import 'package:ims/ui/sales/models/debitnote_model.dart';
// import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
// import 'package:ims/ui/sales/models/purchase_return_data.dart';
// import 'package:ims/ui/sales/models/credit_note_data.dart';
// import 'package:ims/utils/api.dart';
// import 'package:ims/utils/button.dart';
// import 'package:ims/utils/colors.dart';
// import 'package:ims/utils/prefence.dart';
// import 'package:ims/utils/sizes.dart';
// import 'package:ims/utils/textfield.dart';
// import 'package:intl/intl.dart';

// class Gstr3BDashboardScreen extends StatefulWidget {
//   const Gstr3BDashboardScreen({super.key});

//   @override
//   State<Gstr3BDashboardScreen> createState() => _Gstr3BDashboardScreenState();
// }

// class _Gstr3BDashboardScreenState extends State<Gstr3BDashboardScreen> {
//   bool loading = false;

//   DateTime? fromDate;
//   DateTime? toDate;

//   final fromCtrl = TextEditingController();
//   final toCtrl = TextEditingController();

//   List<SaleInvoiceData> saleInvoices = [];
//   List<SaleReturnData> saleReturns = [];
//   List<DebitNoteData> debitNotes = [];

//   List<PurchaseInvoiceData> purchaseInvoices = [];
//   List<PurchaseReturnData> purchaseReturns = [];
//   List<CreditNoteData> creditNotes = [];

//   double outIgst = 0, outCgst = 0, outSgst = 0;
//   double itcIgst = 0, itcCgst = 0, itcSgst = 0;
//   double netIgst = 0, netCgst = 0, netSgst = 0;

//   @override
//   void initState() {
//     super.initState();
//     _setCurrentMonth();
//     loadAll();
//   }

//   void _setCurrentMonth() {
//     final now = DateTime.now();
//     fromDate = DateTime(now.year, now.month, 1);
//     toDate = DateTime(now.year, now.month + 1, 0);
//     fromCtrl.text = DateFormat("dd-MM-yyyy").format(fromDate!);
//     toCtrl.text = DateFormat("dd-MM-yyyy").format(toDate!);
//   }

//   Future<void> loadAll() async {
//     setState(() => loading = true);

//     final results = await Future.wait([
//       ApiService.fetchData("get/invoice", licenceNo: Preference.getint(PrefKeys.licenseNo)),
//       ApiService.fetchData("get/returnsale", licenceNo: Preference.getint(PrefKeys.licenseNo)),
//       ApiService.fetchData("get/debitnote", licenceNo: Preference.getint(PrefKeys.licenseNo)),
//       ApiService.fetchData("get/purchaseinvoice", licenceNo: Preference.getint(PrefKeys.licenseNo)),
//       ApiService.fetchData("get/purchasereturn", licenceNo: Preference.getint(PrefKeys.licenseNo)),
//       ApiService.fetchData("get/purchasenote", licenceNo: Preference.getint(PrefKeys.licenseNo)),
//     ]);

//     saleInvoices = SaleInvoiceListResponse.fromJson(results[0]).data;
//     saleReturns = SaleReturnListResponse.fromJson(results[1]).data;
//     debitNotes = DebitNoteListResponse.fromJson(results[2]).data;

//     purchaseInvoices = PurchaseInvoiceListResponse.fromJson(results[3]).data;
//     purchaseReturns = PurchaseReturnListResponse.fromJson(results[4]).data;
//     creditNotes = CreditNoteListResponse.fromJson(results[5]).data;

//     calculate3B();
//     setState(() => loading = false);
//   }

//   void calculate3B() {
//     outIgst = outCgst = outSgst = 0;
//     itcIgst = itcCgst = itcSgst = 0;

//     final sellerState = Preference.getString(PrefKeys.state).toLowerCase();

//     bool inRange(DateTime d) =>
//         d.isAfter(fromDate!) && d.isBefore(toDate!.add(const Duration(days: 1)));

//     void addTax(bool isInter, double taxable, double rate, bool outward) {
//       final gst = taxable * rate / 100;
//       if (outward) {
//         if (isInter) outIgst += gst;
//         else {
//           outCgst += gst / 2;
//           outSgst += gst / 2;
//         }
//       } else {
//         if (isInter) itcIgst += gst;
//         else {
//           itcCgst += gst / 2;
//           itcSgst += gst / 2;
//         }
//       }
//     }

//     for (final inv in saleInvoices.where((e) => inRange(e.saleInvoiceDate))) {
//       final isInter = inv.placeOfSupply.toLowerCase() != sellerState;
//       for (final item in inv.itemDetails) {
//         final taxable = item.qty * item.price * 100 / (100 + item.gstRate);
//         addTax(isInter, taxable, item.gstRate, true);
//       }
//     }

//     for (final inv in purchaseInvoices.where((e) => inRange(e.purchaseInvoiceDate))) {
//       final isInter = inv.placeOfSupply.toLowerCase() != sellerState;
//       for (final item in inv.itemDetails) {
//         final taxable = item.qty * item.price * 100 / (100 + item.gstRate);
//         addTax(isInter, taxable, item.gstRate, false);
//       }
//     }

//     netIgst = outIgst - itcIgst;
//     netCgst = outCgst - itcCgst;
//     netSgst = outSgst - itcSgst;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColor.white,
//       appBar: AppBar(
//         backgroundColor: AppColor.black,
//         title: Text("GSTR-3B Report", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
//       ),
//       body: loading
//           ? const Center(child: CircularProgressIndicator())
//           : Padding(
//               padding: EdgeInsets.all(Sizes.width * .02),
//               child: ListView(
//                 children: [
//                   _filters(),
//                   _sectionTitle("3.1 Outward Supplies"),
//                   _cardRow("Outward Taxable Supplies", outIgst, outCgst, outSgst),

//                   _sectionTitle("4. ITC Available"),
//                   _cardRow("Input Tax Credit", itcIgst, itcCgst, itcSgst),

//                   _sectionTitle("6. Net GST Payable"),
//                   _cardRow("Net Payable", netIgst, netCgst, netSgst),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _filters() => Row(
//         children: [
//           _date("From", fromCtrl, (d) => fromDate = d),
//           const SizedBox(width: 10),
//           _date("To", toCtrl, (d) => toDate = d),
//           const SizedBox(width: 10),
//           defaultButton(
//             onTap: () => setState(calculate3B),
//             text: "Apply",
//             height: 40,
//             width: 120,
//             buttonColor: AppColor.primary,
//           ),
//         ],
//       );

//   Widget _date(String label, TextEditingController c, Function(DateTime) onPick) {
//     return SizedBox(
//       width: 180,
//       child: CommonTextField(
//         controller: c,
//         readOnly: true,
//         hintText: label,
//         onTap: () async {
//           final d = await showDatePicker(
//             context: context,
//             firstDate: DateTime(2020),
//             lastDate: DateTime(2100),
//           );
//           if (d != null) {
//             c.text = DateFormat("dd-MM-yyyy").format(d);
//             onPick(d);
//           }
//         },
//       ),
//     );
//   }

//   Widget _sectionTitle(String title) => Padding(
//         padding: const EdgeInsets.symmetric(vertical: 10),
//         child: Text(title, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
//       );

//   Widget _cardRow(String title, double igst, double cgst, double sgst) {
//     return Card(
//       elevation: 1,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//       child: Padding(
//         padding: const EdgeInsets.all(12),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
//             Row(
//               children: [
//                 _pill("IGST", igst),
//                 _pill("CGST", cgst),
//                 _pill("SGST", sgst),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _pill(String label, double value) {
//     return Container(
//       margin: const EdgeInsets.only(left: 6),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: const Color(0xffeef1f7),
//         borderRadius: BorderRadius.circular(20),
//       ),
//       child: Text("$label ₹${value.toStringAsFixed(2)}"),
//     );
//   }
// }