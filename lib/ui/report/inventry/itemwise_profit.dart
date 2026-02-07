import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/inventry/item_model.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';

class FifoReportScreen extends StatefulWidget {
  const FifoReportScreen({super.key});

  @override
  State<FifoReportScreen> createState() => _FifoReportScreenState();
}

class _FifoReportScreenState extends State<FifoReportScreen> {
  bool loading = true;

  List<FifoReportModel> list = [];

  TextEditingController fromDateCtrl = TextEditingController(
    text: DateFormat("dd-MM-yyyy").format(DateTime.now()),
  );
  TextEditingController toDateCtrl = TextEditingController(
    text: DateFormat("dd-MM-yyyy").format(DateTime.now()),
  );

  DateTime? fromDate;
  DateTime? toDate;
  TextEditingController searchCtrl = TextEditingController();
  String searchText = "";
  List<FifoReportModel> get filteredList {
    if (searchText.isEmpty) return list;

    return list.where((e) {
      return e.itemName.toLowerCase().contains(searchText.toLowerCase()) ||
          e.itemNo.toLowerCase().contains(searchText.toLowerCase());
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    setFinancialYear();
    fetchReport();
  }

  // ================= FINANCIAL YEAR =================
  void setFinancialYear() {
    final now = DateTime.now();

    if (now.month >= 4) {
      fromDate = DateTime(now.year, 4, 1);
      toDate = DateTime(now.year + 1, 3, 31);
    } else {
      fromDate = DateTime(now.year - 1, 4, 1);
      toDate = DateTime(now.year, 3, 31);
    }

    fromDateCtrl.text = DateFormat("dd/MM/yyyy").format(fromDate!);
    toDateCtrl.text = DateFormat("dd/MM/yyyy").format(toDate!);
  }

  String _fmt(DateTime? d) =>
      d == null ? "" : DateFormat("yyyy-MM-dd").format(d);

  // ================= API =================
  Future<void> fetchReport() async {
    setState(() => loading = true);

    final res = await ApiService.fetchData(
      "get/fiforeports?from_date=${_fmt(fromDate)}&to_date=${_fmt(toDate)}",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    list = (res['data'] as List)
        .map((e) => FifoReportModel.fromJson(e))
        .toList();

    setState(() => loading = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        title: const Text("Profit/Loss Report"),
      ),
      body: Column(
        children: [
          _filterBar(),
          Expanded(child: _table()),
        ],
      ),
    );
  }

  // ================= FILTER BAR =================
  Widget _filterBar() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: CommonTextField(
              controller: searchCtrl,
              hintText: "Search Item",
              suffixIcon: const Icon(Icons.search),
              onChanged: (v) {
                setState(() {
                  searchText = v;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          _dateField("From Date", fromDateCtrl, (d) => fromDate = d),
          const SizedBox(width: 10),
          _dateField("To Date", toDateCtrl, (d) => toDate = d),
          const SizedBox(width: 12),
          defaultButton(
            onTap: fetchReport,
            buttonColor: AppColor.blue,
            text: "🔍 Search",
            height: 40,
            width: 180,
          ),
        ],
      ),
    );
  }

  // ================= TABLE =================
  Widget _table() {
    if (loading) {
      return Center(child: GlowLoader());
    }

    if (list.isEmpty) {
      return const Center(child: Text("No data found"));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [_header(), ...filteredList.map(_row)],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: AppColor.primary,
      child: Row(
        children: [
          _th("Item Name"),
          _th("Item No"),
          _th("Sale"),
          _th("Sale Return"),
          _th("Purchase"),
          _th("Purchase Return"),
          _th("Opening"),
          _th("Closing"),
          _th("Tax Rec."),
          _th("Tax Pay."),
          _th("Profit/Loss"),
        ],
      ),
    );
  }

  Widget _row(FifoReportModel i) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _td(i.itemName),
          _td(i.itemNo),
          _td(i.saleAmount),
          _td(i.saleReturnAmount),
          _td(i.purchaseAmount),
          _td(i.purchaseReturnAmount),
          _td(i.openingStock),
          _td(i.closingStock),
          _td(i.taxReceivable),
          _td(i.taxPayable),
          _td(
            i.netProfitLoss,
            color: i.netProfitLoss.startsWith('-') ? Colors.red : Colors.green,
          ),
        ],
      ),
    );
  }

  // ================= WIDGET HELPERS =================
  Widget _th(String text) => Expanded(
    child: Text(
      text,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    ),
  );

  Widget _td(String text, {Color? color}) => Expanded(
    child: Text(
      text == "NaN" ? "0" : text,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: color ?? Colors.black,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  Widget _dateField(
    String label,
    TextEditingController ctrl,
    Function(DateTime) onPick,
  ) {
    return Expanded(
      child: CommonTextField(
        controller: ctrl,
        readOnly: true,
        hintText: label,
        suffixIcon: const Icon(Icons.calendar_today),

        onTap: () async {
          final d = await showDatePicker(
            context: context,

            firstDate: DateTime(1990),
            lastDate: DateTime(2100),
            initialDate: DateTime.now(),
          );
          if (d != null) {
            ctrl.text = DateFormat("dd-MM-yyyy").format(d);
            onPick(d);
          }
        },
      ),
    );
  }
}
