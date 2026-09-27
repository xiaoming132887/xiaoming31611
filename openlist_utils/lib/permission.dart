// 请求存储权限
import 'package:flutter/cupertino.dart';
import 'package:openlist_utils/toast.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> requestStorage(BuildContext ctx) async {
  PermissionStatus status2 = await Permission.videos.request();
  PermissionStatus status3 = await Permission.audio.request();
  PermissionStatus status4 = await Permission.photos.request();
  PermissionStatus status5 = await Permission.manageExternalStorage.request();
  PermissionStatus status = await Permission.storage.request();
  if (status.isGranted) {
// 存储权限已授权，可以进行文件读写操作
    show_success("Granted",ctx);
  } else if (status.isPermanentlyDenied) {
// 存储权限被永久拒绝，需要引导用户手动授权
    show_failed("Permanently Denied",ctx);
  } else {
// 存储权限被拒绝，可以再次请求权限
    show_failed("Permanently Failed",ctx);
  }
}