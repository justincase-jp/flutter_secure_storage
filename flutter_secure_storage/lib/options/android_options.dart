part of flutter_secure_storage;

class AndroidOptions extends Options {
  const AndroidOptions({bool resetOnError = false})
      : _resetOnError = resetOnError;

  /// When an error is detected, automatically reset all data. This will prevent
  /// fatal errors regarding an unknown key however keep in mind that it will
  /// PERMANENLTY erase the data when an error occurs.
  ///
  /// Defaults to false.
  final bool _resetOnError;

  static const AndroidOptions defaultOptions = AndroidOptions();

  @override
  Map<String, String> toMap() =>
      <String, String>{'resetOnError': '$_resetOnError'};

  AndroidOptions copyWith({bool? resetOnError}) =>
      AndroidOptions(resetOnError: resetOnError ?? _resetOnError);
}
