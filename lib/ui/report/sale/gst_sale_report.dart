import 'package:flutter/material.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:intl/intl.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';

class GstSaleReportScreen extends StatefulWidget {
  const GstSaleReportScreen({super.key});

  @override
  State<GstSaleReportScreen> createState() => _GstSaleReportScreenState();
}

class _GstSaleReportScreenState extends State<GstSaleReportScreen> {
  List<SaleInvoiceData> invoiceList = [];
  List<SaleInvoiceData> filteredList = [];
  List<LedgerListModel> ledgerList = [];

  DateTime? fromDate;
  DateTime? toDate;
  String search = "";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ================= LOAD DATA =================

  Future<void> loadData() async {
    final invoiceRes = await ApiService.fetchData(
      "get/invoice",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final customerRes = await ApiService.fetchData(
      "get/ledger",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    setState(() {
      invoiceList = SaleInvoiceListResponse.fromJson(invoiceRes).data;
      ledgerList = (customerRes['data'] as List)
          .map((e) => LedgerListModel.fromJson(e))
          .where((e) => e.ledgerGroup == "Sundry Debtor")
          .toList();
      filteredList = invoiceList;
    });
  }

  // ================= FILTER =================

  void applyFilter() {
    filteredList = invoiceList.where((inv) {
      final date = inv.saleInvoiceDate;

      final dateMatch =
          (fromDate == null || date.isAfter(fromDate!)) &&
          (toDate == null ||
              date.isBefore(toDate!.add(const Duration(days: 1))));

      final customer = ledgerList.firstWhere((e) => e.id == inv.customerId);

      final searchMatch =
          search.isEmpty ||
          inv.transNo.toString().contains(search) ||
          customer.ledgerName!.toLowerCase().contains(search.toLowerCase());

      return dateMatch && searchMatch;
    }).toList();

    setState(() {});
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("GST Sale Report")),
      body: Column(
        children: [
          _filterBar(),
          const Divider(),
          Expanded(child: _tableView()),
        ],
      ),
    );
  }

  // ================= FILTER BAR =================

  Widget _filterBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Wrap(
        spacing: 12,
        children: [
          _dateBtn("From", (d) {
            fromDate = d;
            applyFilter();
          }),
          _dateBtn("To", (d) {
            toDate = d;
            applyFilter();
          }),
          SizedBox(
            width: 250,
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search Invoice / Customer",
                border: OutlineInputBorder(),
              ),
              onChanged: (v) {
                search = v;
                applyFilter();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBtn(String text, Function(DateTime) onPick) {
    return ElevatedButton(
      onPressed: () async {
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(2022),
          lastDate: DateTime.now(),
          initialDate: DateTime.now(),
        );
        if (d != null) onPick(d);
      },
      child: Text(text),
    );
  }

  // ================= TABLE VIEW =================

  Widget _tableView() {
    if (filteredList.isEmpty) {
      return const Center(child: Text("No Records Found"));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(const Color(0xffF2F2F2)),
          border: TableBorder.all(color: Colors.black12),
          columns: const [
            DataColumn(label: Text("Invoice No")),
            DataColumn(label: Text("Date")),
            DataColumn(label: Text("Customer Name")),
            DataColumn(
              label: Text("State"),
            ), //Match with customer list and place his state as state
            DataColumn(
              label: Text("GST No"),
            ), //Match with customer list and place his GST Number
            DataColumn(label: Text("HSN")),
            DataColumn(label: Text("Item No")),
            DataColumn(label: Text("Item Name")),
            DataColumn(label: Text("Qty")),
            DataColumn(label: Text("Dis. Item")),
            DataColumn(label: Text("Taxable")),
            DataColumn(label: Text("IGST %")),
            DataColumn(label: Text("IGST Amt")),
            DataColumn(label: Text("CGST %")),
            DataColumn(label: Text("CGST Amt")),
            DataColumn(label: Text("SGST %")),
            DataColumn(label: Text("SGST Amt")),
            DataColumn(label: Text("Total")),
          ],
          rows: _buildRows(filteredList, ledgerList),
        ),
      ),
    );
  }

  List<DataRow> _buildRows(
    List<SaleInvoiceData> invoices,
    List<LedgerListModel> customers,
  ) {
    final List<DataRow> rows = [];

    for (final inv in invoices) {
      final customer = customers.firstWhere(
        (e) => e.id == inv.customerId,
        orElse: () => LedgerListModel(),
      );

      for (final item in inv.itemDetails) {
        final customerState = customer.state ?? "";

        bool isSameState =
            customerState.isEmpty ||
            Preference.getString(PrefKeys.state).isEmpty ||
            customerState.toLowerCase() ==
                Preference.getString(PrefKeys.state).toLowerCase();

        double taxable;
        double gstAmount;
        double total;

        if (item.inclusive == true) {
          // ✅ GST INCLUDED IN AMOUNT
          taxable = item.amount / (1 + (item.gstRate / 100));
          gstAmount = item.amount - taxable;
          total = item.amount;
        } else {
          // ✅ GST EXTRA
          taxable = item.amount;
          gstAmount = taxable * item.gstRate / 100;
          total = taxable + gstAmount;
        }

        // ✅ TAX SPLIT
        double cgst = 0;
        double sgst = 0;
        double igst = 0;

        if (isSameState) {
          cgst = gstAmount / 2;
          sgst = gstAmount / 2;
        } else {
          igst = gstAmount;
        }

        rows.add(
          DataRow(
            cells: [
              DataCell(Text(inv.no.toString())),
              DataCell(
                Text(DateFormat('dd-MM-yyyy').format(inv.saleInvoiceDate)),
              ),
              DataCell(Text(customer.ledgerName ?? "")),
              DataCell(Text(customer.state ?? "")),
              DataCell(Text(customer.gstNo ?? "")),

              DataCell(Text(item.hsn)),
              DataCell(Text(item.itemNo)),
              DataCell(Text(item.name)),

              DataCell(Text(item.qty.toString())),
              DataCell(Text(item.discount.toStringAsFixed(2))),

              DataCell(Text(taxable.toStringAsFixed(2))),

              // IGST
              DataCell(Text(isSameState ? "0" : item.gstRate.toString())),
              DataCell(Text(igst.toStringAsFixed(2))),

              // CGST
              DataCell(Text(isSameState ? (item.gstRate / 2).toString() : "0")),
              DataCell(Text(cgst.toStringAsFixed(2))),

              // SGST
              DataCell(Text(isSameState ? (item.gstRate / 2).toString() : "0")),
              DataCell(Text(sgst.toStringAsFixed(2))),

              // TOTAL
              DataCell(
                Text(
                  total.toStringAsFixed(2),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      }
    }

    return rows;
  }
}
