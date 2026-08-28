import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';

class IntegrityService {
  static const _channel = MethodChannel('com.hotel.hostelhubb/integrity');

  String _generateNonce() {
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Url.encode(values);
  }

  Future<String?> getIntegrityToken() async {
    final nonce = _generateNonce(); // 🔐 Use it here
    try {
      final String? token = await _channel.invokeMethod('getIntegrityToken', {
        'nonce': nonce,
      });
      return token;
    } on PlatformException catch (e) {
      //print("Error fetching integrity token: ${e.message}");
      return null;
    }
  }
}
