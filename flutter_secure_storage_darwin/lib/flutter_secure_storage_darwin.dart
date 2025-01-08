
import 'flutter_secure_storage_darwin_platform_interface.dart';

class FlutterSecureStorageDarwin {
  Future<String?> getPlatformVersion() {
    return FlutterSecureStorageDarwinPlatform.instance.getPlatformVersion();
  }
}
