// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MenuActions {
  Map<LogicalKeySet, Intent> buildShortcuts() {
    return {
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN):
          const ActivateIntent('newDesign'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyO):
          const ActivateIntent('openDesign'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS):
          const ActivateIntent('save'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyX):
          const ActivateIntent('cut'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyC):
          const ActivateIntent('copy'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyV):
          const ActivateIntent('paste'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
          const ActivateIntent('undo'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyY):
          const ActivateIntent('redo'),
      LogicalKeySet(LogicalKeyboardKey.alt, LogicalKeyboardKey.f4):
          const ActivateIntent('exit'),
    };
  }

  // * Mapping the shortcuts to Actions
  Map<Type, Action<Intent>> buildActions() {
    return {
      ActivateIntent: CallbackAction<ActivateIntent>(
        onInvoke: (ActivateIntent intent) {
          switch (intent.action) {
            case 'newDesign':
              print('New Design clicked');
              break;
            case 'openDesign':
              print('Open Design clicked');
              break;
            case 'save':
              print('Save clicked');
              break;
            case 'cut':
              print('Cut clicked');
              break;
            case 'copy':
              print('Copy clicked');
              break;
            case 'paste':
              print('Paste clicked');
              break;
            case 'undo':
              print('Undo clicked');
              break;
            case 'redo':
              print('Redo clicked');
              break;
            case 'exit':
              print('Exit clicked');
              break;
          }
          return null;
        },
      ),
    };
  }

  // * Building File Menu in Menu bar
  SubmenuButton buildFileMenu() {
    return SubmenuButton(
      menuChildren: [
        _addMenuItem('New Design', () => print('New clicked'),
            shortcut: 'Ctrl + N'),
        _addMenuItem('Open Design', () => print('Open clicked'),
            shortcut: 'Ctrl + O'),
        const Divider(),
        _addMenuItem('Save', () => print('Save clicked'), shortcut: 'Ctrl + S'),
        _addMenuItem('Save As', () => print('Exit clicked'),
            shortcut: 'Ctrl + S'),
        const Divider(),
        _addMenuItem('Import', () => print('Exit clicked')),
        _addMenuItem('Export', () => print('Exit clicked')),
        const Divider(),
        _addMenuItem('Exit', () => print('Exit clicked'), shortcut: 'Alt + F4'),
      ],
      menuStyle:
          const MenuStyle(padding: MaterialStatePropertyAll(EdgeInsets.all(5))),
      child: const Text("File"),
    );
  }

  // * Building Edit Menu in Menu bar
  SubmenuButton buildEditMenu() {
    return SubmenuButton(
      menuChildren: [
        _addMenuItem('Undo', () => print('Undo clicked'), shortcut: 'Ctrl + Z'),
        _addMenuItem('Redo', () => print('Redo clicked'), shortcut: 'Ctrl + Y'),
        const Divider(),
        _addMenuItem('Cut', () => print('Cut clicked'), shortcut: 'Ctrl + X'),
        _addMenuItem('Copy', () => print('Copy clicked'), shortcut: 'Ctrl + C'),
        _addMenuItem('Paste', () => print('Paste clicked'),
            shortcut: 'Ctrl + V'),
      ],
      menuStyle:
          const MenuStyle(padding: MaterialStatePropertyAll(EdgeInsets.all(5))),
      child: const Text("Edit"),
    );
  }

  // * Building Settings Menu in Menu bar
  SubmenuButton buildSettingsMenu() {
    return SubmenuButton(menuChildren: [
      _addMenuItem('Open Configuration', () => print('Settings clicked')),
    ], child: const Text("Settings"));
  }

  // * Building Help Menu in Menu bar
  SubmenuButton buildHelpMenu() {
    return SubmenuButton(menuChildren: [
      _addMenuItem('About Us', () => print('Help clicked')),
    ], child: const Text("Help"));
  }

  // * Adding Menu Item for menu
  MenuItemButton _addMenuItem(String text, VoidCallback onPressed,
      {String? shortcut}) {
    return MenuItemButton(
        onPressed: onPressed,
        trailingIcon: shortcut != null && shortcut.isNotEmpty
            ? Text(
                shortcut,
                style: const TextStyle(color: Colors.grey),
              )
            : null,
        child: Text(text));
  }
}

// * A custom intent to handle different menu actions
class ActivateIntent extends Intent {
  const ActivateIntent(this.action);
  final String action;
}
