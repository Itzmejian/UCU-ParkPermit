import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Asks for the camera before scanning. Returns true when it may be used.
Future<bool> ensureCameraPermission(BuildContext context) async {
  var status = await Permission.camera.status;
  if (status.isGranted) return true;
  status = await Permission.camera.request();
  if (status.isGranted) return true;
  if (!context.mounted) return false;
  final blocked = status.isPermanentlyDenied || status.isRestricted;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Camera access needed'),
      content: Text(
        blocked
            ? 'Camera access is turned off for UCU ParkPermit. Open Settings, then allow Camera to scan.'
            : 'UCU ParkPermit uses the camera only to scan your OR/CR and parking stickers. Please allow camera access to continue.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Not now')),
        if (blocked)
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
      ],
    ),
  );
  return false;
}

/// Android 13 and newer need permission before showing notifications.
Future<void> requestNotificationPermission() async {
  try {
    final status = await Permission.notification.status;
    if (status.isDenied) await Permission.notification.request();
  } catch (_) {}
}