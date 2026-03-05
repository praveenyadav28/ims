import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/misc_model.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';

class AddGroupScreen extends StatefulWidget {
  final String miscId; // ✅ string now
  final String name;

  const AddGroupScreen({super.key, required this.miscId, required this.name});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  TextEditingController groupController = TextEditingController();
  TextEditingController _editController = TextEditingController();
  TextEditingController searchController = TextEditingController();
  List<MiscItem> filteredGroupList = [];
  List<MiscItem> groupList = [];

  @override
  void initState() {
    super.initState();
    fetchDataByMiscType();

    searchController.addListener(_filterGroups);
  }

  @override
  void dispose() {
    groupController.dispose();
    _editController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _filterGroups() {
    final query = searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredGroupList = List.from(groupList);
      } else {
        filteredGroupList = groupList.where((item) {
          return (item.name ?? "").toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          "Add ${widget.name}",
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
          onPressed: () {
            Navigator.pop(context, "update data");
          },
          icon: const Icon(Icons.arrow_back_ios),
        ),
      ),
      backgroundColor: AppColor.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: Sizes.height * 0.04,
          horizontal: Sizes.width * .04,
        ),
        child: Column(
          children: [
            // ✅ Add Group Field
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      CommonTextField(
                        controller: groupController,
                        hintText: "${widget.name} Name",
                        perfixIcon: Icon(Icons.code, color: AppColor.grey),
                      ),
                      SizedBox(height: Sizes.height * 0.05),

                      // ✅ Save Button
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 30,
                            vertical: 14,
                          ),
                        ),
                        onPressed: () => postData(),
                        child: const Text("Save"),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: Sizes.width * .04),
                Expanded(
                  child: CommonTextField(
                    controller: searchController,
                    hintText: "Search ${widget.name}",
                    perfixIcon: Icon(Icons.search, color: AppColor.grey),
                  ),
                ),
              ],
            ),
            SizedBox(height: Sizes.height * 0.02),
            // ✅ Group List
            SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: Sizes.width * 0.02,
                runSpacing: Sizes.height * 0.02,
                children: List.generate(filteredGroupList.length, (index) {
                  final item = filteredGroupList[index];
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
                          item.name ?? "",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: AppColor.black,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ✅ Edit
                            IconButton(
                              icon: Icon(Icons.edit, color: AppColor.primary),
                              onPressed: () {
                                _editController.text = item.name ?? "";
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text('Edit ${widget.name}'),
                                      content: SizedBox(
                                        height: 50,
                                        child: CommonTextField(
                                          controller: _editController,
                                          hintText: "Edit",
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            editMismaster(
                                              item.id ?? "",
                                              _editController.text,
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

                            // ✅ Delete
                            IconButton(
                              icon: Icon(Icons.delete, color: AppColor.red),
                              onPressed: () {
                                reuseDialog(
                                  context,
                                  title: widget.name,
                                  content: item.name,
                                  action: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          deleteMismaster(item.id ?? ""),
                                      child: Text(
                                        'Delete',
                                        style: TextStyle(color: AppColor.red),
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

  /// ✅ Fetch All Groups and filter by misc_id
  Future<void> fetchDataByMiscType() async {
    try {
      final response = await ApiService.fetchData(
        "get/misc",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      if (response != null && response["status"] == true) {
        final model = miscResponseFromJson(jsonEncode(response));

        // 🔍 Filter only items matching widget.misc_id
        final filteredList = model.data
            .where((item) => item.miscId == widget.miscId) // check misc_id
            .toList();

        setState(() {
          groupList = filteredList;
          filteredGroupList = List.from(filteredList);
        });
      }
    } catch (e) {
      showCustomSnackbarError(context, "Error fetching data: $e");
    }
  }

  /// ✅ Add Group
  Future<void> postData() async {
    final data = {
      "name": groupController.text,
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "misc_id": widget.miscId,
    };
    try {
      final response = await ApiService.postData(
        "misc",
        data,
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );
      if (response["status"] == true) {
        showCustomSnackbarSuccess(context, response["message"]);
        groupController.clear();
        fetchDataByMiscType();
      } else {
        showCustomSnackbarError(
          context,
          response["message"] ?? "Failed to save",
        );
      }
    } catch (e) {
      showCustomSnackbarError(context, "Error: $e");
    }
  }

  /// ✅ Delete Group
  Future<void> deleteMismaster(String id) async {
    try {
      final response = await ApiService.deleteData(
        "misc/$id",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );
      if (response["status"] == true) {
        showCustomSnackbarSuccess(context, response["message"]);
        fetchDataByMiscType();
        Navigator.pop(context, "data update");
      } else {
        showCustomSnackbarError(
          context,
          response["message"] ?? "Failed to delete",
        );
      }
    } catch (e) {
      showCustomSnackbarError(context, "Error deleting: $e");
    }
  }

  /// ✅ Edit Group
  Future<void> editMismaster(String id, String newName) async {
    final data = {
      "name": newName,
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "misc_id": widget.miscId,
    };

    try {
      final response = await ApiService.putData(
        "misc/$id",
        data,
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      if (response["status"] == true) {
        showCustomSnackbarSuccess(context, "Updated successfully");
        fetchDataByMiscType();
        Navigator.pop(context, "data update");
        _editController.clear();
      } else {
        showCustomSnackbarError(
          context,
          response["message"] ?? "Failed to update",
        );
      }
    } catch (e) {
      showCustomSnackbarError(context, "Error editing: $e");
    }
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
