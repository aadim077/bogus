import 'package:screen_protector/screen_protector.dart';

class ScreenSecurity {
  static Future<void> enable() async {
    try {
      // Prevent screenshots / screen recording
      await ScreenProtector.preventScreenshotOn();
    } catch (e) {
      print("Error enabling screen security: $e");
    }
  }

  static Future<void> disable() async {
    try {
      // Allow screenshots / screen recording
      await ScreenProtector.preventScreenshotOff();
    } catch (e) {
      print("Error disabling screen security: $e");
    }
  }

  static Future<void> enableSecure() async {}
}
