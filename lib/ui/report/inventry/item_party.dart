import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:searchfield/searchfield.dart';

import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';

import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/ui/sales/models/sale_return_data.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/ui/sales/models/purchase_return_data.dart';

class PartyLedgerScreen extends StatefulWidget {
  const PartyLedgerScreen({super.key});

  @override
  State<PartyLedgerScreen> createState() => _PartyLedgerScreenState();
}

class _PartyLedgerScreenState extends State<PartyLedgerScreen> {
  final df = DateFormat('dd-MM-yyyy');

  LedgerModelDrop? selectedParty;
  List<LedgerModelDrop> partyList = [];

  final TextEditingController partyCtrl = TextEditingController();
  final TextEditingController itemSearchCtrl = TextEditingController();
  final TextEditingController fromCtrl = TextEditingController();
  final TextEditingController toCtrl = TextEditingController();

  DateTime fromDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime toDate = DateTime.now();

  List<PartyLedgerRow> ledger = [];
  List<PartyLedgerRow> filtered = [];
  double totalAmount = 0;

  @override
  void initState() {
    super.initState();
    fromCtrl.text = df.format(fromDate);
    toCtrl.text = df.format(toDate);
    loadParties();
  }

  // ================= LOAD PARTY =================
  Future<void> loadParties() async {
    final res = await ApiService.fetchData(
      'get/ledger',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final data = (res?['data'] as List?) ?? [];

    partyList = data
        .where(
          (e) =>
              e['ledger_group'] == 'Sundry Debtor' ||
              e['ledger_group'] == 'Sundry Creditor',
        )
        .map((e) => LedgerModelDrop.fromMap(e))
        .toList();

    setState(() {});
  }

  // ================= LOAD LEDGER =================
  Future<void> loadLedger() async {
    ledger.clear();
    totalAmount = 0;

    if (selectedParty == null) return;

    await _loadSales();
    await _loadSalesReturn();
    await _loadPurchase();
    await _loadPurchaseReturn();

    setState(() {});
  }

  bool _inRange(DateTime d) => !d.isBefore(fromDate) && !d.isAfter(toDate);

  // ================= SALES =================
  Future<void> _loadSales() async {
    final res = await ApiService.fetchData(
      "get/invoice",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final data = SaleInvoiceListResponse.fromJson(res).data;

    for (var s in data.where((e) => e.customerId == selectedParty!.id)) {
      if (!_inRange(s.saleInvoiceDate)) continue;

      for (var i in s.itemDetails) {
        ledger.add(
          PartyLedgerRow(
            date: s.saleInvoiceDate,
            invoiceNo: s.no.toString(),
            type: "Sale",
            itemName: i.name,
            qty: i.qty,
            rate: i.price,
            amount: i.amount,
          ),
        );

        totalAmount += i.amount;
      }
    }
  }

  // ================= SALE RETURN =================
  Future<void> _loadSalesReturn() async {
    final res = await ApiService.fetchData(
      "get/returnsale",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final data = SaleReturnListResponse.fromJson(res).data;

    for (var s in data.where((e) => e.customerId == selectedParty!.id)) {
      if (!_inRange(s.saleReturnDate)) continue;

      for (var i in s.itemDetails) {
        ledger.add(
          PartyLedgerRow(
            date: s.saleReturnDate,
            invoiceNo: s.no.toString(),
            type: "Sale Return",
            itemName: i.name,
            qty: i.qty,
            rate: i.price,
            amount: -i.amount,
          ),
        );

        totalAmount -= i.amount;
      }
    }
  }

  // ================= PURCHASE =================
  Future<void> _loadPurchase() async {
    final res = await ApiService.fetchData(
      "get/purchaseinvoice",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final data = PurchaseInvoiceListResponse.fromJson(res).data;

    for (var p in data.where((e) => e.supplierId == selectedParty!.id)) {
      if (!_inRange(p.purchaseInvoiceDate)) continue;

      for (var i in p.itemDetails) {
        ledger.add(
          PartyLedgerRow(
            date: p.purchaseInvoiceDate,
            invoiceNo: p.no.toString(),
            type: "Purchase",
            itemName: i.name,
            qty: i.qty,
            rate: i.price,
            amount: i.amount,
          ),
        );

        totalAmount += i.amount;
      }
    }
  }

  // ================= PURCHASE RETURN =================
  Future<void> _loadPurchaseReturn() async {
    final res = await ApiService.fetchData(
      "get/purchasereturn",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final data = PurchaseReturnListResponse.fromJson(res).data;

    for (var p in data.where((e) => e.supplierId == selectedParty!.id)) {
      if (!_inRange(p.purchaseReturnDate)) continue;

      for (var i in p.itemDetails) {
        ledger.add(
          PartyLedgerRow(
            date: p.purchaseReturnDate,
            invoiceNo: p.no.toString(),
            type: "Purchase Return",
            itemName: i.name,
            qty: i.qty,
            rate: i.price,
            amount: -i.amount,
          ),
        );

        totalAmount -= i.amount;
      }
    }

    filtered = List.from(ledger);
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF3F4F6),
      appBar: AppBar(
        title: const Text("Item Report By Party"),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [_filterCard(), const SizedBox(height: 12), _ledgerCard()],
        ),
      ),
    );
  }

  // ================= FILTER =================
  Widget _filterCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: CommonSearchableDropdownField<LedgerModelDrop>(
                  controller: partyCtrl,
                  hintText: "Select Party",
                  suggestions: partyList
                      .map((e) => SearchFieldListItem(e.name, item: e))
                      .toList(),
                  onSuggestionTap: (v) {
                    selectedParty = v.item;
                    partyCtrl.text = v.searchKey;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: itemSearchCtrl,
                  hintText: "Search Item",
                  onChanged: (value) {
                    setState(() {
                      if (value.isEmpty) {
                        filtered = List.from(ledger);
                      } else {
                        filtered = ledger
                            .where(
                              (e) => e.itemName.toLowerCase().contains(
                                value.toLowerCase(),
                              ),
                            )
                            .toList();
                      }
                    });
                  },
                ),
              ),

              SizedBox(width: 10),
              _dateField("From Date", fromCtrl, true),
              const SizedBox(width: 10),
              _dateField("To Date", toCtrl, false),
              const SizedBox(width: 10),
              defaultButton(
                text: "Search",
                width: 120,
                height: 42,
                onTap: loadLedger,
                buttonColor: AppColor.primary,
              ),
            ],
          ),
        ],
      ),
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

  // ================= LEDGER =================
  Widget _ledgerCard() {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            _tableHeader(),
            Expanded(child: _ledgerList()),
            _totalBar(),
          ],
        ),
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xff111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: const Row(
        children: [
          _Head("Date", 2),
          _Head("No", 1),
          _Head("Type", 2),
          _Head("Item", 3),
          _Head("Qty", 1),
          _Head("Rate", 1),
          _Head("Amount", 2),
        ],
      ),
    );
  }

  Widget _ledgerList() {
    if (filtered.isEmpty) {
      return const Center(child: Text("No Records Found"));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final e = filtered[i];
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _cell(df.format(e.date), 2),
              _cell(e.invoiceNo, 1),
              _cell(
                e.type,
                2,
                color: e.type.contains("Return") ? Colors.orange : Colors.blue,
              ),
              _cell(e.itemName, 3),
              _cell(e.qty.toStringAsFixed(0), 1),
              _cell(e.rate.toStringAsFixed(2), 1),
              _cell(
                e.amount.toStringAsFixed(2),
                2,
                color: e.amount >= 0 ? Colors.green : Colors.red,
                bold: true,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _totalBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      color: Colors.grey.shade100,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text(
            "Net Amount : ",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            "₹ ${totalAmount.toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: totalAmount >= 0 ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(String text, int flex, {Color? color, bool bold = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          color: color ?? Colors.black87,
          fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}

// ================= MODEL =================

class PartyLedgerRow {
  final DateTime date;
  final String invoiceNo;
  final String type;
  final String itemName;
  final double qty;
  final double rate;
  final double amount;

  PartyLedgerRow({
    required this.date,
    required this.invoiceNo,
    required this.type,
    required this.itemName,
    required this.qty,
    required this.rate,
    required this.amount,
  });
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
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
