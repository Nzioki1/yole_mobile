import 'package:flutter/widgets.dart';

class Spacing {
  static const s = 8.0;
  static const m = 12.0;
  static const l = 16.0;
  static const xl = 24.0;

  static EdgeInsets p(double v) => EdgeInsets.all(v);
  static EdgeInsets ph(double v) => EdgeInsets.symmetric(horizontal: v);
  static EdgeInsets pv(double v) => EdgeInsets.symmetric(vertical: v);
}