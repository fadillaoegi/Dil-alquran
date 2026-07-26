import 'package:flutter/widgets.dart';

// Lebar acuan desain (ukuran ponsel standar).
const double _kBaseDesignWidth = 375.0;

// Ambang layar besar (tablet ke atas).
const double kTabletBreakpoint = 600.0;

// Lebar konten maksimum agar tampilan tidak melebar berlebihan di layar besar.
const double kMaxContentWidth = 640.0;

extension ResponsiveContext on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  bool get isSmallScreen => screenWidth < 360.0;
  bool get isTablet => screenWidth >= kTabletBreakpoint;

  // Skala ukuran mengikuti lebar layar, dibatasi agar tidak terlalu kecil
  // di layar mungil maupun terlalu besar di layar lebar.
  double scale(double size) {
    final factor = (screenWidth / _kBaseDesignWidth).clamp(0.85, 1.2);
    return size * factor;
  }
}
