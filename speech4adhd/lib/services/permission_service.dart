import 'package:permission_handler/permission_handler.dart';

/// Microphone permission for recording. Request on first use.
class PermissionService {
  static Future<bool> requestMicrophone() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) return true;
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    if (status.isPermanentlyDenied) {
      await openAppSettings();
      return false;
    }
    return false;
  }

  static Future<bool> get hasMicrophone async {
    return (await Permission.microphone.status).isGranted;
  }

  /// Opens the app's Settings page so the user can enable Microphone.
  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
