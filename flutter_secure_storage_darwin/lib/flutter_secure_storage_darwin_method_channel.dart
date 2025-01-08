import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'flutter_secure_storage_darwin_platform_interface.dart';

/// An implementation of [FlutterSecureStorageDarwinPlatform] that uses method channels.
class MethodChannelFlutterSecureStorageDarwin extends FlutterSecureStorageDarwinPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_secure_storage_darwin');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
