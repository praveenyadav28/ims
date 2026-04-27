import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/model/employee_model.dart';
import 'package:ims/ui/sales/performa_invoice/state/performa_bloc.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';
import 'package:searchfield/searchfield.dart';

class PerformaDetailsCard extends StatelessWidget {
  const PerformaDetailsCard({
    super.key,
    required this.prefixController,
    required this.perfromaNoController,
    required this.pickedPerformaDate,
    required this.onTapPerfromaDate,
    required this.transNoController,
    required this.salesPersonController,
    required this.employeeList,
    required this.prefixTransController,
  });

  final TextEditingController prefixController;
  final TextEditingController perfromaNoController;
  final DateTime? pickedPerformaDate;
  final VoidCallback onTapPerfromaDate;
  final TextEditingController salesPersonController;
  final List<EmployeeModel> employeeList;
  final TextEditingController transNoController;
  final TextEditingController prefixTransController;

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
                  onChanged: (value) async {
                    context.read<PerformaBloc>().add(
                      PerformaUpdatePrefix(value),
                    );

                    final currentText = value;

                    Future.delayed(const Duration(milliseconds: 300), () async {
                      // user ne aur type kiya ho to old request ignore
                      if (prefixController.text != currentText) return;

                      final res = await ApiService.postData(
                        'get/nexttranseno',
                        {
                          "trans_type": "Proforma",
                          "prefix": currentText.trim(),
                        },
                        licenceNo: Preference.getint(PrefKeys.licenseNo),
                      );

                      // latest text hi chale
                      if (prefixController.text != currentText) return;

                      if (res != null && res['status'] == true) {
                        final newNo = res['next_no'].toString();

                        perfromaNoController.value = TextEditingValue(
                          text: newNo,
                          selection: TextSelection.collapsed(
                            offset: newNo.length,
                          ),
                        );

                        context.read<PerformaBloc>().add(
                          PerformaUpdatePerformaNo(newNo),
                        );
                      } else {
                        perfromaNoController.clear();
                      }
                    });
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: perfromaNoController,
                  hintText: 'Performa No',
                  onChanged: (value) {
                    context.read<PerformaBloc>().add(
                      PerformaUpdatePerformaNo(value),
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

        SizedBox(height: Sizes.height * .02),
        nameField(
          text: "Estimate No",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixTransController,
                  hintText: 'Prefix',
                  onChanged: (v) {
                    context.read<PerformaBloc>().add(PerformaSetTransPrefix(v));
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: transNoController,
                  hintText: 'Number',
                  suffixIcon: IconButton(
                    onPressed: () {
                      final bloc = context.read<PerformaBloc>();
                      bloc.add(PerformaSearchTransaction());
                    },
                    icon: Icon(Icons.search),
                  ),
                  onChanged: (v) {
                    context.read<PerformaBloc>().add(PerformaSetTransNo(v));
                  },
                  onFieldSubmitted: (v) {
                    context.read<PerformaBloc>().add(
                      PerformaSearchTransaction(),
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
          text: "Sales Person",
          child: Row(
            children: [
              Expanded(
                child: CommonSearchableDropdownField<EmployeeModel>(
                  controller: salesPersonController,
                  hintText: "Select Sales Person",

                  suggestions: employeeList.map((e) {
                    return SearchFieldListItem<EmployeeModel>(
                      "${e.firstName} ${e.lastName}", // 👈 name show
                      item: e, // 👈 full object store
                    );
                  }).toList(),

                  onSuggestionTap: (value) {
                    final emp = value.item!; // 👈 full employee

                    salesPersonController.text =
                        "${emp.firstName} ${emp.lastName}";

                    // 👇 name
                    context.read<PerformaBloc>().add(
                      PerformaSelectSalesPerson(
                        "${emp.firstName} ${emp.lastName}",
                      ),
                    );

                    // 👇 ID
                    context.read<PerformaBloc>().add(
                      PerformaSelectSalesPersonId(emp.id),
                    );
                  },
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
