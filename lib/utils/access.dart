import 'dart:convert';
import 'package:ims/utils/prefence.dart';

bool isAdmin() {
  return Preference.getString(PrefKeys.userType).toLowerCase() == "admin";
}

bool hasMenuAccess(String menuName) {
  if (isAdmin()) return true;

  final data = Preference.getString(PrefKeys.rights);
  if (data.isEmpty) return false;

  List rights = [];

  try {
    final decoded = jsonDecode(data);

    if (decoded is List) {
      rights = decoded;
    } else if (decoded is String) {
      rights = decoded
          .replaceAll('[', '')
          .replaceAll(']', '')
          .split(',')
          .map((e) => e.trim())
          .toList();
    }
  } catch (e) {
    // fallback अगर गलत format हो
    rights = data
        .replaceAll('[', '')
        .replaceAll(']', '')
        .split(',')
        .map((e) => e.trim())
        .toList();
  }

  return rights.contains(menuName);
}

bool hasModuleAccess(String module, String action) {
  // 🔥 Admin → full access
  if (isAdmin()) return true;

  final data = Preference.getString(PrefKeys.singleRights);
  if (data.isEmpty) return false;

  final List rights = jsonDecode(data);

  final moduleData = rights.firstWhere(
    (e) => e['module'] == module,
    orElse: () => null,
  );

  if (moduleData == null) return false;

  return moduleData[action] == true;
}
