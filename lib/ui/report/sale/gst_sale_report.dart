import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/ui/sales/models/sale_invoice_data.dart';
import 'package:ims/model/cussup_model.dart';

class GstSaleReportScreen extends StatefulWidget {
  const GstSaleReportScreen({super.key});

  @override
  State<GstSaleReportScreen> createState() => _GstSaleReportScreenState();
}

class _GstSaleReportScreenState extends State<GstSaleReportScreen> {
  List<SaleInvoiceData> invoiceList = [];
  List<SaleInvoiceData> filteredList = [];
  List<Customer> customerList = [];

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
      customerList = (customerRes['data'] as List)
          .map((e) => Customer.fromJson(e))
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

      final customer = getCustomer(inv.customerId);

      final searchMatch =
          search.isEmpty ||
          inv.transNo.toString().contains(search) ||
          customer.companyName.toLowerCase().contains(search.toLowerCase());

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
          rows: _buildRows(filteredList, customerList),
        ),
      ),
    );
  }

  List<DataRow> _buildRows(
    List<SaleInvoiceData> invoices,
    List<Customer> customers,
  ) {
    final List<DataRow> rows = [];

    for (final inv in invoices) {
      final customer = getCustomer(inv.customerId);

      for (final item in inv.itemDetails) {
        final gstRate = item.gstRate;
        final isInclusive = item.inclusive;

        double taxable;
        double gstAmount;

        if (isInclusive) {
          taxable = item.amount / (1 + (gstRate / 100));
          gstAmount = item.amount - taxable;
        } else {
          taxable = item.amount;
          gstAmount = taxable * gstRate / 100;
        }

        final cgst = gstAmount / 2;
        final sgst = gstAmount / 2;
        final igst = 0.0; // change if inter-state

        rows.add(
          DataRow(
            cells: [
              DataCell(Text(inv.no.toString())),
              DataCell(
                Text(DateFormat('dd-MM-yyyy').format(inv.saleInvoiceDate)),
              ),
              DataCell(Text(customer.companyName)),
              DataCell(Text(customer.state)),
              DataCell(Text(customer.gstNo)),

              DataCell(Text(item.hsn)),
              DataCell(Text(item.itemNo)),
              DataCell(Text(item.name)),

              DataCell(Text(item.qty.toString())),
              DataCell(Text(item.discount.toStringAsFixed(2))),

              DataCell(Text(taxable.toStringAsFixed(2))),

              DataCell(Text(gstRate.toStringAsFixed(2))),
              DataCell(Text(igst.toStringAsFixed(2))),

              DataCell(Text((gstRate / 2).toStringAsFixed(2))),
              DataCell(Text(cgst.toStringAsFixed(2))),

              DataCell(Text((gstRate / 2).toStringAsFixed(2))),
              DataCell(Text(sgst.toStringAsFixed(2))),

              DataCell(
                Text(
                  (taxable + gstAmount).toStringAsFixed(2),
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

  // ================= CUSTOMER SAFE =================

  Customer getCustomer(String? id) {
    return customerList.firstWhere(
      (e) => e.id == id,
      orElse: () => Customer(
        id: "",
        licenceNo: 0,
        branchId: "",
        customerType: "",
        title: "",
        firstName: "",
        lastName: "",
        related: "",
        parents: "",
        parentsLast: "",
        companyName: "Unknown",
        email: "",
        phone: "",
        mobile: "",
        pan: "",
        gstType: "",
        gstNo: "",
        address: "",
        city: "",
        state: "",
        openingBalance: 0,
        closingBalance: 0,
        address0: "",
        address1: "",
        documents: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        v: 0,
      ),
    );
  }
}
