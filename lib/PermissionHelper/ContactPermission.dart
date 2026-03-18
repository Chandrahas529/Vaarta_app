import 'package:flutter/cupertino.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestContactsPermission() async {
  final status = await Permission.contacts.status;
  if (status.isGranted) return true;

  final result = await Permission.contacts.request();
  return result.isGranted;
}
