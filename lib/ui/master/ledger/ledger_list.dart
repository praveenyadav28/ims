import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/ui/master/ledger/ledger_master.dart';
import 'package:ims/utils/access.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';

class LedgerListScreen extends StatefulWidget {
  const LedgerListScreen({super.key});

  @override
  State<LedgerListScreen> createState() => _LedgerListScreenState();
}

class _LedgerListScreenState extends State<LedgerListScreen> {
  List<LedgerListModel> ledgerList = [];
  List<LedgerListModel> allLedgerList = [];
  List<LedgerListModel> filteredList = [];

  TextEditingController searchController = TextEditingController();
  String selectedGroup = "All";

  int currentPage = 1;
  int rowsPerPage = 100;
  @override
  void initState() {
    super.initState();
    ledgerApi();
  }

  // ---------------- API ----------------
  Future ledgerApi() async {
    var response = await ApiService.fetchData(
      "get/ledger",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    List responseData = response['data'] ?? [];

    setState(() {
      allLedgerList = responseData
          .map((e) => LedgerListModel.fromJson(e))
          .where(
            (e) =>
                e.ledgerGroup != 'Sundry Debtor' &&
                e.ledgerGroup != 'Sundry Creditor',
          )
          .toList();

      applyFilter();
    });
  }

  void applyFilter() {
    List<LedgerListModel> temp = allLedgerList;

    // 🔍 Ledger Name filter
    if (searchController.text.isNotEmpty) {
      temp = temp
          .where(
            (e) => (e.ledgerName ?? "").toLowerCase().contains(
              searchController.text.toLowerCase(),
            ),
          )
          .toList();
    }

    // 🧩 Group filter
    if (selectedGroup != "All") {
      temp = temp.where((e) => e.ledgerGroup == selectedGroup).toList();
    }

    filteredList = temp;
    currentPage = 1;

    setState(() {});
  }

  List<LedgerListModel> get paginatedList {
    final start = (currentPage - 1) * rowsPerPage;

    if (start >= filteredList.length) return [];

    final end = start + rowsPerPage;

    return filteredList.sublist(
      start,
      end > filteredList.length ? filteredList.length : end,
    );
  }

  Widget _filters() {
    List<String> groups = [
      "All",
      ...allLedgerList.map((e) => e.ledgerGroup ?? "").toSet(),
    ];

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // 🔍 Search
          Expanded(
            flex: 4,
            child: CommonTextField(
              controller: searchController,
              onChanged: (_) => applyFilter(),
              hintText: "Search Ledger",
            ),
          ),

          const SizedBox(width: 12),

          // 🧩 Group dropdown
          Expanded(
            child: CommonDropdownField<String>(
              value: selectedGroup,
              items: groups
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (v) {
                selectedGroup = v!;
                applyFilter();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future deleteApi(String id) async {
    var response = await ApiService.deleteData(
      "ledger/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (response['status'] == true) {
      showCustomSnackbarSuccess(context, response['message']);
      ledgerApi();
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
          "Ledger Master",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.white,
          ),
        ),
        actions: [
          if (hasModuleAccess("Ledger", "create"))
            Center(
              child: defaultButton(
                height: 40,
                width: 150,
                onTap: () async {
                  var data = await pushTo(CreateLedger());
                  if (data == "data") ledgerApi();
                },
                text: "Create Ledger",
                buttonColor: AppColor.blue,
              ),
            ),
          const SizedBox(width: 12),
          Center(
            child: defaultButton(
              height: 40,
              width: 150,
              onTap: uploadExcelFile,
              text: "Upload Ledger",
              buttonColor: AppColor.primary,
            ),
          ),

          const SizedBox(width: 12),
        ],
      ),

      body: Column(
        children: [
          SizedBox(height: Sizes.height * .02),

          // ================= TABLE =================
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
                  _filters(), // 👈 NEW
                  _tableHeader(),
                  const Divider(height: 1),

                  Expanded(
                    child: paginatedList.isEmpty
                        ? const Center(child: Text("No Data Found"))
                        : ListView.separated(
                            itemCount: paginatedList.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, i) {
                              return _tableRow(paginatedList[i], i);
                            },
                          ),
                  ),

                  _pagination(), // 👈 NEW
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pagination() {
    int totalPages = (filteredList.length / rowsPerPage).ceil();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            onPressed: currentPage > 1
                ? () {
                    currentPage--;
                    setState(() {});
                  }
                : null,
            icon: Icon(Icons.arrow_back),
          ),

          Text("Page $currentPage of $totalPages"),

          IconButton(
            onPressed: currentPage < totalPages
                ? () {
                    currentPage++;
                    setState(() {});
                  }
                : null,
            icon: Icon(Icons.arrow_forward),
          ),
        ],
      ),
    );
  }

  // ---------------- HEADER ----------------
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
          Expanded(flex: 3, child: Text("Ledger Name", style: _headStyle)),
          Expanded(flex: 2, child: Text("Group", style: _headStyle)),
          Expanded(flex: 2, child: Text("Mobile", style: _headStyle)),
          Expanded(flex: 2, child: Text("Email", style: _headStyle)),
          Expanded(flex: 2, child: Text("City", style: _headStyle)),
          SizedBox(width: 170, child: Text("Action", style: _headStyle)),
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

  // ---------------- ROW ----------------
  Widget _tableRow(LedgerListModel l, int index) {
    final bool even = index.isEven;

    return Container(
      color: even ? const Color(0xffF9FAFB) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      child: Row(
        children: [
          Expanded(flex: 3, child: _cell(l.ledgerName ?? "-")),
          Expanded(flex: 2, child: _groupChip(l.ledgerGroup ?? "-")),
          Expanded(flex: 2, child: _cell(l.contactNo?.toString() ?? "-")),
          Expanded(flex: 2, child: _cell(l.email ?? "-")),
          Expanded(flex: 2, child: _cell(l.city ?? "-")),

          _actionButtons(l),
        ],
      ),
    );
  }

  // ---------------- CELL ----------------
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

  // ---------------- GROUP CHIP ----------------
  Widget _groupChip(String group) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          group,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.orange.shade700,
          ),
        ),
      ),
    );
  }

  // ---------------- ACTIONS ----------------
  Widget _actionButtons(LedgerListModel l) {
    return SizedBox(
      width: 170,
      child: Row(
        children: [
          _iconBtn(Icons.visibility, Colors.blue, () => _showDetails(l)),
          const SizedBox(width: 10),
          if (hasModuleAccess("Ledger", "update"))
            _iconBtn(Icons.edit, AppColor.primary, () async {
              var data = await pushTo(CreateLedger(existing: l));
              if (data != null) ledgerApi();
            }),
          const SizedBox(width: 10),

          if (hasModuleAccess("Ledger", "delete"))
            _iconBtn(Icons.delete, Colors.red, () => _confirmDelete(l.id!)),
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

  // ---------------- DETAILS ----------------
  void _showDetails(LedgerListModel l) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l.ledgerName ?? "Ledger"),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _d("Group", l.ledgerGroup),
              _d("Mobile", l.contactNo?.toString()),
              _d("Email", l.email),
              _d("GST No", l.gstNo?.toString()),
              _d("Address", l.address),
              _d("State", l.state),
              _d("City", l.city),
              const SizedBox(height: 8),
              const Divider(),
              _d(
                "Opening Balance",
                "${l.openingBalance} ${l.openingBalance! < 0 ? 'I Pay' : 'I Receive'}",
              ),
              _d(
                "Closing Balance",
                "${l.closingBalance?.toString() ?? '-'} ${l.closingBalance != null ? (l.closingBalance! < 0 ? 'I Pay' : 'I Receive') : ''}",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Widget _d(String t, String? v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text("$t : ${v ?? "-"}"),
    );
  }

  // ---------------- DELETE ----------------
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Ledger"),
        content: const Text("Are you sure you want to delete this ledger?"),
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

  Future<void> uploadExcelFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        withData: true, // 🔥 IMPORTANT for web
      );

      if (result == null) return;

      final bytes = result.files.single.bytes!;
      final fileName = result.files.single.name;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      FormData formData = FormData.fromMap({
        "ledgerexcel": MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final dio = Dio();

      final response = await dio.post(
        "${ApiService.baseurl}/excel-import-in-ledger",
        data: formData,
        options: Options(
          headers: {
            "licence_no": Preference.getint(PrefKeys.licenseNo),
            "Accept": "application/json",
            "Authorization": "Bearer ${Preference.getString(PrefKeys.token)}",
          },
        ),
      );

      Navigator.pop(context);

      if (response.statusCode == 200 && response.data["status"] == true) {
        showCustomSnackbarSuccess(context, "Excel Uploaded Successfully");
        ledgerApi();
      } else {
        showCustomSnackbarError(
          context,
          response.data["message"] ?? "Upload Failed",
        );
      }
    } catch (e) {
      Navigator.pop(context);
      showCustomSnackbarError(context, "Upload Error: $e");
    }
  }
}
