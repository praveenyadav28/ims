import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/ui/purchase/purchase_return/state/purchase_return_bloc.dart';
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
  });

  final TextEditingController prefixController;
  final TextEditingController purchaseReturnNoController;
  final DateTime? pickedPurchaseReturnDate;
  final VoidCallback onTapPurchaseReturnDate;

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
                  onChanged: (value) {
                    PurchaseReturnBloc bloc = context
                        .read<PurchaseReturnBloc>();
                    bloc.emit(
                      bloc.state.copyWith(
                        purchaseReturnNo: purchaseReturnNoController.text,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: purchaseReturnNoController,
                  hintText: 'P Return No',
                  onChanged: (value) {
                    PurchaseReturnBloc bloc = context
                        .read<PurchaseReturnBloc>();
                    bloc.emit(
                      bloc.state.copyWith(
                        purchaseReturnNo: purchaseReturnNoController.text,
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
        SizedBox(height: Sizes.height * .03),
        nameField(
          text: "Purchase Invoice No",
          child: CommonTextField(
            hintText: 'Number',
            suffixIcon: IconButton(
              onPressed: () {
                final bloc = context.read<PurchaseReturnBloc>();
                bloc.add(PurchaseReturnSearchTransaction());
              },
              icon: Icon(Icons.search),
            ),
            onChanged: (v) {
              context.read<PurchaseReturnBloc>().add(PurchaseReturnSetTransNo(v));
            },
          ),

          flix: 30,
        ),
        SizedBox(height: Sizes.height * .03),
      ],
    );
  }
}
