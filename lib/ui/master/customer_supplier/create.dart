// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/state_cities.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';

class CreateCusSup extends StatefulWidget {
  CreateCusSup({super.key, required this.isCustomer, this.cusSupData});
  bool isCustomer;
  Customer? cusSupData;
  @override
  State<CreateCusSup> createState() => _CreateCusSupState();
}

class _CreateCusSupState extends State<CreateCusSup>
    with SingleTickerProviderStateMixin {
  TextEditingController companyNameController = TextEditingController();
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController firstNameGuardianController = TextEditingController();
  TextEditingController lastNameGuardianController = TextEditingController();
  TextEditingController guardianNameController = TextEditingController();
  TextEditingController guardianlastNameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController mobileController = TextEditingController();
  TextEditingController workPhoneController = TextEditingController();
  TextEditingController panController = TextEditingController();
  TextEditingController gstNumberController = TextEditingController();
  TextEditingController cityDistrictController = TextEditingController();
  TextEditingController addressLine1Controller = TextEditingController();
  TextEditingController addressLine2Controller = TextEditingController();
  TextEditingController openingBalanceController = TextEditingController(
    text: "0",
  );

  String selectedType = "Individual";
  late TabController _tabController;

  List<String> titleList = ["Mr", "Mrs", "Dr"];
  String selectedTitle = "Mr";

  List<String> titleParentList = ["S/O", "D/O", "W/O", "C/O"];
  String selectedTitleParent = "S/O";

  String _selectedBalance = 'Cr';
  final List<String> _balanceType = ['Cr', 'Dr'];

  List<String> gstTypeList = [
    "Unregistered Dealer",
    "Registered Dealer",
    "Composition Dealer",
    "UIN Holder",
    "Govt. Body",
  ];
  String? selectedGstType;

  // State & City (SearchField like staff screen)
  late List<String> statesSuggestions;
  late List<String> citiesSuggestions;
  SearchFieldListItem<String>? selectedState;
  SearchFieldListItem<String>? selectedCity;

  final ImagePicker _picker = ImagePicker();

  List<Map<String, dynamic>> documents = [
    {"duc_title": "", "image": null},
  ];

  Future<void> _pickImage(int index) async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        documents[index]["image"] = File(picked.path);
      });
    }
  }

  void _addNewDocument() {
    setState(() {
      documents.add({"duc_title": "", "image": null});
    });
  }

  void _removeDocument(int index) {
    setState(() {
      documents.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    statesSuggestions = stateCities.keys.toList();
    citiesSuggestions = [];
    _tabController = TabController(length: 3, vsync: this);

    /// ✅ AUTO FILL WHEN EDIT
    if (widget.cusSupData != null) {
      final c = widget.cusSupData!;

      selectedType = c.customerType;
      selectedTitle = c.title;
      selectedTitleParent = c.related;

      companyNameController.text = c.companyName;
      firstNameController.text = c.firstName;
      lastNameController.text = c.lastName;
      firstNameGuardianController.text = c.parents;
      lastNameGuardianController.text = c.parentsLast;

      emailController.text = c.email;
      mobileController.text = c.mobile;
      workPhoneController.text = c.phone ?? "";

      panController.text = c.pan;
      gstNumberController.text = c.gstNo;
      selectedGstType = c.gstType == "" ? null : c.gstType;

      addressLine1Controller.text = c.address0;
      addressLine2Controller.text = c.address1;
      cityDistrictController.text = c.city;

      // State & City
      selectedState = SearchFieldListItem(c.state, item: c.state);
      citiesSuggestions = stateCities[c.state] ?? [];
      selectedCity = SearchFieldListItem(c.city, item: c.city);

      /// DOCUMENTS
      documents = c.documents.isEmpty
          ? [
              {"duc_title": "", "image": null},
            ]
          : c.documents
                .map(
                  (e) => {
                    "duc_title": e.title,
                    "image": e.image, // URL string
                  },
                )
                .toList();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        backgroundColor: AppColor.white,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context, "data");
          },
          icon: Icon(Icons.arrow_back, color: AppColor.black),
        ),
        elevation: .4,
        shadowColor: AppColor.grey,
        title: Text(
          "${widget.cusSupData == null ? "Create New" : "Update"} ${widget.isCustomer ? "Customer" : "Supplier"}",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppColor.blackText,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          right: Sizes.width * .08,
          left: Sizes.width * .08,
          top: Sizes.height * .05,
          bottom: Sizes.height * .02,
        ),
        child: Column(
          children: [
            nameField(
              text: "${widget.isCustomer ? "Customer" : "Supplier"} Type",
              child: Row(
                children: [
                  Radio<String>(
                    value: "Business",
                    activeColor: AppColor.primary,
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  Text(
                    "Business",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColor.blackText,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Radio<String>(
                    value: "Individual",
                    groupValue: selectedType,
                    onChanged: (value) {
                      setState(() {
                        selectedType = value!;
                      });
                    },
                  ),
                  Text(
                    "Individual",
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColor.blackText,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: Sizes.height * .02),
            nameField(
              text: selectedType == "Individual"
                  ? "Party Name"
                  : "Company Name",
              child: CommonTextField(
                controller: companyNameController,
                hintText: selectedType == "Individual"
                    ? "Party Name"
                    : "Company Name",
              ),
            ),
            SizedBox(height: Sizes.height * .02),
            selectedType != "Individual"
                ? nameField(
                    text: "Owner Name",
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: CommonDropdownField<String>(
                            hintText: "",
                            value: titleList.contains(selectedTitle)
                                ? selectedTitle
                                : null,
                            items: titleList.map((title) {
                              return DropdownMenuItem(
                                value: title,
                                child: Text(title),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedType = value!;

                                if (selectedType == "Business") {
                                  selectedTitle = "Mr"; // valid for business
                                } else {
                                  selectedTitleParent =
                                      "S/O"; // valid for individual
                                }
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: CommonTextField(
                            hintText: "First Name",
                            controller: firstNameController,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: CommonTextField(
                            hintText: "Last Name",
                            controller: lastNameController,
                          ),
                        ),
                      ],
                    ),
                  )
                : nameField(
                    text: "Guardian Name",
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: CommonDropdownField<String>(
                            hintText: "",
                            value: titleParentList.contains(selectedTitleParent)
                                ? selectedTitleParent
                                : null,
                            items: titleParentList.map((title) {
                              return DropdownMenuItem(
                                value: title,
                                child: Text(title),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedType = value!;
                                if (selectedType == "Business") {
                                  selectedTitle = "Mr"; // valid for business
                                } else {
                                  selectedTitleParent =
                                      "S/O"; // valid for individual
                                }
                              });
                            },
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: CommonTextField(
                            hintText: "First Name",
                            controller: firstNameGuardianController,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: CommonTextField(
                            hintText: "Last Name",
                            controller: lastNameGuardianController,
                          ),
                        ),
                      ],
                    ),
                  ),
            SizedBox(height: Sizes.height * .02),
            nameField(
              text: "Email Address",
              child: CommonTextField(
                hintText: "Email",
                controller: emailController,
              ),
            ),
            SizedBox(height: Sizes.height * .02),
            nameField(
              text: "Phone",
              child: Row(
                children: [
                  Expanded(
                    child: CommonTextField(
                      hintText: "Mobile",
                      controller: mobileController,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: CommonTextField(
                      hintText: "Work Phone",
                      controller: workPhoneController,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.cusSupData == null) SizedBox(height: Sizes.height * .02),
            if (widget.cusSupData == null)
              nameField(
                text: "Opeing Balance",
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: CommonTextField(
                        controller: openingBalanceController,
                        hintText: 'Opening Balance',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: CommonDropdownField<String>(
                        value: _balanceType.contains(_selectedBalance)
                            ? _selectedBalance
                            : null,
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedBalance = newValue ?? 'Dr';
                          });
                        },
                        items: _balanceType.map<DropdownMenuItem<String>>((
                          String value,
                        ) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: AppColor.lightblack,
                                fontSize: 17,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: Sizes.height * .05),
            Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: Sizes.width * .4,
                child: TabBar(
                  controller: _tabController,
                  labelStyle: GoogleFonts.inter(
                    color: Color(0xFF565D6D),
                    fontSize: 14,
                  ),
                  unselectedLabelStyle: GoogleFonts.inter(
                    color: Color(0xFF565D6D),
                    fontSize: 14,
                  ),
                  indicatorColor: AppColor.blue,
                  tabs: const [
                    Tab(text: "Tax Details"),
                    Tab(text: "Address"),
                    Tab(text: "Documents"),
                  ],
                ),
              ),
            ),
            Divider(height: 10, color: Color(0xFFDEE1E6), thickness: 1.5),
            SizedBox(
              height: 180,
              width: Sizes.width,
              child: TabBarView(
                controller: _tabController,
                children: [
                  /// GST DETAILS TAB
                  Column(
                    children: [
                      SizedBox(height: Sizes.height * .02),
                      nameField(
                        text: "PAN",
                        child: CommonTextField(
                          hintText: "PAN",
                          controller: panController,
                        ),
                      ),
                      SizedBox(height: Sizes.height * .02),
                      nameField(
                        text: "GST Type",
                        child: CommonDropdownField<String>(
                          hintText: "--Select GST Type--",
                          value: gstTypeList.contains(selectedGstType)
                              ? selectedGstType
                              : null,
                          items: gstTypeList.map((gstType) {
                            return DropdownMenuItem(
                              value: gstType,
                              child: Text(gstType),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() => selectedGstType = val!);
                          },
                        ),
                      ),
                      SizedBox(height: Sizes.height * .02),
                      selectedGstType == "Unregistered Dealer"
                          ? Container()
                          : nameField(
                              text: "GST No.",
                              child: CommonTextField(
                                controller: gstNumberController,
                                hintText: "Enter GST Number",
                              ),
                            ),
                    ],
                  ),

                  /// ADDRESS TAB
                  Column(
                    children: [
                      SizedBox(height: Sizes.height * .02),
                      nameField(
                        text: "Address 1",
                        child: Row(
                          children: [
                            Expanded(
                              child: CommonSearchableDropdownField<String>(
                                controller: TextEditingController(
                                  text: selectedState?.item ?? "",
                                ),
                                hintText: "--Select State--",
                                suggestions: statesSuggestions
                                    .map(
                                      (x) => SearchFieldListItem<String>(
                                        x,
                                        item: x,
                                      ),
                                    )
                                    .toList(),
                                onSuggestionTap: (item) {
                                  setState(() {
                                    selectedState = item;
                                    citiesSuggestions =
                                        stateCities[item.searchKey] ?? [];
                                    selectedCity = null;
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 55),
                            Expanded(
                              child: CommonSearchableDropdownField<String>(
                                controller: TextEditingController(
                                  text: selectedCity?.item ?? "",
                                ),
                                hintText: "--Select City--",
                                suggestions: citiesSuggestions
                                    .map(
                                      (x) => SearchFieldListItem<String>(
                                        x,
                                        item: x,
                                      ),
                                    )
                                    .toList(),
                                onSuggestionTap: (item) {
                                  setState(() => selectedCity = item);
                                },
                              ),
                            ),
                            SizedBox(width: 55),
                            Expanded(
                              child: CommonTextField(
                                controller: cityDistrictController,
                                hintText: "Type City/District/Village",
                              ),
                            ),
                            SizedBox(width: 55),
                            Expanded(child: SizedBox()),
                          ],
                        ),
                      ),
                      SizedBox(height: Sizes.height * .02),
                      nameField(
                        text: "Address Line",
                        child: CommonTextField(
                          controller: addressLine1Controller,
                          hintText: "Address",
                        ),
                      ),
                      SizedBox(height: Sizes.height * .02),
                      nameField(
                        text: "Address Line",
                        child: CommonTextField(
                          controller: addressLine2Controller,
                          hintText: "Address",
                        ),
                      ),
                    ],
                  ),

                  /// UPLOAD DOCUMENT TAB
                  Column(
                    children: [
                      SizedBox(height: Sizes.height * .02),

                      /// UPLOAD DOCUMENT TAB
                      SizedBox(
                        height: 180 - Sizes.height * 0.02, // adjust if needed
                        child: GridView.builder(
                          scrollDirection: Axis.horizontal,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 16,
                                crossAxisSpacing: 16,
                                childAspectRatio: .17,
                              ),
                          itemCount: documents.length,
                          itemBuilder: (context, index) {
                            final doc = documents[index];
                            return Container(
                              key: ValueKey(doc), // 👈 add unique key
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: CommonTextField(
                                      key: ValueKey(
                                        'title_$index',
                                      ), // 👈 ensures new controller per item
                                      hintText: "Document Title ${index + 1}",
                                      initialValue: doc["duc_title"],
                                      onChanged: (val) =>
                                          documents[index]["duc_title"] = val
                                              .trim(),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(
                                        color: Color(0xFFD1D5DB),
                                      ),
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 18,
                                      ),
                                    ),
                                    onPressed: () {
                                      if (documents[index]["image"] != null) {
                                        _showImagePopup(
                                          documents[index]["image"]!,
                                          index,
                                        );
                                      } else {
                                        _pickImage(index);
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SvgPicture.asset(
                                          "assets/icons/upload.svg",
                                          height: 20,
                                          color:
                                              documents[index]["image"] != null
                                              ? Colors.green
                                              : AppColor.black,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          documents[index]["image"] != null
                                              ? "Doc Uploaded"
                                              : " Upload File     ",
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                documents[index]["image"] !=
                                                    null
                                                ? Colors.green
                                                : AppColor.black,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.keyboard_arrow_down_sharp,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: Icon(
                                      index != 0 ? Icons.delete : Icons.add,
                                      color: index != 0
                                          ? Colors.redAccent
                                          : Colors.blue,
                                    ),
                                    onPressed: index != 0
                                        ? () => _removeDocument(index)
                                        : _addNewDocument,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(top: 17, bottom: 24, left: 27, right: 27),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColor.grey, width: .5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            defaultButton(
              buttonColor: Color(0xff8947E5),
              text:
                  "${widget.cusSupData == null ? "Create" : "Update"} ${widget.isCustomer ? "Customer" : "Supplier"}",
              height: 40,
              width: 149,
              onTap: () => saveOrUpdate(),
            ),

            SizedBox(width: 18),
            defaultButton(
              buttonColor: Color(0xffE11414),
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

  void _showImagePopup(File imageFile, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text("Uploaded Document"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(imageFile, height: 250, fit: BoxFit.contain),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.grey),
                  label: const Text("Cancel"),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      documents[index]["image"] = null;
                    });
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: const Text(
                    "Remove",
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> saveOrUpdate() async {
    try {
      final dio = Dio();

      final formData = FormData();

      // ✅ Text fields
      formData.fields.addAll([
        MapEntry(
          "licence_no",
          Preference.getint(PrefKeys.licenseNo).toString(),
        ),
        MapEntry("branch_id", Preference.getString(PrefKeys.locationId)),
        MapEntry("customer_type", selectedType),
        MapEntry("title", selectedTitle),
        MapEntry("first_name", firstNameController.text.trim()),
        MapEntry("last_name", lastNameController.text.trim()),
        MapEntry("related", selectedTitleParent),
        MapEntry("parents", firstNameGuardianController.text.trim()),
        MapEntry("parents_last", lastNameGuardianController.text.trim()),
        MapEntry("company_name", companyNameController.text.trim()),
        MapEntry("email", emailController.text.trim()),
        MapEntry("phone", workPhoneController.text.trim()),
        MapEntry("mobile", mobileController.text.trim()),
        MapEntry("pan", panController.text.trim()),
        MapEntry("gst_type", selectedGstType ?? ""),
        MapEntry("gst_no", gstNumberController.text.trim()),
        MapEntry("address", cityDistrictController.text.trim()),
        MapEntry("city", selectedCity?.item ?? ""),
        MapEntry("state", selectedState?.item ?? ""),
        MapEntry(
          'opening_balance',
          openingBalanceController.text.trim().isEmpty
              ? "0"
              : _selectedBalance == "Cr"
              ? "${int.tryParse(openingBalanceController.text.trim())}"
              : "-${int.tryParse(openingBalanceController.text.trim())}",
        ),
        MapEntry("opening_type", _selectedBalance),
        if (widget.cusSupData == null)
          MapEntry(
            "closing_balance",
            openingBalanceController.text.trim().isEmpty
                ? "0"
                : _selectedBalance != "Cr"
                ? "${int.tryParse(openingBalanceController.text.trim())}"
                : "-${int.tryParse(openingBalanceController.text.trim())}",
          ),
        MapEntry("district", cityDistrictController.text.trim()),
        MapEntry("address_0", addressLine1Controller.text.trim()),
        MapEntry("address_1", addressLine2Controller.text.trim()),
      ]);

      // ✅ Documents (same key names multiple times)
      for (final doc in documents) {
        final title = doc["duc_title"]?.toString().trim();
        final imageFile = doc["image"];

        if (imageFile != null && title != null && title.isNotEmpty) {
          formData.files.add(
            MapEntry(
              'image',
              await MultipartFile.fromFile(
                imageFile.path,
                filename: imageFile.path.split('/').last,
              ),
            ),
          );
          formData.fields.add(MapEntry('duc_title', title));
        }
      }

      // ✅ Headers
      final headers = {
        'Accept': 'application/json',
        'Authorization': 'Bearer ${Preference.getString(PrefKeys.token)}',
        'licence_no': Preference.getint(PrefKeys.licenseNo),
      };

      // ✅ Send POST request
      final response = widget.cusSupData != null
          ? await dio.put(
              "${ApiService.baseurl}/${widget.isCustomer ? "customer" : "supplier"}/${widget.cusSupData?.id}",
              data: formData,
              options: Options(
                headers: headers,
                contentType: 'multipart/form-data',
              ),
            )
          : await dio.post(
              "${ApiService.baseurl}/${widget.isCustomer ? "customer" : "supplier"}",
              data: formData,
              options: Options(
                headers: headers,
                contentType: 'multipart/form-data',
              ),
            );

      if (response.statusCode == 200) {
        var data = json.decode("$response");
        if (data['status'] == true) {
          Navigator.pop(context, "data");
          showCustomSnackbarSuccess(context, data['message']);
        } else {
          showCustomSnackbarError(context, data['message']);
        }
      } else {
        showCustomSnackbarError(context, "Failed: ${response.statusMessage}");
      }
    } catch (e, s) {
      print("❌ Error: $e\n$s");
      showCustomSnackbarError(context, "Something went wrong: $e");
    }
  }
}
