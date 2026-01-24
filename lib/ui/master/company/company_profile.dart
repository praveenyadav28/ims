// ignore_for_file: must_be_immutable, avoid_print

import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ims/ui/master/company/company_api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/textfield.dart';
import 'package:ims/utils/state_cities.dart';
import 'package:searchfield/searchfield.dart';

class CompanyProfileScreen extends StatefulWidget {
  const CompanyProfileScreen({super.key});

  @override
  State<CompanyProfileScreen> createState() => _CompanyProfileScreenState();
}

class _CompanyProfileScreenState extends State<CompanyProfileScreen> {
  // Images
  File? companyLogo;
  File? otherLogo;
  File? signatureImage;
  final ImagePicker picker = ImagePicker();

  // Controllers
  final TextEditingController businessName = TextEditingController();
  final TextEditingController phone = TextEditingController();
  final TextEditingController email = TextEditingController();
  final TextEditingController address = TextEditingController();
  final TextEditingController pincode = TextEditingController();
  final TextEditingController pan = TextEditingController();
  final TextEditingController gst = TextEditingController();
  final TextEditingController website = TextEditingController();
  final TextEditingController districtController = TextEditingController();

  // State & City Search Controllers
  TextEditingController stateController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  late List<String> statesSuggestions;
  late List<String> citiesSuggestions;
  SearchFieldListItem<String>? selectedState;
  SearchFieldListItem<String>? selectedCity;

  // Chips
  List<String> businessTypes = [
    'Retailer',
    'Wholesaler',
    'Manufacturer',
    'Service',
  ];
  List<String> industryTypes = [
    'Gift Shop',
    'Electronics',
    'Grocery',
    'Clothing',
  ];
  Set<String> selectedBusinessTypes = {};
  Set<String> selectedIndustryTypes = {};

  // Switches
  bool isGSTRegistered = false;
  bool enableEInvoicing = false;
  bool enableTDS = false;
  bool enableTCS = false;

  // Website list
  List<String> websites = [];

  // Whether record exists (to decide POST or PUT)
  bool hasExistingProfile = false;

  @override
  void initState() {
    statesSuggestions = stateCities.keys.toList();
    citiesSuggestions = [];
    fetchCompanyProfile(); // auto fetch and prefill
    super.initState();
  }

  // ---------------- PICK IMAGE ----------------
  Future<void> pickImage(String target) async {
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      final file = File(picked.path);
      if (target == 'company') companyLogo = file;
      if (target == 'other') otherLogo = file;
      if (target == 'signature') signatureImage = file;
    });
  }

  String? companyId; // store _id from backend
  String companyLogoUrl = "";
  String otherLogoUrl = "";
  String signatureUrl = "";

  Future<void> fetchCompanyProfile() async {
    try {
      final response = await CompanyProfileAPi.getCompanyProfile();
      print(response);

      if (response["status"] == true && response["data"] != null) {
        final data = response["data"];
        final company = data is List && data.isNotEmpty ? data.first : data;

        print("Fetched Company: $company");

        setState(() {
          hasExistingProfile = true;
          companyId = company["_id"]; // ✅ store _id

          businessName.text = company["business_name"] ?? "";
          phone.text = company["phone_no"]?.toString() ?? "";
          email.text = company["email"] ?? "";
          address.text = company["address"] ?? "";
          stateController.text = company["state"] ?? "";
          cityController.text = company["city"] ?? "";
          districtController.text = company["district"] ?? "";
          pincode.text = company["pincode"]?.toString() ?? "";
          gst.text = company["gst_no"] ?? "";
          pan.text = company["pan_number"] ?? "";
          isGSTRegistered = company["gst_register"] ?? false;
          enableEInvoicing = company["e_invoicing"] ?? false;
          enableTDS = company["tds"] ?? false;
          enableTCS = company["tcs"] ?? false;
          selectedBusinessTypes = Set<String>.from(
            company["business_type"] ?? [],
          );
          selectedIndustryTypes = Set<String>.from(
            company["industry_type"] ?? [],
          );
          websites = List<String>.from(company["business_details"] ?? []);

          // ✅ Autoload images if available
          companyLogoUrl = company["company_logo"] ?? "";
          otherLogoUrl = company["other_logo"] ?? "";
          signatureUrl = company["signature"] ?? "";
        });
      } else {
        setState(() {
          hasExistingProfile = false;
        });
      }
    } catch (e) {
      print("❌ Error fetching profile: $e");
    }
  }

  // ---------------- SAVE PROFILE (POST / PUT) ----------------
  Future<void> saveCompanyProfile() async {
    final Map<String, dynamic> data = {
      'licence_no': Preference.getint(PrefKeys.licenseNo),
      'branch_id': Preference.getString(PrefKeys.locationId),
      "business_name": businessName.text.trim(),
      "phone_no": int.tryParse(phone.text.trim()),
      "email": email.text.trim(),
      "address": address.text.trim(),
      "state": stateController.text.trim(),
      "city": cityController.text.trim(),
      "district": districtController.text.trim(),
      "pincode": int.tryParse(pincode.text.trim()),
      "gst_register": isGSTRegistered,
      "gst_no": gst.text.trim(),
      "e_invoicing": enableEInvoicing,
      "pan_number": pan.text.trim(),
      "tds": enableTDS,
      "tcs": enableTCS,
      "business_type": selectedBusinessTypes.toList(),
      "industry_type": selectedIndustryTypes.toList(),
      "registration_type": "Proprietorship",
      "business_details": websites,
    };

    final Map<String, File> images = {};
    if (companyLogo != null) images['company_logo'] = companyLogo!;
    if (otherLogo != null) images['other_logo'] = otherLogo!;
    if (signatureImage != null) images['signature'] = signatureImage!;

    try {
      final response = hasExistingProfile
          ? await CompanyProfileAPi.updateCompanyProfile(
              data: data,
              images: images,
              id: companyId,
            )
          : await CompanyProfileAPi.createCompanyProfile(
              data: data,
              images: images,
            );
      print(response);
      if (response["status"] == true) {
        showCustomSnackbarSuccess(context, response["message"]);
        fetchCompanyProfile();
      } else {
        showCustomSnackbarError(context, response["message"]);
      }
    } catch (e) {
      showCustomSnackbarError(context, "Error: $e");
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColor.white,
        title: Text(
          "Company Profile",
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColor.textColor,
          ),
        ),
        iconTheme: IconThemeData(color: AppColor.black),
        actions: [
          Row(
            children: [
              defaultButton(
                buttonColor: AppColor.primary,
                text: hasExistingProfile ? "Update Profile" : "Save Changes",
                height: 40,
                width: 160,
                onTap: () => saveCompanyProfile(),
              ),
              const SizedBox(width: 18),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          right: Sizes.width * .08,
          left: Sizes.width * .08,
          top: Sizes.height * .03,
          bottom: Sizes.height * .02,
        ),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _leftColumn()),
                  const SizedBox(width: 32),
                  Expanded(child: _rightColumn()),
                ],
              )
            : Column(
                children: [
                  _leftColumn(),
                  SizedBox(height: Sizes.height * .02),
                  _rightColumn(),
                ],
              ),
      ),
    );
  }

  // ---------------- LEFT COLUMN ----------------
  Widget _leftColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            uploadBox("Company Logo", companyLogo, 'company'),
            const SizedBox(width: 44),
            uploadBox("Other Logo", otherLogo, 'other'),
          ],
        ),
        const SizedBox(height: 24),
        TitleTextFeild(
          titleText: "Business Name*",
          controller: businessName,
          hintText: "Enter business name",
        ),
        SizedBox(height: Sizes.height * .02),
        Row(
          children: [
            Expanded(
              child: TitleTextFeild(
                titleText: "Company Phone Number",
                controller: phone,
                hintText: "Enter company number",
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TitleTextFeild(
                titleText: "Company E-Mail",
                controller: email,
                hintText: "Enter company e-mail",
              ),
            ),
          ],
        ),
        SizedBox(height: Sizes.height * .02),
        TitleTextFeild(
          titleText: "Billing Address",
          controller: address,
          hintText: "Enter Billing Address",
        ),
        SizedBox(height: Sizes.height * .02),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select State",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CommonSearchableDropdownField<String>(
                    controller: stateController,
                    hintText: "Enter state name",
                    suggestions: statesSuggestions
                        .map((x) => SearchFieldListItem<String>(x, item: x))
                        .toList(),
                    onSuggestionTap: (item) {
                      setState(() {
                        selectedState = item;
                        stateController.text = item.searchKey;
                        citiesSuggestions = stateCities[item.searchKey] ?? [];
                        selectedCity = null;
                        cityController.clear();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TitleTextFeild(
                titleText: "Pincode",
                controller: pincode,
                hintText: "Enter Pincode",
              ),
            ),
          ],
        ),
        SizedBox(height: Sizes.height * .02),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Select City",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CommonSearchableDropdownField<String>(
                    controller: cityController,
                    hintText: "Enter city name",
                    suggestions: citiesSuggestions
                        .map((x) => SearchFieldListItem<String>(x, item: x))
                        .toList(),
                    onSuggestionTap: (item) {
                      setState(() {
                        selectedCity = item;
                        cityController.text = item.searchKey;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TitleTextFeild(
                controller: districtController,
                titleText: "District/Village",
                hintText: "Enter District/village/town",
              ),
            ),
          ],
        ),
        SizedBox(height: Sizes.height * .02),
        Text(
          "Are you GST Registered?",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColor.textColor,
          ),
        ),
        SizedBox(height: Sizes.height * .02),
        Row(
          children: [
            Radio<bool>(
              activeColor: AppColor.blue,
              value: true,
              groupValue: isGSTRegistered,
              onChanged: (v) => setState(() => isGSTRegistered = true),
            ),
            const Text("Yes"),
            const SizedBox(width: 16),
            Radio<bool>(
              activeColor: AppColor.blue,
              value: false,
              groupValue: isGSTRegistered,
              onChanged: (v) => setState(() => isGSTRegistered = false),
            ),
            const Text("No"),
          ],
        ),
        if (isGSTRegistered)
          TitleTextFeild(
            titleText: "GST Number",
            controller: gst,
            hintText: "Enter GST Number",
          ),
        SizedBox(height: Sizes.height * .02),
        _toggle(
          "Enable e-Invoicing",
          enableEInvoicing,
          (v) => setState(() => enableEInvoicing = v),
        ),
        SizedBox(height: Sizes.height * .02),
        TitleTextFeild(
          titleText: "PAN Number",
          controller: pan,
          hintText: "Enter PAN Number",
        ),
        SizedBox(height: Sizes.height * .02),
        _toggle("Enable TDS", enableTDS, (v) => setState(() => enableTDS = v)),
        SizedBox(height: Sizes.height * .02),
        _toggle("Enable TCS", enableTCS, (v) => setState(() => enableTCS = v)),
      ],
    );
  }

  // ---------------- RIGHT COLUMN ----------------
  Widget _rightColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        chipGroup("Business Type", businessTypes, selectedBusinessTypes),
        const SizedBox(height: 20),
        chipGroup("Industry Type", industryTypes, selectedIndustryTypes),
        const SizedBox(height: 20),
        Text(
          "Business Registration Type",
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColor.blackText,
          ),
        ),
        const SizedBox(height: 8),
        CommonDropdownField<String>(
          hintText: "Select Registration Type",
          value: "Proprietorship",
          items:
              [
                    'Proprietorship',
                    'Partnership',
                    'Private Limited',
                    'LLP',
                    'Others',
                  ]
                  .map(
                    (e) => DropdownMenuItem<String>(value: e, child: Text(e)),
                  )
                  .toList(),
          onChanged: (_) {},
        ),
        SizedBox(height: Sizes.height * .03),
        Text(
          "Note: Signature added below will be shown on your invoices",
          style: GoogleFonts.inter(fontSize: 13, color: Color(0xFF565D6F)),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => pickImage('signature'),
          child: SizedBox(
            width: double.infinity,
            height: 125,
            child: DottedBorder(
              options: RoundedRectDottedBorderOptions(
                strokeWidth: 1.6,
                radius: Radius.circular(6),
                dashPattern: [5, 3],
                color: AppColor.textLightBlack,
              ),
              child: (signatureImage == null && signatureUrl.isEmpty)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.add, size: 30),
                          SizedBox(height: 12),
                          Text("+ Add Signature"),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: signatureImage != null
                          ? Image.file(
                              signatureImage!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 125,
                            )
                          : Image.network(
                              signatureUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 125,
                              errorBuilder: (_, __, ___) => Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.add, size: 30),
                                    SizedBox(height: 12),
                                    Text("+ Add Signature"),
                                  ],
                                ),
                              ),
                            ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _addBusinessDetails(),
      ],
    );
  }

  Widget uploadBox(String title, File? file, String target, {double? width}) {
    String imageUrl = "";
    if (target == 'company') imageUrl = companyLogoUrl;
    if (target == 'other') imageUrl = otherLogoUrl;
    if (target == 'signature') imageUrl = signatureUrl;

    return GestureDetector(
      onTap: () => pickImage(target),
      child: SizedBox(
        width: width ?? 146,
        height: 125,
        child: DottedBorder(
          options: RoundedRectDottedBorderOptions(
            strokeWidth: 1.6,
            radius: Radius.circular(6),
            dashPattern: [5, 3],
            color: AppColor.textLightBlack,
          ),
          child: (file == null && imageUrl.isEmpty)
              ? _uploadPlaceholder(title)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: file != null
                      ? Image.file(
                          file,
                          fit: BoxFit.cover,
                          width: width ?? 146,
                          height: 125,
                        )
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: width ?? 146,
                          height: 125,
                          errorBuilder: (_, __, ___) =>
                              _uploadPlaceholder(title),
                        ),
                ),
        ),
      ),
    );
  }

  Widget chipGroup(String title, List<String> items, Set<String> selectedSet) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColor.blackText,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: items.map((e) {
            final selected = selectedSet.contains(e);
            return FilterChip(
              label: Text(e),
              selected: selected,
              onSelected: (v) {
                setState(() {
                  if (v)
                    selectedSet.add(e);
                  else
                    selectedSet.remove(e);
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: AppColor.primary.withOpacity(0.2),
              labelStyle: GoogleFonts.inter(
                color: selected ? AppColor.primary : AppColor.textColor,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _toggle(String text, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: AppColor.textColor,
          ),
        ),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 50,
            height: 28,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: value ? AppColor.blue : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 200),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColor.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _addBusinessDetails() {
    return Card(
      elevation: 0,
      color: AppColor.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(color: AppColor.borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Add Business Details",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColor.blackText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Add MSME number, Website etc.",
              style: GoogleFonts.inter(fontSize: 13, color: Color(0xFF565D6F)),
            ),
            SizedBox(height: Sizes.height * .025),
            Row(
              children: [
                Expanded(
                  child: CommonTextField(
                    hintText: "www.website.com",
                    controller: website,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (website.text.isNotEmpty) {
                      setState(() {
                        websites.add(website.text);
                        website.clear();
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.blue,
                  ),
                  child: const Text("Add"),
                ),
              ],
            ),
            Column(
              children: websites
                  .map(
                    (e) => ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -3),
                      title: Text(
                        e,
                        style: GoogleFonts.inter(
                          color: AppColor.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: IconButton(
                        onPressed: () => setState(() => websites.remove(e)),
                        icon: Icon(Icons.delete_outline, color: AppColor.red),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadPlaceholder(String title) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            color: AppColor.textLightBlack,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.inter(
              color: AppColor.textLightBlack,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "PNG/JPG, max 5MB",
            style: GoogleFonts.inter(
              color: AppColor.textLightBlack,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
