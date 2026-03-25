import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/misc_model.dart';
import 'package:ims/ui/group/terms_contions.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/textfield.dart';

/// ----------------------------------------------------
///          NOTES SECTION (handles Notes + Terms)
/// ----------------------------------------------------
class GlobalNotesSection extends StatefulWidget {
  final List<String> initialTerms; // <-- NEW

  final Function(List<String>) onTermsChanged;
  final TextEditingController? noteController;
  final String? termId;

  const GlobalNotesSection({
    super.key,
    required this.initialTerms,
    required this.onTermsChanged,
    this.noteController,
    this.termId,
  });

  @override
  State<GlobalNotesSection> createState() => _GlobalNotesSectionState();
}

class _GlobalNotesSectionState extends State<GlobalNotesSection> {
  bool expanded = false;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => expanded = !expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    expanded ? Icons.remove : Icons.add,
                    size: 20,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    "Add Noted",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.deepPurple,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (expanded)
            TitleTextFeild(
              controller: widget.noteController,
              titleText: "Notes",
              maxLines: 3,
            ),
          NotesTcExpandable(
            title: "Terms and Conditions",
            miscId: widget.termId ?? "2",
            initialList: widget.initialTerms, // <-- NEW
            onSelectedChanged: widget.onTermsChanged,
          ),
        ],
      ),
    );
  }
}

/// ----------------------------------------------------
///          EXPANDABLE NOTES + TERMS PICKER
/// ----------------------------------------------------
class NotesTcExpandable extends StatefulWidget {
  final String title;
  final String miscId;
  final List<String> initialList; // <-- NEW
  final Function(List<String>) onSelectedChanged;

  const NotesTcExpandable({
    super.key,
    required this.title,
    required this.miscId,
    required this.initialList,
    required this.onSelectedChanged,
  });

  @override
  State<NotesTcExpandable> createState() => _NotesTcExpandableState();
}

class _NotesTcExpandableState extends State<NotesTcExpandable> {
  bool expanded = false;
  List<MiscItem> list = [];
  List<String> selected = [];

  @override
  void initState() {
    super.initState();

    /// Pre-fill selected notes/terms during edit mode
    selected = List.from(widget.initialList);
    if (selected.isNotEmpty) {
      expanded = true;
    }
    _fetch(); // load all misc items
  }

  void _openAddDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: SizedBox(
          width: 700,
          height: 550,
          child: ManageTermsConditionsScreen(
            transactionId: widget.miscId, // 👈 important
          ),
        ),
      ),
    ).then((updateData) {
      if (updateData != null) {
        _fetch(); // refresh after closing
      }
    });
  }

  void _removeSelected(String name) {
    setState(() {
      selected.remove(name);
      widget.onSelectedChanged(selected);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => expanded = !expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(
                  expanded ? Icons.remove : Icons.add,
                  size: 20,
                  color: Colors.deepPurple,
                ),
                const SizedBox(width: 6),
                Text(
                  "Add ${widget.title}",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (expanded)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _openAddDialog,
                  child: Row(
                    children: [
                      Icon(Icons.add, color: AppColor.primary),
                      const SizedBox(width: 6),
                      Text(
                        "Create New ${widget.title}",
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w500,
                          color: AppColor.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                /// Selected notes/terms list
                ...selected.map((name) {
                  return Card(
                    child: ListTile(
                      title: Text(name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeSelected(name),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),

        const SizedBox(height: 10),
      ],
    );
  }

  Future<void> _fetch() async {
    final res = await ApiService.fetchData(
      "get/term", // 👈 NEW API
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res != null && res["status"] == true) {
      final fullList = res["data"] as List;

      final filtered = fullList.where((item) {
        return (item["id"] ?? "").toString() == widget.miscId.toString();
      }).toList();

      setState(() {
        // 👉 dropdown list ke liye
        list = filtered
            .map(
              (e) => MiscItem(
                id: e["id"],
                name: e["remark"],
                miscId: widget.miscId,
              ),
            )
            .toList();

        // 🔥 AUTO SELECT ACTIVE TERMS
        selected = filtered
            .where((e) => e["status"] == true)
            .map<String>((e) => e["remark"].toString())
            .toList();

        widget.onSelectedChanged(selected);
      });
    }
  }
}
