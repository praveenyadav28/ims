import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/ui/report/gst_r2_report/gst_r2_b2b.dart';
import 'package:ims/ui/report/gst_r2_report/gst_r2_b2bur.dart';
import 'package:ims/ui/report/gst_r2_report/gst_r2_cdnr.dart';
import 'package:ims/ui/report/gst_r2_report/gst_r2_cdnur.dart';
import 'package:ims/ui/report/gst_r2_report/gst_r2_docs.dart';
import 'package:ims/ui/report/gst_r2_report/gst_r2_hsn.dart';
import 'package:ims/ui/report/gst_r2_report/gst_r2_itc.dart';
import 'package:ims/ui/sales/models/credit_note_data.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
// import 'package:ims/ui/report/gst_r2_report/gstr2_b2b.dart';
// import 'package:ims/ui/report/gst_r2_report/gstr2_b2bur.dart';
// import 'package:ims/ui/report/gst_r2_report/gstr2_cdnr.dart';
// import 'package:ims/ui/report/gst_r2_report/gstr2_hsn.dart';
// import 'package:ims/ui/report/gst_r2_report/gstr2_docs.dart';
import 'package:ims/ui/sales/models/purchase_return_data.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class Gstr2DashboardScreen extends StatefulWidget {
  const Gstr2DashboardScreen({super.key});

  @override
  State<Gstr2DashboardScreen> createState() => _Gstr2DashboardScreenState();
}

class _Gstr2DashboardScreenState extends State<Gstr2DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  bool loading = false;

  DateTime? fromDate;
  DateTime? toDate;

  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();

  List<PurchaseInvoiceData> invoices = [];
  List<PurchaseReturnData> returns = [];
  List<CreditNoteData> creditNotes = [];
  List<Customer> suppliers = [];

  List<PurchaseInvoiceData> fInvoices = [];
  List<PurchaseReturnData> fReturns = [];
  List<CreditNoteData> fNotes = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 9, vsync: this);
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => loading = true);

    final results = await Future.wait([
      ApiService.fetchData(
        "get/purchaseinvoice",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      ),
      ApiService.fetchData(
        "get/purchasereturn",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      ),
      ApiService.fetchData(
        "get/purchasenote",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      ),
      ApiService.fetchData(
        "get/supplier",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      ),
    ]);

    invoices = PurchaseInvoiceListResponse.fromJson(results[0]).data;
    returns = PurchaseReturnListResponse.fromJson(results[1]).data;
    creditNotes = CreditNoteListResponse.fromJson(results[2]).data;
    suppliers = (results[3]['data'] as List)
        .map((e) => Customer.fromJson(e))
        .toList();

    applyFilter();
    setState(() => loading = false);
  }

  void applyFilter() {
    bool inRange(DateTime d) {
      if (fromDate == null || toDate == null) return true;
      return d.isAfter(fromDate!) &&
          d.isBefore(toDate!.add(const Duration(days: 1)));
    }

    fInvoices = invoices.where((e) => inRange(e.purchaseInvoiceDate)).toList();
    fReturns = returns.where((e) => inRange(e.purchaseReturnDate)).toList();
    fNotes = creditNotes.where((e) => inRange(e.creditNoteDate)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.black,
        title: Text(
          "GSTR-2 Report",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.white,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          vertical: Sizes.height * .02,
          horizontal: Sizes.width * .02,
        ),
        child: Column(
          children: [
            _filters(),
            SizedBox(height: Sizes.height * .02),
            Card(
              color: AppColor.appbarColor,
              child: TabBar(
                controller: _tab,
                unselectedLabelColor: AppColor.black,
                labelColor: AppColor.white,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: AppColor.primary,
                ),
                tabs: const [
                  Tab(text: "B2B"),
                  Tab(text: "B2BUR"),
                  Tab(text: "CDNR"),
                  Tab(text: "CDNUR"),
                  Tab(text: "AT"),
                  Tab(text: "ATADJ"),
                  Tab(text: "HSN"),
                  Tab(text: "DOCS"),
                  Tab(text: "ITC"),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: GlowLoader())
                  : Card(
                      child: TabBarView(
                        controller: _tab,
                        children: [
                          Gstr2B2BReportScreen(
                            invoices: fInvoices,
                            suppliers: suppliers,
                          ),
                          Gstr2B2BURReportScreen(
                            invoices: fInvoices,
                            suppliers: suppliers,
                          ),

                          Gstr2CdnrReportScreen(
                            purchaseReturns: fReturns,
                            creditNotes: fNotes,
                            suppliers: suppliers,
                          ),

                          Gstr2CdnurReportScreen(
                            purchaseReturns: fReturns,
                            creditNotes: fNotes,
                            suppliers: suppliers,
                          ),
                          Center(child: Text("No Data Found")),
                          Center(child: Text("No Data Found")),
                          Gstr2HsnSummaryScreen(
                            invoices: fInvoices,
                            sellerState: Preference.getString(PrefKeys.state),
                          ),

                          Gstr2DocsReportScreen(
                            invoices: fInvoices,
                            purchaseReturns: fReturns,
                            creditNotes: fNotes,
                          ),
                          Gstr2ItcSummaryScreen(
                            invoices: fInvoices,
                            purchaseReturns: fReturns,
                            creditNotes: fNotes,
                            sellerState: Preference.getString(PrefKeys.state),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters() => Row(
    children: [
      _date("From Date", fromCtrl, (d) => fromDate = d),
      const SizedBox(width: 10),
      _date("To Date", toCtrl, (d) => toDate = d),
      const SizedBox(width: 10),
      defaultButton(
        onTap: () => setState(applyFilter),
        text: "Apply",
        height: 40,
        width: 120,
        buttonColor: AppColor.blue,
      ),
      const SizedBox(width: 10),
      InkWell(
        onTap: () async {},
        child: Container(
          width: 50,
          height: 40,
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            color: AppColor.white,
            border: Border.all(width: 1, color: AppColor.borderColor),
          ),
          child: Image.asset("assets/images/excel.png"),
        ),
      ),
    ],
  );

  Widget _date(
    String label,
    TextEditingController c,
    Function(DateTime) onPick,
  ) {
    return SizedBox(
      width: 250,
      child: CommonTextField(
        controller: c,
        readOnly: true,
        hintText: label,
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (d != null) {
            c.text = DateFormat("dd-MM-yyyy").format(d);
            onPick(d);
          }
        },
      ),
    );
  }
}
