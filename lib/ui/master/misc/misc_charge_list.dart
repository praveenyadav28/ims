import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/master/misc/misc_charge.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';
import 'misc_charge_model.dart';

class MiscChargeScreen extends StatefulWidget {
  const MiscChargeScreen({super.key});

  @override
  State<MiscChargeScreen> createState() => _MiscChargeScreenState();
}

class _MiscChargeScreenState extends State<MiscChargeScreen> {
  List<MiscChargeModelList> miscList = [];
  String _search = "";

  @override
  void initState() {
    super.initState();
    fetchMiscCharges();
  }

  // ---------------- API ----------------
  Future<void> fetchMiscCharges() async {
    final res = await ApiService.fetchData(
      "get/misccharge",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res["status"] == true) {
      miscList = (res["data"] as List)
          .map((e) => MiscChargeModelList.fromJson(e))
          .toList();
      setState(() {});
    }
  }

  Future<void> deleteMisc(String id) async {
    final res = await ApiService.deleteData(
      "misccharge/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res["status"] == true) {
      showCustomSnackbarSuccess(context, res["message"]);
      fetchMiscCharges();
    } else {
      showCustomSnackbarError(context, res["message"]);
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final filtered = miscList.where((e) {
      return e.name.toLowerCase().contains(_search.toLowerCase()) ||
          e.ledgerName.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColor.black,
        title: Text(
          "Misc Charges",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.white,
          ),
        ),
        actions: [
          Center(
            child: TextButton.icon(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateMiscCharge()),
                );
                if (updated == "refresh") fetchMiscCharges();
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Create",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),

      body: Column(
        children: [
          const SizedBox(height: 16),

          // -------- SEARCH ----------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CommonTextField(
              hintText: "Search by name or ledger...",
              onChanged: (v) => setState(() => _search = v),
            ),
          ),

          const SizedBox(height: 16),

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
                    child: filtered.isEmpty
                        ? const Center(child: Text("No Data Found"))
                        : ListView.separated(
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                Divider(height: 1, color: Colors.grey.shade200),
                            itemBuilder: (context, i) {
                              return _tableRow(filtered[i], i);
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
          Expanded(flex: 3, child: Text("Name", style: _headStyle)),
          Expanded(flex: 3, child: Text("Ledger", style: _headStyle)),
          Expanded(flex: 2, child: Text("GST %", style: _headStyle)),
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

  // ---------------- ROW ----------------
  Widget _tableRow(MiscChargeModelList e, int index) {
    final bool even = index.isEven;

    return Container(
      color: even ? const Color(0xffF9FAFB) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      child: Row(
        children: [
          Expanded(flex: 3, child: _cell(e.name)),
          Expanded(flex: 3, child: _ledgerChip(e.ledgerName)),
          Expanded(flex: 2, child: _gstChip(e.gst)),
          _actionButtons(e),
        ],
      ),
    );
  }

  // ---------------- CELLS ----------------
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

  Widget _ledgerChip(String ledger) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          ledger,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.indigo.shade700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _gstChip(double? gst) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          "${gst ?? 0}%",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Colors.green.shade700,
          ),
        ),
      ),
    );
  }

  // ---------------- ACTIONS ----------------
  Widget _actionButtons(MiscChargeModelList e) {
    return SizedBox(
      width: 110,
      child: Row(
        children: [
          _iconBtn(Icons.edit, AppColor.primary, () async {
            final updated = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CreateMiscCharge(editData: e)),
            );
            if (updated == "refresh") fetchMiscCharges();
          }),
          const SizedBox(width: 10),
          _iconBtn(Icons.delete, Colors.red, () => _confirmDelete(e.id)),
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

  // ---------------- DELETE ----------------
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Misc Charge"),
        content: const Text("Are you sure you want to delete this entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await deleteMisc(id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
