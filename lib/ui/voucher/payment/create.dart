import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';

class PaymentEntry extends StatefulWidget {
  const PaymentEntry({super.key});

  @override
  State<PaymentEntry> createState() => _PaymentEntryState();
}

class _PaymentEntryState extends State<PaymentEntry> {
  TextEditingController partyController = TextEditingController();
  TextEditingController invoiceNoController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_back, color: AppColor.black),
        ),
        elevation: 0,
        // shadowColor: AppColor.grey,
        title: Text(
          "Create Payment Voucher",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppColor.blackText,
          ),
        ),

        actions: [
          Row(
            children: [
              defaultButton(
                buttonColor: const Color(0xffE11414),
                text: "Cancel",
                height: 40,
                width: 93,
              ),
              const SizedBox(width: 18),
              defaultButton(
                buttonColor: const Color(0xff8947E5),
                text: "Save",
                height: 40,
                width: 113,
              ),
              const SizedBox(width: 18),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          vertical: Sizes.height * .02,
          horizontal: 14,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 19),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff171a1f14),
                          offset: Offset(0, .5),
                          blurRadius: 4,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColor.borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Party Name",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColor.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CommonSearchableDropdownField<String>(
                                    controller: partyController,
                                    hintText: "Search party by name or number",
                                    suggestions: [],
                                    onSuggestionTap: (item) {
                                      setState(() {});
                                    },
                                    suffixIcon: Icon(Icons.keyboard_arrow_down),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Invoice",
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: AppColor.textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CommonSearchableDropdownField<String>(
                                    controller: invoiceNoController,
                                    hintText: "Enter Invoice Number",
                                    suggestions: [],
                                    onSuggestionTap: (item) {
                                      setState(() {});
                                    },
                                    suffixIcon: Icon(Icons.keyboard_arrow_down),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: Sizes.height * .02),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Payment Mode",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CommonSearchableDropdownField<String>(
                              controller: partyController,
                              hintText: "Select Payment Mode",
                              suggestions: [],
                              onSuggestionTap: (item) {
                                setState(() {});
                              },
                              suffixIcon: Icon(Icons.keyboard_arrow_down),
                            ),
                          ],
                        ),

                        SizedBox(height: Sizes.height * .02),
                        TitleTextFeild(
                          controller: amountController,
                          titleText: "Enter Payment Amount",
                          hintText: "0",
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 18),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 20, horizontal: 19),
                    decoration: BoxDecoration(
                      color: AppColor.white,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xff171a1f14),
                          offset: Offset(0, .5),
                          blurRadius: 4,
                        ),
                      ],
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColor.borderColor),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TitleTextFeild(titleText: "Payment Date"),
                            ),
                            SizedBox(width: 30),
                            Expanded(
                              child: TitleTextFeild(
                                titleText: "Voucher Prifix",
                              ),
                            ),
                            SizedBox(width: 30),
                            Expanded(
                              child: TitleTextFeild(
                                titleText: "Payment Voucher No.",
                              ),
                            ),
                            SizedBox(width: 30),
                          ],
                        ),
                        SizedBox(height: Sizes.height * .037),
                        TitleTextFeild(
                          titleText: "Notes",
                          maxLines: 5,
                          hintText: "Enter Notes",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
