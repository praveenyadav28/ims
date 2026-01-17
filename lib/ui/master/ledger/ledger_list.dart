import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/ui/master/ledger/ledger_master.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';

class LedgerListScreen extends StatefulWidget {
  const LedgerListScreen({super.key});

  @override
  State<LedgerListScreen> createState() => _LedgerListScreenState();
}

class _LedgerListScreenState extends State<LedgerListScreen> {
  List<LedgerListModel> ledgerList = [];

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
      ledgerList = responseData
          .map((e) => LedgerListModel.fromJson(e))
          .toList();
    });
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
                  _tableHeader(),
                  const Divider(height: 1),
                  Expanded(
                    child: ledgerList.isEmpty
                        ? const Center(child: Text("No Data Found"))
                        : ListView.separated(
                            itemCount: ledgerList.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, i) {
                              return _tableRow(ledgerList[i], i);
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
          _iconBtn(Icons.edit, AppColor.primary, () async {
            var data = await pushTo(CreateLedger(existing: l));
            if (data != null) ledgerApi();
          }),
          const SizedBox(width: 10),
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
              _d("Opening Balance", "${l.openingBalance} ${l.openingType}"),
              _d("Closing Balance", l.closingBalance?.toString()),
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
}
