import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/purchase/purchase_order/state/purchase_order_bloc.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class PurchaseOrderDetailsCard extends StatelessWidget {
  const PurchaseOrderDetailsCard({
    super.key,
    required this.prefixController,
    required this.purchaseOrderNoController,
    required this.validForController,
    required this.pickedPurchaseOrderDate,
    required this.pickedValidityDate,
    required this.onTapPurchaseOrderDate,
    required this.onTapValidityDate,
    required this.onValidForChanged,
  });

  final TextEditingController prefixController;
  final TextEditingController purchaseOrderNoController;
  final TextEditingController validForController;
  final DateTime? pickedPurchaseOrderDate;
  final DateTime? pickedValidityDate;
  final VoidCallback onTapPurchaseOrderDate;
  final VoidCallback onTapValidityDate;
  final ValueChanged<String> onValidForChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nameField(
          text: "Purchase Order No.",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixController,
                  hintText: 'Prefix',
                  onChanged: (value) {
                    PurchaseOrderBloc bloc = context.read<PurchaseOrderBloc>();
                    bloc.emit(
                      bloc.state.copyWith(
                        purchaseOrderNo: purchaseOrderNoController.text,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: purchaseOrderNoController,
                  hintText: 'Order No',
                  onChanged: (value) {
                    PurchaseOrderBloc bloc = context.read<PurchaseOrderBloc>();
                    bloc.emit(
                      bloc.state.copyWith(
                        purchaseOrderNo: purchaseOrderNoController.text,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          flix: 30,
        ),

        SizedBox(height: Sizes.height * .03),
        nameField(
          text: "Purchase Order Date",
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: CommonTextField(
                  onTap: onTapPurchaseOrderDate,
                  controller: TextEditingController(
                    text: pickedPurchaseOrderDate == null
                        ? 'Select Date'
                        : DateFormat(
                            'yyyy-MM-dd',
                          ).format(pickedPurchaseOrderDate!),
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
                        : DateFormat('yyyy-MM-dd').format(pickedValidityDate!),
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
