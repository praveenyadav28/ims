import 'package:flutter/material.dart';

class Sizes {
  static BuildContext? _context;

  static double get width {
    assert(_context != null,
        'Sizes.init() must be called before accessing width.');
    return MediaQuery.of(_context!).size.width;
  }

  static double get height {
    assert(_context != null,
        'Sizes.init() must be called before accessing height.');
    return MediaQuery.of(_context!).size.height;
  }

  static void init(BuildContext context) {
    _context = context;
  }

  static double blockSizeHorizontal(double percent) {
    return (width * percent) / 100;
  }

  static double blockSizeVertical(double percent) {
    return (height * percent) / 100;
  }
}
