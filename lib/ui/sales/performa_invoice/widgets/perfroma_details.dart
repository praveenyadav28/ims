import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/ui/sales/performa_invoice/state/performa_bloc.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class PerformaDetailsCard extends StatelessWidget {
  const PerformaDetailsCard({
    super.key,
    required this.prefixController,
    required this.perfromaNoController,
    required this.pickedPerformaDate,
    required this.onTapPerfromaDate,
  });

  final TextEditingController prefixController;
  final TextEditingController perfromaNoController;
  final DateTime? pickedPerformaDate;
  final VoidCallback onTapPerfromaDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nameField(
          text: "Perfroma Invoice No.",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixController,
                  hintText: 'Prefix',
                  onChanged: (value) {
                    PerformaBloc bloc = context.read<PerformaBloc>();
                    bloc.emit(
                      bloc.state.copyWith(
                        performaNo: perfromaNoController.text,
                      ),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: perfromaNoController,
                  hintText: 'Performa No',
                  onChanged: (value) {
                    PerformaBloc bloc = context.read<PerformaBloc>();
                    bloc.emit(
                      bloc.state.copyWith(
                        performaNo: perfromaNoController.text,
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
          text: "Performa Date",
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: CommonTextField(
                  onTap: onTapPerfromaDate,
                  controller: TextEditingController(
                    text: pickedPerformaDate == null
                        ? 'Select Date'
                        : DateFormat('yyyy-MM-dd').format(pickedPerformaDate!),
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
