import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/estimate/models/estimate_models.dart';
import 'package:ims/ui/sales/estimate/state/estimate_bloc.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';

class BillToCard extends StatelessWidget {
  const BillToCard({
    super.key,
    required this.state,
    required this.bloc,
    required this.cusNameController,
    required this.cashMobileController,
    required this.cashBillingController,
    required this.cashShippingController,
    required this.onCreateCustomer,
  });

  final EstState state;
  final EstBloc bloc;
  final TextEditingController cusNameController;
  final TextEditingController cashMobileController;
  final TextEditingController cashBillingController;
  final TextEditingController cashShippingController;
  final VoidCallback onCreateCustomer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bill To',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColor.textColor,
              ),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.primary,
                side: BorderSide(color: AppColor.primary, width: 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              onPressed: () {
                if (!state.cashSaleDefault) {
                  bloc.add(EstToggleCashSale(true));
                } else {
                  cusNameController.clear();
                  cashMobileController.clear();
                  cashBillingController.clear();
                  cashShippingController.clear();
                  bloc.add(EstToggleCashSale(false));
                }
              },
              child: Text(
                state.cashSaleDefault
                    ? 'Disable Cash Sale'
                    : 'Set Cash Sale as default',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: Sizes.height * .05),
        if (state.cashSaleDefault)
          _CashSaleFields(
            cusNameController: cusNameController,
            cashMobileController: cashMobileController,
            onChangeParty: () {
              cusNameController.clear();
              cashMobileController.clear();
              cashBillingController.clear();
              cashShippingController.clear();
              bloc.add(EstToggleCashSale(false));
            },
          )
        else
          _CustomerDropdown(
            state: state,
            bloc: bloc,
            onCreateCustomer: onCreateCustomer,
            mobileController: cashMobileController,
          ),
      ],
    );
  }
}

class _CashSaleFields extends StatelessWidget {
  const _CashSaleFields({
    required this.cusNameController,
    required this.cashMobileController,
    required this.onChangeParty,
  });

  final TextEditingController cusNameController;
  final TextEditingController cashMobileController;
  final VoidCallback onChangeParty;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cash Sale',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColor.textColor,
          ),
        ),
        SizedBox(height: Sizes.height * .02),
        CommonTextField(
          hintText: 'Customer Name',
          controller: cusNameController,
        ),
        SizedBox(height: Sizes.height * .02),
        CommonTextField(hintText: 'Mobile', controller: cashMobileController),
      ],
    );
  }
}

class _CustomerDropdown extends StatelessWidget {
  const _CustomerDropdown({
    required this.state,
    required this.bloc,
    required this.onCreateCustomer,
    required this.mobileController,
  });

  final EstState state;
  final EstBloc bloc;
  final VoidCallback onCreateCustomer;
  final TextEditingController mobileController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ---------------- SEARCH FIELD ----------------
        SearchField<CustomerModel>(
          key: ValueKey(state.selectedCustomer?.id),

          selectedValue: state.selectedCustomer != null
              ? SearchFieldListItem<CustomerModel>(
                  state.selectedCustomer!.name,
                  item: state.selectedCustomer!,
                )
              : null,

          suggestions: state.customers
              .map((c) => SearchFieldListItem<CustomerModel>(c.name, item: c))
              .toList(),

          suggestionState: Suggestion.expand,

          hint: 'Select Customer',

          onSuggestionTap: (item) {
            final c = item.item;

            // FILL MOBILE TEXTFIELD
            mobileController.text = c?.mobile ?? "";

            // UPDATE STATE
            bloc.add(EstSelectCustomer(c));

            (context as Element).markNeedsBuild();
          },

          searchInputDecoration: SearchInputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            labelText: "Select Party",
            labelStyle: GoogleFonts.inter(
              color: const Color(0xFF565D6D),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Color(0xFFDEE1E6)),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Color(0xFFDEE1E6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Color(0xFFDEE1E6)),
            ),
          ),

          suggestionStyle: GoogleFonts.inter(
            color: const Color(0xFF565D6D),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        SizedBox(height: Sizes.height * .02),

        // ---------------- MOBILE TEXTFIELD (AUTO FILL) ----------------
        CommonTextField(controller: mobileController, hintText: "Mobile"),

        SizedBox(height: Sizes.height * .02),

        // ---------------- NEW BUTTON ----------------
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColor.primary,
              side: BorderSide(color: AppColor.primary, width: 1),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            onPressed: onCreateCustomer,
            child: Text(
              'New',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
