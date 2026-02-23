// ignore_for_file: must_be_immutable
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';

class UserRight {
  String title;
  bool view;
  bool create;
  bool update;
  bool delete;

  UserRight({
    required this.title,
    this.view = false,
    this.create = false,
    this.update = false,
    this.delete = false,
  });
}

class UserScreenCreate extends StatefulWidget {
  const UserScreenCreate({super.key});

  @override
  State<UserScreenCreate> createState() => _UserScreenCreateState();
}

class _UserScreenCreateState extends State<UserScreenCreate> {
  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  List<UserRight> rightsList = [
    UserRight(title: "Item"),
    UserRight(title: "Ledger"),
    UserRight(title: "Misc Charge"),
    UserRight(title: "Employee"),
    UserRight(title: "User"),
    UserRight(title: "Payment Voucher"),
    UserRight(title: "Receipt Voucher"),
    UserRight(title: "Contra Voucher"),
    UserRight(title: "Expense Voucher"),
    UserRight(title: "Journal Voucher"),
    UserRight(title: "Purchase Order"),
    UserRight(title: "Purchase Invoice"),
    UserRight(title: "Purchase Return"),
    UserRight(title: "Debit Note"),
    UserRight(title: "Estimate"),
    UserRight(title: "Performa Invoice"),
    UserRight(title: "Delivery Challan"),
    UserRight(title: "Sale Invoice"),
    UserRight(title: "Sale Return"),
    UserRight(title: "Credit Note"),
  ];

  List<String> singleRights = [
    "Dashboard",
    "Outstanding Report",
    "Profit/Loss Report",
    "Company Profile",
    "GSTR-1",
    "GSTR-2",
    "Bank Book",
    "Cash Book",
    "Day Book",
    "Ledger Report",
    "Purchase Invoice Report",
    "Sale Invoice Report",
    "GST Purchase Report",
    "GST Sale Report",
    "Item Report by Party",
    "Item Sale-Purchase Summary",
    "Item Profit/Loss Reprot",
    "Stock Details Reprot",
  ];

  List<String> singleRightsSelected = [];

  bool allViewSelected = false;
  bool allCreateSelected = false;
  bool allUpdateSelected = false;
  bool allDeleteSelected = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF9FAFC),
      appBar: AppBar(
        backgroundColor: AppColor.white,
        elevation: .4,
        shadowColor: AppColor.grey,
        iconTheme: IconThemeData(color: AppColor.black),
        title: Text(
          "Create New User",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.blackText,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: Sizes.width * .03,
          vertical: Sizes.height * .04,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// USER DETAILS
            _sectionCard(
              title: "User Details",
              child: Row(
                children: [
                  Expanded(
                    child: CommonTextField(
                      hintText: "User Name",
                      controller: userNameController,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CommonTextField(
                      hintText: "Password",
                      controller: passwordController,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            /// MODULE RIGHTS HEADER
            _moduleHeader(),

            const SizedBox(height: 15),

            /// MODULE RIGHTS LIST
            SizedBox(
              width: double.infinity,
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 5,
                children: rightsList.map((e) => _buildRightCard(e)).toList(),
              ),
            ),

            const SizedBox(height: 30),

            /// OTHER RIGHTS
            _sectionCard(
              title: "Other Rights",
              child: SizedBox(
                width: double.infinity,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runSpacing: 20,
                  spacing: 10,
                  children: singleRights
                      .map((e) => _singleRightTile(e))
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      ),

      /// BUTTONS
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColor.white,
          border: Border(top: BorderSide(color: AppColor.grey, width: .5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            defaultButton(
              buttonColor: const Color(0xff8947E5),
              text: "Create User",
              height: 40,
              width: 149,
              onTap: () => saveOrUpdate(),
            ),
            const SizedBox(width: 18),
            defaultButton(
              buttonColor: const Color(0xffE11414),
              text: "Cancel",
              height: 40,
              width: 93,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _moduleHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "Module Rights",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            _headerChip("View", allViewSelected, () => _toggleAll("view")),
            _headerChip(
              "Create",
              allCreateSelected,
              () => _toggleAll("create"),
            ),
            _headerChip(
              "Update",
              allUpdateSelected,
              () => _toggleAll("update"),
            ),
            _headerChip(
              "Delete",
              allDeleteSelected,
              () => _toggleAll("delete"),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerChip(String text, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected ? const Color(0xff8947E5) : const Color(0xffEDE5FF),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : const Color(0xff8947E5),
          ),
        ),
      ),
    );
  }

  void _toggleAll(String type) {
    setState(() {
      if (type == "view") {
        allViewSelected = !allViewSelected;
        for (var e in rightsList) {
          e.view = allViewSelected;
        }
        if (allViewSelected) {
          singleRightsSelected = List.from(singleRights);
        } else {
          singleRightsSelected.clear();
        }
      }

      if (type == "create") {
        allCreateSelected = !allCreateSelected;
        for (var e in rightsList) {
          e.create = allCreateSelected;
          if (allCreateSelected) e.view = true;
        }
      }

      if (type == "update") {
        allUpdateSelected = !allUpdateSelected;
        for (var e in rightsList) {
          e.update = allUpdateSelected;
          if (allUpdateSelected) e.view = true;
        }
      }

      if (type == "delete") {
        allDeleteSelected = !allDeleteSelected;
        for (var e in rightsList) {
          e.delete = allDeleteSelected;
          if (allDeleteSelected) e.view = true;
        }
      }
    });
  }

  Widget _buildRightCard(UserRight right) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColor.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColor.grey.withOpacity(.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            right.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            children: [
              _permissionChip(
                "View",
                right.view,
                (v) => setState(() => right.view = v),
              ),
              _permissionChip("Create", right.create, (v) {
                setState(() {
                  right.create = v;
                  if (v) right.view = true;
                });
              }),
              _permissionChip("Update", right.update, (v) {
                setState(() {
                  right.update = v;
                  if (v) right.view = true;
                });
              }),
              _permissionChip("Delete", right.delete, (v) {
                setState(() {
                  right.delete = v;
                  if (v) right.view = true;
                });
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _permissionChip(String text, bool value, Function(bool) onChanged) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: value ? const Color(0xff8947E5) : const Color(0xffF3F4F6),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: value ? Colors.white : Colors.black54,
          ),
        ),
      ),
    );
  }

  Widget _singleRightTile(String title) {
    final selected = singleRightsSelected.contains(title);

    return SizedBox(
      width: Sizes.width * .215,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? const Color(0xffEDE5FF) : const Color(0xffF8F9FC),
          border: Border.all(
            color: selected ? const Color(0xff8947E5) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Switch(
              value: selected,
              activeColor: const Color(0xff8947E5),
              onChanged: (val) {
                setState(() {
                  if (val) {
                    singleRightsSelected.add(title);
                  } else {
                    singleRightsSelected.remove(title);
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveOrUpdate() async {
    if (userNameController.text.trim().isEmpty) {
      showCustomSnackbarError(context, "Please enter username");
      return;
    }
    if (passwordController.text.trim().isEmpty) {
      showCustomSnackbarError(context, "Please enter password");
      return;
    }
    final payload = {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "username": userNameController.text.trim(),
      "password": passwordController.text.trim(),
      "role": "user",
      "is_active": "true",
      "rights": rightsList
          .map(
            (e) => {
              "module": e.title,
              "view": e.view,
              "create": e.create,
              "update": e.update,
              "delete": e.delete,
            },
          )
          .toList(),
      "singlr_tight": singleRightsSelected,
    };

    final res = await ApiService.postData(
      "user",
      payload,
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res != null && res["status"] == true) {
      print(res);
      Navigator.pop(context, "refresh");
      showCustomSnackbarSuccess(context, res["message"]);
    } else {
      showCustomSnackbarError(context, res?["message"] ?? "Error");
    }
  }
}
