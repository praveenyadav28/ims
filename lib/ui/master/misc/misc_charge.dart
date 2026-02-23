import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/ui/master/misc/misc_charge_model.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/textfield.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/ui/group/hsn.dart';

class CreateMiscCharge extends StatefulWidget {
  final MiscChargeModelList? editData;
  const CreateMiscCharge({super.key, this.editData});

  @override
  State<CreateMiscCharge> createState() => _CreateMiscChargeState();
}

class _CreateMiscChargeState extends State<CreateMiscCharge> {
  final TextEditingController nameCtrl = TextEditingController();

  // ========= POSTING ACCOUNT ==========
  List<Map<String, dynamic>> ledgerList = [];
  List<String> postingAccountNames = [];
  Map<String, String> postingAccountIdMap = {}; // name -> id

  String? selectedPostingName;
  String? selectedPostingId;

  // ========= HSN + GST ==========
  List<Map<String, dynamic>> hsnList = [];
  List<String> hsnNames = [];
  String? selectedHsn;

  final TextEditingController igstCtrl = TextEditingController(text: "0");
  final TextEditingController cgstCtrl = TextEditingController(text: "0");
  final TextEditingController sgstCtrl = TextEditingController(text: "0");

  bool applyTax = false;
  bool printInInvoice = true;
  bool rePaymentRequired = false;
  String? _pendingLedgerName;
  String? _pendingHsn;

  @override
  void initState() {
    if (widget.editData != null) {
      final e = widget.editData!;
      nameCtrl.text = e.name;
      _pendingLedgerName = e.ledgerName; // ← store temporarily
      _pendingHsn = e.hsn ?? ""; // ← store temporarily

      applyTax = e.tax;
      printInInvoice = e.printIn;
      rePaymentRequired = e.rePay;

      igstCtrl.text = e.gst?.toString() ?? "0";
    }

    super.initState();
    _loadHsnCodes();
    _loadPostingAccounts();
  }

  bool get isEdit => widget.editData != null;

  // ===================== LOAD LEDGER (POSTING ACCOUNTS) =====================
  Future<void> _loadPostingAccounts() async {
    try {
      final resp = await ApiService.fetchData(
        "get/ledger",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      if (resp != null && resp['status'] == true) {
        ledgerList = List<Map<String, dynamic>>.from(resp['data']);

        postingAccountNames.clear();
        postingAccountIdMap.clear();

        // Filter only ledgers with group = Misc Charges
        for (var e in ledgerList) {
          if ((e["ledger_group"] ?? "").toString() == "Misc Charges") {
            final name = e["ledger_name"].toString();
            final id = e["_id"].toString();

            postingAccountNames.add(name);
            postingAccountIdMap[name] = id;
          }
        }
      }

      setState(() {
        if (_pendingLedgerName != null &&
            postingAccountNames.contains(_pendingLedgerName)) {
          selectedPostingName = _pendingLedgerName;
          selectedPostingId = postingAccountIdMap[_pendingLedgerName];
          _pendingLedgerName = null;
        }
      });
    } catch (e) {
    }
  }

  // ======================= LOAD HSN CODES =======================
  Future<void> _loadHsnCodes() async {
    try {
      final resp = await ApiService.fetchData(
        "get/hsn",
        licenceNo: Preference.getint(PrefKeys.licenseNo),
      );

      if (resp != null && resp['status'] == true) {
        hsnList = List<Map<String, dynamic>>.from(resp['data']);
        hsnNames = hsnList.map((e) => e['name'].toString()).toList();
      }
      setState(() {
        if (_pendingHsn != null && hsnNames.contains(_pendingHsn)) {
          selectedHsn = _pendingHsn;
          _pendingHsn = null;
        }
      });
    } catch (e) {
     }
  }

  // ===================== ON HSN SELECT =====================
  void _onHsnSelected(String? value) {
    if (value == null) return;

    setState(() {
      selectedHsn = value;

      final data = hsnList.firstWhere(
        (e) => e['name'] == value,
        orElse: () => {},
      );

      igstCtrl.text = data["igst"]?.toString() ?? "0";
      cgstCtrl.text = data["cgst"]?.toString() ?? "0";
      sgstCtrl.text = data["sgst"]?.toString() ?? "0";
    });
  }

  Future<void> _saveMiscCharge() async {
    if (nameCtrl.text.trim().isEmpty) {
      showCustomSnackbarError(context, "Enter charge name");
      return;
    }

    if (selectedPostingId == null || selectedPostingName == null) {
      showCustomSnackbarError(context, "Select posting account");
      return;
    }

    final payload = {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),

      // Posting Account
      "ledger_id": selectedPostingId, // _id of ledger
      "ledger_name": selectedPostingName, // ledger_name
      // Charge name
      "name": nameCtrl.text.trim(),

      // Boolean fields
      "re_pay": rePaymentRequired,
      "print_in": printInInvoice,
      "tax": applyTax,

      // Optional HSN + GST
      "hsn": selectedHsn ?? "",
      "gst": applyTax ? double.tryParse(igstCtrl.text) ?? 0 : 0,
    };
    final res = await ApiService.postData(
      "misccharge",
      payload,
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res != null && res["status"] == true) {
      Navigator.pop(context, "refresh");
      showCustomSnackbarSuccess(context, res["message"]);
    } else {
      showCustomSnackbarError(context, res?["message"] ?? "Error");
    }
  }

  // ===================== UI =====================
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
          "Misc-Charge Master",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.blackText,
          ),
        ),
        actions: [
          Center(
            child: defaultButton(
              width: 120,
              height: 40,
              buttonColor: AppColor.blue,
              text: isEdit ? "Update" : "Save",
              onTap: isEdit ? _updateMiscCharge : _saveMiscCharge,
            ),
          ),
          SizedBox(width: 10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // NAME FIELD
              nameField(
                text: "Name",
                child: CommonTextField(controller: nameCtrl, hintText: ""),
              ),
              const SizedBox(height: 20),

              // Posting Account (with ID mapping)
              nameField(
                text: "Posting Account",
                child: CommonDropdownField<String>(
                  value: selectedPostingName,
                  items: postingAccountNames
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedPostingName = v;
                      selectedPostingId = postingAccountIdMap[v]; // get _id
                    });
                  },

                  hintText: "Select Posting Account",
                ),
              ),
              const SizedBox(height: 20),

              // HSN SECTION
              if (applyTax)
                nameField(
                  text: "HSN Code",
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CommonDropdownField<String>(
                          value: selectedHsn,
                          items: hsnNames.map((e) {
                            return DropdownMenuItem(value: e, child: Text(e));
                          }).toList(),
                          onChanged: _onHsnSelected,
                          hintText: "Select HSN",
                        ),
                      ),

                      const SizedBox(width: 15),

                      // ADD HSN BUTTON
                      addDefaultButton(() async {
                        await showDialog(
                          context: context,
                          builder: (_) => Dialog(
                            child: SizedBox(
                              width: 400,
                              height: 500,
                              child: const AddHsnScreen(),
                            ),
                          ),
                        );
                        await _loadHsnCodes();
                      }),
                    ],
                  ),
                ),
              if (applyTax) const SizedBox(height: 20),

              // GST FIELDS
              if (applyTax)
                nameField(
                  text: "GST",
                  child: Row(
                    children: [
                      Expanded(
                        child: TitleTextFeild(
                          titleText: "IGST",
                          readOnly: true,
                          controller: igstCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TitleTextFeild(
                          titleText: "CGST",
                          readOnly: true,
                          controller: cgstCtrl,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TitleTextFeild(
                          titleText: "SGST",
                          readOnly: true,
                          controller: sgstCtrl,
                        ),
                      ),
                    ],
                  ),
                ),
              if (applyTax) const SizedBox(height: 20),

              // CHECKBOXES
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: CheckboxListTile(
                        value: applyTax,
                        onChanged: (v) => setState(() => applyTax = v!),
                        title: const Text("Apply Tax"),
                      ),
                    ),
                  ),
                  Spacer(),
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: CheckboxListTile(
                        value: printInInvoice,
                        onChanged: (v) => setState(() => printInInvoice = v!),
                        title: const Text("Print in Invoice"),
                      ),
                    ),
                  ),
                  Spacer(),
                  Expanded(
                    flex: 2,
                    child: Card(
                      child: CheckboxListTile(
                        value: rePaymentRequired,
                        onChanged: (v) =>
                            setState(() => rePaymentRequired = v!),
                        title: const Text("Re-Payment Required"),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateMiscCharge() async {
    if (nameCtrl.text.trim().isEmpty) {
      showCustomSnackbarError(context, "Enter charge name");
      return;
    }

    if (selectedPostingId == null) {
      showCustomSnackbarError(context, "Select posting account");
      return;
    }

    final payload = {
      "licence_no": Preference.getint(PrefKeys.licenseNo),
      "branch_id": Preference.getString(PrefKeys.locationId),
      "ledger_id": selectedPostingId,
      "ledger_name": selectedPostingName,
      "name": nameCtrl.text.trim(),
      "re_pay": rePaymentRequired,
      "print_in": printInInvoice,
      "tax": applyTax,
      "hsn": selectedHsn ?? "",
      "gst": applyTax ? double.tryParse(igstCtrl.text) ?? 0 : 0,
    };

    final res = await ApiService.putData(
      "misccharge/${widget.editData!.id}",
      payload,
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res["status"] == true) {
      showCustomSnackbarSuccess(context, "Misc Charge Updated");
      Navigator.pop(context, "refresh");
    } else {
      showCustomSnackbarError(context, res?["message"] ?? "Error");
    }
  }
}
