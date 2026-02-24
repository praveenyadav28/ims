import 'package:excel/excel.dart' hide Border;
import 'package:ims/ui/report/gst_r1_report/gstr_1_total.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'dart:io';
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
        onTap: _exportGstr2Excel,
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

  Future<void> _exportGstr2Excel() async {
    final excel = Excel.createExcel();

    _addGstr2B2BSheet(excel);
    _addGstr2B2BURSheet(excel);
    _addGstr2CDNRSheet(excel);
    _addGstr2CDNURSheet(excel);
    _addGstr2HSNSheet(excel);
    _addGstr2DocsSheet(excel);
    _addGstr2ItcSheet(excel);

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      "${dir.path}/GSTR_2_${DateFormat('MMM_yyyy').format(DateTime.now())}.xlsx",
    );

    final bytes = excel.encode();
    await file.writeAsBytes(bytes!);

    await OpenFilex.open(file.path);
  }

  void _addHeader(Sheet sheet, List<String> headers) {
    sheet.appendRow(headers.map((e) => TextCellValue(e)).toList());
  }

  void _addGstr2B2BSheet(Excel excel) {
    final sheet = excel['B2B'];

    _addHeader(sheet, [
      "GSTIN of Supplier",
      "Invoice No",
      "Invoice Date",
      "Invoice Value",
      "Place Of Supply",
      "Reverse Charge",
      "Invoice Type",
      "Rate",
      "Taxable Value",
      "IGST Paid",
      "CGST Paid",
      "SGST Paid",
      "Eligibility for ITC",
      "Availed ITC IGST",
      "Availed ITC CGST",
      "Availed ITC SGST",
    ]);

    final sellerState = Preference.getString(PrefKeys.state);

    for (final inv in fInvoices) {
      final supplier = suppliers.firstWhere(
        (s) =>
            s.companyName.trim().toLowerCase() ==
            inv.supplierName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer,
      );

      if (supplier.gstType != "Registered Dealer") continue;

      final isInter =
          inv.placeOfSupply.toLowerCase() != sellerState.toLowerCase();

      for (final item in inv.itemDetails) {
        final taxable = (item.qty * item.price) * 100 / (100 + item.gstRate);
        final gstAmt = taxable * item.gstRate / 100;

        final igst = isInter ? gstAmt : 0;
        final cgst = isInter ? 0 : gstAmt / 2;
        final sgst = isInter ? 0 : gstAmt / 2;

        sheet.appendRow([
          TextCellValue(supplier.gstNo),
          TextCellValue("${inv.prefix}${inv.no}"),
          TextCellValue(
            DateFormat("dd-MMM-yyyy").format(inv.purchaseInvoiceDate),
          ),
          DoubleCellValue(inv.totalAmount),
          TextCellValue(inv.placeOfSupply),
          TextCellValue("N"),
          TextCellValue("Regular"),
          DoubleCellValue(item.gstRate),
          DoubleCellValue(taxable),
          DoubleCellValue(igst.toDouble()),
          DoubleCellValue(cgst.toDouble()),
          DoubleCellValue(sgst.toDouble()),
          TextCellValue("Eligible"),
          DoubleCellValue(igst.toDouble()),
          DoubleCellValue(cgst.toDouble()),
          DoubleCellValue(sgst.toDouble()),
        ]);
      }
    }
  }

  void _addGstr2B2BURSheet(Excel excel) {
    final sheet = excel['B2BUR'];

    _addHeader(sheet, [
      "Supplier Name",
      "Invoice No",
      "Invoice Date",
      "Invoice Value",
      "Place Of Supply",
      "Rate",
      "Taxable Value",
      "IGST",
      "CGST",
      "SGST",
    ]);

    final sellerState = Preference.getString(PrefKeys.state);

    for (final inv in fInvoices) {
      final supplier = suppliers.firstWhere(
        (s) =>
            s.companyName.trim().toLowerCase() ==
            inv.supplierName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer,
      );

      if (supplier.gstType == "Registered Dealer") continue;

      final isInter =
          inv.placeOfSupply.toLowerCase() != sellerState.toLowerCase();

      for (final item in inv.itemDetails) {
        final taxable = (item.qty * item.price) * 100 / (100 + item.gstRate);
        final gstAmt = taxable * item.gstRate / 100;

        sheet.appendRow([
          TextCellValue(inv.supplierName),
          TextCellValue("${inv.prefix}${inv.no}"),
          TextCellValue(
            DateFormat("dd-MMM-yyyy").format(inv.purchaseInvoiceDate),
          ),
          DoubleCellValue(inv.totalAmount),
          TextCellValue(inv.placeOfSupply),
          DoubleCellValue(item.gstRate),
          DoubleCellValue(taxable),
          DoubleCellValue(isInter ? gstAmt : 0),
          DoubleCellValue(isInter ? 0 : gstAmt / 2),
          DoubleCellValue(isInter ? 0 : gstAmt / 2),
        ]);
      }
    }
  }

  void _addGstr2CDNRSheet(Excel excel) {
    final sheet = excel['CDNR'];

    _addHeader(sheet, [
      "GSTIN of Supplier",
      "Supplier Name",
      "Note No",
      "Note Date",
      "Type (C/D)",
      "Place Of Supply",
      "Rate",
      "Taxable",
      "IGST",
      "CGST",
      "SGST",
    ]);

    final sellerState = Preference.getString(PrefKeys.state);

    for (final pr in fReturns) {
      final supplier = suppliers.firstWhere(
        (s) =>
            s.companyName.trim().toLowerCase() ==
            pr.supplierName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer,
      );
      if (supplier.gstType != "Registered Dealer") continue;

      final isInter =
          pr.placeOfSupply.toLowerCase() != sellerState.toLowerCase();

      for (final item in pr.itemDetails) {
        final taxable = (item.qty * item.price) * 100 / (100 + item.gstRate);
        final gstAmt = taxable * item.gstRate / 100;

        sheet.appendRow([
          TextCellValue(supplier.gstNo),
          TextCellValue(pr.supplierName),
          TextCellValue("${pr.prefix}${pr.no}"),
          TextCellValue(
            DateFormat("dd-MMM-yyyy").format(pr.purchaseReturnDate),
          ),
          TextCellValue("C"),
          TextCellValue(pr.placeOfSupply),
          DoubleCellValue(item.gstRate),
          DoubleCellValue(taxable),
          DoubleCellValue(isInter ? gstAmt : 0),
          DoubleCellValue(isInter ? 0 : gstAmt / 2),
          DoubleCellValue(isInter ? 0 : gstAmt / 2),
        ]);
      }
    }
  }

  void _addGstr2CDNURSheet(Excel excel) {
    final sheet = excel['CDNUR'];

    _addHeader(sheet, [
      "Supplier Name",
      "Note No",
      "Note Date",
      "Type (C/D)",
      "Place Of Supply",
      "Rate",
      "Taxable",
      "IGST",
      "CGST",
      "SGST",
    ]);

    final sellerState = Preference.getString(PrefKeys.state);

    for (final pr in fReturns) {
      final supplier = suppliers.firstWhere(
        (s) =>
            s.companyName.trim().toLowerCase() ==
            pr.supplierName.trim().toLowerCase(),
        orElse: () => TableStyle.emptyCustomer,
      );
      if (supplier.gstType == "Registered Dealer") continue;

      final isInter =
          pr.placeOfSupply.toLowerCase() != sellerState.toLowerCase();

      for (final item in pr.itemDetails) {
        final taxable = (item.qty * item.price) * 100 / (100 + item.gstRate);
        final gstAmt = taxable * item.gstRate / 100;

        sheet.appendRow([
          TextCellValue(pr.supplierName),
          TextCellValue("${pr.prefix}${pr.no}"),
          TextCellValue(
            DateFormat("dd-MMM-yyyy").format(pr.purchaseReturnDate),
          ),
          TextCellValue("C"),
          TextCellValue(pr.placeOfSupply),
          DoubleCellValue(item.gstRate),
          DoubleCellValue(taxable),
          DoubleCellValue(isInter ? gstAmt : 0),
          DoubleCellValue(isInter ? 0 : gstAmt / 2),
          DoubleCellValue(isInter ? 0 : gstAmt / 2),
        ]);
      }
    }
  }

  void _addGstr2HSNSheet(Excel excel) {
    final sheet = excel['HSN'];

    _addHeader(sheet, [
      "HSN",
      "Description",
      "Qty",
      "Total Value",
      "Rate",
      "Taxable",
      "IGST",
      "CGST",
      "SGST",
      "Cess",
    ]);

    final sellerState = Preference.getString(PrefKeys.state);

    for (final inv in fInvoices) {
      final isInter =
          inv.placeOfSupply.toLowerCase() != sellerState.toLowerCase();

      for (final item in inv.itemDetails) {
        final gross = item.qty * item.price;
        final taxable = gross * 100 / (100 + item.gstRate);
        final gstAmt = taxable * item.gstRate / 100;

        sheet.appendRow([
          TextCellValue(item.hsn),
          TextCellValue(item.name),
          DoubleCellValue(item.qty),
          DoubleCellValue(gross),
          DoubleCellValue(item.gstRate),
          DoubleCellValue(taxable),
          DoubleCellValue(isInter ? gstAmt : 0),
          DoubleCellValue(isInter ? 0 : gstAmt / 2),
          DoubleCellValue(isInter ? 0 : gstAmt / 2),
          DoubleCellValue(0),
        ]);
      }
    }
  }

  void _addGstr2DocsSheet(Excel excel) {
    final sheet = excel['DOCS'];

    _addHeader(sheet, [
      "Nature of Document",
      "Sr. No. From",
      "Sr. No. To",
      "Total",
      "Cancelled",
    ]);

    if (fInvoices.isNotEmpty) {
      final nums = fInvoices.map((e) => e.no).toList()..sort();
      sheet.appendRow([
        TextCellValue("Invoices for inward supply"),
        IntCellValue(nums.first),
        IntCellValue(nums.last),
        IntCellValue(nums.length),
        IntCellValue(0),
      ]);
    }
  }

  void _addGstr2ItcSheet(Excel excel) {
    final sheet = excel['ITC'];

    _addHeader(sheet, ["Type of ITC", "ITC Available", "ITC Availed"]);

    double igst = 0, cgst = 0, sgst = 0;

    final sellerState = Preference.getString(PrefKeys.state);

    for (final inv in fInvoices) {
      final isInter =
          inv.placeOfSupply.toLowerCase() != sellerState.toLowerCase();

      for (final item in inv.itemDetails) {
        final taxable = (item.qty * item.price) * 100 / (100 + item.gstRate);
        final gstAmt = taxable * item.gstRate / 100;

        if (isInter) {
          igst += gstAmt;
        } else {
          cgst += gstAmt / 2;
          sgst += gstAmt / 2;
        }
      }
    }

    sheet.appendRow([
      TextCellValue("IGST"),
      DoubleCellValue(igst),
      DoubleCellValue(igst),
    ]);
    sheet.appendRow([
      TextCellValue("CGST"),
      DoubleCellValue(cgst),
      DoubleCellValue(cgst),
    ]);
    sheet.appendRow([
      TextCellValue("SGST"),
      DoubleCellValue(sgst),
      DoubleCellValue(sgst),
    ]);
  }
}
