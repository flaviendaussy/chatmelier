// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

void launchAdminConsole() {
  html.window.location.replace('/admin_console/index.html');
}
