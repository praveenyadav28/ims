import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';

class ManageTermsConditionsScreen extends StatefulWidget {
  final String transactionId;

  const ManageTermsConditionsScreen({super.key, required this.transactionId});

  @override
  State<ManageTermsConditionsScreen> createState() =>
      _ManageTermsConditionsScreenState();
}

class _ManageTermsConditionsScreenState
    extends State<ManageTermsConditionsScreen> {
  final TextEditingController _controller = TextEditingController();

  List<dynamic> termsList = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fetchTerms();
  }

  Future<void> fetchTerms() async {
    setState(() => loading = true);

    final res = await ApiService.fetchData(
      "get/term",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res != null && res["status"] == true) {
      final fullList = res["data"] as List;

      // ✅ FILTER HERE
      termsList = fullList.where((item) {
        return item["id"].toString() == widget.transactionId.toString();
      }).toList();
    }

    setState(() => loading = false);
  }

  // ---------------- ADD ----------------
  Future<void> addTerm() async {
    if (_controller.text.trim().isEmpty) return;

    final res = await ApiService.postData("term", {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "id": widget.transactionId,
      "remark": _controller.text.trim(),
      "status": true,
    }, licenceNo: Preference.getint(PrefKeys.licenseNo));

    if (res["status"] == true) {
      _controller.clear();
      fetchTerms();
      showCustomSnackbarSuccess(context, "Added");
    } else {
      showCustomSnackbarError(context, res["message"]);
    }
  }

  // ---------------- STATUS UPDATE ----------------
  Future<void> updateStatus(String id, bool value, String termId) async {
    var data = await ApiService.putData("term/$id", {
      "status": value,
      "id": termId,
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
    }, licenceNo: Preference.getint(PrefKeys.licenseNo));
    print("$data new data");

    if (data != null && data["status"] == true) {
      await fetchTerms();
    } else {
      showCustomSnackbarError(context, data?["message"] ?? "Update failed");
    }
  }

  // ---------------- DELETE ----------------
  Future<void> deleteTerm(String id) async {
    var data = await ApiService.deleteData(
      "term/$id",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    print("$data new data");
    if (data != null && data["status"] == true) {
      await fetchTerms();
      showCustomSnackbarSuccess(context, "Deleted");
    } else {
      showCustomSnackbarError(context, data?["message"] ?? "Delete failed");
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: AppColor.black),
          onPressed: () {
            Navigator.pop(context, true);
          },
        ),
        title: Text(
          "Manage Terms",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColor.black,
          ),
        ),
        backgroundColor: AppColor.appbarColor,
        elevation: 1,
        iconTheme: IconThemeData(color: AppColor.black),
      ),
      backgroundColor: AppColor.white,
      body: Column(
        children: [
          // -------- ADD FIELD --------
          Padding(
            padding: const EdgeInsets.all(12),

            child: TitleTextFeild(
              controller: _controller,
              maxLines: 4,

              hintText: "Write Terms & Conditions",

              titleText: "Terms & Conditions",
              suffixIcon: SizedBox(
                width: 100,
                child: Padding(
                  padding: EdgeInsetsGeometry.only(right: 10),
                  child: defaultButton(
                    onTap: addTerm,

                    buttonColor: AppColor.primary,
                    text: "Add",
                    height: 40,
                    width: 90,
                  ),
                ),
              ),
            ),
          ),

          const Divider(),

          // -------- LIST --------
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : termsList.isEmpty
                ? const Center(child: Text("No Terms Found"))
                : ListView.builder(
                    itemCount: termsList.length,
                    itemBuilder: (_, index) {
                      final item = termsList[index];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ListTile(
                          title: Text(item["remark"] ?? ""),

                          // ✅ ACTIVE SWITCH
                          leading: Switch(
                            value: item["status"] == true,
                            activeColor: AppColor.primary,
                            onChanged: (v) {
                              print("CLICKED: ${item}");
                              print("ID: ${item["id"]}");
                              updateStatus(
                                item["_id"].toString(),
                                v,
                                item["id"],
                              );
                            },
                          ),

                          // ✅ DELETE
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: AppColor.red),
                            onPressed: () {
                              _showDeleteDialog(item["_id"], item["remark"]);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          "Delete Term",
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        content: Text(
          "Are you sure you want to delete\n\"$name\" ?",
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: AppColor.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColor.red),
            onPressed: () async {
              Navigator.pop(context); // close dialog
              await deleteTerm(id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
