import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/ui/master/customer_supplier/create.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';

class SupplierTableScreen extends StatefulWidget {
  const SupplierTableScreen({super.key});

  @override
  State<SupplierTableScreen> createState() => _SupplierTableScreenState();
}

class _SupplierTableScreenState extends State<SupplierTableScreen> {
  List<Customer> supplierList = [];
  List<Customer> filteredList = [];
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    gstApi();
    searchController.addListener(() {
      _filterSuppliers();
    });
  }

  void _filterSuppliers() {
    final query = searchController.text.toLowerCase();

    setState(() {
      filteredList = supplierList.where((s) {
        final name = s.companyName.toLowerCase();
        final mobile = s.mobile.toLowerCase();

        return name.contains(query) || mobile.contains(query);
      }).toList();
    });
  }

  Future gstApi() async {
    var response = await ApiService.fetchData(
      "get/supplier",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    List responseData = response['data'] ?? [];
    setState(() {
      supplierList = responseData.map((e) => Customer.fromJson(e)).toList();
      filteredList = supplierList; // 🔥 IMPORTANT
    });
  }

  Future deleteApi(String id) async {
    var response = await ApiService.deleteData(
      "supplier/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (response['status'] == true) {
      showCustomSnackbarSuccess(context, response['message']);
      gstApi();
    } else {
      showCustomSnackbarError(context, response['message']);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColor.black,
        title: Text(
          "All Suppliers",
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
                var data = await pushTo(CreateCusSup(isCustomer: false));
                if (data == "data") gstApi();
              },
              text: "Create Supplier",
              buttonColor: AppColor.blue,
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),

      // ================= BODY =================
      body: Column(
        children: [
          SizedBox(height: Sizes.height * .02),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: CommonTextField(
              controller: searchController,
              hintText: "Search by name or mobile",
              perfixIcon: const Icon(Icons.search),
            ),
          ),

          Expanded(
            child: Container(
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
                    child: supplierList.isEmpty
                        ? const Center(child: Text("No Data Found"))
                        : ListView.separated(
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemCount: filteredList.length,
                            itemBuilder: (context, i) {
                              return _tableRow(filteredList[i], i);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HEADER =================
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
          Expanded(flex: 2, child: Text("Mobile", style: _headStyle)),
          Expanded(flex: 3, child: Text("Email", style: _headStyle)),
          Expanded(flex: 2, child: Text("GST Type", style: _headStyle)),
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

  // ================= ROW =================
  Widget _tableRow(Customer c, int index) {
    final bool even = index.isEven;

    return Container(
      color: even ? const Color(0xffF9FAFB) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      child: Row(
        children: [
          Expanded(flex: 3, child: _cell(c.companyName)),
          Expanded(flex: 2, child: _typeChip(c.customerType)),
          Expanded(flex: 2, child: _cell(c.mobile)),
          Expanded(flex: 3, child: _cell(c.email)),
          Expanded(flex: 2, child: _cell(c.gstType)),
          _actionButtons(c),
        ],
      ),
    );
  }

  // ================= CELL =================
  Widget _cell(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w500,
        fontSize: 13,
        color: Color(0xff374151),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  // ================= TYPE CHIP =================
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
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ================= ACTIONS =================
  Widget _actionButtons(Customer c) {
    return SizedBox(
      width: 110,
      child: Row(
        children: [
          _iconBtn(Icons.edit, AppColor.primary, () async {
            var data = await pushTo(
              CreateCusSup(isCustomer: false, cusSupData: c),
            );
            if (data != null) {
              gstApi();
            }
          }),
          SizedBox(width: 10),
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

  // ================= DELETE =================
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
}
