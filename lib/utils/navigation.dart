import 'package:flutter/material.dart';

class NavigationService {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
}

pushTo(Widget name) async {
  return await Navigator.push(
    NavigationService.navigatorKey.currentContext!,
    MaterialPageRoute(builder: (context) => name),
  );
}

void replaceRoute(Widget name) {
  Navigator.pushReplacement(NavigationService.navigatorKey.currentContext!,
      MaterialPageRoute(builder: (context) => name));
}

pushName(BuildContext context, String route) {
  return Navigator.pushNamed(context, route);
}

void pushNdRemove(Widget name) {
  Navigator.of(
    NavigationService.navigatorKey.currentContext!,
  ).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => name),
      (Route<dynamic> route) => false);
}
