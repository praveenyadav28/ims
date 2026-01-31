import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:searchfield/searchfield.dart';

import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/textfield.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/ui/sales/data/global_repository.dart';
import 'package:ims/ui/sales/models/global_models.dart';

class ItemLedgerScreen extends StatefulWidget {
  const ItemLedgerScreen({super.key});

  @override
  State<ItemLedgerScreen> createState() => _ItemLedgerScreenState();
}

class _ItemLedgerScreenState extends State<ItemLedgerScreen> {
  final df = DateFormat('dd-MM-yyyy');

  final repo = GLobalRepository();

  final TextEditingController itemCtrl = TextEditingController();
  final TextEditingController fromCtrl = TextEditingController();
  final TextEditingController toCtrl = TextEditingController();

  List<ItemServiceModel> items = [];
  ItemServiceModel? selectedItem;

  DateTime fromDate = DateTime.now();
  DateTime toDate = DateTime.now();

  List<ItemLedgerRow> ledger = [];

  double openingStock = 0;
  double inward = 0;
  double outward = 0;

  @override
  void initState() {
    super.initState();
    setFinancialYear();
    loadItems();
    fromCtrl.text = df.format(fromDate);
    toCtrl.text = df.format(toDate);
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

    fromCtrl.text = DateFormat("dd/MM/yyyy").format(fromDate);
    toCtrl.text = DateFormat("dd/MM/yyyy").format(toDate);
  }

  Future<void> loadItems() async {
    items = await repo.fetchOnyItem();
    setState(() {});
  }

  // ================= LOAD LEDGER =================
  Future<void> loadLedger() async {
    if (selectedItem == null) return;

    ledger.clear();
    inward = 0;
    outward = 0;

    final res = await ApiService.fetchData(
      "get/itemrecodes/${selectedItem!.id}",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    openingStock = (res['Item']['opening_stock'] ?? 0).toDouble();

    void addEntry({
      required DateTime date,
      required String type,
      required int no,
      required String party,
      required double qty,
      required double rate,
      required double amount,
    }) {
      double effect = 0;

      if (type == "Purchase" || type == "Sale Return") {
        effect = qty;
      } else {
        effect = -qty;
      }

      // opening stock calculation
      if (date.isBefore(fromDate)) {
        openingStock += effect;
        return;
      }

      if (date.isAfter(toDate)) return;

      if (effect > 0) inward += qty;
      if (effect < 0) outward += qty.abs();

      ledger.add(
        ItemLedgerRow(
          date: date,
          tranNo: no.toString(),
          type: type,
          party: party,
          inwardQty: effect > 0 ? qty : 0,
          outwardQty: effect < 0 ? qty.abs() : 0,
          rate: rate,
          value: amount,
        ),
      );
    }

    /// PURCHASE
    for (var p in res['Purchaseinvoice'] ?? []) {
      for (var i in p['item_details']) {
        addEntry(
          date: DateTime.parse(p['purchaseinvoice_date']),
          type: "Purchase",
          no: p['no'],
          party: p['supplier_name'],
          qty: i['qty'].toDouble(),
          rate: i['price'].toDouble(),
          amount: i['amount'].toDouble(),
        );
      }
    }

    /// PURCHASE RETURN
    for (var p in res['Purchasereturn'] ?? []) {
      for (var i in p['item_details']) {
        addEntry(
          date: DateTime.parse(p['purchasereturn_date']),
          type: "Purchase Return",
          no: p['no'],
          party: p['supplier_name'],
          qty: i['qty'].toDouble(),
          rate: i['price'].toDouble(),
          amount: i['amount'].toDouble(),
        );
      }
    }

    /// SALE
    for (var s in res['Saleinvoice'] ?? []) {
      for (var i in s['item_details']) {
        addEntry(
          date: DateTime.parse(s['invoice_date']),
          type: "Sale",
          no: s['no'],
          party: s['customer_name'],
          qty: i['qty'].toDouble(),
          rate: i['price'].toDouble(),
          amount: i['amount'].toDouble(),
        );
      }
    }

    /// SALE RETURN
    for (var s in res['Salereturn'] ?? []) {
      for (var i in s['item_details']) {
        addEntry(
          date: DateTime.parse(s['returnsale_date']),
          type: "Sale Return",
          no: s['no'],
          party: s['customer_name'],
          qty: i['qty'].toDouble(),
          rate: i['price'].toDouble(),
          amount: i['amount'].toDouble(),
        );
      }
    }

    setState(() {});
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Item Ledger"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [_filterRow(), const SizedBox(height: 16), _ledgerCard()],
        ),
      ),
    );
  }

  Widget _filterRow() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CommonSearchableDropdownField<ItemServiceModel>(
            controller: itemCtrl,
            hintText: "Select Item",
            suggestions: items
                .map((e) => SearchFieldListItem(e.name, item: e))
                .toList(),
            onSuggestionTap: (v) {
              selectedItem = v.item;
              itemCtrl.text = v.item!.name;
            },
          ),
        ),
        const SizedBox(width: 10),
        _dateField("From Date", fromCtrl, true),
        const SizedBox(width: 10),
        _dateField("To Date", toCtrl, false),
        const SizedBox(width: 10),
        defaultButton(
          text: "Submit",
          width: 170,
          height: 42,
          onTap: loadLedger,
          buttonColor: AppColor.primary,
        ),
      ],
    );
  }

  Widget _dateField(String label, TextEditingController ctrl, bool isFrom) {
    return Expanded(
      child: CommonTextField(
        hintText: label,
        controller: ctrl,
        readOnly: true,
        suffixIcon: const Icon(Icons.calendar_today),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            firstDate: DateTime(2020),
            lastDate: DateTime.now(),
            initialDate: isFrom ? fromDate : toDate,
          );
          if (picked != null) {
            setState(() {
              if (isFrom) {
                fromDate = picked;
                fromCtrl.text = df.format(picked);
              } else {
                toDate = picked;
                toCtrl.text = df.format(picked);
              }
            });
          }
        },
      ),
    );
  }

  // ================= LEDGER TABLE =================
  Widget _ledgerCard() {
    final balance = openingStock + inward - outward;

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
          ],
        ),
        child: Column(
          children: [
            _tableHeader(),
            Expanded(child: _tableBody()),
            _summary(balance),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xff111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: const Row(
        children: [
          _Head("Date", 2),
          _Head("No", 1),
          _Head("Type", 2),
          _Head("Party", 3),
          _Head("In", 1),
          _Head("Out", 1),
          _Head("Rate", 1),
          _Head("Value", 2),
        ],
      ),
    );
  }

  Widget _tableBody() {
    if (ledger.isEmpty) {
      return const Center(child: Text("No Data Found"));
    }

    return ListView.separated(
      itemCount: ledger.length,
      separatorBuilder: (_, __) => Divider(height: 1),
      itemBuilder: (_, i) {
        final e = ledger[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _cell(df.format(e.date), 2),
              _cell(e.tranNo, 1),
              _cell(e.type, 2),
              _cell(e.party, 3),
              _cell(e.inwardQty.toInt().toString(), 1),
              _cell(e.outwardQty.toInt().toString(), 1),
              _cell(e.rate.toStringAsFixed(2), 1),
              _cell(e.value.toStringAsFixed(2), 2),
            ],
          ),
        );
      },
    );
  }

  Widget _summary(double balance) {
    return Container(
      padding: const EdgeInsets.all(14),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _box("Opening", openingStock.toInt()),
          _box("Inward", inward.toInt()),
          _box("Outward", outward.toInt()),
          _box("Balance", balance.toInt()),
        ],
      ),
    );
  }

  Widget _box(String title, int val) {
    return Container(
      margin: const EdgeInsets.only(left: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 12)),
          Text(
            val.toString(),
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.inter(fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _Head extends StatelessWidget {
  final String text;
  final int flex;
  const _Head(this.text, this.flex);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}

class ItemLedgerRow {
  final DateTime date;
  final String tranNo;
  final String type;
  final String party;
  final double inwardQty;
  final double outwardQty;
  final double rate;
  final double value;

  ItemLedgerRow({
    required this.date,
    required this.tranNo,
    required this.type,
    required this.party,
    required this.inwardQty,
    required this.outwardQty,
    required this.rate,
    required this.value,
  });
}
