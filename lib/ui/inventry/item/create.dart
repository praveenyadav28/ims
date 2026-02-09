// ignore_for_file: unused_local_variable, must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/group/group.dart';
import 'package:ims/ui/group/hsn.dart';
import 'package:ims/ui/inventry/item_model.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/datetext_field.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class CreateNewItemScreen extends StatefulWidget {
  CreateNewItemScreen({super.key, this.editItem});
  ItemModel? editItem;
  @override
  State<CreateNewItemScreen> createState() => _CreateNewItemScreenState();
}

class _CreateNewItemScreenState extends State<CreateNewItemScreen> {
  // Tabs
  int selectedTab = 0; // 0 = Basic Details, 1 = Other Details

  // Item type: 0 = Product, 1 = Service
  int selectedItemType = 0;
  bool productEnabled = false; // show variant section for product
  bool gstIncluded = false; // global inclusive/exclusive toggle

  // Basic fields
  final TextEditingController itemNameController = TextEditingController();
  final TextEditingController itemNoController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController remarksController = TextEditingController();
  final TextEditingController mfgDateController = TextEditingController();
  final TextEditingController expDateController = TextEditingController();

  // Category list (from misc)
  List<String> categoryList = [];
  String? selectedCategory;

  // HSN & GST
  String? selectedHsn;
  List<Map<String, dynamic>> hsnList = [];
  List<String> hsnNames = [];
  final TextEditingController gstRateController = TextEditingController();

  String? baseUnit;
  String? secondaryUnit;
  String conversionValue = "1";

  // Price controllers
  final TextEditingController salePriceController = TextEditingController();
  final TextEditingController amountController =
      TextEditingController(); // base/amount entered by user (service)
  final TextEditingController grossController =
      TextEditingController(); // derived gross amount (for display)
  final TextEditingController purchasePriceController = TextEditingController();

  // With Tax / Without Tax
  List<String> titleList = ["With Tax", "Without Tax"];
  String selectedTitle = "With Tax";

  // Units & Stocks
  String? selectedMeasuringUnit;
  List<String> measuringUnitList = [];
  final TextEditingController openingStockController = TextEditingController();
  final TextEditingController minOrderController = TextEditingController();
  final TextEditingController minStockController = TextEditingController();
  final TextEditingController reorderController = TextEditingController();
  final TextEditingController marginPercentController = TextEditingController();
  final TextEditingController marginAmtController = TextEditingController();

  // Variant / Option
  List<Map<String, dynamic>> variantsList = [];
  List<Map<String, dynamic>> optionsList = [];

  List<String> selectedVariantOrder = [];
  Map<String, Set<String>> selectedOptionsMap =
      {}; // variantId -> selected option names

  // Generated items (product combinations)
  List<Map<String, dynamic>> generatedItems = [];

  // Dialog controllers
  final TextEditingController variantController = TextEditingController();
  final TextEditingController optionController = TextEditingController();

  // Tax logic for Product
  String saleTaxMode = "With Tax"; // sale ke liye dropdown (With/Without Tax)
  String purchaseTaxMode = "With Tax"; // purchase ke liye dropdown

  @override
  void initState() {
    super.initState();
    _loadMiscDropdowns();
    getVariant();
    _loadHsnCodes();
    getOptions();

    // compute on changes
    amountController.addListener(_computeDerivedPrices);
    gstRateController.addListener(_computeDerivedPrices);
    salePriceController.addListener(_computeDerivedPrices);
    purchasePriceController.addListener(_computeDerivedPrices);

    /// 👇 IMPORTANT
    if (widget.editItem != null) {
      _fillEditData(widget.editItem!);
    }
    // keep margin text fields reactive via onChanged in UI (not listeners here)
  }

  void _fillEditData(ItemModel item) {
    // Basic
    itemNameController.text = item.itemName;
    itemNoController.text = item.itemNo;
    selectedCategory = item.group;

    // Stock
    openingStockController.text = item.openingStock;
    minOrderController.text = item.minOrderQty;
    minStockController.text = item.minStockQty;
    reorderController.text = item.reorderLevel;

    // Price
    salePriceController.text = item.salesPrice;
    purchasePriceController.text = item.purchasePriceSe;

    // GST
    gstRateController.text = item.gstRate;
    gstIncluded = item.gstInclude;

    // Unit
    baseUnit = item.baseUnit;
    secondaryUnit = item.secondaryUnit;
    conversionValue = item.conversionAmount;

    // Dates
    mfgDateController.text = item.mfgDate;
    expDateController.text = item.expiryDate;

    // Margin
    marginPercentController.text = item.margin;
    marginAmtController.text = item.marginAmt;

    // Stock qty
    openingStockController.text = item.openingStock;

    // Variant
    selectedItemType = item.itemType == "Service" ? 1 : 0;

    // Tax mode
    saleTaxMode = item.gstInclude ? "With Tax" : "Without Tax";
    purchaseTaxMode = item.gstIncludePurchase ? "With Tax" : "Without Tax";
    selectedHsn = item.hsnCode;
    // UI refresh
    setState(() {});
  }

  @override
  void dispose() {
    itemNameController.dispose();
    itemNoController.dispose();
    descriptionController.dispose();
    remarksController.dispose();
    salePriceController.dispose();
    amountController.dispose();
    grossController.dispose();
    purchasePriceController.dispose();
    gstRateController.dispose();
    openingStockController.dispose();
    minOrderController.dispose();
    minStockController.dispose();
    reorderController.dispose();
    marginPercentController.dispose();
    marginAmtController.dispose();
    variantController.dispose();
    optionController.dispose();
    super.dispose();
  }

  Future<void> _loadHsnCodes() async {
    try {
      final resp = await ApiService.fetchData(
        "get/hsn",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      if (resp != null && resp['status'] == true) {
        final List<dynamic> data = resp['data'] ?? [];
        hsnList = List<Map<String, dynamic>>.from(data);
        hsnNames = hsnList
            .map((e) => e['name']?.toString() ?? "")
            .where((name) => name.isNotEmpty)
            .toList();
        if (!hsnNames.contains(selectedHsn)) selectedHsn = null;
      }
      setState(() {});
    } catch (e) {
      debugPrint("Error loading HSN: $e");
    }
  }

  // ----------------- API loaders -----------------
  Future<void> _loadMiscDropdowns() async {
    try {
      final response = await ApiService.fetchData(
        "get/misc",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      categoryList.clear();
      measuringUnitList.clear();
      if (response != null && response['status'] == true) {
        final List<dynamic> data = response['data'] ?? [];
        for (var item in data) {
          final id = item['misc_id']?.toString();
          final name = (item['name'] ?? '').toString();
          if (name.isEmpty) continue;

          if (id == '1') categoryList.add(name); // category group
          if (id == '2') measuringUnitList.add(name); // measuring unit group
        }
      }

      selectedCategory ??= categoryList.isNotEmpty ? categoryList.first : null;
      selectedMeasuringUnit ??= measuringUnitList.isNotEmpty
          ? measuringUnitList.first
          : null;
      setState(() {});
    } catch (e) {
      debugPrint("Error loading misc: $e");
    }
  }

  Future<void> getVariant() async {
    final response = await ApiService.fetchData(
      'get/variant',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (response != null && response["status"] == true) {
      variantsList = List<Map<String, dynamic>>.from(response["data"]);
    } else {
      variantsList = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> getOptions() async {
    final response = await ApiService.fetchData(
      'get/option',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    if (response != null && response["status"] == true) {
      optionsList = List<Map<String, dynamic>>.from(response["data"]);
    } else {
      optionsList = [];
    }
    if (mounted) setState(() {});
  }

  Future<void> addVariant(String name) async {
    final response = await ApiService.postData('variant', {
      'licence_no': Preference.getint(PrefKeys.licenseNo),
      'branch_id': Preference.getString(PrefKeys.locationId),
      'name': name,
    }, licenceNo: Preference.getint(PrefKeys.licenseNo));

    if (!mounted) return;
    if (response["status"] == true) {
      showCustomSnackbarSuccess(context, "Variant created successfully");
      variantController.clear();
      await getVariant();
    } else {
      showCustomSnackbarError(context, response['message']);
    }
  }

  Future<void> addOptions(String name, String variantId) async {
    final response = await ApiService.postData('option', {
      'licence_no': Preference.getint(PrefKeys.licenseNo),
      'branch_id': Preference.getString(PrefKeys.locationId),
      'variant_id': variantId,
      'name': name,
    }, licenceNo: Preference.getint(PrefKeys.licenseNo));

    if (!mounted) return;
    if (response["status"] == true) {
      showCustomSnackbarSuccess(context, "Option Created");
      optionController.clear();
      await getOptions();
    } else {
      showCustomSnackbarError(context, response['message']);
    }
  }

  Future<void> _deleteVariant(String variantId) async {
    final response = await ApiService.deleteData(
      'variant/$variantId',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (response["status"] == true) {
      showCustomSnackbarSuccess(context, "Variant deleted successfully");
      await getVariant();
      await getOptions();
    } else {
      showCustomSnackbarError(context, response['message']);
    }
    if (mounted) setState(() {});
  }

  Future<void> _deleteOption(String optionId) async {
    final response = await ApiService.deleteData(
      'option/$optionId',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (response["status"] == true) {
      showCustomSnackbarSuccess(context, "Option deleted successfully");
      await getOptions();
      Navigator.pop(context);
    } else {
      showCustomSnackbarError(context, response['message']);
    }
    if (mounted) setState(() {});
  }

  // ----------------- Variant selection toggles -----------------
  void _toggleVariantSelection(
    String variantId,
    String variantName,
    bool selected,
  ) {
    setState(() {
      if (selected) {
        if (!selectedVariantOrder.contains(variantId))
          selectedVariantOrder.add(variantId);
        selectedOptionsMap.putIfAbsent(variantId, () => <String>{});
      } else {
        selectedVariantOrder.remove(variantId);
        selectedOptionsMap.remove(variantId);
      }
    });
  }

  void _toggleOptionSelection(
    String variantId,
    String optionName,
    bool selected,
  ) {
    setState(() {
      selectedOptionsMap.putIfAbsent(variantId, () => <String>{});
      final set = selectedOptionsMap[variantId]!;
      if (selected) {
        set.add(optionName);
        if (!selectedVariantOrder.contains(variantId))
          selectedVariantOrder.add(variantId);
      } else {
        set.remove(optionName);
      }
    });
  }

  void generateCombinations() {
    final selectedVariantOptions = selectedVariantOrder
        .where((vId) => (selectedOptionsMap[vId] ?? {}).isNotEmpty)
        .map((vId) {
          final variantName =
              variantsList.firstWhere(
                (v) => v["_id"] == vId,
                orElse: () => {},
              )["name"] ??
              '';
          final options = selectedOptionsMap[vId]!.toList();
          return {"variant": variantName, "options": options};
        })
        .toList();

    if (selectedVariantOptions.isEmpty) {
      showCustomSnackbarError(
        context,
        "Please select at least one variant option",
      );
      return;
    }

    // All options combinations
    List<List<String>> allOptions = selectedVariantOptions
        .map((v) => List<String>.from(v["options"] as List))
        .toList();

    List<List<String>> combos = [[]];
    for (List<String> options in allOptions) {
      combos = [
        for (List<String> prev in combos)
          for (String option in options) [...prev, option],
      ];
    }

    // Generate final list
    setState(() {
      generatedItems = combos.map((combo) {
        final variantNames = selectedVariantOptions
            .map((v) => v["variant"])
            .join(" - ");
        final variantValues = combo.join(" - ");
        return {
          "variant_type": variantNames,
          "variant_value": variantValues,
          "item_no": "",
          "opening_stock": "",
          "purchase_price": "",
          "sales_price": "",
        };
      }).toList();
    });

    showCustomSnackbarSuccess(context, "Combinations generated successfully!");
  }

  void _onHsnSelected(String? val) {
    if (val == null) {
      setState(() {
        selectedHsn = null;
        gstRateController.text = '';
      });
      return;
    }

    setState(() {
      selectedHsn = val;
      final selected = hsnList.firstWhere(
        (e) => e["name"] == val,
        orElse: () => {},
      );
      final igst = selected["igst"]?.toString() ?? "0";
      gstRateController.text = igst;
    });

    _computeDerivedPrices();
  }
  // ----------------- FINAL ACCURATE CALCULATION LOGIC -----------------

  // Get base price (price without GST)
  double _getBaseFromEntered(
    double entered,
    double gst,
    String mode, // "With Tax" / "Without Tax"
    bool inclusive,
  ) {
    if (mode == "Without Tax") return entered;

    // With Tax but Inclusive → entered = gross (includes GST)
    if (inclusive) {
      return gst > 0 ? entered / (1 + gst / 100) : entered;
    }

    // With Tax but Exclusive → entered = base, GST added later
    return entered;
  }

  // Get gross (price including GST)
  double _getGrossFromBase(
    double base,
    double gst,
    String mode, // "With Tax" / "Without Tax"
    bool inclusive,
  ) {
    if (mode == "Without Tax") return base;

    if (inclusive) {
      // already included in base
      return base * (1 + 0);
    } else {
      // exclusive → GST add hoga
      return base * (1 + gst / 100);
    }
  }

  // ----------------- Derived Prices -----------------
  void _computeDerivedPrices() {
    final gst = double.tryParse(gstRateController.text.trim()) ?? 0.0;

    // SERVICE CASE
    if (selectedItemType == 1) {
      final entered = double.tryParse(amountController.text.trim()) ?? 0.0;

      if (selectedTitle == "Without Tax") {
        grossController.text = entered.toStringAsFixed(2);
        purchasePriceController.text = entered.toStringAsFixed(2);
        return;
      }

      if (gstIncluded) {
        final base = gst > 0 ? entered / (1 + gst / 100) : entered;
        purchasePriceController.text = base.toStringAsFixed(2);
        grossController.text = entered.toStringAsFixed(2);
      } else {
        final gross = entered * (1 + gst / 100);
        purchasePriceController.text = entered.toStringAsFixed(2);
        grossController.text = gross.toStringAsFixed(2);
      }
      return;
    }

    // PRODUCT CASE (without variant)
    if (selectedItemType == 0 && !productEnabled) {
      final purchaseEntered =
          double.tryParse(purchasePriceController.text.trim()) ?? 0.0;
      final saleEntered =
          double.tryParse(salePriceController.text.trim()) ?? 0.0;

      // Base values
      final purchaseBase = _getBaseFromEntered(
        purchaseEntered,
        gst,
        purchaseTaxMode,
        gstIncluded,
      );
      final saleBase = _getBaseFromEntered(
        saleEntered,
        gst,
        saleTaxMode,
        gstIncluded,
      );

      // Margin (always based on base)
      final marginAmt = saleBase - purchaseBase;
      final marginPercent = purchaseBase > 0
          ? (marginAmt / purchaseBase) * 100
          : 0.0;

      // Gross value (exclusive adds GST)
      final saleGross = _getGrossFromBase(
        saleBase,
        gst,
        saleTaxMode,
        gstIncluded,
      );

      // Update controllers
      grossController.text = saleGross.toStringAsFixed(2);
      marginAmtController.text = marginAmt.toStringAsFixed(2);
      marginPercentController.text = marginPercent.toStringAsFixed(2);
    }
  }

  void _onMarginPercentChanged() {
    final gst = double.tryParse(gstRateController.text.trim()) ?? 0.0;
    final percent = double.tryParse(marginPercentController.text.trim()) ?? 0.0;
    final purchaseEntered =
        double.tryParse(purchasePriceController.text.trim()) ?? 0.0;

    double purchaseBase = purchaseEntered;
    double saleBase;
    double saleGross;

    if (gstIncluded) {
      // GST inclusive → extract base first
      purchaseBase = gst > 0
          ? purchaseEntered / (1 + gst / 100)
          : purchaseEntered;
      saleBase = purchaseBase + (purchaseBase * percent / 100);
      saleGross = saleBase * (1 + gst / 100); // GST add after margin
    } else {
      // GST excluded → no GST considered
      saleBase = purchaseBase + (purchaseBase * percent / 100);
      saleGross = saleBase; // direct
    }

    setState(() {
      marginAmtController.text = (saleBase - purchaseBase).toStringAsFixed(2);
      salePriceController.text = saleGross.toStringAsFixed(2);
      grossController.text = saleGross.toStringAsFixed(2);
    });
  }

  void _onMarginAmountChanged() {
    final gst = double.tryParse(gstRateController.text.trim()) ?? 0.0;
    final marginAmt = double.tryParse(marginAmtController.text.trim()) ?? 0.0;
    final purchaseEntered =
        double.tryParse(purchasePriceController.text.trim()) ?? 0.0;

    double purchaseBase = purchaseEntered;
    double saleBase;
    double saleGross;

    if (gstIncluded) {
      // GST inclusive → remove GST first
      purchaseBase = gst > 0
          ? purchaseEntered / (1 + gst / 100)
          : purchaseEntered;
      saleBase = purchaseBase + marginAmt;
      saleGross = saleBase * (1 + gst / 100);
    } else {
      // GST excluded → direct base calc
      saleBase = purchaseBase + marginAmt;
      saleGross = saleBase;
    }

    final percent = purchaseBase > 0 ? (marginAmt / purchaseBase) * 100 : 0.0;

    setState(() {
      salePriceController.text = saleGross.toStringAsFixed(2);
      grossController.text = saleGross.toStringAsFixed(2);
      marginPercentController.text = percent.toStringAsFixed(2);
    });
  }

  // ----------------- Edit cell helper for generated table -----------------
  Widget editCell(Map<String, dynamic> item, String field) {
    return TextFormField(
      initialValue: item[field],
      decoration: const InputDecoration(
        isDense: true,
        border: OutlineInputBorder(),
      ),
      onChanged: (val) => item[field] = val,
    );
  }

  // ----------------- Dialogs for add variant/option -----------------
  Widget _buildAddVariantDialog() {
    final controller = TextEditingController();
    return AlertDialog(
      title: const Text("Add Variant"),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(hintText: "Variant name"),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              addVariant(name);
              Navigator.pop(context);
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }

  void _showAddOptionDialog(String variantId, String variantName) {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add option to $variantName"),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(hintText: "Option name"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final name = c.text.trim();
              if (name.isNotEmpty) {
                addOptions(name, variantId);
                Navigator.pop(context);
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  // ----------------- Delete confirms -----------------
  void _deleteVariantConfirm(String variantId, String variantName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete $variantName?"),
        content: const Text("This will remove variant and its options."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVariant(variantId);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _deleteOptionConfirm(String optionId, String optionName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Delete $optionName?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteOption(optionId);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  // ----------------- UI Widgets -----------------
  Widget tabButton(String title, int index) {
    final isSelected = selectedTab == index;
    return InkWell(
      onTap: () => setState(() => selectedTab = index),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(5),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: !isSelected
              ? AppColor.white
              : const Color.fromARGB(227, 237, 229, 255),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              index == 0
                  ? "assets/icons/basic_item.svg"
                  : "assets/icons/rupee.svg",
              height: 20,
              color: isSelected ? AppColor.blue : AppColor.textColor,
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: GoogleFonts.inter(
                color: isSelected ? AppColor.blue : AppColor.textColor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget currencyField(
    String label, {
    TextEditingController? controller,
    bool showTaxDropdown = false,
    bool readOnly = false,
    Widget? suffix,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          flex: 3,
          child: TitleTextFeild(
            titleText: label,
            controller: controller,
            readOnly: readOnly,
            prefixIcon: const Icon(Icons.currency_rupee, size: 16),
            hintText: controller?.text.isNotEmpty == true
                ? controller!.text
                : (label == "Opening Stock" ? "0" : null),
            suffixIcon: suffix,
          ),
        ),
        if (showTaxDropdown) const SizedBox(width: 10),
        if (showTaxDropdown)
          Expanded(
            flex: 1,
            child: CommonDropdownField<String>(
              value: selectedTitle,
              items: titleList
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (val) {
                setState(() {
                  selectedTitle = val ?? titleList.first;
                  _computeDerivedPrices();
                });
              },
            ),
          ),
      ],
    );
  }

  // Basic Details Card
  Widget basicDetailsCard() {
    return Column(
      children: [
        // Row: Item Type + Category
        Row(
          children: [
            Expanded(child: itemTypeField()),
            const SizedBox(width: 24),
            Expanded(child: categoryField()),
          ],
        ),

        SizedBox(height: Sizes.height * .04),

        // Row: Item Name, Item No
        Row(
          children: [
            Expanded(
              child: TitleTextFeild(
                titleText: "${selectedItemType == 0 ? "Item" : "Service"} Name",
                controller: itemNameController,
                hintText:
                    "Enter ${selectedItemType == 0 ? "item" : "service"} name",
              ),
            ),
            const SizedBox(width: 24),
            if (selectedItemType == 1 || !productEnabled)
              Expanded(
                child: TitleTextFeild(
                  controller: itemNoController,
                  titleText:
                      "${selectedItemType == 0 ? "Item" : "Service"} No.",
                  hintText:
                      "Enter ${selectedItemType == 0 ? "item" : "service"} number",
                ),
              )
            else
              Expanded(child: measuringUnitField()),
          ],
        ),
        SizedBox(height: Sizes.height * .03),

        // Row: Price fields (difference for Product / Service)
        if (selectedItemType == 0)
          Row(
            children: [
              // SALE PRICE FIELD
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (selectedItemType == 1 || !productEnabled)
                      Expanded(
                        flex: 3,
                        child: TitleTextFeild(
                          titleText: "Sale Price",
                          controller: salePriceController,
                          prefixIcon: const Icon(
                            Icons.currency_rupee,
                            size: 16,
                          ),
                          hintText: "Enter sale price",
                          onChanged: (_) => _computeDerivedPrices(),
                        ),
                      ),

                    if (selectedItemType == 1 || !productEnabled)
                      const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedItemType == 0 && productEnabled)
                            Text(
                              "Sale Price",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textColor,
                              ),
                            ),

                          if (selectedItemType == 0 && productEnabled)
                            const SizedBox(height: 8),

                          CommonDropdownField<String>(
                            value: saleTaxMode,
                            items: ["With Tax", "Without Tax"]
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                saleTaxMode = val!;
                                _computeDerivedPrices();
                              });
                            },
                            hintText: "Tax Type",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // PURCHASE PRICE FIELD
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (selectedItemType == 1 || !productEnabled)
                      Expanded(
                        flex: 3,
                        child: TitleTextFeild(
                          titleText: "Purchase Price",
                          controller: purchasePriceController,
                          prefixIcon: const Icon(
                            Icons.currency_rupee,
                            size: 16,
                          ),
                          hintText: "Enter purchase price",
                          onChanged: (_) => _computeDerivedPrices(),
                        ),
                      ),

                    if (selectedItemType == 1 || !productEnabled)
                      const SizedBox(width: 10),
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (selectedItemType == 0 && productEnabled)
                            Text(
                              "Purchase Price",
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColor.textColor,
                              ),
                            ),

                          if (selectedItemType == 0 && productEnabled)
                            const SizedBox(height: 8),

                          CommonDropdownField<String>(
                            value: purchaseTaxMode,
                            items: ["With Tax", "Without Tax"]
                                .map(
                                  (v) => DropdownMenuItem(
                                    value: v,
                                    child: Text(v),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              setState(() {
                                purchaseTaxMode = val!;
                                _computeDerivedPrices();
                              });
                            },
                            hintText: "Tax Type",
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          // Service: amount (base) + computed purchase price
          Row(
            children: [
              Expanded(
                child: currencyField(
                  "Amount",
                  controller: amountController,
                  showTaxDropdown: true,
                ),
              ),
              const SizedBox(width: 24),

              if (selectedItemType != 0) Expanded(child: measuringUnitField()),
            ],
          ),

        if (selectedTitle == "With Tax") SizedBox(height: Sizes.height * .03),

        // Row: HSN & GST (shown only when With Tax)
        if (selectedTitle == "With Tax")
          Row(
            children: [
              Expanded(child: hsnField()),
              const SizedBox(width: 24),
              Expanded(child: gstFieldWithToggle()),
            ],
          ),

        if (selectedItemType == 0) SizedBox(height: Sizes.height * .03),

        // Row: Measuring Unit & Opening Stock
        if (selectedItemType == 1 || !productEnabled)
          Row(
            children: [
              if (selectedItemType == 0) Expanded(child: measuringUnitField()),
              const SizedBox(width: 24),
              Expanded(
                child: selectedItemType == 0
                    ? TitleTextFeild(
                        titleText: "Opening Stock",
                        hintText: "0",
                        controller: openingStockController,
                      )
                    : Container(),
              ),
            ],
          ),

        const SizedBox(height: 20),

        // If Product and variant enabled -> show Variant Section & generated table
        if (selectedItemType == 0 && productEnabled) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _buildAddVariantDialog(),
                ),
                icon: const Icon(Icons.add),
                label: const Text("Add Variant"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff8947E5),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: generateCombinations,
                icon: const Icon(Icons.auto_fix_high),
                label: const Text("Generate List"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff0A66C2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          variantSection(),
          const SizedBox(height: 16),
          generatedItemTable(),
        ],

        const SizedBox(height: 24),

        // Show computed Gross amount preview for Service or non-variant products
        if (selectedItemType == 1)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Gross Amount',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  grossController.text.isNotEmpty
                      ? '₹ ${grossController.text}'
                      : '—',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget gstFieldWithToggle() {
    return TitleTextFeild(
      titleText: "GST Tax Rate (%)",
      controller: gstRateController,
      readOnly: true,
      suffixIcon: GestureDetector(
        onTap: () {
          setState(() {
            gstIncluded = !gstIncluded;
            _computeDerivedPrices();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: gstIncluded ? Colors.green.shade50 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                gstIncluded ? Icons.check_circle : Icons.remove_circle_outline,
                size: 16,
                color: gstIncluded ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 6),
              Text(
                gstIncluded ? 'Incl GST' : 'Excl GST',
                style: GoogleFonts.inter(fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget itemTypeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Item Type*",
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColor.textColor,
              ),
            ),
            const Spacer(),
            if (selectedItemType == 0)
              Text(
                productEnabled ? "Variant Enabled" : "Variant Disabled",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: productEnabled ? Colors.green : AppColor.textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => selectedItemType = 0),
              child: Row(
                children: [
                  Radio<int>(
                    value: 0,
                    groupValue: selectedItemType,
                    onChanged: (v) => setState(() => selectedItemType = v ?? 0),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Product",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () => setState(() => selectedItemType = 1),
              child: Row(
                children: [
                  Radio<int>(
                    value: 1,
                    groupValue: selectedItemType,
                    onChanged: (v) => setState(() => selectedItemType = v ?? 1),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Service",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Spacer(),
            if (selectedItemType == 0)
              Switch(
                value: productEnabled,
                onChanged: (val) => setState(() => productEnabled = val),
              ),
          ],
        ),
      ],
    );
  }

  Widget categoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "${selectedItemType == 0 ? "Item" : "Service"} Group",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColor.textColor,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CommonDropdownField(
                value: (categoryList.contains(selectedCategory))
                    ? selectedCategory
                    : null,
                items: categoryList
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(
                          v,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF565D6D),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val),
                hintText: "Enter group",
              ),
            ),
            const SizedBox(width: 12),
            addDefaultButton(() async {
              await showDialog(
                barrierDismissible: false,
                context: context,
                builder: (context) {
                  return Dialog(
                    insetPadding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: SizedBox(
                      width: Sizes.width * 0.9,
                      height: Sizes.height * 0.8,
                      child: AddGroupScreen(miscId: "1", name: 'Category'),
                    ),
                  );
                },
              ).then((updateData) {
                if (updateData != null) {
                  _loadMiscDropdowns().then((_) => setState(() {}));
                }
              });
            }),
          ],
        ),
      ],
    );
  }

  Widget hsnField() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "HSN Code",
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: AppColor.textColor,
                ),
              ),
              const SizedBox(height: 8),
              CommonDropdownField<String>(
                value: selectedHsn,
                items: hsnNames
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(
                          v,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF565D6D),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) => _onHsnSelected(val),
                hintText: "Select HSN Code",
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: addDefaultButton(() async {
            await showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) {
                return Dialog(
                  insetPadding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SizedBox(
                    width: Sizes.width < 800
                        ? Sizes.width * 0.9
                        : Sizes.width * 0.4,
                    height: Sizes.height * 0.8,
                    child: const AddHsnScreen(),
                  ),
                );
              },
            ).then((updateData) async {
              if (updateData != null) {
                await _loadHsnCodes(); // ✅ Refresh only once after dialog close
              }
            });
          }),
        ),
      ],
    );
  }

  Widget gstField() {
    return TitleTextFeild(
      titleText: "GST Tax Rate (%)",
      hintText: gstRateController.text.isNotEmpty
          ? gstRateController.text
          : "Select Tax Rate",
      readOnly: true,
    );
  }

  Widget measuringUnitField() {
    return TitleTextFeild(
      titleText: "Measuring Unit",
      onTap: _openUnitDialog,
      hintText: selectedMeasuringUnit ?? 'Select Measuring Unit',
    );
  }

  void _openUnitDialog() {
    String localBase =
        baseUnit ??
        (measuringUnitList.isNotEmpty ? measuringUnitList.first : '');
    String localSecondary = secondaryUnit ?? localBase;

    final TextEditingController conversionController = TextEditingController(
      text: conversionValue,
    );

    void autoFill() {
      _autoFillConversion(localBase, localSecondary, conversionController);
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Select Measuring Units"),
          content: StatefulBuilder(
            builder: (context, setDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  defaultButton(
                    height: 35,
                    width: 110,
                    buttonColor: AppColor.primary,
                    onTap: () async {
                      await showDialog(
                        barrierDismissible: false,
                        context: context,
                        builder: (context) {
                          return Dialog(
                            insetPadding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: SizedBox(
                              width: Sizes.width * 0.9,
                              height: Sizes.height * 0.8,
                              child: const AddGroupScreen(
                                miscId: "2",
                                name: 'Measuring Unit',
                              ),
                            ),
                          );
                        },
                      ).then((updateData) async {
                        if (updateData != null) {
                          // 🔄 reload from API
                          await _loadMiscDropdowns();

                          // auto select new unit
                          setDialog(() {
                            if (measuringUnitList.isNotEmpty) {
                              localBase = measuringUnitList.last;
                              localSecondary = localBase;
                            }
                          });

                          autoFill();
                        }
                      });
                    },
                    text: "Add New",
                  ),
                  SizedBox(height: 10),
                  Divider(),

                  /// -------- BASE + SECONDARY ----------
                  Row(
                    children: [
                      Expanded(
                        child: CommonDropdownField<String>(
                          value: localBase,
                          items: measuringUnitList
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setDialog(() => localBase = val);
                            autoFill();
                          },
                          hintText: "Base Unit",
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CommonDropdownField<String>(
                          value: localSecondary,
                          items: measuringUnitList
                              .map(
                                (u) =>
                                    DropdownMenuItem(value: u, child: Text(u)),
                              )
                              .toList(),
                          onChanged: (val) {
                            if (val == null) return;
                            setDialog(() => localSecondary = val);
                            autoFill();
                          },
                          hintText: "Secondary Unit",
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// -------- CONVERSION ----------
                  TitleTextFeild(
                    controller: conversionController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    titleText: "Conversion (1 Base = ? Secondary)",
                  ),

                  const Divider(),

                  /// -------- ADD NEW UNIT ----------
                ],
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            defaultButton(
              onTap: () {
                setState(() {
                  baseUnit = localBase;
                  secondaryUnit = localSecondary;
                  conversionValue = conversionController.text.trim().isEmpty
                      ? "1"
                      : conversionController.text.trim();

                  selectedMeasuringUnit =
                      "$baseUnit (1 $baseUnit = $conversionValue $secondaryUnit)";
                });
                Navigator.pop(context);
              },
              text: "Save",
              buttonColor: AppColor.blue,
              height: 35,
              width: 80,
            ),
          ],
        );
      },
    );
  }

  void _autoFillConversion(
    String base,
    String secondary,
    TextEditingController controller,
  ) {
    if (base == secondary) {
      controller.text = '1';
    }
    /// Common presets
    else if ((base == 'Box' && secondary == 'Pieces') ||
        (base == 'Dozen' && secondary == 'Pieces')) {
      controller.text = '12';
    } else if ((base == 'KG' && secondary == 'Gram') ||
        (base == 'Litre' && secondary == 'ML')) {
      controller.text = '1000';
    } else if (base == 'Meter' && secondary == 'CM') {
      controller.text = '100';
    } else if (base == 'Packet' && secondary == 'Pieces') {
      controller.text = '10';
    } else {
      controller.text = '1'; // default safe value
    }
  }

  Widget variantSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
        color: AppColor.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Variants & Options",
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: variantsList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, idx) {
              final v = variantsList[idx];
              final vid = v["_id"];
              final vname = v["name"] ?? "Variant";
              final variantOptions = optionsList
                  .where((o) => o["variant_id"] == vid)
                  .toList();
              final isVariantSelected = selectedVariantOrder.contains(vid);
              final selectedSet = selectedOptionsMap[vid] ?? <String>{};

              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade200),
                  borderRadius: BorderRadius.circular(6),
                  color: const Color(0xFFF8F8FB),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: isVariantSelected,
                          onChanged: (val) =>
                              _toggleVariantSelection(vid, vname, val == true),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            vname,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _deleteVariantConfirm(vid, vname),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: variantOptions.length <= 6 ? null : 80,
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var opt in variantOptions)
                              FilterChip(
                                label: Text(opt["name"]),
                                selected: selectedSet.contains(opt["name"]),
                                onSelected: (sel) => _toggleOptionSelection(
                                  vid,
                                  opt["name"],
                                  sel,
                                ),
                                onDeleted: () => _deleteOptionConfirm(
                                  opt["_id"],
                                  opt["name"],
                                ),
                              ),
                            ActionChip(
                              label: const Text("+ Add"),
                              avatar: const Icon(Icons.add, size: 18),
                              onPressed: () => _showAddOptionDialog(vid, vname),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!isVariantSelected)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Tick to include this variant in combinations",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget generatedItemTable() {
    if (generatedItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Generated Variant Items",
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text("Item Name")),
                DataColumn(label: Text("Variant Type")),
                DataColumn(label: Text("Variant Value")),
                DataColumn(label: Text("Item No.")),
                DataColumn(label: Text("Opening Stock")),
                DataColumn(label: Text("Purchase Price")),
                DataColumn(label: Text("Sale Price")),
                DataColumn(label: Text("Actions")),
              ],
              rows: List.generate(generatedItems.length, (i) {
                var item = generatedItems[i];
                return DataRow(
                  cells: [
                    DataCell(Text(itemNameController.text.toString())),
                    DataCell(Text(item["variant_type"] ?? "")),
                    DataCell(Text(item["variant_value"] ?? "")),
                    DataCell(editCell(item, "item_no")),
                    DataCell(editCell(item, "opening_stock")),
                    DataCell(editCell(item, "purchase_price")),
                    DataCell(editCell(item, "sales_price")),
                    DataCell(
                      IconButton(
                        onPressed: () =>
                            setState(() => generatedItems.removeAt(i)),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  // Other Details card
  Widget otherDetailsCard() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TitleTextFeild(
                titleText: "Minimum Order Quantity",
                hintText: "0",
                controller: minOrderController,
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: TitleTextFeild(
                titleText: "Minimum Stock Quantity",
                hintText: "0",
                controller: minStockController,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: TitleTextFeild(
                      readOnly: true,
                      titleText: "Purchase Price",
                      hintText: "₹ 0",
                      controller: purchasePriceController,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: TitleTextFeild(
                      readOnly: true,
                      titleText: "Sale Price",
                      hintText: "₹ 0",
                      controller: salePriceController,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: TitleTextFeild(
                      titleText: "Margin %",
                      hintText: "%0",
                      controller: marginPercentController,
                      // onChanged: (_) => ,
                      suffixIcon: IconButton(
                        onPressed: () => _onMarginPercentChanged(),
                        icon: Icon(Icons.save),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: TitleTextFeild(
                      titleText: "Margin Amt",
                      hintText: "0",
                      controller: marginAmtController,
                      suffixIcon: IconButton(
                        onPressed: () => _onMarginAmountChanged(),
                        icon: Icon(Icons.save),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: DateTextField(
                      title: "MFG Date",
                      controller: mfgDateController,
                      onTap: () => pickDate(context, mfgDateController),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: DateTextField(
                      title: "EXP Date",
                      controller: expDateController,
                      onTap: () => pickDate(context, expDateController),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 20),
            Expanded(
              child: TitleTextFeild(
                titleText: "Re-order Level",
                hintText: "0 PCS",
                controller: reorderController,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ----------------- Scaffold -----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.appbarColor,
        elevation: .4,
        shadowColor: AppColor.grey,
        iconTheme: IconThemeData(color: AppColor.black),
        title: Text(
          "${widget.editItem == null ? "Create New" : "Update"} Item",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.blackText,
          ),
        ),
      ),
      body: Row(
        children: [
          // Left sidebar
          Container(
            width: 183,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColor.borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 10),
                  child: Text(
                    "Item \nDetails",
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColor.blackText,
                    ),
                  ),
                ),
                tabButton("Basic \nDetails", 0),
                if (selectedItemType == 0 && !productEnabled)
                  tabButton("Other \nDetails", 1),
              ],
            ),
          ),

          // Right content
          Expanded(
            child: Container(
              height: Sizes.height,
              padding: const EdgeInsets.all(24),
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColor.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColor.borderColor),
              ),
              child: SingleChildScrollView(
                child: selectedTab == 0
                    ? basicDetailsCard()
                    : otherDetailsCard(),
              ),
            ),
          ),
        ],
      ),

      // Bottom nav - Save & Cancel
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(
          top: 17,
          bottom: 24,
          left: 27,
          right: 27,
        ),
        decoration: BoxDecoration(color: AppColor.appbarColor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            defaultButton(
              buttonColor: const Color(0xff8947E5),
              text:
                  "${widget.editItem == null ? "Save New " : "Update "}${selectedItemType == 0 ? "Item" : "Service"}",
              height: 40,
              width: 149,
              onTap: saveItemAPi,
            ),
            const SizedBox(width: 18),
            defaultButton(
              buttonColor: const Color(0xffE11414),
              text: "Cancel",
              height: 40,
              width: 93,
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveItemAPi() async {
    final name = itemNameController.text.trim();
    if (name.isEmpty) {
      showCustomSnackbarError(context, 'Please enter item name');
      return;
    }

    if (selectedItemType == 1) {
      // --- 1. SERVICE ---
      await _saveServiceItem();
    } else if (selectedItemType == 0 && !productEnabled) {
      // --- 2. PRODUCT without variant ---
      await _saveSimpleProduct();
    } else if (selectedItemType == 0 && productEnabled) {
      // --- 3. PRODUCT with variant (temp dummy) ---
      _saveVariantProduct();
    }
  }

  Future<void> _saveServiceItem() async {
    try {
      final payload = {
        "licence_no": Preference.getint(PrefKeys.licenseNo),
        "branch_id": Preference.getString(PrefKeys.locationId),
        "service_no": itemNoController.text.trim().isNotEmpty
            ? itemNoController.text.trim()
            : "",
        "service_name": itemNameController.text.trim().isNotEmpty
            ? itemNameController.text.trim()
            : "",
        "baseunit": baseUnit ?? "",
        "secondryunit": secondaryUnit ?? "",
        "convertion_amount": conversionValue.isNotEmpty ? conversionValue : "1",
        "hsn": selectedHsn ?? "",
        "gst_include": selectedTitle == "With Tax" ? true : false,
        "gst_rate": gstRateController.text.trim().isNotEmpty
            ? gstRateController.text
            : "",
        "group": selectedCategory ?? "",
        "basic_price": purchasePriceController.text.trim().isNotEmpty
            ? purchasePriceController.text
            : "",
        "gross_amount": grossController.text.trim().isNotEmpty
            ? grossController.text
            : "",
      };

      debugPrint("Service Payload => $payload");

      final response = await ApiService.postData(
        'service',
        payload,
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      if (response?['status'] == true) {
        showCustomSnackbarSuccess(context, response?['message']);
        Navigator.of(context).pop(true);
      } else {
        showCustomSnackbarError(context, response?['message'] ?? 'Save failed');
      }
    } catch (e) {
      debugPrint("Error in _saveServiceItem: $e");
      showCustomSnackbarError(context, "Something went wrong: $e");
    }
  }

  Future<void> _saveSimpleProduct() async {
    _computeDerivedPrices(); // ensure values present
    final gst = double.tryParse(gstRateController.text) ?? 0;
    final enteredPrice = double.tryParse(purchasePriceController.text) ?? 0;

    final priceData = calculatePurchasePrice(
      enteredPrice: enteredPrice,
      gst: gst,
      isWithTax: purchaseTaxMode == "With Tax",
    );
    final payload = {
      'licence_no': Preference.getint(PrefKeys.licenseNo),
      'branch_id': Preference.getString(PrefKeys.locationId),

      'item_type': 'Product',
      'item_name': itemNameController.text,
      'item_no': itemNoController.text,
      'group': selectedCategory,
      'sales_price': salePriceController.text,
      'title': selectedTitle,
      "purchase_price": priceData["purchase_price"],
      "purchase_price_se": priceData["purchase_price_se"],
      'hsn_code': selectedHsn,
      "baseunit": baseUnit ?? "",
      "secondryunit": secondaryUnit ?? "",
      "convertion_amount": conversionValue.isNotEmpty ? conversionValue : "1",
      "gst_include": selectedTitle == "With Tax" ? true : false,
      "gstinclude_purchase": purchaseTaxMode == "With Tax" ? true : false,
      "gst_tax_rate": gstRateController.text.trim().isNotEmpty
          ? gstRateController.text
          : "",
      if (openingStockController.text.isNotEmpty)
        'opening_stock': openingStockController.text,
      if (openingStockController.text.isNotEmpty)
        'stock_qty': openingStockController.text,
      if (minOrderController.text.isNotEmpty)
        'm_o_qty': minOrderController.text,
      if (minStockController.text.isNotEmpty)
        'm_s_qty': minStockController.text,
      if (mfgDateController.text.isNotEmpty) 'mfg_date': mfgDateController.text,
      if (expDateController.text.isNotEmpty)
        'expiry_date': expDateController.text,
      'margin': marginPercentController.text,
      'margin_amt': marginAmtController.text,
      're_o_level': reorderController.text.trim().isEmpty
          ? 0
          : reorderController.text,
      'variant_list': [],
    };

    final response = widget.editItem == null
        ? await ApiService.postData(
            'item',
            payload,
            licenceNo: Preference.getint(PrefKeys.licenseNo),
          )
        : await ApiService.putData(
            'item/${widget.editItem!.id}',
            payload,
            licenceNo: Preference.getint(PrefKeys.licenseNo),
          );
    if (response?['status'] == true) {
      showCustomSnackbarSuccess(
        context,
        response?['message'] ?? 'Product saved successfully',
      );
      Navigator.of(context).pop(true);
    } else {
      showCustomSnackbarError(context, response?['message'] ?? 'Save failed');
    }
  }

  Future<void> _saveVariantProduct() async {
    if (generatedItems.isEmpty) {
      showCustomSnackbarError(context, "Please generate variant list first");
      return;
    }

    final allNos = generatedItems
        .map((e) => e['item_no']?.toString().trim() ?? "")
        .toList();

    if (allNos.any((no) => no.isEmpty)) {
      showCustomSnackbarError(context, "Each variant must have an Item Number");
      return;
    }

    if (allNos.toSet().length != allNos.length) {
      showCustomSnackbarError(context, "Duplicate Item Numbers found!");
      return;
    }

    final gst = double.tryParse(gstRateController.text.trim()) ?? 0.0;
    final gstInclusive = gstIncluded; // global inclusive/exclusive toggle

    // Show loader
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (_) => Center(child: GlowLoader()),
    );

    // Clone list to avoid modification while looping
    final List<Map<String, dynamic>> tempList = List.from(generatedItems);

    for (final item in tempList) {
      final purchaseEnteredRe =
          double.tryParse(item["purchase_price"]?.toString() ?? "0") ?? 0.0;
      final stockQty =
          int.tryParse(item["opening_stock"]?.toString() ?? "0") ?? 0;
      final purchaseEntered =
          double.tryParse(item["purchase_price"]?.toString() ?? "0") ?? 0.0;
      final saleEntered =
          double.tryParse(item["sales_price"]?.toString() ?? "0") ?? 0.0;

      // ----------------- 1️⃣ BASE CALC (PURCHASE) -----------------
      double purchaseBase;
      if (purchaseTaxMode == "With Tax") {
        purchaseBase = gstInclusive
            ? (gst > 0 ? purchaseEntered / (1 + gst / 100) : purchaseEntered)
            : purchaseEntered;
      } else {
        purchaseBase = purchaseEntered;
      }

      // ----------------- 2️⃣ BASE CALC (SALE) -----------------
      double saleBase;
      if (saleTaxMode == "With Tax") {
        saleBase = gstInclusive
            ? (gst > 0 ? saleEntered / (1 + gst / 100) : saleEntered)
            : saleEntered;
      } else {
        saleBase = saleEntered;
      }

      // ----------------- 3️⃣ MARGIN CALC -----------------
      final marginAmt = saleBase - purchaseBase;
      final marginPercent = purchaseBase > 0
          ? (marginAmt / purchaseBase) * 100
          : 0.0;

      // ----------------- 4️⃣ GROSS VALUES -----------------
      double purchaseGross;
      double saleGross;

      if (purchaseTaxMode == "With Tax") {
        purchaseGross = gstInclusive
            ? purchaseEntered
            : purchaseEntered * (1 + gst / 100);
      } else {
        purchaseGross = purchaseEntered;
      }

      if (saleTaxMode == "With Tax") {
        saleGross = gstInclusive ? saleEntered : saleEntered * (1 + gst / 100);
      } else {
        saleGross = saleEntered;
      }

      // ----------------- 5️⃣ PAYLOAD BUILD -----------------
      final payload = {
        "licence_no": Preference.getint(PrefKeys.licenseNo),
        "branch_id": Preference.getString(PrefKeys.locationId),
        "item_type": "Product",
        "item_name": itemNameController.text.trim(),
        "variant_type": item["variant_type"],
        "variant_name": item["variant_value"],
        "item_no": item["item_no"].toString().isEmpty
            ? itemNameController.text.trim()
            : item["item_no"],
        "group": selectedCategory,
        "purchase_price": purchaseEntered.toStringAsFixed(2),
        "purchase_price_se": purchaseEnteredRe.toStringAsFixed(2),
        "sales_price": saleEntered.toStringAsFixed(2),
        "opening_stock": stockQty,
        "stock_qty": stockQty,
        "hsn_code": selectedHsn,
        "gst_tax_rate": gstRateController.text.trim(),
        "gst_include": saleTaxMode == "With Tax",
        "gstinclude_purchase": purchaseTaxMode == "With Tax",
        "baseunit": baseUnit ?? "",
        "secondryunit": secondaryUnit ?? "",
        "convertion_amount": conversionValue.isNotEmpty ? conversionValue : "1",
        "title": selectedTitle,
        "m_o_qty": 0,
        "m_s_qty": 0,
        "margin": marginPercent.toStringAsFixed(2),
        "margin_amt": marginAmt.toStringAsFixed(2),
        "re_o_level": 0,
        "variant_list": [],
      };

      debugPrint("✅ Posting Variant Payload => $payload");

      final res = await ApiService.postData(
        'item',
        payload,
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      // ✅ If successfully saved → remove from list
      if (res != null && res["status"] == true) {
        setState(() {
          generatedItems.removeWhere((e) => e["item_no"] == item["item_no"]);
        });
        debugPrint("🟢 Saved & removed item: ${item["item_no"]}");
      } else {
        showCustomSnackbarError(
          context,
          "❌ Error saving ${item["item_no"]}: ${res?["message"] ?? "failed"}",
        );
        break; // stop loop if one fails
      }
    }

    Navigator.pop(context); // close loader

    if (generatedItems.isEmpty) {
      showCustomSnackbarSuccess(
        context,
        "🎉 All variant items saved and cleared from list!",
      );
    } else {
      showCustomSnackbarSuccess(
        context,
        "${generatedItems.length} items remaining (some saved successfully).",
      );
    }
  }

  Future<void> pickDate(
    BuildContext context,
    TextEditingController controller,
  ) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      controller.text = DateFormat("yyyy-MM-dd").format(picked);
    }
  }

  Map<String, String> calculatePurchasePrice({
    required double enteredPrice,
    required double gst,
    required bool isWithTax,
  }) {
    double basePrice = enteredPrice;
    double withTaxPrice = enteredPrice;

    if (isWithTax && gst > 0) {
      basePrice = enteredPrice / (1 + gst / 100);
    }

    return {
      "purchase_price": basePrice.toStringAsFixed(2),
      "purchase_price_se": withTaxPrice.toStringAsFixed(2),
    };
  }
}
