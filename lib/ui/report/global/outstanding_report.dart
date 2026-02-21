import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/cussup_model.dart';
import 'package:ims/model/ledger_model.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/sizes.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';

class OutstandingReportScreen extends StatefulWidget {
  const OutstandingReportScreen({super.key});

  @override
  State<OutstandingReportScreen> createState() =>
      _OutstandingReportScreenState();
}

class _OutstandingReportScreenState extends State<OutstandingReportScreen> {
  List<LedgerListModel> ledgerList = [];
  List<Customer> customerList = [];
  bool loading = false;

  DateTime fromDate = DateTime(1900, 1, 1); // 🔥 very old date (fixed)
  DateTime toDate = DateTime.now(); // 🔥 default today

  final toCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    toCtrl.text = DateFormat("dd-MM-yyyy").format(toDate);
    loadAll();
  }

  Future<void> loadAll() async {
    setState(() => loading = true);
    await Future.wait([ledgerApi(), getCustomerApi()]);
    setState(() => loading = false);
  }

  Future ledgerApi() async {
    final apiFrom = DateFormat("yyyy-MM-dd").format(fromDate);
    final apiTo = DateFormat("yyyy-MM-dd").format(toDate);

    var response = await ApiService.fetchData(
      "get/ledgers?from_date=$apiFrom&to_date=$apiTo",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    List responseData = response['data'] ?? [];

    ledgerList = responseData
        .map((e) => LedgerListModel.fromJson(e))
        .where((e) => e.ledgerGroup == "Sundry Debtor")
        .toList();
  }

  // ---------------- CUSTOMER API ----------------
  Future getCustomerApi() async {
    var response = await ApiService.fetchData(
      "get/customer",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    List responseData = response['data'] ?? [];
    customerList = responseData.map((e) => Customer.fromJson(e)).toList();
  }

  Customer _findCustomer(LedgerListModel l) {
    return customerList.firstWhere(
      (c) =>
          c.companyName.trim().toLowerCase() ==
          (l.ledgerName ?? "").trim().toLowerCase(),
      orElse: () => Customer(
        id: '',
        licenceNo: 0,
        branchId: '',
        customerType: '',
        title: '',
        firstName: '',
        lastName: '',
        related: '',
        parents: '',
        parentsLast: '',
        companyName: '',
        email: '',
        mobile: '',
        pan: '',
        gstType: '',
        gstNo: '',
        address: '',
        city: '',
        state: '',
        openingBalance: 0,
        closingBalance: 0,
        address0: '',
        address1: '',
        documents: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        v: 0,
      ),
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColor.primary,
        title: Text(
          "Outstanding Report",
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.white,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= FILTER BAR =================
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 180,
                  child: TitleTextFeild(
                    readOnly: true,
                    titleText: "Outstanding At",
                    controller: toCtrl,
                    onTap: () async {
                      final d = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDate: toDate,
                      );
                      if (d != null) {
                        setState(() {
                          toDate = d;
                          toCtrl.text = DateFormat(
                            "dd-MM-yyyy",
                          ).format(toDate); // UI format
                        });
                        await loadAll(); // API yyyy-MM-dd bhejega
                      }
                    },
                    suffixIcon: const Icon(Icons.calendar_today, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                InkWell(
                  onTap: () async {},
                  child: Container(
                    width: 50,
                    height: 40,
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: AppColor.white,
                      border: Border.all(width: 1, color: AppColor.borderColor),
                    ),
                    child: Image.asset("assets/images/excel.png"),
                  ),
                ),
              ],
            ),
            SizedBox(height: Sizes.height * .02),

            // ================= TABLE =================
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _tableHeader(),
                    const Divider(height: 1),
                    Expanded(
                      child: loading
                          ? const Center(child: GlowLoader())
                          : ledgerList.isEmpty
                          ? const Center(child: Text("No Outstanding Found"))
                          : ListView.separated(
                              itemCount: ledgerList.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                              ),
                              itemBuilder: (context, i) {
                                return _tableRow(ledgerList[i], i);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _tableHeader() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          _h("Ledger Name", 3),
          _h("Group", 2),
          _h("Mobile", 2),
          _h("State", 2),
          _h("GST Type", 2),
          _h("Closing Balance", 2),
        ],
      ),
    );
  }

  Widget _h(String t, int f) => Expanded(
    flex: f,
    child: Text(t, style: _headStyle, textAlign: TextAlign.center),
  );

  static final TextStyle _headStyle = GoogleFonts.inter(
    color: Colors.white,
    fontWeight: FontWeight.w600,
    fontSize: 13,
    letterSpacing: .4,
  );

  // ---------------- ROW ----------------
  Widget _tableRow(LedgerListModel l, int index) {
    final bool even = index.isEven;
    final customer = _findCustomer(l);

    return Container(
      color: even ? const Color(0xffF9FAFB) : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      child: Row(
        children: [
          _c(l.ledgerName ?? "-", 3),
          _groupChip(l.ledgerGroup ?? "-", 2),
          _c(l.contactNo?.toString() ?? "-", 2),
          _c(l.state ?? "-", 2),
          _c(customer.gstType.isEmpty ? "-" : customer.gstType, 2),
          _c(l.closingBalance?.toString() ?? "0", 2),
        ],
      ),
    );
  }

  Widget _c(String text, int f) => Expanded(
    flex: f,
    child: Center(
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w500,
          fontSize: 13,
          color: const Color(0xff374151),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );

  Widget _groupChip(String group, int f) => Expanded(
    flex: f,
    child: Align(
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          group,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Colors.orange.shade700,
          ),
        ),
      ),
    ),
  );
}
