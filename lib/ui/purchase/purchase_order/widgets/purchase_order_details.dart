import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/purchase/purchase_order/state/purchase_order_bloc.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
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
                  onChanged: (value) async {
                    context.read<PurchaseOrderBloc>().add(
                      PurchaseOrderUpdatePrefix(value),
                    );

                    final currentText = value;

                    Future.delayed(const Duration(milliseconds: 300), () async {
                      // user ne aur type kiya ho to old request ignore
                      if (prefixController.text.trim() != currentText.trim())
                        return;

                      final res = await ApiService.postData(
                        'get/nexttranseno',
                        {
                          "trans_type": "Purchaseoder",
                          "prefix": currentText.trim(),
                        },
                        licenceNo: Preference.getint(PrefKeys.licenseNo),
                      );

                      // latest text hi chale
                      if (prefixController.text.trim() != currentText.trim())
                        return;

                      if (res != null && res['status'] == true) {
                        final newNo = res['next_no'].toString();

                        purchaseOrderNoController.value = TextEditingValue(
                          text: newNo,
                          selection: TextSelection.collapsed(
                            offset: newNo.length,
                          ),
                        );

                        context.read<PurchaseOrderBloc>().add(
                          PurchaseOrderUpdateNo(newNo),
                        );
                      } else {
                        purchaseOrderNoController.clear();
                      }
                    });
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: purchaseOrderNoController,
                  hintText: 'Order No',
                  onChanged: (value) {
                    context.read<PurchaseOrderBloc>().add(
                      PurchaseOrderUpdateNo(value),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
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
            ],
          ),
          flix: 15,
        ),

        SizedBox(height: Sizes.height * .02),
        nameField(
          text: "Vaild For",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: validForController,

                  onChanged: onValidForChanged,
                  suffixIcon: Container(
                    width: 60,
                    alignment: Alignment.centerRight,
                    child: Text("Days  "),
                  ),
                ),
              ),

              SizedBox(width: 10),
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
            ],
          ),
          flix: 15,
        ),
      ],
    );
  }
}
