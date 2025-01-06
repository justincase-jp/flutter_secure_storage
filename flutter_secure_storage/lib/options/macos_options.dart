part of '../flutter_secure_storage.dart';

/// Specific options for macOS platform.
class MacOsOptions extends AppleOptions {
  /// Creates an instance of `MacOsOptions` with configurable parameters
  /// for keychain access and storage behavior on macOS.
  ///
  /// Parameters:
  /// - [groupId]: The app group identifier for shared access. Enables sharing
  ///   of keychain items across apps within the same app group.
  /// - [accountName]: The account name associated with the keychain items.
  /// - [accessibility]: The level of accessibility for keychain items
  ///   (e.g., accessible after first unlock, when unlocked, etc.).
  /// - [synchronizable]: Whether the keychain items are synchronized with
  ///   iCloud.
  /// - [useDataProtectionKeyChain]: Indicates whether the data protection
  ///   keychain is used. Defaults to `true`.
  const MacOsOptions({
    super.groupId,
    super.accountName,
    super.accessibility,
    super.synchronizable,
    bool useDataProtectionKeyChain = true,
  })  : _useDataProtectionKeyChain = useDataProtectionKeyChain;

  /// A predefined `MacOsOptions` instance with default settings.
  ///
  /// This can be used as a fallback or when no specific options are required.
  static const MacOsOptions defaultOptions = MacOsOptions();

  /// Indicates whether the data protection keychain is used.
  /// Defaults to `true`.
  final bool _useDataProtectionKeyChain;

  /// Creates a new instance of `MacOsOptions` by copying the current instance
  /// and replacing specified properties with new values.
  ///
  /// Parameters:
  /// - [groupId]: Overrides the existing `groupId`.
  /// - [accountName]: Overrides the existing `accountName`.
  /// - [accessibility]: Overrides the existing `accessibility`.
  /// - [synchronizable]: Overrides the existing `synchronizable`.
  /// - [useDataProtectionKeyChain]: Overrides the existing
  ///   `useDataProtectionKeyChain`.
  ///
  /// Returns:
  /// - A new `MacOsOptions` instance with the specified changes.
  MacOsOptions copyWith({
    String? groupId,
    String? accountName,
    KeychainAccessibility? accessibility,
    bool? synchronizable,
    bool? useDataProtectionKeyChain,
  }) =>
      MacOsOptions(
        groupId: groupId ?? _groupId,
        accountName: accountName ?? _accountName,
        accessibility: accessibility ?? _accessibility,
        synchronizable: synchronizable ?? _synchronizable,
        useDataProtectionKeyChain:
        useDataProtectionKeyChain ?? _useDataProtectionKeyChain,
      );

  /// Converts the `MacOsOptions` instance into a map representation,
  /// including macOS-specific properties.
  ///
  /// Returns:
  /// - A map containing the properties of the `MacOsOptions` instance.
  ///
  /// Overrides:
  /// - [AppleOptions.toMap] to include the `useDataProtectionKeyChain`
  ///   property.
  @override
  Map<String, String> toMap() => <String, String>{
    ...super.toMap(),
    'useDataProtectionKeyChain': '$_useDataProtectionKeyChain',
  };
}
