import 'package:flutter/material.dart';
import 'package:ims/utils/api.dart';
import 'package:ims/utils/prefence.dart';
import 'package:ims/utils/snackbar.dart';
import 'package:ims/utils/state_cities.dart';
import 'package:ims/utils/textfield.dart';
import 'package:searchfield/searchfield.dart';

Future<void> showCreateCustomerDialog({
  required BuildContext context,
  required Function() onCustomerCreated,
  bool? isCustomer,
}) async {
  final nameCtrl = TextEditingController();
  final stateCtrl = TextEditingController();

  List<String> statesSuggestions = stateCities.keys.toList();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text('Create ${isCustomer ?? true ? "Customer" : "Supplier"}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CommonTextField(controller: nameCtrl, hintText: 'Name'),

          const SizedBox(height: 12),

          CommonSearchableDropdownField<String>(
            hintText: "Select State",
            controller: stateCtrl,
            suggestions: statesSuggestions
                .map((e) => SearchFieldListItem<String>(e))
                .toList(),
            onSuggestionTap: (val) {
              stateCtrl.text = val.searchKey;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),

        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) {
              showCustomSnackbarError(context, "Enter customer name");
              return;
            }

            if (stateCtrl.text.trim().isEmpty) {
              showCustomSnackbarError(context, "Select state");
              return;
            }

            final res = await ApiService.postData(
              isCustomer ?? true ? "customer" : "supplier",
              {
                "customer_type": "Individual",
                'company_name': nameCtrl.text.trim(),
                'state': stateCtrl.text.trim(),
                'licence_no': Preference.getint(PrefKeys.licenseNo).toString(),
                'branch_id': Preference.getString(PrefKeys.locationId),
              },
              licenceNo: Preference.getint(PrefKeys.licenseNo),
            );

            if (res != null && res['status'] == true) {
              showCustomSnackbarSuccess(context, '${isCustomer ?? true ? "Customer" : "Supplier"} created');

              onCustomerCreated();

              Navigator.pop(context);
            } else {
              showCustomSnackbarError(context, res?['message'] ?? 'Failed');
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
}
