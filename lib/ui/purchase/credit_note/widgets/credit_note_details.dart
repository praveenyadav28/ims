import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/ui/purchase/credit_note/state/credit_note_bloc.dart';
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
  });

  final TextEditingController prefixController;
  final TextEditingController creditNoteNoController;
  final DateTime? pickedCreditNoteDate;
  final VoidCallback onTapCreditNoteDate;

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
                    CreditNoteBloc bloc = context
                        .read<CreditNoteBloc>();
                    bloc.emit(
                      bloc.state.copyWith(
                        creditNoteNo: creditNoteNoController.text,
                      ),
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
                    CreditNoteBloc bloc = context
                        .read<CreditNoteBloc>();
                    bloc.emit(
                      bloc.state.copyWith(
                        creditNoteNo: creditNoteNoController.text,
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
      ],
    );
  }
}
