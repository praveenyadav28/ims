import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/colors.dart';

class TrialBalanceScreen extends StatefulWidget {
  const TrialBalanceScreen({super.key});

  @override
  State<TrialBalanceScreen> createState() => _TrialBalanceScreenState();
}

class _TrialBalanceScreenState extends State<TrialBalanceScreen> {
  final fromCtrl = TextEditingController();
  final toCtrl = TextEditingController();

  DateTime fromDate = DateTime(DateTime.now().year, 4, 1);
  DateTime toDate = DateTime(DateTime.now().year + 1, 3, 31);

  bool loading = false;
  bool hideZero = false;

  List<_LedgerRow> rows = [];
  Map<String, _GroupSum> groupSums = {};

  double totalDr = 0;
  double totalCr = 0;

  @override
  void initState() {
    super.initState();
    fromCtrl.text = _fmt(fromDate);
    toCtrl.text = _fmt(toDate);
    fetchTB();
  }

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> pickDate(TextEditingController c, bool isFrom) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isFrom ? fromDate : toDate,
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        if (isFrom) {
          fromDate = d;
          fromCtrl.text = _fmt(d);
        } else {
          toDate = d;
          toCtrl.text = _fmt(d);
        }
      });
    }
  }

  String _reportGroup(String rawGroup, String ledgerName) {
    final name = ledgerName.toLowerCase();
    if (name == 'purchases') return 'Purchase Accounts';
    if (name == 'sales') return 'Sales Accounts';

    if (rawGroup == 'Bank Account' ||
        rawGroup == 'Cash In Hand' ||
        rawGroup == 'Sundry Debtor')
      return 'Current Assets';
    if (rawGroup == 'Sundry Creditor') return 'Current Liabilities';
    if (rawGroup == 'Expense' || rawGroup == 'Misc Charges')
      return 'Expenses (InDirect)';
    if (rawGroup == 'Income') return 'Sales Accounts';
    if (rawGroup == 'Fixed Asset') return 'Fixed Assets';
    if (rawGroup == 'Capital') return 'Capital Account';
    if (rawGroup == 'Loans (Liability)') return 'Loans (Liability)';
    return rawGroup;
  }

  Future<void> fetchTB() async {
    setState(() => loading = true);

    final res = await ApiService.fetchData(
      "get/ledgers?from_date=${fromCtrl.text}&to_date=${toCtrl.text}",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final List list = res['data'] ?? [];

    rows.clear();
    groupSums.clear();
    totalDr = 0;
    totalCr = 0;

    for (final e in list) {
      final name = e['ledger_name'] ?? '';
      final rawGroup = e['ledger_group'] ?? '';
      final group = _reportGroup(rawGroup, name);
      final bal = (e['closing_balance'] ?? 0).toDouble();

      if (hideZero && bal == 0) continue;

      double dr = 0, cr = 0;
      if (bal > 0) {
        dr = bal;
        totalDr += dr;
      } else if (bal < 0) {
        cr = bal.abs();
        totalCr += cr;
      }

      rows.add(_LedgerRow(name: name, group: group, dr: dr, cr: cr));

      groupSums.putIfAbsent(group, () => _GroupSum());
      groupSums[group]!.dr += dr;
      groupSums[group]!.cr += cr;
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    // final balanced = (totalDr - totalCr).abs() < 0.01;

    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColor.primary,
        title: Text(
          "Trial Balance",
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        actions: [
          // Row(
          //   children: [
          //     const Text("Hide Zero", style: TextStyle(color: Colors.white)),
          //     Switch(
          //       value: hideZero,
          //       onChanged: (v) {
          //         setState(() => hideZero = v);
          //         fetchTB();
          //       },
          //     ),
          //   ],
          // ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _filterCard(),

                  const SizedBox(height: 16),
                  _sectionTitle("Category Summary"),
                  _cardTable(
                    header: const ["Category", "Dr.", "Cr."],
                    rows: groupSums.entries
                        .map((e) => [e.key, _amt(e.value.dr), _amt(e.value.cr)])
                        .toList(),
                  ),
                  _totalRow(totalDr, totalCr),

                  const SizedBox(height: 24),
                  _sectionTitle("Account-wise Details"),
                  _cardTable(
                    header: const ["Account", "Category", "Dr.", "Cr."],
                    rows: rows
                        .map((r) => [r.name, r.group, _amt(r.dr), _amt(r.cr)])
                        .toList(),
                  ),
                  _totalRow(totalDr, totalCr),

                  // const SizedBox(height: 12),
                  // Row(
                  //   children: [
                  //     Icon(
                  //       balanced
                  //           ? Icons.verified_rounded
                  //           : Icons.warning_rounded,
                  //       color: balanced ? Colors.green : Colors.red,
                  //     ),
                  //     const SizedBox(width: 8),
                  //     Text(
                  //       balanced
                  //           ? "Trial Balance Matched"
                  //           : "Trial Balance Mismatch",
                  //       style: GoogleFonts.inter(
                  //         fontWeight: FontWeight.w700,
                  //         color: balanced ? Colors.green : Colors.red,
                  //       ),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
    );
  }

  // =================== UI Components ===================

  Widget _filterCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDeco(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _dateBox(fromCtrl, true),
          const SizedBox(width: 12),
          _dateBox(toCtrl, false),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: fetchTB,
            icon: const Icon(Icons.search),
            label: const Text("Apply"),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColor.primary,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      t,
      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );

  Widget _cardTable({
    required List<String> header,
    required List<List<String>> rows,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: _cardDeco(),
      child: Column(
        children: [
          _modernHeader(header),
          const Divider(height: 1),
          ...rows.asMap().entries.map((e) => _modernRow(e.value, e.key)),
        ],
      ),
    );
  }

  Widget _modernHeader(List<String> cols) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColor.primary, AppColor.primary.withOpacity(.85)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Expanded(flex: 4, child: _h(cols[0])),
          if (cols.length == 4) Expanded(flex: 3, child: _h(cols[1])),
          Expanded(child: _h(cols[cols.length - 2], right: true)),
          Expanded(child: _h(cols.last, right: true)),
        ],
      ),
    );
  }

  Widget _modernRow(List<String> cols, int i) {
    final even = i.isEven;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      color: even ? const Color(0xffF9FAFB) : Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              cols[0],
              style: GoogleFonts.inter(fontWeight: FontWeight.w500),
            ),
          ),
          if (cols.length == 4)
            Expanded(
              flex: 3,
              child: Text(
                cols[1],
                style: GoogleFonts.inter(color: Colors.grey[700]),
              ),
            ),
          Expanded(
            child: Text(cols[cols.length - 2], textAlign: TextAlign.right),
          ),
          Expanded(child: Text(cols.last, textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _totalRow(double dr, double cr) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              "Total",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              _amt(dr),
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            child: Text(
              _amt(cr),
              textAlign: TextAlign.right,
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBox(TextEditingController c, bool isFrom) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(1990),
          lastDate: DateTime(2100),
          initialDate: isFrom ? fromDate : toDate,
        );
        if (d != null) {
          setState(() {
            if (isFrom) {
              fromDate = d;
              fromCtrl.text = _fmt(d);
            } else {
              toDate = d;
              toCtrl.text = _fmt(d);
            }
          });
        }
      },
      child: Container(
        width: 140,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColor.backgroundColor),
          borderRadius: BorderRadius.circular(5),
          color: Colors.white,
        ),
        child: Text(
          c.text,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  BoxDecoration _cardDeco() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 12)],
    border: Border.all(color: Colors.black12),
  );

  Widget _h(String t, {bool right = false}) => Text(
    t,
    textAlign: right ? TextAlign.right : TextAlign.left,
    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700),
  );

  String _amt(double v) => v == 0 ? "0.00" : v.toStringAsFixed(2);
}

class _LedgerRow {
  final String name;
  final String group;
  final double dr;
  final double cr;
  _LedgerRow({
    required this.name,
    required this.group,
    required this.dr,
    required this.cr,
  });
}

class _GroupSum {
  double dr = 0;
  double cr = 0;
}
