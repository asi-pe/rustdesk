import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/mobile/widgets/dialog.dart';
import 'package:flutter_hbb/models/platform_model.dart';

const String kOptionSavedPrivateServer = 'saved-private-server';

/// One-click switch between the public RustDesk server and a private one.
///
/// The private server's settings are remembered in a local option, so
/// switching back to private does not require typing them again.
class ServerSwitchWidget extends StatelessWidget {
  final RxBool isUsingPublicServer;

  const ServerSwitchWidget({Key? key, required this.isUsingPublicServer})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Obx(() => SegmentedButton<bool>(
          showSelectedIcon: false,
          style: ButtonStyle(
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          segments: [
            ButtonSegment(value: true, label: Text(translate('Public server'))),
            ButtonSegment(
                value: false, label: Text(translate('Private server'))),
          ],
          selected: {isUsingPublicServer.value},
          onSelectionChanged: (selection) async {
            final toPublic = selection.first;
            if (toPublic == isUsingPublicServer.value) return;
            if (toPublic) {
              await _switchToPublicServer();
              isUsingPublicServer.value = true;
            } else if (await _switchToPrivateServer()) {
              isUsingPublicServer.value = false;
            }
          },
        ));
  }
}

Future<ServerConfig> _currentServerConfig() async {
  Map<String, dynamic> options = {};
  try {
    options = jsonDecode(await bind.mainGetOptions());
  } catch (_) {}
  return ServerConfig.fromOptions(options);
}

Future<void> _switchToPublicServer() async {
  final current = await _currentServerConfig();
  if (current.idServer.isNotEmpty) {
    await bind.mainSetLocalOption(
        key: kOptionSavedPrivateServer, value: current.encode());
  }
  await setServerConfig(null, null, ServerConfig());
}

/// Returns false when no private server is saved yet; the server settings
/// dialog is opened instead so the user can enter it once.
Future<bool> _switchToPrivateServer() async {
  final saved = bind.mainGetLocalOption(key: kOptionSavedPrivateServer);
  ServerConfig? config;
  if (saved.isNotEmpty) {
    try {
      config = ServerConfig.decode(saved);
    } catch (_) {}
  }
  if (config == null || config.idServer.isEmpty) {
    showServerSettings(gFFI.dialogManager, (fn) => fn());
    return false;
  }
  return setServerConfig(null, null, config);
}
