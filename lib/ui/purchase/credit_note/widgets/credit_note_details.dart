import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/ui/purchase/credit_note/state/credit_note_bloc.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class CreditNoteDetailsCard extends StatelessWidget {
  const CreditNoteDetailsCard({
    super.key,
    required this.prefixController,
    required this.creditNoteNoController,
    required this.pickedCreditNoteDate,
    required this.onTapCreditNoteDate,
    required this.transNoController,
    required this.prefixTransController,
  });

  final TextEditingController prefixController;
  final TextEditingController creditNoteNoController;
  final DateTime? pickedCreditNoteDate;
  final VoidCallback onTapCreditNoteDate;
  final TextEditingController transNoController;
  final TextEditingController prefixTransController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nameField(
          text: "Credit Note No.",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixController,
                  hintText: 'Prefix',
                  onChanged: (value) {
                    context.read<CreditNoteBloc>().add(
                      CreditNoteUpdatePrefix(value),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: creditNoteNoController,
                  hintText: 'Credit Note No',
                  onChanged: (value) {
                    context.read<CreditNoteBloc>().add(
                      CreditNoteUpdateEstimateNo(value),
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
          text: "Credit Note Date",
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: CommonTextField(
                  onTap: onTapCreditNoteDate,
                  controller: TextEditingController(
                    text: pickedCreditNoteDate == null
                        ? 'Select Date'
                        : DateFormat(
                            'yyyy-MM-dd',
                          ).format(pickedCreditNoteDate!),
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
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixTransController,
                  hintText: 'Prefix',
                  onChanged: (v) {
                    context.read<CreditNoteBloc>().add(
                      CreditNoteSetTransPrefix(v),
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
                        final bloc = context.read<CreditNoteBloc>();
                        bloc.add(CreditNoteSearchTransaction());
                      },
                      onChanged: (v) {
                        context.read<CreditNoteBloc>().add(
                          CreditNoteSetTransNo(v),
                        );
                      },
                    ),
                    IconButton(
                      onPressed: () {
                        final bloc = context.read<CreditNoteBloc>();
                        bloc.add(CreditNoteSearchTransaction());
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
