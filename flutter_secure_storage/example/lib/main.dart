import 'dart:io' show Platform;
import 'dart:math' show Random;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  runApp(const MaterialApp(home: HomePage()));
}

enum _Actions { deleteAll, isProtectedDataAvailable }

enum _ItemActions { delete, edit, containsKey, read }

/// Homepage of the example app of flutter_secure_storage
class HomePage extends StatefulWidget {
  /// Creates an instance of `HomePage`.
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

/// The `HomePageState` class represents the mutable state for the `HomePage`
/// widget. It manages the state and behavior of the user interface.
class HomePageState extends State<HomePage> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _accountNameController =
      TextEditingController(text: 'flutter_secure_storage_service');

  final List<_SecItem> _items = [];

  @override
  void initState() {
    super.initState();

    _accountNameController.addListener(_readAll);
    _readAll();
  }

  @override
  void dispose() {
    _accountNameController
      ..removeListener(_readAll)
      ..dispose();

    super.dispose();
  }

  Future<void> _readAll() async {
    final all = await _storage.readAll(
      iOptions: _getIOSOptions(),
      aOptions: _getAndroidOptions(),
    );
    setState(() {
      _items
        ..clear()
        ..addAll(all.entries.map((e) => _SecItem(e.key, e.value)))
        ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
    });
  }

  Future<void> _deleteAll() async {
    await _storage.deleteAll(
      iOptions: _getIOSOptions(),
      aOptions: _getAndroidOptions(),
    );
    await _readAll();
  }

  Future<void> _isProtectedDataAvailable() async {
    final scaffold = ScaffoldMessenger.of(context);
    final result = await _storage.isCupertinoProtectedDataAvailable();

    scaffold.showSnackBar(
      SnackBar(
        content: Text('Protected data available: $result'),
        backgroundColor: result != null && result ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _addNewItem() async {
    await _storage.write(
      key: DateTime.timestamp().microsecondsSinceEpoch.toString(),
      value: _randomValue(),
      iOptions: _getIOSOptions(),
      aOptions: _getAndroidOptions(),
    );
    await _readAll();
  }

  IOSOptions _getIOSOptions() => IOSOptions(
        accountName: _getAccountName(),
      );

  AndroidOptions _getAndroidOptions() => AndroidOptions.defaultOptions;

  String? _getAccountName() =>
      _accountNameController.text.isEmpty ? null : _accountNameController.text;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plugin example app'),
        actions: <Widget>[
          IconButton(
            key: const Key('add_random'),
            onPressed: _addNewItem,
            icon: const Icon(Icons.add),
          ),
          PopupMenuButton<_Actions>(
            key: const Key('popup_menu'),
            onSelected: (action) {
              switch (action) {
                case _Actions.deleteAll:
                  _deleteAll();
                case _Actions.isProtectedDataAvailable:
                  _isProtectedDataAvailable();
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<_Actions>>[
              const PopupMenuItem(
                key: Key('delete_all'),
                value: _Actions.deleteAll,
                child: Text('Delete all'),
              ),
              const PopupMenuItem(
                key: Key('is_protected_data_available'),
                value: _Actions.isProtectedDataAvailable,
                child: Text('IsProtectedDataAvailable'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          if (!kIsWeb && Platform.isIOS)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextFormField(
                controller: _accountNameController,
                decoration: const InputDecoration(labelText: 'kSecAttrService'),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (BuildContext context, int index) => ListTile(
                trailing: PopupMenuButton(
                  key: Key('popup_row_$index'),
                  onSelected: (_ItemActions action) =>
                      _performAction(action, _items[index], context),
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<_ItemActions>>[
                    PopupMenuItem(
                      value: _ItemActions.delete,
                      child: Text(
                        'Delete',
                        key: Key('delete_row_$index'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _ItemActions.edit,
                      child: Text(
                        'Edit',
                        key: Key('edit_row_$index'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _ItemActions.containsKey,
                      child: Text(
                        'Contains Key',
                        key: Key('contains_row_$index'),
                      ),
                    ),
                    PopupMenuItem(
                      value: _ItemActions.read,
                      child: Text(
                        'Read',
                        key: Key('contains_row_$index'),
                      ),
                    ),
                  ],
                ),
                title: Text(
                  _items[index].value,
                  key: Key('title_row_$index'),
                ),
                subtitle: Text(
                  _items[index].key,
                  key: Key('subtitle_row_$index'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performAction(
    _ItemActions action,
    _SecItem item,
    BuildContext context,
  ) async {
    switch (action) {
      case _ItemActions.delete:
        await _storage.delete(
          key: item.key,
          iOptions: _getIOSOptions(),
          aOptions: _getAndroidOptions(),
        );
        await _readAll();
      case _ItemActions.edit:
        if (!context.mounted) return;
        final result = await showDialog<String>(
          context: context,
          builder: (_) => _EditItemWidget(item.value),
        );
        if (result != null) {
          await _storage.write(
            key: item.key,
            value: result,
            iOptions: _getIOSOptions(),
            aOptions: _getAndroidOptions(),
          );
          await _readAll();
        }
      case _ItemActions.containsKey:
        final key = await _displayTextInputDialog(context, item.key);
        final result = await _storage.containsKey(key: key);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contains Key: $result, key checked: $key'),
            backgroundColor: result ? Colors.green : Colors.red,
          ),
        );
      case _ItemActions.read:
        final key = await _displayTextInputDialog(context, item.key);
        final result =
            await _storage.read(key: key, aOptions: _getAndroidOptions());
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('value: $result'),
          ),
        );
    }
  }

  Future<String> _displayTextInputDialog(
    BuildContext context,
    String key,
  ) async {
    final controller = TextEditingController(text: key);
    await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Check if key exists'),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: const Text('OK'),
          ),
        ],
        content: TextField(controller: controller),
      ),
    );
    return controller.text;
  }

  String _randomValue() {
    final rand = Random();
    final codeUnits =
        List<int>.generate(20, (_) => rand.nextInt(26) + 65, growable: false);

    return String.fromCharCodes(codeUnits);
  }
}

class _EditItemWidget extends StatelessWidget {
  _EditItemWidget(String text)
      : _controller = TextEditingController(text: text);

  final TextEditingController _controller;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit item'),
      content: TextField(
        key: const Key('title_field'),
        controller: _controller,
        autofocus: true,
      ),
      actions: <Widget>[
        TextButton(
          key: const Key('cancel'),
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          key: const Key('save'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SecItem {
  const _SecItem(this.key, this.value);

  final String key;
  final String value;
}
