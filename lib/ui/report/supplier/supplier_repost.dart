import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/ui/master/customer_supplier/create.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';
// import 'package:intl/intl.dart';

class SupplierReportScreen extends StatefulWidget {
  const SupplierReportScreen({super.key});

  @override
  State<SupplierReportScreen> createState() => _SupplierReportScreenState();
}

class _SupplierReportScreenState extends State<SupplierReportScreen> {
  List<Customer> allCustomers = [];
  List<Customer> filteredCustomers = [];

  // filters
  final TextEditingController searchController = TextEditingController();
  String searchText = "";

  String typeFilter = "All";
  String balanceFilter = "All";
  DateTime? fromDate;
  DateTime? toDate;

  bool loading = true;

  // ---------------- INIT ----------------
  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  // ---------------- API ----------------
  Future fetchCustomers() async {
    setState(() => loading = true);

    var response = await ApiService.fetchData(
      "get/supplier",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    List responseData = response['data'] ?? [];

    allCustomers = responseData.map((e) => Customer.fromJson(e)).toList();
    applyFilters();

    setState(() => loading = false);
  }

  void applyFilters() {
    filteredCustomers = allCustomers.where((c) {
      bool ok = true;

      // TYPE FILTER
      if (typeFilter != "All") {
        ok &= c.customerType == typeFilter;
      }

      // BALANCE FILTER
      if (balanceFilter == "Outstanding") {
        ok &= c.closingBalance < 0;
      } else if (balanceFilter == "Advance") {
        ok &= c.closingBalance > 0;
      }

      // DATE FILTER
      if (fromDate != null) {
        ok &=
            c.createdAt.isAfter(fromDate!) ||
            c.createdAt.isAtSameMomentAs(fromDate!);
      }
      if (toDate != null) {
        ok &=
            c.createdAt.isBefore(toDate!) ||
            c.createdAt.isAtSameMomentAs(toDate!);
      }

      // 🔍 SEARCH FILTER (Party name + contact name)
      if (searchText.isNotEmpty) {
        final q = searchText.toLowerCase();
        ok &=
            c.companyName.toLowerCase().contains(q) ||
            c.firstName.toLowerCase().contains(q) ||
            c.lastName.toLowerCase().contains(q);
      }

      return ok;
    }).toList();

    setState(() {});
  }

  // ---------------- REPORT DATA ----------------
  int get totalCustomers => filteredCustomers.length;

  int get totalOutstanding => filteredCustomers
      .where((e) => e.closingBalance < 0)
      .fold(0, (p, e) => p + e.closingBalance.abs());

  int get totalAdvance => filteredCustomers
      .where((e) => e.closingBalance > 0)
      .fold(0, (p, e) => p + e.closingBalance);

  int get netBalance =>
      filteredCustomers.fold(0, (p, e) => p + e.closingBalance);

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.black,
        title: Text(
          "Customer Report",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.white,
          ),
        ),
        actions: [
          Center(
            child: defaultButton(
              height: 40,
              width: 150,
              onTap: () async {
                var data = await pushTo(CreateCusSup(isCustomer: true));
                if (data == "data") fetchCustomers();
              },
              text: "Create Supplier",
              buttonColor: AppColor.blue,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: loading
          ? Center(child: GlowLoader())
          : Column(
              children: [
                _filterBar(),
                _reportBar(),
                Expanded(child: _table()),
              ],
            ),
    );
  }

  // =========================================================
  // ======================== FILTER =========================
  // =========================================================
  Widget _filterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xffF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // 🔍 SEARCH FIELD
          SizedBox(
            width: 280,
            child: CommonTextField(
              controller: searchController,
              hintText: "Search Party Name",
              onChanged: (v) {
                searchText = v;
                applyFilters();
              },
            ),
          ),

          const SizedBox(width: 12),

          _dropdown(
            value: typeFilter,
            items: const ["All", "Individual", "Business"],
            onChanged: (v) {
              typeFilter = v!;
              applyFilters();
            },
          ),
          const SizedBox(width: 12),

          _dropdown(
            value: balanceFilter,
            items: const ["All", "Outstanding", "Advance"],
            onChanged: (v) {
              balanceFilter = v!;
              applyFilters();
            },
          ),

          const Spacer(),

          TextButton(
            onPressed: () {
              typeFilter = "All";
              balanceFilter = "All";
              fromDate = null;
              toDate = null;
              searchText = "";
              searchController.clear();
              applyFilters();
            },
            child: const Text("Clear"),
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return SizedBox(
      width: 250,
      child: CommonDropdownField<String>(
        value: value,
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  // Widget _dateBtn(String label, DateTime? date, Function(DateTime) onPick) {
  //   return OutlinedButton(
  //     onPressed: () async {
  //       final picked = await showDatePicker(
  //         context: context,
  //         firstDate: DateTime(2020),
  //         lastDate: DateTime.now(),
  //         initialDate: date ?? DateTime.now(),
  //       );
  //       if (picked != null) onPick(picked);
  //     },
  //     child: Text(
  //       date == null ? label : DateFormat("dd MMM yyyy").format(date),
  //     ),
  //   );
  // }

  // =========================================================
  // ======================== REPORT =========================
  // =========================================================

  Widget _reportBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _reportCard(
            "Suppliers",
            totalCustomers.toString(),
            const Color(0xffE0F2FE),
          ),
          _reportCard(
            "Outstanding",
            "₹ $totalOutstanding",
            const Color(0xffFEE2E2),
          ),
          _reportCard("Advance", "₹ $totalAdvance", const Color(0xffDCFCE7)),
          _reportCard("Net Balance", "₹ $netBalance", const Color(0xffFEF3C7)),
        ],
      ),
    );
  }

  Widget _reportCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ======================== TABLE ==========================
  // =========================================================

  Widget _table() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _tableHeader(),
          const Divider(height: 1),
          Expanded(
            child: filteredCustomers.isEmpty
                ? const Center(child: Text("No Data Found"))
                : ListView.separated(
                    itemCount: filteredCustomers.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, i) {
                      return _tableRow(filteredCustomers[i], i);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tableHeader() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Color(0xff111827),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text("Party Name", style: _headStyle)),
          Expanded(flex: 2, child: Text("Type", style: _headStyle)),
          Expanded(flex: 3, child: Text("Contact Name", style: _headStyle)),
          Expanded(flex: 2, child: Text("Mobile", style: _headStyle)),
          Expanded(flex: 2, child: Text("Balance", style: _headStyle)),
          SizedBox(width: 110, child: Text("Action", style: _headStyle)),
        ],
      ),
    );
  }

  static final TextStyle _headStyle = GoogleFonts.inter(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    letterSpacing: .4,
  );

  Widget _tableRow(Customer c, int index) {
    final bool even = index.isEven;

    return Container(
      color: even ? const Color(0xffF9FAFB) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      child: Row(
        children: [
          Expanded(flex: 3, child: _cell(c.companyName)),
          Expanded(flex: 2, child: _typeChip(c.customerType)),
          Expanded(flex: 3, child: _cell("${c.firstName} ${c.lastName}")),
          Expanded(flex: 2, child: _cell(c.mobile)),
          Expanded(flex: 2, child: _balanceText(c.closingBalance)),
          _actionButtons(c),
        ],
      ),
    );
  }

  Widget _balanceText(int bal) {
    return Text(
      "₹ $bal",
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        color: bal < 0 ? Colors.red : Colors.green,
      ),
    );
  }

  Widget _cell(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: const Color(0xff374151),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _typeChip(String type) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          type,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.blue.shade700,
          ),
        ),
      ),
    );
  }

  Widget _actionButtons(Customer c) {
    return SizedBox(
      width: 110,
      child: Row(
        children: [
          _iconBtn(Icons.edit, AppColor.primary, () async {
            var data = await pushTo(
              CreateCusSup(isCustomer: true, cusSupData: c),
            );
            if (data != null) fetchCustomers();
          }),
          const SizedBox(width: 10),
          _iconBtn(Icons.delete, Colors.red, () => _confirmDelete(c.id)),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: color.withOpacity(.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Record"),
        content: const Text("Are you sure you want to delete this record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await deleteApi(id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future deleteApi(String id) async {
    var response = await ApiService.deleteData(
      "supplier/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (response['status'] == true) {
      showCustomSnackbarSuccess(context, response['message']);
      fetchCustomers();
    } else {
      showCustomSnackbarError(context, response['message']);
    }
  }
}
