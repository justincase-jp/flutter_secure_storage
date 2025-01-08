import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_secure_storage_darwin_method_channel.dart';

abstract class FlutterSecureStorageDarwinPlatform extends PlatformInterface {
  /// Constructs a FlutterSecureStorageDarwinPlatform.
  FlutterSecureStorageDarwinPlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterSecureStorageDarwinPlatform _instance = MethodChannelFlutterSecureStorageDarwin();

  /// The default instance of [FlutterSecureStorageDarwinPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterSecureStorageDarwin].
  static FlutterSecureStorageDarwinPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterSecureStorageDarwinPlatform] when
  /// they register themselves.
  static set instance(FlutterSecureStorageDarwinPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
