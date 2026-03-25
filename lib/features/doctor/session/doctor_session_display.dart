import 'package:flutter/foundation.dart';

import '../../../core/network/token_storage.dart';

/// In-memory name/role for the doctor drawer; kept in sync with [TokenStorage].
class DoctorSessionDisplay {
  DoctorSessionDisplay._();

  static final ValueNotifier<String> name = ValueNotifier<String>('');
  static final ValueNotifier<String> role = ValueNotifier<String>('');

  static Future<void> hydrate() async {
    final n = await TokenStorage.instance.getDoctorDrawerName();
    final r = await TokenStorage.instance.getDoctorDrawerRole();
    name.value = n ?? '';
    role.value = r ?? '';
  }

  static Future<void> apply({
    required String name,
    required String role,
  }) async {
    await TokenStorage.instance.saveDoctorDrawerInfo(name: name, role: role);
    DoctorSessionDisplay.name.value = name;
    DoctorSessionDisplay.role.value = role;
  }

  static void resetNotifiers() {
    name.value = '';
    role.value = '';
  }
}
