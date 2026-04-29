import 'dart:io';

import 'package:permission_handler/permission_handler.dart';

Future<PermissionStatus> requestGallerySavePermission() async {
  if (Platform.isIOS) {
    return Permission.photosAddOnly.request();
  }

  if (!Platform.isAndroid) {
    return PermissionStatus.granted;
  }

  final photosStatus = await Permission.photos.request();
  if (photosStatus.isGranted || photosStatus.isLimited) {
    return photosStatus;
  }

  return Permission.storage.request();
}
