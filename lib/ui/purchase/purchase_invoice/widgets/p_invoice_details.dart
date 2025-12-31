import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/ui/purchase/purchase_invoice/state/p_invoice_bloc.dart';
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
  });

  final TextEditingController prefixController;
  final TextEditingController purchaseInvoiceNoController;
  final DateTime? pickedPurchaseInvoiceDate;
  final VoidCallback onTapPurchaseInvoiceDate;

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
                  onChanged: (value) {
                    PurchaseInvoiceBloc bloc = context
                        .read<PurchaseInvoiceBloc>();
                    bloc.emit(
                      bloc.state.copyWith(
                        purchaseInvoiceNo: purchaseInvoiceNoController.text,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: purchaseInvoiceNoController,
                  hintText: 'Invoice No',
                  onChanged: (value) {
                    PurchaseInvoiceBloc bloc = context
                        .read<PurchaseInvoiceBloc>();
                    bloc.emit(
                      bloc.state.copyWith(
                        purchaseInvoiceNo: purchaseInvoiceNoController.text,
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
          child: CommonTextField(
            hintText: 'Number', suffixIcon: IconButton(
              onPressed: () {
                final bloc = context.read<PurchaseInvoiceBloc>();
                bloc.add(PurchaseInvoiceSearchTransaction());
              },
              icon: Icon(Icons.search),
            ),
            onChanged: (v) {
              context.read<PurchaseInvoiceBloc>().add(PurchaseInvoiceSetTransNo(v));
            },
          ),

          flix: 30,
        ),
        SizedBox(height: Sizes.height * .03),
      ],
    );
  }
}
