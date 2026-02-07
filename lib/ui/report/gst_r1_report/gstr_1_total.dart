import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/ui/report/gst_r1_report/docs.dart';
import 'package:ims/ui/report/gst_r1_report/gst_r1_b2b.dart';
import 'package:ims/ui/report/gst_r1_report/gst_r1_b2cs.dart';
import 'package:ims/ui/report/gst_r1_report/gst_r1_cdnr.dart';
import 'package:ims/ui/report/gst_r1_report/gst_r1_cdnur.dart';
import 'package:ims/ui/report/gst_r1_report/gst_r1_hsn.dart';
import 'package:ims/ui/report/gst_r1_report/gst_rq_b2cl.dart';
import 'package:ims/ui/sales/models/debitnote_model.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/ui/sales/models/sale_return_data.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class Gstr1DashboardScreen extends StatefulWidget {
  const Gstr1DashboardScreen({super.key});

  @override
  State<Gstr1DashboardScreen> createState() => _Gstr1DashboardScreenState();
}

class _Gstr1DashboardScreenState extends State<Gstr1DashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  bool loading = false;

  DateTime? fromDate;
  DateTime? toDate;

  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();

  List<SaleInvoiceData> invoices = [];
  List<SaleReturnData> saleReturns = [];
  List<DebitNoteData> debitNotes = [];
  List<Customer> customers = [];

  List<SaleInvoiceData> fInvoices = [];
  List<SaleReturnData> fReturns = [];
  List<DebitNoteData> fNotes = [];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 10, vsync: this);
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => loading = true);

    final results = await Future.wait([
      ApiService.fetchData(
        "get/invoice",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      ),
      ApiService.fetchData(
        "get/returnsale",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      ),
      ApiService.fetchData(
        "get/debitnote",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      ),
      ApiService.fetchData(
        "get/customer",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      ),
    ]);

    invoices = SaleInvoiceListResponse.fromJson(results[0]).data;
    saleReturns = SaleReturnListResponse.fromJson(results[1]).data;
    debitNotes = DebitNoteListResponse.fromJson(results[2]).data;
    customers = (results[3]['data'] as List)
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

    fInvoices = invoices.where((e) => inRange(e.saleInvoiceDate)).toList();
    fReturns = saleReturns.where((e) => inRange(e.saleReturnDate)).toList();
    fNotes = debitNotes.where((e) => inRange(e.debitNoteDate)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.black,
        title: Text(
          "GSTR-1 Report",
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
            SizedBox(
              width: double.infinity,
              child: Card(
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
                    Tab(text: "B2CL"),
                    Tab(text: "B2CS"),
                    Tab(text: "CDNR"),
                    Tab(text: "CDNUR"),
                    Tab(text: "EXP"),
                    Tab(text: "AT"),
                    Tab(text: "ATADJ"),
                    Tab(text: "HSN"),
                    Tab(text: "DOCS"),
                  ],
                ),
              ),
            ),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
                      child: ClipRRect(
                        borderRadius: BorderRadiusGeometry.circular(6),
                        child: TabBarView(
                          controller: _tab,
                          children: [
                            Gstr1B2BReportScreen(
                              invoices: fInvoices,
                              customers: customers,
                            ),
                            Gstr1B2CLReportScreen(
                              invoices: fInvoices,
                              customers: customers,
                            ),
                            Gstr1B2CSReportScreen(
                              invoices: fInvoices,
                              customers: customers,
                            ),
                            Gstr1CdnrReportScreen(
                              saleReturns: fReturns,
                              debitNotes: fNotes,
                              customers: customers,
                            ),
                            Gstr1CDNURReportScreen(
                              saleReturns: fReturns,
                              debitNotes: fNotes,
                              customers: customers,
                            ),
                            const Center(child: Text("No Data")),
                            const Center(child: Text("No Data")),
                            const Center(child: Text("No Data")),
                            Gstr1HsnSummaryScreen(
                              invoices: fInvoices,
                              sellerState: Preference.getString(PrefKeys.state),
                            ),
                            Gstr1DocsReportScreen(
                              invoices: fInvoices,
                              saleReturns: fReturns,
                              debitNotes: fNotes,
                            ),
                          ],
                        ),
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

class TableStyle {
  static DataColumn label(text) {
    return DataColumn(
      headingRowAlignment: MainAxisAlignment.center,
      label: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
        textAlign: TextAlign.center,
      ),
    );
  }

  static DataCell labelCell(text) {
    return DataCell(
      Center(
        child: Text(
          text,
          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w400),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  static var emptyCustomer = Customer(
    id: '',
    licenceNo: 0,
    branchId: '',
    customerType: '',
    title: '',
    firstName: '',
    lastName: '',
    related: '',
    parents: '',
    parentsLast: '',
    companyName: '',
    email: '',
    mobile: '',
    pan: '',
    gstType: '',
    gstNo: '',
    address: '',
    city: '',
    state: '',
    openingBalance: 0,
    closingBalance: 0,
    address0: '',
    address1: '',
    documents: [],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    v: 0,
  );
  static Widget globalSum(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Row(
        children: [
          Text(label, style: GoogleFonts.inter(color: Colors.black87)),
          const SizedBox(width: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
