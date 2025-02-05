import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage/test/test_flutter_secure_storage_platform.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterSecureStoragePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FlutterSecureStoragePlatform {}

class ImplementsFlutterSecureStoragePlatform extends Mock
    implements FlutterSecureStoragePlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FlutterSecureStorage storage;
  late MockFlutterSecureStoragePlatform mockPlatform;

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  final methodStorage = MethodChannelFlutterSecureStorage();
  final log = <MethodCall>[];

  Future<bool?>? handler(MethodCall methodCall) async {
    log.add(methodCall);
    if (methodCall.method == 'containsKey') {
      return true;
    } else if (methodCall.method == 'isProtectedDataAvailable') {
      return true;
    }
    return null;
  }

  setUp(() {
    mockPlatform = MockFlutterSecureStoragePlatform();
    FlutterSecureStoragePlatform.instance = mockPlatform;
    storage = const FlutterSecureStorage();

    // Ensure method channel mock is set up for the tests
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, handler);

    log.clear(); // Clear logs before each test
  });

  tearDown(() {
    log.clear(); // Clear logs after each test
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null); // Remove the mock handler
  });

  group('Method Channel Interaction Tests for FlutterSecureStorage', () {
    test('read', () async {
      const key = 'test_key';
      const options = <String, String>{};
      await methodStorage.read(key: key, options: options);

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'read',
            arguments: <String, Object>{
              'key': key,
              'options': options,
            },
          ),
        ],
      );
    });

    test('write', () async {
      const key = 'test_key';
      const options = <String, String>{};
      await methodStorage.write(key: key, value: 'test', options: options);

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'write',
            arguments: <String, Object>{
              'key': key,
              'value': 'test',
              'options': options,
            },
          ),
        ],
      );
    });

    test('containsKey', () async {
      const key = 'test_key';
      const options = <String, String>{};
      await methodStorage.write(key: key, value: 'test', options: options);

      final result =
          await methodStorage.containsKey(key: key, options: options);

      expect(result, true);
    });

    test('delete', () async {
      const key = 'test_key';
      const options = <String, String>{};
      await methodStorage.write(key: key, value: 'test', options: options);
      await methodStorage.delete(key: key, options: options);

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'write',
            arguments: <String, Object>{
              'key': key,
              'value': 'test',
              'options': options,
            },
          ),
          isMethodCall(
            'delete',
            arguments: <String, Object>{
              'key': key,
              'options': options,
            },
          ),
        ],
      );
    });

    test('deleteAll', () async {
      const options = <String, String>{};
      await methodStorage.deleteAll(options: options);

      expect(
        log,
        <Matcher>[
          isMethodCall(
            'deleteAll',
            arguments: <String, Object>{
              'options': options,
            },
          ),
        ],
      );
    });
  });

  group('Platform-Specific Interface Tests', () {
    test('Cannot be implemented with `implements`', () {
      expect(
        () {
          FlutterSecureStoragePlatform.instance =
              ImplementsFlutterSecureStoragePlatform();
        },
        throwsA(isInstanceOf<AssertionError>()),
      );
    });

    test('Can be mocked with `implements`', () {
      final mock = MockFlutterSecureStoragePlatform();
      FlutterSecureStoragePlatform.instance = mock;
    });

    test('Can be extended', () {
      FlutterSecureStoragePlatform.instance =
          TestFlutterSecureStoragePlatform({});
    });
  });

  group('FlutterSecureStorage Methods Invocation Tests', () {
    const testKey = 'testKey';
    const testValue = 'testValue';

    test('write should call platform write method', () async {
      when(
        () => mockPlatform.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      await storage.write(key: testKey, value: testValue);

      verify(
        () => mockPlatform.write(
          key: testKey,
          value: testValue,
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('read should return correct value', () async {
      when(
        () => mockPlatform.read(
          key: any(named: 'key'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => testValue);

      final result = await storage.read(key: testKey);

      expect(result, equals(testValue));
      verify(
        () => mockPlatform.read(
          key: testKey,
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('delete should call platform delete method', () async {
      when(
        () => mockPlatform.delete(
          key: any(named: 'key'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      await storage.delete(key: testKey);

      verify(
        () => mockPlatform.delete(
          key: testKey,
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('containsKey should return true if key exists', () async {
      when(
        () => mockPlatform.containsKey(
          key: any(named: 'key'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async => true);

      final result = await storage.containsKey(key: testKey);

      expect(result, isTrue);
      verify(
        () => mockPlatform.containsKey(
          key: testKey,
          options: any(named: 'options'),
        ),
      ).called(1);
    });

    test('write with null value should trigger delete', () async {
      when(
        () => mockPlatform.delete(
          key: any(named: 'key'),
          options: any(named: 'options'),
        ),
      ).thenAnswer((_) async {});

      await storage.write(key: testKey, value: null);

      verify(
        () => mockPlatform.delete(
          key: testKey,
          options: any(named: 'options'),
        ),
      ).called(1);
    });
  });

  group('AndroidOptions Configuration Tests', () {
    test('Default AndroidOptions should have correct default values', () {
      const options = AndroidOptions.defaultOptions;

      expect(options.toMap(), {
        'encryptedSharedPreferences': 'false',
        'resetOnError': 'false',
        'keyCipherAlgorithm': 'RSA_ECB_PKCS1Padding',
        'storageCipherAlgorithm': 'AES_CBC_PKCS7Padding',
        'sharedPreferencesName': '',
        'preferencesKeyPrefix': '',
      });
    });

    test('AndroidOptions with custom values', () {
      const options = AndroidOptions(
        resetOnError: true,
        keyCipherAlgorithm:
            KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
        sharedPreferencesName: 'customPrefs',
        preferencesKeyPrefix: 'customPrefix',
      );

      expect(options.toMap(), {
        'encryptedSharedPreferences': 'false',
        'resetOnError': 'true',
        'keyCipherAlgorithm': 'RSA_ECB_OAEPwithSHA_256andMGF1Padding',
        'storageCipherAlgorithm': 'AES_GCM_NoPadding',
        'sharedPreferencesName': 'customPrefs',
        'preferencesKeyPrefix': 'customPrefix',
      });
    });

    test('copyWith should correctly override values', () {
      const original = AndroidOptions.defaultOptions;

      final copied = original.copyWith(
        resetOnError: true,
        sharedPreferencesName: 'newPrefs',
      );

      expect(copied.toMap(), {
        'encryptedSharedPreferences': 'false',
        'resetOnError': 'true',
        'keyCipherAlgorithm': 'RSA_ECB_PKCS1Padding',
        'storageCipherAlgorithm': 'AES_CBC_PKCS7Padding',
        'sharedPreferencesName': 'newPrefs',
        'preferencesKeyPrefix': '',
      });
    });

    test('copyWith without changes should retain original values', () {
      const original = AndroidOptions(
        resetOnError: true,
        keyCipherAlgorithm:
            KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
        storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      );

      final copied = original.copyWith();

      expect(copied.toMap(), original.toMap());
    });

    test(
        'AndroidOptions handles null sharedPreferencesName and '
        'preferencesKeyPrefix', () {
      const options = AndroidOptions.defaultOptions;

      expect(options.toMap()['sharedPreferencesName'], '');
      expect(options.toMap()['preferencesKeyPrefix'], '');
    });

    test('Deprecated encryptedSharedPreferences still functions', () {
      // Ignore for test
      // ignore: deprecated_member_use_from_same_package
      const options = AndroidOptions(encryptedSharedPreferences: true);

      expect(options.toMap()['encryptedSharedPreferences'], 'true');
    });
  });

  group('WebOptions Configuration Tests', () {
    test('Default WebOptions should have correct default values', () {
      const options = WebOptions.defaultOptions;

      expect(options.toMap(), {
        'dbName': 'FlutterEncryptedStorage',
        'publicKey': 'FlutterSecureStorage',
        'wrapKey': '',
        'wrapKeyIv': '',
        'useSessionStorage': 'false',
      });
    });

    test('WebOptions with custom values', () {
      const options = WebOptions(
        dbName: 'CustomDB',
        publicKey: 'CustomPublicKey',
        wrapKey: 'CustomWrapKey',
        wrapKeyIv: 'CustomWrapKeyIv',
        useSessionStorage: true,
      );

      expect(options.toMap(), {
        'dbName': 'CustomDB',
        'publicKey': 'CustomPublicKey',
        'wrapKey': 'CustomWrapKey',
        'wrapKeyIv': 'CustomWrapKeyIv',
        'useSessionStorage': 'true',
      });
    });

    test('WebOptions handles empty wrapKey and wrapKeyIv', () {
      const options = WebOptions.defaultOptions;

      expect(options.toMap()['wrapKey'], '');
      expect(options.toMap()['wrapKeyIv'], '');
    });

    test('WebOptions defaultOptions matches default constructor', () {
      const defaultOptions = WebOptions.defaultOptions;
      // Ignore for test
      // ignore: use_named_constants
      const constructorOptions = WebOptions();

      expect(defaultOptions.toMap(), constructorOptions.toMap());
    });

    test('WebOptions with only sessionStorage enabled', () {
      const options = WebOptions(useSessionStorage: true);

      expect(options.toMap(), {
        'dbName': 'FlutterEncryptedStorage',
        'publicKey': 'FlutterSecureStorage',
        'wrapKey': '',
        'wrapKeyIv': '',
        'useSessionStorage': 'true',
      });
    });
  });

  group('WindowsOptions Configuration Tests', () {
    test('Default WindowsOptions should have correct default values', () {
      const options = WindowsOptions.defaultOptions;

      expect(options.toMap(), {
        'useBackwardCompatibility': 'false',
      });
    });

    test('WindowsOptions with useBackwardCompatibility set to true', () {
      const options = WindowsOptions(useBackwardCompatibility: true);

      expect(options.toMap(), {
        'useBackwardCompatibility': 'true',
      });
    });

    test('WindowsOptions copyWith should override values correctly', () {
      const original = WindowsOptions.defaultOptions;

      final copied = original.copyWith(useBackwardCompatibility: true);

      expect(copied.toMap(), {
        'useBackwardCompatibility': 'true',
      });
    });

    test(
        'WindowsOptions copyWith without changes should retain original values',
        () {
      const original = WindowsOptions(useBackwardCompatibility: true);

      final copied = original.copyWith();

      expect(copied.toMap(), original.toMap());
    });

    test('WindowsOptions defaultOptions matches default constructor', () {
      const defaultOptions = WindowsOptions.defaultOptions;
      // Ignore for test
      // ignore: use_named_constants
      const constructorOptions = WindowsOptions();

      expect(defaultOptions.toMap(), constructorOptions.toMap());
    });
  });

  group('iOSOptions Configuration Tests', () {
    test('Default IOSOptions should have correct default values', () {
      const options = IOSOptions.defaultOptions;

      expect(options.toMap(), {
        'accountName': 'flutter_secure_storage_service',
        'accessibility': 'unlocked',
        'synchronizable': 'false',
      });
    });

    test('IOSOptions with custom values', () {
      final options = IOSOptions(
        accountName: 'customAccount',
        groupId: 'group.com.example',
        accessibility: KeychainAccessibility.unlocked_this_device,
        synchronizable: true,
        label: 'Custom Label',
        description: 'Test Description',
        comment: 'Test Comment',
        isInvisible: true,
        isNegative: false,
        creationDate: DateTime(2023),
        lastModifiedDate: DateTime(2024),
        resultLimit: 10,
        shouldReturnPersistentReference: true,
        authenticationUIBehavior: 'require_auth',
        accessControlFlags: [AccessControlFlag.biometryCurrentSet],
      );

      expect(options.toMap(), {
        'accountName': 'customAccount',
        'groupId': 'group.com.example',
        'accessibility': 'unlocked_this_device',
        'synchronizable': 'true',
        'label': 'Custom Label',
        'description': 'Test Description',
        'comment': 'Test Comment',
        'isInvisible': 'true',
        'isNegative': 'false',
        'creationDate': '2023-01-01T00:00:00.000',
        'lastModifiedDate': '2024-01-01T00:00:00.000',
        'resultLimit': '10',
        'shouldReturnPersistentReference': 'true',
        'authenticationUIBehavior': 'require_auth',
        'accessControlFlags':
            [AccessControlFlag.biometryCurrentSet.name].toString(),
      });
    });

    test('IOSOptions defaultOptions matches default constructor', () {
      const defaultOptions = IOSOptions.defaultOptions;
      // Ignore for test
      // ignore: use_named_constants
      const constructorOptions = IOSOptions();

      expect(defaultOptions.toMap(), constructorOptions.toMap());
    });
  });

  group('macOSOptions Configuration Tests', () {
    test('Default macOSOptions should have correct default values', () {
      // Ignore for test
      // ignore: use_named_constants
      const options = MacOsOptions();

      expect(options.toMap(), {
        'accountName': 'flutter_secure_storage_service',
        'accessibility': 'unlocked',
        'synchronizable': 'false',
        'usesDataProtectionKeychain': 'true',
      });
    });

    test('macOSOptions with custom values', () {
      const options = MacOsOptions(
        accountName: 'macAccount',
        groupId: 'group.mac.example',
        accessibility: KeychainAccessibility.first_unlock,
        synchronizable: true,
        usesDataProtectionKeychain: false,
      );

      expect(options.toMap(), {
        'accountName': 'macAccount',
        'groupId': 'group.mac.example',
        'accessibility': 'first_unlock',
        'synchronizable': 'true',
        'usesDataProtectionKeychain': 'false',
      });
    });

    test('macOSOptions defaultOptions matches default constructor', () {
      const defaultOptions = MacOsOptions.defaultOptions;
      // Ignore for test
      // ignore: use_named_constants
      const constructorOptions = MacOsOptions();

      expect(defaultOptions.toMap(), constructorOptions.toMap());
    });
  });
}
