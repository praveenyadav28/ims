import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/employee_model.dart';
import 'package:ims/ui/sales/dilivery_chalan/state/dilivery_bloc.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';
import 'package:searchfield/searchfield.dart';

class DiliveryChallanDetailsCard extends StatelessWidget {
  const DiliveryChallanDetailsCard({
    super.key,
    required this.prefixController,
    required this.invoiceNoController,
    required this.pickedInvoiceDate,
    required this.onTapInvoiceDate,
    required this.transNoController,
    required this.salesPersonController,
    required this.employeeList,
    required this.prefixTransController,
  });

  final TextEditingController prefixController;
  final TextEditingController invoiceNoController;
  final DateTime? pickedInvoiceDate;
  final VoidCallback onTapInvoiceDate;
  final TextEditingController transNoController;
  final TextEditingController salesPersonController;
  final List<EmployeeModel> employeeList;
  final TextEditingController prefixTransController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nameField(
          text: "Dilivery Challan",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixController,
                  hintText: 'Prefix',
                  onChanged: (value) async {
                    context.read<DiliveryChallanBloc>().add(
                      DiliveryChallanUpdatePrefix(value),
                    );

                    final currentText = value;

                    Future.delayed(const Duration(milliseconds: 300), () async {
                      // user ne aur type kiya ho to old request ignore
                      if (prefixController.text.trim() != currentText.trim())
                        return;

                      final res = await ApiService.postData(
                        'get/nexttranseno',
                        {"trans_type": "Dilvery", "prefix": currentText.trim()},
                        licenceNo: Preference.getint(PrefKeys.licenseNo),
                      );

                      // latest text hi chale
                      if (prefixController.text.trim() != currentText.trim())
                        return;

                      if (res != null && res['status'] == true) {
                        final newNo = res['next_no'].toString();

                        invoiceNoController.value = TextEditingValue(
                          text: newNo,
                          selection: TextSelection.collapsed(
                            offset: newNo.length,
                          ),
                        );

                        context.read<DiliveryChallanBloc>().add(
                          DiliveryChallanUpdateNo(newNo),
                        );
                      } else {
                        invoiceNoController.clear();
                      }
                    });
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: invoiceNoController,
                  hintText: 'Challan No',
                  onChanged: (value) {
                    context.read<DiliveryChallanBloc>().add(
                      DiliveryChallanUpdateNo(value),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  onTap: onTapInvoiceDate,
                  readOnly: true,
                  hintText: 'Select Date',
                  controller: TextEditingController(
                    text: pickedInvoiceDate == null
                        ? 'Select Date'
                        : DateFormat('yyyy-MM-dd').format(pickedInvoiceDate!),
                  ),
                ),
              ),
            ],
          ),
          flix: 15,
        ),
        SizedBox(height: Sizes.height * .02),
        nameField(
          text: "Transaction Type",
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: CommonDropdownField<String>(
                  hintText: "Select Type",
                  items: [
                    DropdownMenuItem(
                      value: "Estimate",
                      child: Text(
                        "Estimate",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF565D6D),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    DropdownMenuItem(
                      value: "Proforma",
                      child: Text(
                        "Performa Invoice",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF565D6D),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    context.read<DiliveryChallanBloc>().add(
                      DiliveryChallanSetTransType(v ?? "Estimate"),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: CommonTextField(
                  controller: prefixTransController,
                  hintText: 'Prefix',
                  onChanged: (v) {
                    context.read<DiliveryChallanBloc>().add(
                      DiliveryChallanSetTransPrefix(v),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                flex: 3,
                child: CommonTextField(
                  controller: transNoController,
                  hintText: 'Number',
                  suffixIcon: IconButton(
                    onPressed: () {
                      final bloc = context.read<DiliveryChallanBloc>();
                      bloc.add(DiliveryChallanSearchTransaction());
                    },
                    icon: Icon(Icons.search),
                  ),
                  onChanged: (v) {
                    context.read<DiliveryChallanBloc>().add(
                      DiliveryChallanSetTransNo(v),
                    );
                  },
                  onFieldSubmitted: (v) {
                    context.read<DiliveryChallanBloc>().add(
                      DiliveryChallanSearchTransaction(),
                    );
                  },
                ),
              ),
            ],
          ),

          flix: 15,
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
                    context.read<DiliveryChallanBloc>().add(
                      DiliveryChallanSelectSalesPerson(
                        "${emp.firstName} ${emp.lastName}",
                      ),
                    );

                    // 👇 ID
                    context.read<DiliveryChallanBloc>().add(
                      DiliveryChallanSelectSalesPersonId(emp.id),
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
