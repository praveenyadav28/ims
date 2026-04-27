import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/ui/purchase/purchase_return/state/purchase_return_bloc.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class PurchaseReturnDetailsCard extends StatelessWidget {
  const PurchaseReturnDetailsCard({
    super.key,
    required this.prefixController,
    required this.purchaseReturnNoController,
    required this.pickedPurchaseReturnDate,
    required this.onTapPurchaseReturnDate,
    required this.transNoController,
    required this.prefixTransController,
  });

  final TextEditingController prefixController;
  final TextEditingController purchaseReturnNoController;
  final DateTime? pickedPurchaseReturnDate;
  final VoidCallback onTapPurchaseReturnDate;
  final TextEditingController transNoController;
  final TextEditingController prefixTransController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nameField(
          text: "Purchase Return No.",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixController,
                  hintText: 'Prefix',
                  onChanged: (value) async {
                    context.read<PurchaseReturnBloc>().add(
                      PurchaseReturnUpdatePrefix(value),
                    );

                    final currentText = value;

                    Future.delayed(const Duration(milliseconds: 300), () async {
                      // user ne aur type kiya ho to old request ignore
                      if (prefixController.text.trim() != currentText.trim())
                        return;

                      final res = await ApiService.postData(
                        'get/nexttranseno',
                        {
                          "trans_type": "Purchasereturn",
                          "prefix": currentText.trim(),
                        },
                        licenceNo: Preference.getint(PrefKeys.licenseNo),
                      );

                      // latest text hi chale
                      if (prefixController.text.trim() != currentText.trim())
                        return;

                      if (res != null && res['status'] == true) {
                        final newNo = res['next_no'].toString();

                        purchaseReturnNoController.value = TextEditingValue(
                          text: newNo,
                          selection: TextSelection.collapsed(
                            offset: newNo.length,
                          ),
                        );

                        context.read<PurchaseReturnBloc>().add(
                          PurchaseReturnUpdateNo(newNo),
                        );
                      } else {
                        purchaseReturnNoController.clear();
                      }
                    });
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: purchaseReturnNoController,
                  hintText: 'P Return No',
                  onChanged: (value) {
                    context.read<PurchaseReturnBloc>().add(
                      PurchaseReturnUpdateNo(value),
                    );
                  },
                ),
              ),
            ],
          ),
          flix: 30,
        ),

        SizedBox(height: Sizes.height * .02),
        nameField(
          text: "Purchase Return Date",
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: CommonTextField(
                  onTap: onTapPurchaseReturnDate,
                  controller: TextEditingController(
                    text: pickedPurchaseReturnDate == null
                        ? 'Select Date'
                        : DateFormat(
                            'yyyy-MM-dd',
                          ).format(pickedPurchaseReturnDate!),
                  ),
                ),
              ),
              Spacer(flex: 2),
            ],
          ),
          flix: 30,
        ),
        SizedBox(height: Sizes.height * .02),
        nameField(
          text: "Purchase Invoice No",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixTransController,
                  hintText: 'Prefix',
                  onChanged: (v) {
                    context.read<PurchaseReturnBloc>().add(
                      PurchaseReturnSetTransPrefix(v),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    CommonTextField(
                      controller: transNoController,
                      hintText: 'Number',
                      onFieldSubmitted: (v) {
                        final bloc = context.read<PurchaseReturnBloc>();
                        bloc.add(PurchaseReturnSearchTransaction());
                      },
                      onChanged: (v) {
                        context.read<PurchaseReturnBloc>().add(
                          PurchaseReturnSetTransNo(v),
                        );
                      },
                    ),
                    IconButton(
                      onPressed: () {
                        final bloc = context.read<PurchaseReturnBloc>();
                        bloc.add(PurchaseReturnSearchTransaction());
                      },
                      icon: Icon(Icons.search, color: AppColor.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          flix: 30,
        ),
      ],
    );
  }
}
