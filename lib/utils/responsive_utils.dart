import 'package:flutter/material.dart';

/// Responsive utility class for consistent mobile/tablet/desktop layouts
class ResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  // Screen size checks
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;

  // Responsive padding
  static double getPagePadding(BuildContext context) {
    if (isMobile(context)) return 16.0;
    if (isTablet(context)) return 20.0;
    return 24.0;
  }

  static double getCardPadding(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    return 20.0;
  }

  static double getElementSpacing(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 16.0;
    return 20.0;
  }

  // Responsive font sizes
  static double getH1Size(BuildContext context) {
    if (isMobile(context)) return 24.0;
    if (isTablet(context)) return 28.0;
    return 32.0;
  }

  static double getH2Size(BuildContext context) {
    if (isMobile(context)) return 20.0;
    if (isTablet(context)) return 22.0;
    return 24.0;
  }

  static double getH3Size(BuildContext context) {
    if (isMobile(context)) return 18.0;
    if (isTablet(context)) return 19.0;
    return 20.0;
  }

  static double getBodySize(BuildContext context) {
    if (isMobile(context)) return 14.0;
    if (isTablet(context)) return 15.0;
    return 16.0;
  }

  static double getCaptionSize(BuildContext context) {
    if (isMobile(context)) return 12.0;
    if (isTablet(context)) return 13.0;
    return 14.0;
  }

  // Responsive dimensions
  static double getButtonHeight(BuildContext context) {
    if (isMobile(context)) return 48.0;
    return 52.0;
  }

  static double getIconSize(BuildContext context) {
    if (isMobile(context)) return 20.0;
    if (isTablet(context)) return 22.0;
    return 24.0;
  }

  static double getAvatarRadius(BuildContext context) {
    if (isMobile(context)) return 20.0;
    if (isTablet(context)) return 22.0;
    return 24.0;
  }

  // Dialog sizing
  static double getDialogWidth(BuildContext context) {
    if (isMobile(context)) return MediaQuery.of(context).size.width - 32;
    if (isTablet(context)) return 500;
    return 600;
  }

  static EdgeInsets getDialogPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(16);
    }
    return const EdgeInsets.all(24);
  }

  // Layout helpers
  static int getGridCrossAxisCount(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  static bool shouldStackButtons(BuildContext context) {
    return isMobile(context);
  }

  // Responsive widget builder
  static Widget responsive({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }
}
