import 'package:flutter/material.dart';
import 'package:ims/ui/sales/models/purcahseinvoice_data.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';

class GstPurchaseReportScreen extends StatefulWidget {
  const GstPurchaseReportScreen({super.key});

  @override
  State<GstPurchaseReportScreen> createState() =>
      _GstPurchaseReportScreenState();
}

class _GstPurchaseReportScreenState extends State<GstPurchaseReportScreen> {
  List<PurchaseInvoiceData> invoiceList = [];
  List<PurchaseInvoiceData> filteredList = [];

  DateTime? fromDate;
  DateTime? toDate;
  String search = "";

  // 🔥 Advanced filters
  String? selectedItem;
  String? selectedHsn;
  double? selectedGstRate;

  final Set<String> itemList = {};
  final Set<String> hsnList = {};
  final Set<double> gstRateList = {};

  @override
  void initState() {
    super.initState();
    setFinancialYear();
    loadData();
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
  }

  // ================= LOAD DATA =================

  Future<void> loadData() async {
    final res = await ApiService.fetchData(
      "get/purchaseinvoice",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    final data = PurchaseInvoiceListResponse.fromJson(res).data;

    // Prepare filter masters
    for (final inv in data) {
      for (final item in inv.itemDetails) {
        itemList.add(item.name);
        hsnList.add(item.hsn);
        gstRateList.add(item.gstRate);
      }
    }

    setState(() {
      invoiceList = data;
      filteredList = data;
    });
  }

  // ================= FILTER =================

  void applyFilter() {
    filteredList = invoiceList.where((inv) {
      final date = inv.purchaseInvoiceDate;

      final dateMatch =
          (fromDate == null || !date.isBefore(fromDate!)) &&
          (toDate == null ||
              !date.isAfter(toDate!.add(const Duration(days: 1))));

      final searchMatch =
          search.isEmpty ||
          inv.no.toString().contains(search) ||
          inv.supplierName.toLowerCase().contains(search.toLowerCase());

      // 🔥 Item-level filter
      final rowMatch = inv.itemDetails.any((item) {
        final itemMatch = selectedItem == null || item.name == selectedItem;
        final hsnMatch = selectedHsn == null || item.hsn == selectedHsn;
        final gstMatch =
            selectedGstRate == null || item.gstRate == selectedGstRate;

        return itemMatch && hsnMatch && gstMatch;
      });

      return dateMatch && searchMatch && rowMatch;
    }).toList();

    setState(() {});
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("GST Purchase Report"),
        backgroundColor: AppColor.primary,
      ),
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
      child: Row(
        spacing: 12,
        children: [
          // 📅 From Date
          _dateField(
            label: "From Date",
            value: fromDate,
            onPicked: (d) {
              fromDate = d;
              applyFilter();
            },
          ),

          // 📅 To Date
          _dateField(
            label: "To Date",
            value: toDate,
            onPicked: (d) {
              toDate = d;
              applyFilter();
            },
          ),

          Expanded(
            flex: 2,
            child: CommonTextField(
              hintText: "Invoice / Customer",

              onChanged: (v) {
                search = v;
                applyFilter();
              },
            ),
          ),

          _dropdown<String>(
            label: "Item",
            value: selectedItem,
            items: itemList.toList(),
            onChanged: (v) {
              selectedItem = v;
              applyFilter();
            },
            flex: 2,
          ),

          _dropdown<String>(
            label: "HSN",
            value: selectedHsn,
            items: hsnList.toList(),
            onChanged: (v) {
              selectedHsn = v;
              applyFilter();
            },
          ),

          _dropdown<double>(
            label: "GST %",
            value: selectedGstRate,
            items: gstRateList.toList(),
            onChanged: (v) {
              selectedGstRate = v;
              applyFilter();
            },
          ),
        ],
      ),
    );
  }

  Widget _dropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required Function(T?) onChanged,
    int? flex,
  }) {
    return Expanded(
      flex: flex ?? 1,
      child: CommonDropdownField<T>(
        value: value,
        hintText: label,

        items: [
          const DropdownMenuItem(value: null, child: Text("All")),
          ...items.map(
            (e) => DropdownMenuItem(value: e, child: Text(e.toString())),
          ),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _dateField({
    required String label,
    required DateTime? value,
    required Function(DateTime) onPicked,
  }) {
    return Expanded(
      child: CommonTextField(
        readOnly: true,
        hintText: label,
        controller: TextEditingController(
          text: value == null ? "" : DateFormat('dd-MM-yyyy').format(value),
        ),
        suffixIcon: const Icon(Icons.calendar_month),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(1990),
            lastDate: DateTime(2100),
          );

          if (picked != null) {
            onPicked(picked);
          }
        },
      ),
    );
  }

  // ================= TABLE =================

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
            DataColumn(label: Text("Customer")),
            DataColumn(label: Text("State")),
            DataColumn(label: Text("HSN")),
            DataColumn(label: Text("Item")),
            DataColumn(label: Text("Qty")),
            DataColumn(label: Text("Taxable")),
            DataColumn(label: Text("IGST")),
            DataColumn(label: Text("CGST")),
            DataColumn(label: Text("SGST")),
            DataColumn(label: Text("Total")),
          ],
          rows: _buildRows(filteredList),
        ),
      ),
    );
  }

  // ================= ROW BUILDER =================

  List<DataRow> _buildRows(List<PurchaseInvoiceData> invoices) {
    final List<DataRow> rows = [];

    final companyState = Preference.getString(
      PrefKeys.state,
    ).trim().toLowerCase();

    for (final inv in invoices) {
      final invoiceState = inv.placeOfSupply.trim().toLowerCase();

      final bool isSameState =
          invoiceState.isNotEmpty &&
          companyState.isNotEmpty &&
          invoiceState == companyState;

      for (final item in inv.itemDetails) {
        double taxable;
        double gst;
        double total;

        if (item.inclusive) {
          taxable = item.amount / (1 + (item.gstRate / 100));
          gst = item.amount - taxable;
          total = item.amount;
        } else {
          taxable = item.amount;
          gst = taxable * item.gstRate / 100;
          total = taxable + gst;
        }

        final igst = isSameState ? 0 : gst;
        final cgst = isSameState ? gst / 2 : 0;
        final sgst = isSameState ? gst / 2 : 0;

        rows.add(
          DataRow(
            cells: [
              DataCell(Text(inv.no.toString())),
              DataCell(
                Text(DateFormat('dd-MM-yyyy').format(inv.purchaseInvoiceDate)),
              ),
              DataCell(Text(inv.supplierName)),
              DataCell(Text(inv.placeOfSupply)),
              DataCell(Text(item.hsn)),
              DataCell(Text(item.name)),
              DataCell(Text(item.qty.toString())),
              DataCell(Text(taxable.toStringAsFixed(2))),
              DataCell(Text(igst.toStringAsFixed(2))),
              DataCell(Text(cgst.toStringAsFixed(2))),
              DataCell(Text(sgst.toStringAsFixed(2))),
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
