import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';

class AddHsnScreen extends StatefulWidget {
  const AddHsnScreen({super.key});

  @override
  State<AddHsnScreen> createState() => _AddHsnScreenState();
}

class _AddHsnScreenState extends State<AddHsnScreen> {
  TextEditingController hsnCodeController = TextEditingController();
  TextEditingController igstController = TextEditingController();
  TextEditingController cgstController = TextEditingController();
  TextEditingController sgstController = TextEditingController();
  TextEditingController _editController = TextEditingController();

  List<Map<String, dynamic>> hsnList = [];

  @override
  void initState() {
    super.initState();
    fetchHsnList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Add HSN",
          style: GoogleFonts.inter(
            color: AppColor.black,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: IconThemeData(color: AppColor.black),
        elevation: 2,
        backgroundColor: AppColor.appbarColor,
        leading: IconButton(
          onPressed: () => Navigator.pop(context, "update data"),
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: Sizes.height * 0.03,
          horizontal: Sizes.width * 0.04,
        ),
        child: Column(
          children: [
            CommonTextField(
              controller: hsnCodeController,
              hintText: "HSN Code",
              perfixIcon: Icon(Icons.qr_code, color: AppColor.grey),
            ),
            SizedBox(height: Sizes.height * 0.02),

            // IGST Field
            CommonTextField(
              controller: igstController,
              hintText: "Enter IGST %",
              perfixIcon: Icon(Icons.percent, color: AppColor.grey),
              onChanged: (val) {
                final igst = double.tryParse(val) ?? 0;
                cgstController.text = (igst / 2).toStringAsFixed(2);
                sgstController.text = (igst / 2).toStringAsFixed(2);
                setState(() {});
              },
            ),
            SizedBox(height: Sizes.height * 0.02),

            // CGST & SGST (auto)
            Row(
              children: [
                Expanded(
                  child: CommonTextField(
                    controller: cgstController,
                    hintText: "CGST %",
                    readOnly: true,
                    perfixIcon: Icon(Icons.percent, color: AppColor.grey),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: CommonTextField(
                    controller: sgstController,
                    hintText: "SGST %",
                    readOnly: true,
                    perfixIcon: Icon(Icons.percent, color: AppColor.grey),
                  ),
                ),
              ],
            ),

            SizedBox(height: Sizes.height * 0.04),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 14,
                ),
              ),
              onPressed: () => postHsn(),
              child: const Text("Save"),
            ),
            SizedBox(height: Sizes.height * 0.03),

            // HSN List
            hsnList.isEmpty
                ? const Center(child: Text("No HSN found"))
                : SizedBox(
                    width: double.infinity,
                    child: Wrap(
                      spacing: Sizes.width * 0.02,
                      runSpacing: Sizes.height * 0.02,
                      children: List.generate(hsnList.length, (index) {
                        final item = hsnList[index];
                        return SizedBox(
                          width: Sizes.width * 0.293,
                          child: Card(
                            child: ListTile(
                              leading: Text(
                                "${index + 1}",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: AppColor.black,
                                ),
                              ),
                              title: Text(
                                item["name"] ?? "",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: AppColor.black,
                                ),
                              ),
                              subtitle: Text(
                                "IGST: ${item["igst"] ?? ""}% | CGST: ${item["cgst"] ?? ""}% | SGST: ${item["sgst"] ?? ""}%",
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: AppColor.primary,
                                    ),
                                    onPressed: () {
                                      _editController.text = item["name"] ?? "";
                                      final TextEditingController
                                      _editIgstController =
                                          TextEditingController(
                                            text:
                                                item["igst"]?.toString() ?? "",
                                          );
                                      final TextEditingController
                                      _editCgstController =
                                          TextEditingController(
                                            text:
                                                item["cgst"]?.toString() ?? "",
                                          );
                                      final TextEditingController
                                      _editSgstController =
                                          TextEditingController(
                                            text:
                                                item["sgst"]?.toString() ?? "",
                                          );

                                      showDialog(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            title: const Text('Edit HSN'),
                                            content: SingleChildScrollView(
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  CommonTextField(
                                                    controller: _editController,
                                                    hintText: "HSN Name",
                                                    perfixIcon: Icon(
                                                      Icons.qr_code,
                                                      color: AppColor.grey,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  CommonTextField(
                                                    controller:
                                                        _editIgstController,
                                                    hintText: "IGST %",
                                                    perfixIcon: Icon(
                                                      Icons.percent,
                                                      color: AppColor.grey,
                                                    ),
                                                    onChanged: (val) {
                                                      final igst =
                                                          double.tryParse(
                                                            val,
                                                          ) ??
                                                          0;
                                                      _editCgstController
                                                          .text = (igst / 2)
                                                          .toStringAsFixed(2);
                                                      _editSgstController
                                                          .text = (igst / 2)
                                                          .toStringAsFixed(2);
                                                    },
                                                  ),
                                                  const SizedBox(height: 12),
                                                  Row(
                                                    children: [
                                                      Expanded(
                                                        child: CommonTextField(
                                                          controller:
                                                              _editCgstController,
                                                          hintText: "CGST %",
                                                          readOnly: true,
                                                          perfixIcon: Icon(
                                                            Icons.percent,
                                                            color:
                                                                AppColor.grey,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: CommonTextField(
                                                          controller:
                                                              _editSgstController,
                                                          hintText: "SGST %",
                                                          readOnly: true,
                                                          perfixIcon: Icon(
                                                            Icons.percent,
                                                            color:
                                                                AppColor.grey,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  editHsn(
                                                    item["_id"].toString(),
                                                    _editController.text,
                                                    _editIgstController.text,
                                                    _editCgstController.text,
                                                    _editSgstController.text,
                                                  );
                                                },
                                                child: Text(
                                                  'Save',
                                                  style: TextStyle(
                                                    color: AppColor.red,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color: AppColor.red,
                                    ),
                                    onPressed: () {
                                      reuseDialog(
                                        context,
                                        title: "HSN",
                                        content: item["name"],
                                        action: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => deleteHsn(
                                              item["_id"].toString(),
                                            ),
                                            child: Text(
                                              'Delete',
                                              style: TextStyle(
                                                color: AppColor.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  /// ✅ Fetch all HSNs
  Future<void> fetchHsnList() async {
    try {
      final response = await ApiService.fetchData(
        "get/hsn",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      if (response != null && response["status"] == true) {
        final List<dynamic> data = response["data"] ?? [];
        setState(() {
          hsnList = List<Map<String, dynamic>>.from(data);
        });
      } else {
        setState(() => hsnList = []);
      }
    } catch (e) {
      showCustomSnackbarError(context, "Error fetching HSNs: $e");
    }
  }

  /// ✅ Add new HSN
  Future<void> postHsn() async {
    final data = {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "name": hsnCodeController.text,
      "igst": igstController.text,
      "cgst": cgstController.text,
      "sgst": sgstController.text,
    };

    try {
      final response = await ApiService.postData(
        "hsn",
        data,
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      if (response["status"] == true) {
        showCustomSnackbarSuccess(context, response["message"]);
        hsnCodeController.clear();
        igstController.clear();
        cgstController.clear();
        sgstController.clear();
        fetchHsnList();
      } else {
        showCustomSnackbarError(
          context,
          response["message"] ?? "Failed to save",
        );
      }
    } catch (e) {
      showCustomSnackbarError(context, "Error posting HSN: $e");
    }
  }

  /// ✅ Delete HSN
  Future<void> deleteHsn(String id) async {
    try {
      final response = await ApiService.deleteData(
        "hsn/$id",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      if (response["status"] == true) {
        showCustomSnackbarSuccess(context, response["message"]);
        fetchHsnList();
        Navigator.pop(context, "data update");
      } else {
        showCustomSnackbarError(
          context,
          response["message"] ?? "Failed to delete",
        );
      }
    } catch (e) {
      showCustomSnackbarError(context, "Error deleting HSN: $e");
    }
  }

  //// ✅ Edit HSN name & IGST/CGST/SGST
  Future<void> editHsn(
    String id,
    String newName,
    String igst,
    String cgst,
    String sgst,
  ) async {
    final data = {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "name": newName,
      "igst": igst,
      "cgst": cgst,
      "sgst": sgst,
    };

    try {
      final response = await ApiService.putData(
        "hsn/$id",
        data,
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      if (response["status"] == true) {
        showCustomSnackbarSuccess(context, "Updated successfully");
        fetchHsnList();
        Navigator.pop(context, "data update");
        _editController.clear();
      } else {
        showCustomSnackbarError(
          context,
          response["message"] ?? "Failed to update",
        );
      }
    } catch (e) {
      showCustomSnackbarError(context, "Error updating HSN: $e");
    }
  }

  /// ✅ Reusable Delete Confirmation
  reuseDialog(BuildContext context, {title, content, List<Widget>? action}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete $title'),
          content: Text('Are you sure you want to delete $content ?'),
          actions: action,
        );
      },
    );
  }
}
