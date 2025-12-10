import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/ui/sales/debit_note/state/debitnote_bloc.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class DebitNoteDetailsCard extends StatelessWidget {
  const DebitNoteDetailsCard({
    super.key,
    required this.prefixController,
    required this.noteNoController,
    required this.pickedInvoiceDate,
    required this.onTapInvoiceDate,
  });

  final TextEditingController prefixController;
  final TextEditingController noteNoController;
  final DateTime? pickedInvoiceDate;
  final VoidCallback onTapInvoiceDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nameField(
          text: "Debit Note No.",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixController,
                  hintText: 'Prefix',
                  onChanged: (value) {
                    DebitNoteBloc bloc = context.read<DebitNoteBloc>();
                    bloc.emit(
                      bloc.state.copyWith(debitNoteNo: noteNoController.text),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: noteNoController,
                  hintText: 'Debit Note No',
                  onChanged: (value) {
                    DebitNoteBloc bloc = context.read<DebitNoteBloc>();
                    bloc.emit(
                      bloc.state.copyWith(debitNoteNo: noteNoController.text),
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
          text: "Debit Note Date",
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
      ],
    );
  }
}
