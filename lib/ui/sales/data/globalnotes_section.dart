import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ims/model/misc_model.dart';
import 'package:ims/ui/group/notes.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/colors.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/textfield.dart';

/// ----------------------------------------------------
///          NOTES SECTION (handles Notes + Terms)
/// ----------------------------------------------------
class GlobalNotesSection extends StatelessWidget {
  final List<String> initialNotes; // <-- NEW
  final List<String> initialTerms; // <-- NEW

  final Function(List<String>) onNotesChanged;
  final Function(List<String>) onTermsChanged;

  const GlobalNotesSection({
    super.key,
    required this.initialNotes,
    required this.initialTerms,
    required this.onNotesChanged,
    required this.onTermsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          NotesTcExpandable(
            title: "Notes",
            miscId: "10",
            initialList: initialNotes, // <-- NEW
            onSelectedChanged: onNotesChanged,
          ),
          NotesTcExpandable(
            title: "Terms and Conditions",
            miscId: "11",
            initialList: initialTerms, // <-- NEW
            onSelectedChanged: onTermsChanged,
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

  Future<void> _fetch() async {
    final res = await ApiService.fetchData(
      "get/misc",
      licenceNo: Preference.getint(PrefKeys.licenseNo),
    );

    if (res != null && res["status"] == true) {
      final model = miscResponseFromJson(jsonEncode(res));

      setState(() {
        list = model.data.where((e) => e.miscId == widget.miscId).toList();
      });
    }
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
          child: AddNotesScreen(miscId: widget.miscId, name: widget.title),
        ),
      ),
    ).then((updateData) {
      if (updateData != null) {
        _fetch();
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

                /// Dropdown list of notes/terms
                CommonDropdownField<String>(
                  hintText: "Select ${widget.title}",
                  value: null,
                  items: list.map((item) {
                    return DropdownMenuItem(
                      value: item.id,
                      child: Text(item.name ?? ""),
                    );
                  }).toList(),
                  onChanged: (id) {
                    if (id != null) {
                      final item = list.firstWhere(
                        (e) => e.id == id,
                        orElse: () => list.first,
                      );

                      if (!selected.contains(item.name)) {
                        setState(() {
                          selected.add(item.name ?? "");
                          widget.onSelectedChanged(selected);
                        });
                      }
                    }
                  },
                ),

                const SizedBox(height: 12),

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
}
