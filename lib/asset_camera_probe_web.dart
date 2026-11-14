import 'dart:js_interop';
import 'package:web/web.dart' as web;

/// Enumerate video inputs without opening a stream or prompting for access.
/// Camera labels/IDs are never stored. Security/permission errors are unknown.
Future<bool?> detectAvailableWebcam() async {
  try {
    final devices =
        (await web.window.navigator.mediaDevices.enumerateDevices().toDart)
            .toDart;
    return devices.any((device) => device.kind == 'videoinput');
  } catch (_) {
    // Insecure origins, unsupported browsers, blocked policies, or revocation.
    return null;
  }
}
