import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/employee_model.dart';
import 'package:ims/ui/sales/sale_invoice/state/invoice_bloc.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';
import 'package:searchfield/searchfield.dart';

class SaleInvoiceDetailsCard extends StatelessWidget {
  const SaleInvoiceDetailsCard({
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
  final TextEditingController transNoController;
  final TextEditingController prefixTransController;
  final TextEditingController salesPersonController;
  final List<EmployeeModel> employeeList;
  final DateTime? pickedInvoiceDate;
  final VoidCallback onTapInvoiceDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        nameField(
          text: "Sale Invoice No.",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixController,
                  hintText: 'Prefix',
                  onChanged: (value) async {
                    context.read<SaleInvoiceBloc>().add(
                      SaleInvoiceUpdatePrefix(value),
                    );

                    final currentText = value;

                    Future.delayed(const Duration(milliseconds: 300), () async {
                      // agar user ne aur type kar diya ho to old request cancel
                      if (prefixController.text != currentText) return;

                      final res = await ApiService.postData(
                        'get/nexttranseno',
                        {"trans_type": "Invoice", "prefix": currentText.trim()},
                        licenceNo: Preference.getint(PrefKeys.licenseNo),
                      );

                      // response ke time bhi latest text check
                      if (prefixController.text != currentText) return;

                      if (res != null && res['status'] == true) {
                        final newNo = res['next_no'].toString();

                        invoiceNoController.value = TextEditingValue(
                          text: newNo,
                          selection: TextSelection.collapsed(
                            offset: newNo.length,
                          ),
                        );

                        context.read<SaleInvoiceBloc>().add(
                          SaleInvoiceUpdateInvoiceNo(newNo),
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
                  hintText: 'Invoice No',
                  onChanged: (value) {
                    context.read<SaleInvoiceBloc>().add(
                      SaleInvoiceUpdateInvoiceNo(value),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  onTap: onTapInvoiceDate,
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

        SizedBox(height: Sizes.height * .03),

        nameField(
          text: "Select Transaction",
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: CommonDropdownField<String>(
                  value: context.select(
                    (SaleInvoiceBloc bloc) => bloc.state.transType,
                  ),
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
                    DropdownMenuItem(
                      value: "Dilvery",
                      child: Text(
                        "Delivery Challan",
                        style: GoogleFonts.inter(
                          color: const Color(0xFF565D6D),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) {
                    context.read<SaleInvoiceBloc>().add(
                      SaleInvoiceSetTransType(v ?? "Estimate"),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: CommonTextField(
                  controller: prefixTransController,
                  hintText: 'Prefix',
                  onChanged: (value) {
                    context.read<SaleInvoiceBloc>().add(
                      SaleInvoiceSetTransPrefix(value),
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
                    icon: Icon(Icons.search),
                    onPressed: () {
                      final bloc = context.read<SaleInvoiceBloc>();
                      bloc.add(SaleInvoiceSearchTransaction());
                    },
                  ),
                  onFieldSubmitted: (v) {
                    final bloc = context.read<SaleInvoiceBloc>();
                    bloc.add(SaleInvoiceSearchTransaction());
                  },
                  onChanged: (v) {
                    context.read<SaleInvoiceBloc>().add(
                      SaleInvoiceSetTransNo(v),
                    );
                  },
                ),
              ),
            ],
          ),
          flix: 15,
        ),

        SizedBox(height: Sizes.height * .03),
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

                    context.read<SaleInvoiceBloc>().add(
                      SaleInvoiceSelectSalesPerson(
                        "${emp.firstName} ${emp.lastName}",
                      ),
                    );

                    // 👇 ID
                    context.read<SaleInvoiceBloc>().add(
                      SaleInvoiceSelectSalesPersonId(emp.id),
                    );
                  },
                ),
              ),
            ],
          ),
          flix: 15,
        ),
      ],
    );
  }
}
