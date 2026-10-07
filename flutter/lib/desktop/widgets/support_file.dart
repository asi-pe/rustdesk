import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/desktop/widgets/server_switch.dart';

const String _portableUrl =
    'https://github.com/rustdesk/rustdesk/releases/download/1.5.0/rustdesk-1.5.0-x86_64.exe';

/// Button that exports a support file for the person being helped.
///
/// The file is built from the private server saved in this RustDesk, so no
/// server details live in the source code.
class SupportFileButton extends StatelessWidget {
  const SupportFileButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      icon: const Icon(Icons.support_agent, size: 18),
      label: Text(translate('Create support file')),
      onPressed: () => _createSupportFile(),
    );
  }
}

Future<void> _createSupportFile() async {
  final config = await privateServerConfig();
  if (config == null) {
    showToast(translate('support_file_no_private_server_tip'));
    return;
  }
  final path = await FilePicker.platform.saveFile(
    dialogTitle: translate('Create support file'),
    fileName: 'RustDesk-Support.bat',
    allowedExtensions: ['bat'],
    type: FileType.custom,
  );
  if (path == null) return;
  try {
    await File(path).writeAsString(buildSupportBat(config.idServer, config.key),
        flush: true);
    showToast(translate('Successful'));
  } catch (e) {
    showToast('${translate('Failed')}: $e');
  }
}

String _psMessage(String text) {
  final rtl = RegExp(r'[֐-ࣿ]').hasMatch(text);
  final options = rtl
      ? ",'OK','Information','Button1',([System.Windows.Forms.MessageBoxOptions]::RtlReading -bor [System.Windows.Forms.MessageBoxOptions]::RightAlign)"
      : ",'OK','Information'";
  final ps = "Add-Type -AssemblyName System.Windows.Forms;"
      "[System.Windows.Forms.MessageBox]::Show('${text.replaceAll("'", "''")}','RustDesk'$options) | Out-Null";
  final units = ps.codeUnits;
  final bytes = Uint8List(units.length * 2);
  for (var i = 0; i < units.length; i++) {
    bytes[i * 2] = units[i] & 0xFF;
    bytes[i * 2 + 1] = units[i] >> 8;
  }
  return 'powershell -NoProfile -EncodedCommand ${base64Encode(bytes)}';
}

/// Windows batch file for the person being helped:
/// - RustDesk installed: switches it to [host] until they press OK, then back
///   to the public server. Running the file again also reverts.
/// - Not installed: runs the official portable RustDesk with [host] taken
///   from its file name, which changes nothing on the computer.
String buildSupportBat(String host, String key) {
  final active = _psMessage(translate('support_file_active_tip'));
  final done = _psMessage(translate('support_file_done_tip'));
  final reverted = _psMessage(translate('support_file_reverted_tip'));
  final portable = _psMessage(translate('support_file_portable_tip'));
  final failed = _psMessage(translate('support_file_download_failed_tip'));
  final lines = <String>[
    '@echo off',
    'setlocal',
    'set "HOST=$host"',
    'set "KEY=$key"',
    r'set "MARK=%ProgramData%\RustDeskSupport.active"',
    '',
    'net session >nul 2>&1',
    'if errorlevel 1 (',
    '  powershell -NoProfile -Command "Start-Process -FilePath \'%~f0\' -Verb RunAs"',
    '  exit /b',
    ')',
    '',
    'set "RD="',
    r'if exist "%ProgramFiles%\RustDesk\rustdesk.exe" set "RD=%ProgramFiles%\RustDesk\rustdesk.exe"',
    r'if not defined RD if exist "%ProgramFiles(x86)%\RustDesk\rustdesk.exe" set "RD=%ProgramFiles(x86)%\RustDesk\rustdesk.exe"',
    'if not defined RD goto portable',
    '',
    'if exist "%MARK%" goto revert_previous',
    'echo active> "%MARK%"',
    'start "" /wait "%RD%" --config "host=%HOST%,key=%KEY%,"',
    'start "" /wait "%RD%" --option stop-service ""',
    'net start RustDesk >nul 2>&1',
    'start "" "%RD%"',
    active,
    'call :revert',
    done,
    'exit /b',
    '',
    ':revert_previous',
    'call :revert',
    reverted,
    'exit /b',
    '',
    ':revert',
    'start "" /wait "%RD%" --option custom-rendezvous-server ""',
    'start "" /wait "%RD%" --option relay-server ""',
    'start "" /wait "%RD%" --option api-server ""',
    'start "" /wait "%RD%" --option key ""',
    'del "%MARK%" >nul 2>&1',
    'exit /b',
    '',
    ':portable',
    r'set "DIR=%TEMP%\RustDeskSupport"',
    'if not exist "%DIR%" mkdir "%DIR%"',
    r'set "EXE=%DIR%\rustdesk-host=%HOST%,key=%KEY%,.exe"',
    'if not exist "%EXE%" curl -sL -o "%EXE%" "$_portableUrl"',
    'if not exist "%EXE%" goto download_failed',
    'start "" "%EXE%"',
    portable,
    'exit /b',
    '',
    ':download_failed',
    failed,
    'exit /b',
  ];
  return '${lines.join('\r\n')}\r\n';
}

