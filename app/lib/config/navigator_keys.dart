import 'package:flutter/material.dart';

/// Global navigator key for the root navigator (topmost dialogs, full-screen routes)
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// Global navigator key for the adaptive shell route (tabs and in-tab bottom sheets)
final shellNavigatorKey = GlobalKey<NavigatorState>();
