import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class EstimateDetailsCard extends StatelessWidget {
  const EstimateDetailsCard({
    super.key,
    required this.prefixController,
    required this.estimateNoController,
    required this.validForController,
    required this.pickedEstimateDate,
    required this.pickedValidityDate,
    required this.onTapEstimateDate,
    required this.onTapValidityDate,
    required this.onValidForChanged,
  });

  final TextEditingController prefixController;
  final TextEditingController estimateNoController;
  final TextEditingController validForController;
  final DateTime? pickedEstimateDate;
  final DateTime? pickedValidityDate;
  final VoidCallback onTapEstimateDate;
  final VoidCallback onTapValidityDate;
  final ValueChanged<String> onValidForChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nameField(
          text: "Estimate Invoice No.",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixController,
                  hintText: 'Prefix',
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: estimateNoController,
                  hintText: 'Estimate No',
                ),
              ),
            ],
          ),
          flix: 30,
        ),

        SizedBox(height: Sizes.height * .03),
        nameField(
          text: "Estimate Date",
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: CommonTextField(
                  onTap: onTapEstimateDate,
                  controller: TextEditingController(
                    text: pickedEstimateDate == null
                        ? 'Select Date'
                        : DateFormat('dd MMM yyyy').format(pickedEstimateDate!),
                  ),
                ),
              ),
              Spacer(flex: 2),
            ],
          ),
          flix: 30,
        ),

        SizedBox(height: Sizes.height * .03),
        nameField(
          text: "Vaild For",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: validForController,

                  onChanged: onValidForChanged,
                ),
              ),
              Text(
                "     days",
                style: GoogleFonts.inter(
                  color: Color(0xFF565D6D),
                  fontSize: 14,
                ),
              ),
              Spacer(flex: 2),
            ],
          ),
          flix: 30,
        ),
        SizedBox(height: Sizes.height * .03),
        nameField(
          text: "Vailidity Date",
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: CommonTextField(
                  onTap: onTapValidityDate,
                  controller: TextEditingController(
                    text: pickedValidityDate == null
                        ? 'Select Date'
                        : DateFormat('dd MMM yyyy').format(pickedValidityDate!),
                  ),
                ),
              ),
              Spacer(flex: 2),
            ],
          ),
          flix: 30,
        ),
      ],
    );
  }
}
