import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ims/model/employee_model.dart';
import 'package:ims/ui/sales/estimate/state/estimate_bloc.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';

class EstimateDetailsCard extends StatelessWidget {
  const EstimateDetailsCard({
    super.key,
    required this.prefixController,
    required this.estimateNoController,
    required this.validForController,
    required this.pickedEstimateDate,
    required this.pickedValidityDate,
    required this.onTapEstimateDate,
    required this.onTapValidityDate,
    required this.onValidForChanged,
    required this.salesPersonController,
    required this.employeeList,
    required this.estimateDateController,
    required this.validityDateController,
  });

  final TextEditingController prefixController;
  final TextEditingController estimateNoController;
  final TextEditingController validForController;
  final TextEditingController salesPersonController;
  final DateTime? pickedEstimateDate;
  final DateTime? pickedValidityDate;
  final VoidCallback onTapEstimateDate;
  final VoidCallback onTapValidityDate;
  final ValueChanged<String> onValidForChanged;
  final List<EmployeeModel> employeeList;
  final TextEditingController estimateDateController;
  final TextEditingController validityDateController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nameField(
          text: "Estimate Invoice No.",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixController,
                  hintText: 'Prefix',
                  onChanged: (value) async {
                    context.read<EstBloc>().add(EstUpdatePrefix(value));

                    final currentText = value;

                    Future.delayed(const Duration(milliseconds: 300), () async {
                      // user ne aur type kiya ho to old request ignore
                      if (prefixController.text != currentText) return;

                      final res = await ApiService.postData(
                        'get/nexttranseno',
                        {
                          "trans_type": "Estimate",
                          "prefix": currentText.trim(),
                        },
                        licenceNo: Preference.getint(PrefKeys.licenseNo),
                      );

                      // latest text hi chale
                      if (prefixController.text != currentText) return;

                      if (res != null && res['status'] == true) {
                        final newNo = res['next_no'].toString();

                        estimateNoController.value = TextEditingValue(
                          text: newNo,
                          selection: TextSelection.collapsed(
                            offset: newNo.length,
                          ),
                        );

                        context.read<EstBloc>().add(EstUpdateEstimateNo(newNo));
                      } else {
                        estimateNoController.clear();
                      }
                    });
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: estimateNoController,
                  hintText: 'Estimate No',
                  onChanged: (value) {
                    context.read<EstBloc>().add(EstUpdateEstimateNo(value));
                  },
                ),
              ),
            ],
          ),
          flix: 30,
        ),

        SizedBox(height: Sizes.height * .02),
        nameField(
          text: "Estimate Date",
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: CommonTextField(
                  onTap: onTapEstimateDate,
                  controller: estimateDateController,
                ),
              ),
              Spacer(flex: 2),
            ],
          ),
          flix: 30,
        ),

        SizedBox(height: Sizes.height * .02),
        nameField(
          text: "Valid For Days",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: validForController,

                  onChanged: onValidForChanged,
                ),
              ),
              SizedBox(width: 20),
              Expanded(
                flex: 3,
                child: CommonTextField(
                  onTap: onTapValidityDate,
                  controller: validityDateController,
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
                    context.read<EstBloc>().add(
                      EstSelectSalesPerson("${emp.firstName} ${emp.lastName}"),
                    );

                    // 👇 ID
                    context.read<EstBloc>().add(EstSelectSalesPersonId(emp.id));
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
