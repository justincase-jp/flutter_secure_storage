import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_secure_storage_platform_interface/flutter_secure_storage_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// ✅ Correct Mock Class Implementation
class MockFlutterSecureStoragePlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FlutterSecureStoragePlatform {}

void main() {
  late FlutterSecureStorage storage;
  late MockFlutterSecureStoragePlatform mockPlatform;

  setUp(() {
    mockPlatform = MockFlutterSecureStoragePlatform();
    FlutterSecureStoragePlatform.instance = mockPlatform;
    storage = FlutterSecureStorage();
  });

  group('FlutterSecureStorage Tests', () {
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
}
