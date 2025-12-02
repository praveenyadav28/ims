import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/component/side_menu.dart';
import 'package:ims/utils/colors.dart';

class CreateNewItemScreenOld extends StatefulWidget {
  const CreateNewItemScreenOld({super.key});

  @override
  State<CreateNewItemScreenOld> createState() => _CreateNewItemScreenOldState();
}

class _CreateNewItemScreenOldState extends State<CreateNewItemScreenOld> {
  int selectedTab = 0; // 0 = Basic Details, 1 = Other Details

  void saveOrUpdate() {
    // Your save logic here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ---------------------- APP BAR ----------------------
      appBar: AppBar(
        backgroundColor: AppColor.appbarColor,
        // leading: IconButton(
        //   onPressed: () {
        //     Navigator.pop(context);
        //   },
        //   icon: Icon(Icons.arrow_back, color: AppColor.black),
        // ),
        elevation: .4,
        shadowColor: AppColor.grey,
        title: Text(
          "Create New Item",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppColor.blackText,
          ),
        ),
      ),
      drawer: SideMenu(),
      // ---------------------- BODY ----------------------
      body: Row(
        children: [
          // ------------ LEFT SIDEBAR ------------
          Container(
            width: 200,
            color: Color(0xffF9F9FB),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30, left: 20, bottom: 20),
                  child: Text(
                    "Item Details",
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColor.blackText,
                    ),
                  ),
                ),
                tabButton("Basic Details*", 0),
                tabButton("Other Details", 1),
              ],
            ),
          ),

          // ------------ RIGHT CONTENT AREA ------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: selectedTab == 0
                  ? basicDetailsWidget()
                  : otherDetailsWidget(),
            ),
          ),
        ],
      ),

      // ---------------------- BOTTOM NAVIGATION ----------------------
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(
          top: 17,
          bottom: 24,
          left: 27,
          right: 27,
        ),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColor.grey, width: .5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            defaultButton(
              buttonColor: const Color(0xff8947E5),
              text: "Save New Item",
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
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- TAB BUTTON ----------------------
  Widget tabButton(String title, int index) {
    final isSelected = selectedTab == index;
    return InkWell(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
        color: isSelected ? Colors.white : Color(0xffF9F9FB),
        child: Row(
          children: [
            Icon(
              Icons.currency_rupee,
              size: 18,
              color: isSelected ? const Color(0xff8947E5) : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: isSelected ? const Color(0xff8947E5) : Colors.black54,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------- BASIC DETAILS ----------------------
  Widget basicDetailsWidget() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: itemTypeField()),
              const SizedBox(width: 24),
              Expanded(child: categoryField()),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: textField("Item Name*", "Maggie 20gm")),
              const SizedBox(width: 24),
              Expanded(child: textField("Item No.*", "Maggie 20gm")),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: priceField("Sales Price", "₹ 200", true)),
              const SizedBox(width: 24),
              Expanded(child: priceField("Purchase Price", "₹ 200", false)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: textField("HSN CODE", "HSN CODE")),
              const SizedBox(width: 24),
              Expanded(child: textField("GST Tax Rate (%)", "Select Tax Rate")),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: textField("Measuring Unit", "Pieces (PCS)")),
              const SizedBox(width: 24),
              Expanded(child: textField("Opening Stock", "150 PCS")),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------- OTHER DETAILS ----------------------
  Widget otherDetailsWidget() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey),
        borderRadius: BorderRadius.circular(6),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: textField("Minimum Order Quantity", "Maggie 20gm"),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: textField("Minimum Stock Quantity", "Maggie 20gm"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: textField("Purchase Price", "₹ 200")),
              const SizedBox(width: 24),
              Expanded(child: textField("Sale Price", "₹ 200")),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: textField("Margin %", "%150")),
              const SizedBox(width: 24),
              Expanded(child: textField("Margin Amt", "150")),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [Expanded(child: textField("Re-order Level", "150 PCS"))],
          ),
        ],
      ),
    );
  }

  // ---------------------- FIELD WIDGETS ----------------------
  Widget textField(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.grey),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColor.grey),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget itemTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Item Type*",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Radio(value: 0, groupValue: 1, onChanged: (_) {}),
            const Text("Product"),
            const SizedBox(width: 10),
            Radio(value: 1, groupValue: 1, onChanged: (_) {}),
            const Text("Service"),
          ],
        ),
      ],
    );
  }

  Widget categoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Category",
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          decoration: InputDecoration(
            hintText: "Select Category",
            suffixIcon: const Icon(Icons.add, color: Colors.black54),
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppColor.grey),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget priceField(String label, String value, bool withTax) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                decoration: InputDecoration(
                  hintText: value,
                  prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: AppColor.grey),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (withTax)
              Expanded(
                flex: 1,
                child: Container(
                  height: 47,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColor.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: const Text("With Tax"),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ---------------------- BUTTON ----------------------
  Widget defaultButton({
    required Color buttonColor,
    required String text,
    double height = 45,
    double width = 120,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: buttonColor,
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
