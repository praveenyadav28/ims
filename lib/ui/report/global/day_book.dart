// top of file
import 'dart:io';
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class DayBookReportScreen extends StatefulWidget {
  const DayBookReportScreen({super.key});

  @override
  State<DayBookReportScreen> createState() => _DayBookReportScreenState();
}

class _DayBookReportScreenState extends State<DayBookReportScreen> {
  bool loading = false;

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 1));
  DateTime toDate = DateTime.now();

  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();

  List<_DayBookRow> rows = [];

  @override
  void initState() {
    super.initState();
    fromCtrl.text = DateFormat("yyyy-MM-dd").format(fromDate);
    toCtrl.text = DateFormat("yyyy-MM-dd").format(toDate);
    loadData();
  }

  Future<void> loadData() async {
    setState(() => loading = true);

    final res = await ApiService.fetchData(
      "get/trangection?from_date=${fromCtrl.text}&to_date=${toCtrl.text}",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    rows.clear();

    final List data = res['data'] ?? [];
    if (data.isNotEmpty) {
      final obj = data.first;

      void mapList(List list, String type) {
        for (final e in list) {
          rows.add(_DayBookRow.fromJson(e, type));
        }
      }

      mapList(obj['sale'] ?? [], "Sale");
      mapList(obj['Salereturn'] ?? [], "Sale Return");
      mapList(obj['Purchase'] ?? [], "Purchase");
      mapList(obj['Purchasereturn'] ?? [], "Purchase Return");
      mapList(obj['Debit'] ?? [], "Debit Note");
      mapList(obj['Purchasenote'] ?? [], "Credit Note");
      mapList(obj['Contra'] ?? [], "Contra");
      mapList(obj['Journal'] ?? [], "Journal");
      mapList(obj['Payment'] ?? [], "Payment");
      mapList(obj['Reciept'] ?? [], "Receipt");
      mapList(obj['Estimate'] ?? [], "Estimate");
      mapList(obj['proforma'] ?? [], "Proforma");
      mapList(obj['Dilvery'] ?? [], "Delivery Challan");
    }

    rows.sort((a, b) => a.date.compareTo(b.date));

    setState(() => loading = false);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        title: Text(
          "Day Book",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _filters(),
            SizedBox(height: Sizes.height * .02),
            Expanded(child: _table()),
          ],
        ),
      ),
    );
  }

  Widget _filters() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _date("From", fromCtrl, (d) {
          fromDate = d;
        }),
        const SizedBox(width: 12),
        _date("To", toCtrl, (d) {
          toDate = d;
        }),
        const SizedBox(width: 12),
        defaultButton(
          onTap: loadData,
          text: "Apply",
          height: 40,
          width: 120,
          buttonColor: AppColor.primary,
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: exportDayBookExcel,
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
  }

  Widget _date(
    String label,
    TextEditingController c,
    Function(DateTime) onPick,
  ) {
    return SizedBox(
      width: 200,
      child: TitleTextFeild(
        titleText: label,
        controller: c,
        onTap: () async {
          final d = await showDatePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
            initialDate: DateTime.now(),
          );
          if (d != null) {
            c.text = DateFormat("yyyy-MM-dd").format(d);
            onPick(d);
          }
        },
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
      ),
    );
  }

  Widget _table() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _header(),
          const Divider(height: 1),
          Expanded(
            child: loading
                ? const Center(child: GlowLoader())
                : rows.isEmpty
                ? const Center(child: Text("No Transactions Found"))
                : ListView.separated(
                    itemCount: rows.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (_, i) => _row(rows[i], i),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: const [
          _H("Date", 2),
          _H("Type", 2),
          _H("Voucher No", 2),
          _H("Party / Ledger", 4),
          _H("Amount", 2),
        ],
      ),
    );
  }

  Widget _row(_DayBookRow r, int i) {
    return Container(
      color: i.isEven ? const Color(0xffF9FAFB) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _C(DateFormat("dd-MM-yyyy").format(r.date), 2),
          _C(r.type, 2),
          _C("${r.prefix}${r.voucherNo}", 2),
          _C(r.party, 4),
          _C(r.amount.toStringAsFixed(2), 2),
        ],
      ),
    );
  }

  Future<void> exportDayBookExcel() async {
    if (rows.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No data to export")));
      return;
    }

    final excel = Excel.createExcel();
    final sheet = excel['Day Book'];

    CellValue cv(dynamic v) {
      if (v == null) return TextCellValue('');
      if (v is num) return DoubleCellValue(v.toDouble());
      return TextCellValue(v.toString());
    }

    // 🔹 Header Info (like FIFO/Bank Book style)
    sheet.appendRow([cv('From Date'), cv('To Date'), cv(''), cv(''), cv('')]);

    sheet.appendRow([
      cv(fromCtrl.text),
      cv(toCtrl.text),
      cv(''),
      cv(''),
      cv(''),
    ]);

    // 🔹 Table Header
    sheet.appendRow([
      cv('Date'),
      cv('Type'),
      cv('Voucher No'),
      cv('Party / Ledger'),
      cv('Amount'),
    ]);

    // 🔹 Data Rows
    for (final r in rows) {
      sheet.appendRow([
        cv(DateFormat("dd-MM-yyyy").format(r.date)),
        cv(r.type),
        cv("${r.prefix}${r.voucherNo}"),
        cv(r.party),
        cv(r.amount),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File(
      "${dir.path}/DayBook_${DateFormat('ddMMyyyy_HHmm').format(DateTime.now())}.xlsx",
    );

    final bytes = excel.encode();
    await file.writeAsBytes(bytes!);
    await OpenFilex.open(file.path);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Day Book Excel exported successfully")),
    );
  }
}

// ================= ROW MODEL =================
class _DayBookRow {
  final DateTime date;
  final String type;
  final String prefix;
  final int voucherNo;
  final String party;
  final double amount;

  _DayBookRow({
    required this.date,
    required this.type,
    required this.prefix,
    required this.voucherNo,
    required this.party,
    required this.amount,
  });
  factory _DayBookRow.fromJson(Map<String, dynamic> j, String type) {
    String dateStr =
        j['date'] ??
        j['returnsale_date'] ??
        j['purchaseinvoice_date'] ??
        j['purchasereturn_date'] ??
        j['invoice_date'] ??
        j['estimate_date'] ??
        j['proforma_date'] ??
        "";

    DateTime parsedDate;
    try {
      parsedDate = dateStr.isNotEmpty
          ? DateTime.parse(dateStr)
          : DateTime.now();
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return _DayBookRow(
      date: parsedDate,
      type: type,
      prefix: (j['prefix'] ?? "").toString(),
      voucherNo: (j['vouncher_no'] ?? j['no'] ?? 0) as int,
      party:
          (j['customer_name'] ??
                  j['supplier_name'] ??
                  j['ledger_name'] ??
                  j['account_name'] ??
                  "-")
              .toString(),
      amount: (j['amount'] ?? j['totle_amo'] ?? j['totalAmount'] ?? 0)
          .toDouble(),
    );
  }
}

// ================= SMALL UI =================
class _H extends StatelessWidget {
  final String t;
  final int f;
  const _H(this.t, this.f);
  @override
  Widget build(BuildContext context) => Expanded(
    flex: f,
    child: Center(
      child: Text(
        t,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}

class _C extends StatelessWidget {
  final String t;
  final int f;
  const _C(this.t, this.f);
  @override
  Widget build(BuildContext context) => Expanded(
    flex: f,
    child: Center(
      child: Text(
        t,
        style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
  );
}
