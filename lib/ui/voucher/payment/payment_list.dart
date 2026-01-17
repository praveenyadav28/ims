import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/payment_model.dart';
import 'package:ims/ui/voucher/payment/create.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/prefence.dart';
import 'package:intl/intl.dart';

class PaymentListTableScreen extends StatefulWidget {
  const PaymentListTableScreen({super.key});

  @override
  State<PaymentListTableScreen> createState() => _PaymentListTableScreenState();
}

class _PaymentListTableScreenState extends State<PaymentListTableScreen> {
  bool loading = false;
  List<PaymentModel> list = [];

  @override
  void initState() {
    super.initState();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    setState(() => loading = true);

    final res = await ApiService.fetchData(
      'get/payment',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    list = (res['data'] as List).map((e) => PaymentModel.fromJson(e)).toList();

    setState(() => loading = false);
  }

  Future<void> deletePayment(String id) async {
    await ApiService.deleteData(
      'payment/$id',
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );
    fetchPayments();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColor.white,
        iconTheme: IconThemeData(color: AppColor.black),
        title: Text(
          "Payments",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.blackText,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------- TOP BAR ----------
            Row(
              children: [
                const Icon(Icons.currency_rupee, color: Colors.deepPurple),
                const SizedBox(width: 6),
                Text(
                  "Payment Received",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: Colors.deepPurple,
                  ),
                ),
                const Spacer(),
                // OutlinedButton.icon(
                //   onPressed: () {},
                //   icon: const Icon(Icons.filter_alt_outlined),
                //   label: const Text("Apply Filter"),
                // ),
                const SizedBox(width: 12),
                defaultButton(
                  onTap: () {
                    pushTo(PaymentEntry());
                  },
                  buttonColor: AppColor.blue,
                  text: "Create Payment",
                  height: 40,
                  width: 150,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ---------- TABLE ----------
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColor.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColor.borderColor),
                ),
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                    ? const Center(
                        child: Text(
                          "No Transactions Matching the current filter",
                        ),
                      )
                    : Column(
                        children: [
                          _tableHeader(),
                          const Divider(height: 1),
                          Expanded(
                            child: ListView.separated(
                              itemCount: list.length,
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final p = list[i];
                                return _tableRow(p);
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

  // ---------- HEADER ----------
  Widget _tableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      color: Colors.deepPurple.withOpacity(.08),
      child: Row(
        children: const [
          Expanded(flex: 2, child: Text("Date")),
          Expanded(flex: 3, child: Text("Payment Number")),
          Expanded(flex: 3, child: Text("Party Name")),
          Expanded(flex: 2, child: Text("Amount")),
          Expanded(flex: 3, child: Text("Narration")),
          SizedBox(width: 70),
        ],
      ),
    );
  }

  // ---------- ROW ----------
  Widget _tableRow(PaymentModel p) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(DateFormat('yyyy-MM-dd').format(p.date)),
          ),
          Expanded(flex: 3, child: Text("${p.prefix} ${p.voucherNo}")),
          Expanded(flex: 3, child: Text(p.supplierName)),
          Expanded(
            flex: 2,
            child: Text(
              "₹ ${p.amount}",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(p.note, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  // TODO: OPEN EDIT
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => confirmDelete(p.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- DELETE DIALOG ----------
  void confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Payment"),
        content: const Text("Are you sure you want to delete this payment?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              await deletePayment(id);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
