part of '../flutter_secure_storage.dart';
/// The `IOSOptions` class extends `AppleOptions`, providing iOS-specific
/// options for configuring keychain storage in Flutter.
class IOSOptions extends AppleOptions {
  /// Creates an instance of `IOSOptions` with optional parameters to
  /// configure iOS-specific options.
  ///
  /// Parameters:
  /// - [groupId]: The app group identifier for shared access. Enables sharing
  ///   of keychain items across apps within the same app group.
  /// - [accountName]: The account name associated with the keychain items.
  /// - [accessibility]: The level of accessibility for keychain items
  ///   (e.g., accessible after first unlock, when unlocked, etc.).
  /// - [synchronizable]: Whether the keychain items are synchronized with
  ///   iCloud.
  const IOSOptions({
    super.groupId,
    super.accountName,
    super.accessibility,
    super.synchronizable,
  });

  /// A predefined `IOSOptions` instance with default settings.
  ///
  /// This can be used as a fallback or when no specific options are required.
  static const IOSOptions defaultOptions = IOSOptions();

  /// Creates a new instance of `IOSOptions` by copying the current instance
  /// and replacing specified properties with new values.
  ///
  /// Parameters:
  /// - [groupId]: Overrides the existing `groupId`.
  /// - [accountName]: Overrides the existing `accountName`.
  /// - [accessibility]: Overrides the existing `accessibility`.
  /// - [synchronizable]: Overrides the existing `synchronizable`.
  ///
  /// Returns:
  /// - A new `IOSOptions` instance with the specified changes.
  IOSOptions copyWith({
    String? groupId,
    String? accountName,
    KeychainAccessibility? accessibility,
    bool? synchronizable,
  }) =>
      IOSOptions(
        groupId: groupId ?? _groupId,
        accountName: accountName ?? _accountName,
        accessibility: accessibility ?? _accessibility,
        synchronizable: synchronizable ?? _synchronizable,
      );
}
