import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/sale_invoice/state/invoice_bloc.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class SaleInvoiceDetailsCard extends StatelessWidget {
  const SaleInvoiceDetailsCard({
    super.key,
    required this.prefixController,
    required this.invoiceNoController,
    required this.pickedInvoiceDate,
    required this.onTapInvoiceDate,
  });

  final TextEditingController prefixController;
  final TextEditingController invoiceNoController;
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
                  onChanged: (value) {
                    SaleInvoiceBloc bloc = context.read<SaleInvoiceBloc>();
                    bloc.emit(
                      bloc.state.copyWith(
                        saleInvoiceNo: invoiceNoController.text,
                      ),
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
                    SaleInvoiceBloc bloc = context.read<SaleInvoiceBloc>();
                    bloc.emit(
                      bloc.state.copyWith(
                        saleInvoiceNo: invoiceNoController.text,
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
          text: "Invoice Date",
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
          flix: 30,
        ),
        SizedBox(height: Sizes.height * .03),

        nameField(
          text: "Transaction No",
          child: CommonTextField(
            hintText: 'Number',
            suffixIcon: IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                final bloc = context.read<SaleInvoiceBloc>();
                bloc.add(SaleInvoiceSearchTransaction());
              },
            ),
            onChanged: (v) {
              context.read<SaleInvoiceBloc>().add(SaleInvoiceSetTransNo(v));
            },
          ),
          flix: 30,
        ),
        SizedBox(height: Sizes.height * .03),
      ],
    );
  }
}
