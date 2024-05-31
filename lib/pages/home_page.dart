// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'dart:async';
import 'dart:convert'; // Import for base64Url encoding

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _deviceId;
  final String _encryptionKey = 'my32lengthsupersecretnooneknows1';

  @override
  void initState() {
    super.initState();
    _initDeviceId();
  }

  Future<void> _initDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedDeviceId = prefs.getString('device_id');

    String deviceId = await _generateDeviceId();
    print('Generated Device ID: $deviceId'); // Debug statement
    String encryptedDeviceId = _encryptFernet(deviceId);
    print('Encrypted Device ID: $encryptedDeviceId'); // Debug statement
    String decryptedDeviceId = _decryptFernet(encryptedDeviceId);
    print('Decrypted Device ID: $decryptedDeviceId'); // Debug statement

    prefs.setString('device_id', encryptedDeviceId);
    storedDeviceId = encryptedDeviceId;

    setState(() {
      _deviceId = storedDeviceId;
    });
  }

  Future<String> _generateDeviceId() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    String deviceId;

    if (Theme.of(context).platform == TargetPlatform.iOS) {
      var iosDeviceInfo = await deviceInfoPlugin.iosInfo;
      deviceId = iosDeviceInfo.identifierForVendor ?? 'Unknown iOS ID'; // Unique ID on iOS
    } else {
      var androidDeviceInfo = await deviceInfoPlugin.androidInfo;
      deviceId = androidDeviceInfo.id ?? 'Unknown Android ID'; // Unique ID on Android
    }

    return deviceId;
  }

  String _encryptFernet(String plainText) {
    final keyBytes = utf8.encode(_encryptionKey); // Convert key to bytes
    final key = encrypt.Key(keyBytes);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.Fernet(key));
    final encrypted = encrypter.encrypt(plainText);
    return encrypted.base64;
  }

  String _decryptFernet(String encryptedDeviceId) {
    final keyBytes = utf8.encode(_encryptionKey); // Convert key to bytes
    final key = encrypt.Key(keyBytes);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.Fernet(key));
  
    // Add padding to the encrypted value if needed
    final paddedEncryptedDeviceId = encryptedDeviceId.padRight(
      (encryptedDeviceId.length + 3) & ~3,
      '=');
  
    final decrypted = encrypter.decrypt64(paddedEncryptedDeviceId);
    return decrypted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Device ID App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.device_hub, size: 50), // Icon for device
            SizedBox(height: 20),
            Text(
              'Device ID',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ), // Title
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _deviceId ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Device ID copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: 20),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _deviceId ?? 'No Device ID',
                  style: TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ), // Encrypted Device ID
            SizedBox(height: 10),
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: _deviceId ?? ''));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Device ID copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Icon(Icons.content_copy), // Icon for copy-paste
            ), // Copy Icon
          ],
        ),
      ),
    );
  }
}
