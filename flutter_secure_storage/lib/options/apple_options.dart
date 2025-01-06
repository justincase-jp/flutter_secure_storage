part of '../flutter_secure_storage.dart';

// Ignore enum check and change it in a later release
//ignore_for_file: constant_identifier_names
/// KeyChain accessibility attributes as defined here:
/// https://developer.apple.com/documentation/security/ksecattraccessible?language=objc
enum KeychainAccessibility {
  /// The data in the keychain can only be accessed when the device is unlocked.
  /// Only available if a passcode is set on the device.
  /// Items with this attribute do not migrate to a new device.
  passcode,

  /// The data in the keychain item can be accessed only while the device is
  /// unlocked by the user.
  unlocked,

  /// The data in the keychain item can be accessed only while the device is
  /// unlocked by the user.
  /// Items with this attribute do not migrate to a new device.
  unlocked_this_device,

  /// The data in the keychain item cannot be accessed after a restart until the
  /// device has been unlocked once by the user.
  first_unlock,

  /// The data in the keychain item cannot be accessed after a restart until the
  /// device has been unlocked once by the user.
  /// Items with this attribute do not migrate to a new device.
  first_unlock_this_device,
}

/// Specific options for Apple platform.
abstract class AppleOptions extends Options {
  /// Creates an instance of `AppleOptions` with configurable parameters
  /// for keychain access and storage behavior.
  ///
  /// Parameters:
  /// - [groupId]: The app group identifier for shared access. Enables sharing
  ///   of keychain items across apps within the same app group.
  /// - [accountName]: The account name associated with the keychain items.
  ///   Defaults to [AppleOptions.defaultAccountName].
  /// - [accessibility]: The level of accessibility for keychain items
  ///   (e.g., accessible after first unlock, when unlocked, etc.).
  ///   Defaults to [KeychainAccessibility.unlocked].
  /// - [synchronizable]: Whether the keychain items are synchronized with
  ///   iCloud.
  ///   Defaults to `false`.
  const AppleOptions({
    String? groupId,
    String? accountName = AppleOptions.defaultAccountName,
    KeychainAccessibility? accessibility = KeychainAccessibility.unlocked,
    bool synchronizable = false,
  })  : _groupId = groupId,
        _accessibility = accessibility,
        _accountName = accountName,
        _synchronizable = synchronizable;

  /// The default account name associated with the keychain items.
  static const defaultAccountName = 'flutter_secure_storage_service';

  /// A key with a value that’s a string indicating the access group the item is
  /// in.
  ///
  /// (kSecAttrAccessGroup)
  final String? _groupId;

  /// A key whose value is a string indicating the item's service.
  ///
  /// (kSecAttrService)
  final String? _accountName;

  /// A key with a value that indicates when the keychain item is accessible.
  /// https://developer.apple.com/documentation/security/ksecattraccessible?language=swift
  /// (kSecAttrAccessible)
  final KeychainAccessibility? _accessibility;

  /// A key with a value that’s a string indicating whether the item
  /// synchronizes through iCloud.
  ///
  /// (kSecAttrSynchronizable)
  final bool _synchronizable;

  @override
  Map<String, String> toMap() => <String, String>{
        if (_accessibility != null) 'accessibility': _accessibility.name,
        if (_accountName != null) 'accountName': _accountName,
        if (_groupId != null) 'groupId': _groupId,
        'synchronizable': '$_synchronizable',
      };
}
