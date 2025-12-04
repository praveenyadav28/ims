import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/component/side_menu.dart';
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

  // ----------------------- FETCH DATA -------------------------
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

  // ----------------------- DELETE -------------------------
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

  // ----------------------- DELETE CONFIRMATION -------------------------
  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Misc Charge"),
        content: const Text("Are you sure you want to delete this entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              deleteMisc(id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = miscList.where((e) {
      return e.name.toLowerCase().contains(_search.toLowerCase()) ||
          e.ledgerName.toLowerCase().contains(_search.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.appbarColor,
        iconTheme: IconThemeData(color: AppColor.black),
        elevation: .4,
        title: Text(
          "Misc Charge List",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.blackText,
          ),
        ),
        actions: [
          InkWell(
            onTap: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateMiscCharge()),
              );

              if (updated == "refresh") fetchMiscCharges();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add),

                Text("Create  ", style: TextStyle(color: AppColor.black)),
              ],
            ),
          ),
        ],
      ),
      drawer: SideMenu(),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🌟 Search
            CommonTextField(
              hintText: "Search...",
              onChanged: (v) => setState(() => _search = v),
            ),
            const SizedBox(height: 20),

            // 🌟 Table Header
            Container(
              decoration: const BoxDecoration(color: Color(0xffE5FDDD)),
              child: Table(
                border: TableBorder.all(color: Colors.grey),

                children: const [
                  TableRow(
                    children: [
                      _Header("Name"),
                      _Header("Ledger"),
                      _Header("GST (%)"),
                      _Header("Action"),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Table(
                  border: TableBorder.all(color: Colors.grey),
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  children: filtered.map((e) {
                    return TableRow(
                      children: [
                        _Cell(e.name),
                        _Cell(e.ledgerName),
                        _Cell(e.gst?.toString() ?? "0"),
                        _actionButtons(e),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------- TABLE CELLS -------------------------

  Widget _actionButtons(MiscChargeModelList e) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Edit
          IconButton(
            onPressed: () async {
              final updated = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateMiscCharge(editData: e),
                ),
              );
              if (updated == "refresh") fetchMiscCharges();
            },
            icon: Icon(Icons.edit, color: AppColor.blue),
          ),

          // Delete
          IconButton(
            onPressed: () => confirmDelete(e.id),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  const _Header(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final String text;
  const _Cell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}
