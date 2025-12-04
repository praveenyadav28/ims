import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/component/side_menu.dart';
import 'package:ims/ui/sales/estimate/estimate_screen.dart';
import 'package:ims/utils/navigation.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:intl/intl.dart';
import 'package:ims/ui/sales/estimate/models/estimateget_model.dart';
import 'package:ims/ui/sales/estimate/data/estimate_repository.dart';

class EstimateListScreen extends StatefulWidget {
  const EstimateListScreen({super.key});

  @override
  State<EstimateListScreen> createState() => _EstimateListScreenState();
}

class _EstimateListScreenState extends State<EstimateListScreen> {
  final EstimateRepository repo = EstimateRepository();
  bool loading = true;
  List<EstimateData> estimates = [];
  List<EstimateData> filtered = [];

  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    estimates = await repo.getEstimates();
    filtered = List.from(estimates);
    setState(() => loading = false);
  }

  void search(String q) {
    q = q.toLowerCase().trim();
    filtered = estimates.where((e) {
      return e.customerName.toLowerCase().contains(q) ||
          "${e.prefix}-${e.no}".toLowerCase().contains(q);
    }).toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF2F4F7),
      appBar: AppBar(
        elevation: 0.6,
        title: Text(
          "Estimates",
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
        actions: [
          Card(
            child: TextButton(
              onPressed: () {
                pushTo(CreateEstimateFullScreen());
              },
              child: Text("Create"),
            ),
          ),
        ],
      ),
      drawer: SideMenu(),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  // ---------------- BODY ---------------------
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _searchBar(),

          const SizedBox(height: 20),

          _headerRow(),

          const SizedBox(height: 4),

          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollBehavior().copyWith(scrollbars: true),
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (_, i) => _rowCard(filtered[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SEARCH BAR -------------------
  Widget _searchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      width: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black12),
      ),
      child: TextField(
        controller: searchCtrl,
        onChanged: search,
        decoration: InputDecoration(
          hintText: "Search (Customer / Estimate No)",
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade600, size: 20),
        ),
      ),
    );
  }

  // ---------------- HEADER (COLUMN TITLES) -------------------
  Widget _headerRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _headerCell("Customer", flex: 3),
          _headerCell("Estimate No", flex: 2),
          _headerCell("Date", flex: 2),
          _headerCell("Total", flex: 2),
          _headerCell("Total Item/Serive", flex: 2),
          _headerCell("Actions", flex: 2),
        ],
      ),
    );
  }

  Widget _headerCell(String name, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        name,
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  // ---------------- EACH ROW CARD (DESKTOP FRIENDLY) -------------------
  Widget _rowCard(EstimateData e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Row(
          children: [
            // -------- Customer --------
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.deepPurple.shade100,
                    child: Text(
                      e.customerName.isNotEmpty
                          ? e.customerName[0].toUpperCase()
                          : "?",
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      e.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // -------- Estimate No --------
            Expanded(
              flex: 2,
              child: Text(
                "${e.prefix}-${e.no}",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),

            // -------- Date --------
            Expanded(
              flex: 2,
              child: Text(
                DateFormat("dd MMM yyyy").format(e.estimateDate),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade700,
                ),
              ),
            ),

            // -------- Total --------
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

            // -------- Signature --------
            Expanded(
              flex: 2,
              child: Text(
                "${e.itemDetails.length + e.serviceDetails.length}",
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),

            // -------- ACTIONS --------
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _actionBtn(
                    icon: Icons.visibility,
                    tooltip: "View",
                    color: Colors.blue.shade600,
                    onTap: () {},
                  ),
                  const SizedBox(width: 6),
                  _actionBtn(
                    icon: Icons.edit,
                    tooltip: "Edit",
                    color: Colors.orange.shade700,
                    onTap: () {},
                  ),
                  const SizedBox(width: 6),
                  _actionBtn(
                    icon: Icons.delete,
                    tooltip: "Delete",
                    color: Colors.red.shade600,
                    onTap: () => _confirmDelete(e.id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
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
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Delete Estimate"),
          content: Text(
            "Are you sure you want to delete Estimate",
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(context);

                final success = await repo.deleteEstimate(id);

                if (success) {
                  showCustomSnackbarSuccess(context, "Estimate deleted");
                  load(); // reload list
                } else {
                  showCustomSnackbarError(context, "Delete failed");
                }
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }
}
