import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/ui/purchase/purchase_invoice/state/p_invoice_bloc.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class PurchaseInvoiceDetailsCard extends StatelessWidget {
  const PurchaseInvoiceDetailsCard({
    super.key,
    required this.prefixController,
    required this.purchaseInvoiceNoController,
    required this.pickedPurchaseInvoiceDate,
    required this.onTapPurchaseInvoiceDate,
    required this.transNoController,
    required this.prefixTransController,
  });

  final TextEditingController prefixController;
  final TextEditingController purchaseInvoiceNoController;
  final DateTime? pickedPurchaseInvoiceDate;
  final VoidCallback onTapPurchaseInvoiceDate;
  final TextEditingController transNoController;
  final TextEditingController prefixTransController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nameField(
          text: "Purchase Invocie No.",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixController,
                  hintText: 'Prefix',
                  onChanged: (value) async {
                    context.read<PurchaseInvoiceBloc>().add(
                      PurchaseInvoiceUpdatePrefix(value),
                    );

                    final currentText = value;

                    Future.delayed(const Duration(milliseconds: 300), () async {
                      // user ne aur type kiya ho to old request ignore
                      if (prefixController.text.trim() != currentText.trim())
                        return;

                      final res = await ApiService.postData(
                        'get/nexttranseno',
                        {
                          "trans_type": "Purchaseinvoice",
                          "prefix": currentText.trim(),
                        },
                        licenceNo: Preference.getint(PrefKeys.licenseNo),
                      );

                      // latest text hi chale
                      if (prefixController.text.trim() != currentText.trim())
                        return;

                      if (res != null && res['status'] == true) {
                        final newNo = res['next_no'].toString();

                        purchaseInvoiceNoController.value = TextEditingValue(
                          text: newNo,
                          selection: TextSelection.collapsed(
                            offset: newNo.length,
                          ),
                        );

                        context.read<PurchaseInvoiceBloc>().add(
                          PurchaseInvoiceUpdateNo(newNo),
                        );
                      } else {
                        purchaseInvoiceNoController.clear();
                      }
                    });
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: purchaseInvoiceNoController,
                  hintText: 'Invoice No',
                  onChanged: (value) {
                    context.read<PurchaseInvoiceBloc>().add(
                      PurchaseInvoiceUpdateNo(value),
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
          text: "Purchase Invoice Date",
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: CommonTextField(
                  onTap: onTapPurchaseInvoiceDate,
                  controller: TextEditingController(
                    text: pickedPurchaseInvoiceDate == null
                        ? 'Select Date'
                        : DateFormat(
                            'yyyy-MM-dd',
                          ).format(pickedPurchaseInvoiceDate!),
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
          text: "Purchase Order No",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixTransController,
                  hintText: 'Prefix',
                  onChanged: (value) {
                    context.read<PurchaseInvoiceBloc>().add(
                      PurchaseInvoiceSetTransPrefix(value),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: transNoController,
                  hintText: 'Number',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: () {
                      final bloc = context.read<PurchaseInvoiceBloc>();
                      bloc.add(PurchaseInvoiceSearchTransaction());
                    },
                  ),
                  onFieldSubmitted: (v) {
                    final bloc = context.read<PurchaseInvoiceBloc>();
                    bloc.add(PurchaseInvoiceSearchTransaction());
                  },
                  onChanged: (v) {
                    context.read<PurchaseInvoiceBloc>().add(
                      PurchaseInvoiceSetTransNo(v),
                    );
                  },
                ),
              ),
            ],
          ),
          flix: 30,
        ),
        SizedBox(height: Sizes.height * .03),
      ],
    );
  }
}
