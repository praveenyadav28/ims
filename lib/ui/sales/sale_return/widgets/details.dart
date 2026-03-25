import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/ui/sales/sale_return/state/return_bloc.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class SaleReturnDetailsCard extends StatelessWidget {
  const SaleReturnDetailsCard({
    super.key,
    required this.prefixController,
    required this.invoiceNoController,
    required this.pickedInvoiceDate,
    required this.onTapInvoiceDate,
    required this.transNoController,
    required this.prefixTransController,
  });

  final TextEditingController prefixController;
  final TextEditingController invoiceNoController;
  final DateTime? pickedInvoiceDate;
  final VoidCallback onTapInvoiceDate;
  final TextEditingController transNoController;
  final TextEditingController prefixTransController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nameField(
          text: "Sale Return No.",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixController,
                  hintText: 'Prefix',
                  onChanged: (value) {
                    context.read<SaleReturnBloc>().add(
                      SaleReturnUpdatePrefix(value),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: invoiceNoController,
                  hintText: 'Return No',
                  onChanged: (value) {
                    context.read<SaleReturnBloc>().add(
                      SaleReturnUpdateNo(value),
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
          text: "Return Date",
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: CommonTextField(
                  onTap: onTapInvoiceDate,
                  controller: TextEditingController(
                    text: pickedInvoiceDate == null
                        ? 'Select Date'
                        : DateFormat('yyyy-MM-dd').format(pickedInvoiceDate!),
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
          text: "Sale Invoice No",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixTransController,
                  hintText: 'Prefix',
                  onChanged: (v) {
                    context.read<SaleReturnBloc>().add(
                      SaleReturnSetTransPrefix(v),
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
                        final bloc = context.read<SaleReturnBloc>();
                        bloc.add(SaleReturnSearchTransaction());
                      },
                      onChanged: (v) {
                        context.read<SaleReturnBloc>().add(
                          SaleReturnSetTransNo(v),
                        );
                      },
                    ),
                    IconButton(
                      onPressed: () {
                        final bloc = context.read<SaleReturnBloc>();
                        bloc.add(SaleReturnSearchTransaction());
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
        SizedBox(height: Sizes.height * .03),
      ],
    );
  }
}
