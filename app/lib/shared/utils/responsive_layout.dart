import 'package:flutter/material.dart';

/// Form factors supported by Chatmelier
enum FormFactor {
  mobile,
  tablet,
  desktop,
}

/// Central responsive utility and breakpoint manager
class Responsive {
  /// Breakpoint between mobile and tablet form factor
  static const double tabletBreakpoint = 700.0;

  /// Breakpoint between tablet and desktop / wide web form factor
  static const double desktopBreakpoint = 1100.0;

  /// Optimal maximum content width for readability on ultra-wide screens
  static const double maxContentWidth = 1400.0;

  /// Optimal form width for login / register / profile screens
  static const double maxFormWidth = 480.0;

  /// Returns true if the screen width is considered mobile (< 700px)
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletBreakpoint;

  /// Returns true if the screen width is considered tablet (700px - 1100px)
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tabletBreakpoint && width < desktopBreakpoint;
  }

  /// Returns true if the screen width is considered desktop or wide web (>= 1100px)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  /// Returns true if the screen is either tablet or desktop
  static bool isTabletOrDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint;

  /// Returns the current FormFactor based on the app window width
  static FormFactor formFactor(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return FormFactor.desktop;
    if (width >= tabletBreakpoint) return FormFactor.tablet;
    return FormFactor.mobile;
  }
}

/// Widget that builds different UI trees based on available width
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= Responsive.desktopBreakpoint) {
          return desktop;
        }
        if (constraints.maxWidth >= Responsive.tabletBreakpoint) {
          return tablet ?? desktop;
        }
        return mobile;
      },
    );
  }
}

/// Container that limits the maximum width of content and centers it on large screens
class ResponsiveContentWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveContentWrapper({
    super.key,
    required this.child,
    this.maxWidth = Responsive.maxContentWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
