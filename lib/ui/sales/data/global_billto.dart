// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/sales/models/global_models.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';

class GlobalBillToCard extends StatefulWidget {
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
    this.isReturn,
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
  final bool? isReturn;

  @override
  State<GlobalBillToCard> createState() => _GlobalBillToCardState();
}

class _GlobalBillToCardState extends State<GlobalBillToCard> {
  bool _autoFilled = false;

  LedgerModelDrop? getCashSaleCustomer() {
    try {
      return widget.customers.firstWhere(
        (e) => e.name.toLowerCase() == "cash sale",
      );
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cashCustomer = getCashSaleCustomer();
    if (widget.isCashSale &&
        cashCustomer != null &&
        !_autoFilled &&
        widget.mobileController.text.isEmpty) {
      _autoFilled = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onCustomerSelected(cashCustomer);
        widget.mobileController.text = cashCustomer.mobile;
        widget.billingController.text = cashCustomer.billingAddress;
        widget.shippingController.text = cashCustomer.shippingAddress;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(),
        SizedBox(height: Sizes.height * .02),
        if (widget.isCashSale && getCashSaleCustomer() == null)
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.red),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Cash Sale ledger not found. Please create ledger with name 'Cash Sale'",
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

        /// SHOW CASH SALE FIELDS
        if (widget.isCashSale)
          _CashSaleFields(
            cusNameController: widget.cusNameController,
            cashMobileController: widget.mobileController,
            onDisableCashSale: () {
              widget.cusNameController.clear();
              widget.mobileController.clear();
              widget.billingController.clear();
              widget.shippingController.clear();

              _autoFilled = false; // 🔥 VERY IMPORTANT
              widget.onToggleCashSale();
            },
          )
        /// SHOW CUSTOMER DROPDOWN
        else
          _CustomerDropdown(
            customers: widget.customers,
            selectedCustomer: widget.selectedCustomer,
            onCreateCustomer: widget.onCreateCustomer,
            onSelectCustomer: (c) {
              widget.mobileController.text = c.mobile;
              widget.billingController.text = c.billingAddress;
              widget.shippingController.text = c.shippingAddress;
              widget.onCustomerSelected(c);
            },
            isReturn: widget.isReturn ?? true,
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
        widget.ispurchase
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
                onPressed: widget.onToggleCashSale,
                child: Text(
                  widget.isCashSale ? 'Disable Cash Sale' : '  Set Cash Sale  ',
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
  _CustomerDropdown({
    required this.customers,
    required this.selectedCustomer,
    required this.onCreateCustomer,
    required this.onSelectCustomer,
    required this.isReturn,
  });

  final List<LedgerModelDrop> customers;
  final LedgerModelDrop? selectedCustomer;

  final VoidCallback onCreateCustomer;
  final Function(LedgerModelDrop customer) onSelectCustomer;
  bool isReturn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AbsorbPointer(
          absorbing: !(isReturn), // 👈 disable touch only
          child: SearchField<LedgerModelDrop>(
            key: ValueKey(selectedCustomer?.id),
            readOnly: !(isReturn),

            selectedValue: selectedCustomer != null
                ? SearchFieldListItem(
                    selectedCustomer!.name,
                    item: selectedCustomer!,
                    child: _customerTile(selectedCustomer!),
                  )
                : null,

            suggestions: customers.map((c) {
              return SearchFieldListItem(
                c.name,
                item: c,
                child: _customerTile(c),
              );
            }).toList(),

            hint: 'Select Party',

            onSuggestionTap: (item) {
              if (item.item != null) {
                onSelectCustomer(item.item!);
              }
            },
            searchInputDecoration: SearchInputDecoration(
              isDense: true,
              filled: true,
              hintStyle: GoogleFonts.inter(
                color: const Color(0xFF565D6D),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              fillColor: AppColor.white,
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
                borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: Color(0xFFDEE1E6), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(
                  color: const Color(0xFF565D6D),
                  width: 1,
                ),
              ),
            ),
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

        if (isReturn)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColor.primary,
                side: BorderSide(color: AppColor.primary, width: 1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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

  Widget _customerTile(LedgerModelDrop c) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          c.name,
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        Text(
          "₹ ${(double.parse(c.closingBalance ?? "0").abs())} ${(double.tryParse(c.closingBalance ?? "0") ?? 0) < 0 ? "Cr" : "Dr"}",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: (double.tryParse(c.closingBalance ?? "0") ?? 0) < 0
                ? Colors.red
                : Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
