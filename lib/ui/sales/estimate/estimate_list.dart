import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/component/side_menu.dart';
import 'package:ims/ui/sales/estimate/widgets/estimate_pdf.dart';
import 'package:ims/utils/button.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/textfield.dart';
import 'package:intl/intl.dart';
import 'package:ims/ui/sales/estimate/models/estimateget_model.dart';
import 'package:ims/ui/sales/estimate/data/estimate_repository.dart';
import 'package:ims/ui/sales/estimate/estimate_screen.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/snackbar.dart';

class EstimateListScreen extends StatefulWidget {
  const EstimateListScreen({super.key});

  @override
  State<EstimateListScreen> createState() => _EstimateListScreenState();
}

class _EstimateListScreenState extends State<EstimateListScreen> {
  final EstimateRepository repo = EstimateRepository();

  List<EstimateData> estimates = [];
  List<EstimateData> filtered = [];
  bool loading = true;

  EstimateData? activeRow;
  final searchCtrl = TextEditingController();

  // Day filters
  String dateRange = "Last 365 Days";
  final Map<String, int> dayFilters = {
    "Last 1 Day": 1,
    "Last 7 Days": 7,
    "Last 30 Days": 30,
    "Last 180 Days": 180,
    "Last 365 Days": 365,
  };

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    loading = true;
    setState(() {});

    estimates = await repo.getEstimates();
    _applyFilters();

    loading = false;
    setState(() {});
  }

  // ---------------- APPLY FILTERS (DATE + SEARCH) ----------------
  void _applyFilters() {
    int days = dayFilters[dateRange] ?? 365;

    DateTime now = DateTime.now();
    DateTime minDate = now.subtract(Duration(days: days));

    String q = searchCtrl.text.toLowerCase().trim();

    filtered = estimates.where((e) {
      bool dateOk =
          e.estimateDate.isAfter(minDate) ||
          e.estimateDate.isAtSameMomentAs(minDate);

      bool searchOk =
          q.isEmpty ||
          e.customerName.toLowerCase().contains(q) ||
          "${e.prefix}-${e.no}".toLowerCase().contains(q);

      return dateOk && searchOk;
    }).toList();
  }

  void search(String _) {
    _applyFilters();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.white,
      appBar: AppBar(
        elevation: 0.4,
        backgroundColor: AppColor.white,
        title: Text(
          "Estimate",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColor.blackText,
          ),
        ),
        iconTheme: IconThemeData(color: AppColor.blackText),
      ),
      drawer: SideMenu(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _pageLayout(),
    );
  }

  // ---------------- PAGE LAYOUT ----------------
  Widget _pageLayout() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _topFilters(),
          const SizedBox(height: 20),
          _headerRow(),
          Expanded(child: _dataSection()),
        ],
      ),
    );
  }

  // ---------------- TOP FILTER ROW ----------------
  Widget _topFilters() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: CommonTextField(
            controller: searchCtrl,
            onChanged: search,
            hintText: "Search Estimate...",
          ),
        ),

        const SizedBox(width: 12),

        _dateFilterDropdown(),
        const Spacer(flex: 3),

        defaultButton(
          height: 40,
          width: 160,
          buttonColor: AppColor.blue,
          onTap: () async {
            var data = await pushTo(CreateEstimateFullScreen());
            if (data == "update") {
              load();
            }
          },
          text: "Create Estimate",
        ),
      ],
    );
  }

  // ---------------- DATE DROPDOWN (WORKING FILTER) ----------------
  Widget _dateFilterDropdown() {
    return Expanded(
      flex: 1,
      child: PopupMenuButton<String>(
        onSelected: (value) {
          dateRange = value;
          _applyFilters();
          setState(() {});
        },
        itemBuilder: (context) {
          return dayFilters.keys.map((label) {
            return PopupMenuItem(
              value: label,
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }).toList();
        },
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: Colors.black12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateRange,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ROW ----------------
  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColor.primary,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(7),
          topLeft: Radius.circular(7),
        ),
      ),
      child: Row(
        children: [
          _head("DATE", flex: 2),
          _head("ESTIMATE NUMBER", flex: 3),
          _head("PARTY NAME", flex: 3),
          _head("AMOUNT", flex: 2),
          _head("STATUS", flex: 2),
        ],
      ),
    );
  }

  Widget _head(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  // ---------------- DATA SECTION ----------------
  Widget _dataSection() {
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.hourglass_empty, size: 46, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              "No Transactions Matching the current filter",
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) => _rowTile(filtered[i]),
    );
  }

  // ---------------- EACH ROW TILE ----------------
  Widget _rowTile(EstimateData e) {
    final selected = activeRow?.id == e.id;

    return InkWell(
      onDoubleTap: () {
        setState(() => activeRow = selected ? null : e);
      },
      child: Container(
        height: 55,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: selected ? const Color(0xff6E56CF) : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(0),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                DateFormat("dd MMM yyyy").format(e.estimateDate),
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),

            Expanded(
              flex: 3,
              child: Text(
                "${e.prefix}-${e.no}",
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),

            Expanded(
              flex: 3,
              child: Text(
                e.customerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 14),
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                "₹${e.totalAmount.toStringAsFixed(2)}",
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.green.shade700,
                ),
              ),
            ),

            Expanded(
              flex: 2,
              child: Text(
                "Pending",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade700,
                ),
              ),
            ),

            if (selected) ...[
              const SizedBox(width: 12),
              _actionBtn(Icons.visibility, Colors.blue, () {
                print(e.customerName);
                generateEstimatePdf(e);
              }),
              const SizedBox(width: 6),
              _actionBtn(Icons.edit, Colors.orange, () {
                pushTo(CreateEstimateFullScreen(estimateData: e));
              }),
              const SizedBox(width: 6),
              _actionBtn(Icons.delete, Colors.red, () => _delete(e.id)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  void _delete(String id) async {
    final ok = await repo.deleteEstimate(id);
    if (ok) {
      showCustomSnackbarSuccess(context, "Estimate deleted");
      load();
    } else {
      showCustomSnackbarError(context, "Delete failed");
    }
  }
}
