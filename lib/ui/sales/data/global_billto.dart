import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';

class GlobalBillToCard extends StatelessWidget {
  const GlobalBillToCard({
    super.key,
    required this.isCashSale,
    required this.customers,
    required this.selectedCustomer,
    required this.cusNameController,
    required this.mobileController,
    required this.billingController,
    required this.shippingController,

    required this.onToggleCashSale,
    required this.onCustomerSelected,
    required this.onCreateCustomer,
    required this.ispurchase,
  });

  /// DATA
  final bool isCashSale;
  final List<LedgerModelDrop> customers;
  final LedgerModelDrop? selectedCustomer;

  /// CONTROLLERS
  final TextEditingController cusNameController;
  final TextEditingController mobileController;
  final TextEditingController billingController;
  final TextEditingController shippingController;

  /// CALLBACKS
  final VoidCallback onToggleCashSale;
  final Function(LedgerModelDrop customer) onCustomerSelected;
  final VoidCallback onCreateCustomer;
  final bool ispurchase;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        SizedBox(height: Sizes.height * .05),

        /// SHOW CASH SALE FIELDS
        if (isCashSale)
          _CashSaleFields(
            cusNameController: cusNameController,
            cashMobileController: mobileController,
            onDisableCashSale: () {
              cusNameController.clear();
              mobileController.clear();
              billingController.clear();
              shippingController.clear();
              onToggleCashSale();
            },
          )
        /// SHOW CUSTOMER DROPDOWN
        else
          _CustomerDropdown(
            customers: customers,
            selectedCustomer: selectedCustomer,
            onCreateCustomer: onCreateCustomer,
            onSelectCustomer: (c) {
              mobileController.text = c.mobile;
              billingController.text = c.billingAddress;
              shippingController.text = c.shippingAddress;
              onCustomerSelected(c);
            },
          ),
      ],
    );
  }

  Widget _header() {
    return Row(
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
        ispurchase
            ? Container()
            : OutlinedButton(
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
                onPressed: onToggleCashSale,
                child: Text(
                  isCashSale ? 'Disable Cash Sale' : 'Set Cash Sale as default',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
      ],
    );
  }
}

class _CashSaleFields extends StatelessWidget {
  const _CashSaleFields({
    required this.cusNameController,
    required this.cashMobileController,
    required this.onDisableCashSale,
  });

  final TextEditingController cusNameController;
  final TextEditingController cashMobileController;
  final VoidCallback onDisableCashSale;

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
    required this.customers,
    required this.selectedCustomer,
    required this.onCreateCustomer,
    required this.onSelectCustomer,
  });

  final List<LedgerModelDrop> customers;
  final LedgerModelDrop? selectedCustomer;

  final VoidCallback onCreateCustomer;
  final Function(LedgerModelDrop customer) onSelectCustomer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SearchField<LedgerModelDrop>(
          key: ValueKey(selectedCustomer?.id),

          selectedValue: selectedCustomer != null
              ? SearchFieldListItem<LedgerModelDrop>(
                  selectedCustomer!.name,
                  item: selectedCustomer!,
                )
              : null,

          suggestions: customers
              .map((c) => SearchFieldListItem<LedgerModelDrop>(c.name, item: c))
              .toList(),

          suggestionState: Suggestion.expand,

          hint: 'Select Customer',

          onSuggestionTap: (item) {
            if (item.item != null) {
              onSelectCustomer(item.item!);
              (context as Element).markNeedsBuild();
            }
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
              color: Color(0xFF565D6D),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: Color(0xFFDEE1E6)),
            ),
          ),

          suggestionStyle: GoogleFonts.inter(
            color: Color(0xFF565D6D),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),

        SizedBox(height: Sizes.height * .02),

        CommonTextField(
          controller: TextEditingController(
            text: selectedCustomer?.mobile ?? "",
          ),
          hintText: "Mobile",
        ),

        SizedBox(height: Sizes.height * .02),

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
