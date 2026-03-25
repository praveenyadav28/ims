import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/dilivery_chalan/state/dilivery_bloc.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class DiliveryChallanDetailsCard extends StatelessWidget {
  const DiliveryChallanDetailsCard({
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
          text: "Dilivery Challan No.",
          child: Row(
            children: [
              Expanded(
                child: CommonTextField(
                  controller: prefixController,
                  hintText: 'Prefix',
                  onChanged: (value) {
                    context.read<DiliveryChallanBloc>().add(
                      DiliveryChallanUpdatePrefix(value),
                    );
                  },
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: CommonTextField(
                  controller: invoiceNoController,
                  hintText: 'Invoice No',
                  onChanged: (value) {
                    context.read<DiliveryChallanBloc>().add(
                      DiliveryChallanUpdateNo(value),
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
          text: "Challan Date",
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
          text: "Transaction Type",
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
          flix: 30,
        ),
        SizedBox(height: Sizes.height * .03),

        nameField(
          text: "Transaction No",
          child: Row(
            children: [
              Expanded(
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

          flix: 30,
        ),
        SizedBox(height: Sizes.height * .03),
      ],
    );
  }
}
