// lib/utils/responsive_utils.dart
import 'package:flutter/material.dart';

class ResponsiveUtils {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 1024;
  static const double desktopBreakpoint = 1440;

  // Device type detection
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < tabletBreakpoint;
  }

  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= tabletBreakpoint;
  }

  static bool isLargeDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  // Font size methods
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile * 1.4;
    } else if (isTablet(context)) {
      return tablet ?? mobile * 1.2;
    } else {
      return mobile;
    }
  }

  // Icon size methods
  static double getResponsiveIconSize(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile * 1.3;
    } else if (isTablet(context)) {
      return tablet ?? mobile * 1.15;
    } else {
      return mobile;
    }
  }

  // Spacing methods
  static double getResponsiveSpacing(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile * 1.5;
    } else if (isTablet(context)) {
      return tablet ?? mobile * 1.25;
    } else {
      return mobile;
    }
  }

  // Padding methods
  static EdgeInsets getResponsivePadding(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
    EdgeInsets? mobilePadding,
    EdgeInsets? tabletPadding,
    EdgeInsets? desktopPadding,
  }) {
    if (mobilePadding != null || tabletPadding != null || desktopPadding != null) {
      if (isDesktop(context)) {
        return desktopPadding ?? tabletPadding ?? mobilePadding ?? const EdgeInsets.all(24);
      } else if (isTablet(context)) {
        return tabletPadding ?? mobilePadding ?? const EdgeInsets.all(20);
      } else {
        return mobilePadding ?? const EdgeInsets.all(16);
      }
    } else {
      final basePadding = mobile ?? 16.0;
      if (isDesktop(context)) {
        return EdgeInsets.all(desktop ?? tablet ?? basePadding * 1.5);
      } else if (isTablet(context)) {
        return EdgeInsets.all(tablet ?? basePadding * 1.25);
      } else {
        return EdgeInsets.all(basePadding);
      }
    }
  }

  // Horizontal padding method
  static EdgeInsets getResponsiveHorizontalPadding(
    BuildContext context, {
    double? mobile,
    double? tablet,
    double? desktop,
  }) {
    final basePadding = mobile ?? 16.0;
    if (isDesktop(context)) {
      return EdgeInsets.symmetric(horizontal: desktop ?? tablet ?? basePadding * 1.5);
    } else if (isTablet(context)) {
      return EdgeInsets.symmetric(horizontal: tablet ?? basePadding * 1.25);
    } else {
      return EdgeInsets.symmetric(horizontal: basePadding);
    }
  }

  // Large screen detection
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  // Container builder
  static Widget buildResponsiveContainer({
    BuildContext? context,
    required Widget child,
    EdgeInsets? padding,
    double? maxWidth,
    BoxDecoration? decoration,
  }) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth ?? double.infinity,
      ),
      padding: padding,
      decoration: decoration,
      child: child,
    );
  }

  // Layout helpers
  static bool shouldCenterTitle(BuildContext context) {
    return isMobile(context);
  }

  // Responsive layout builder
  static Widget buildResponsiveLayout({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= tabletBreakpoint) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= mobileBreakpoint) {
          return tablet ?? mobile;
        } else {
          return mobile;
        }
      },
    );
  }

  // Grid helpers
  static int getResponsiveGridCount(BuildContext context, {
    int mobile = 1,
    int? tablet,
    int? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile * 3;
    } else if (isTablet(context)) {
      return tablet ?? mobile * 2;
    } else {
      return mobile;
    }
  }

  // Width helpers
  static double getResponsiveWidth(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile * 1.5;
    } else if (isTablet(context)) {
      return tablet ?? mobile * 1.25;
    } else {
      return mobile;
    }
  }

  // Height helpers  
  static double getResponsiveHeight(
    BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    if (isDesktop(context)) {
      return desktop ?? tablet ?? mobile * 1.3;
    } else if (isTablet(context)) {
      return tablet ?? mobile * 1.15;
    } else {
      return mobile;
    }
  }

  // Responsive text widget
  static Widget buildResponsiveText(
    String text, {
    required BuildContext context,
    TextStyle? style,
    double? mobileFontSize,
    double? tabletFontSize,
    double? desktopFontSize,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    final fontSize = getResponsiveFontSize(
      context,
      mobile: mobileFontSize ?? 14,
      tablet: tabletFontSize,
      desktop: desktopFontSize,
    );

    return Text(
      text,
      style: (style ?? const TextStyle()).copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  // Responsive text button
  static Widget buildResponsiveTextButton({
    required String text,
    required VoidCallback onPressed,
    required BuildContext context,
    TextStyle? textStyle,
    double? mobileFontSize,
    double? tabletFontSize,
    double? desktopFontSize,
    EdgeInsets? padding,
  }) {
    final fontSize = getResponsiveFontSize(
      context,
      mobile: mobileFontSize ?? 16,
      tablet: tabletFontSize,
      desktop: desktopFontSize,
    );

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: padding ?? getResponsivePadding(context, mobile: 12),
      ),
      child: Text(
        text,
        style: (textStyle ?? const TextStyle()).copyWith(fontSize: fontSize),
      ),
    );
  }

  // Screen size helpers
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Safe area helpers
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    return MediaQuery.of(context).padding;
  }

  // Orientation helpers
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
}
