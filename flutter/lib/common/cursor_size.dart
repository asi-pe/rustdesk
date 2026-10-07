import 'package:get/get.dart';

import 'package:flutter_hbb/common.dart' show isWindows;
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/native/win32.dart'
    if (dart.library.html) 'package:flutter_hbb/web/win32.dart';

const String kOptionRemoteCursorSize = 'remote-cursor-size';
const String kRemoteCursorSizeSystem = 'system';
const String kRemoteCursorSizeDefault = '100';

List<String> remoteCursorSizeChoices() => [
      if (isWindows) kRemoteCursorSizeSystem,
      '100',
      '150',
      '200',
      '250',
      '300',
    ];

final remoteCursorSize = _loadRemoteCursorSize().obs;

String _loadRemoteCursorSize() {
  final v = bind.mainGetLocalOption(key: kOptionRemoteCursorSize);
  return remoteCursorSizeChoices().contains(v) ? v : kRemoteCursorSizeDefault;
}

Future<void> setRemoteCursorSize(String value) async {
  await bind.mainSetLocalOption(key: kOptionRemoteCursorSize, value: value);
  remoteCursorSize.value = value;
}

/// Multiplier applied on top of RustDesk's own cursor scale.
///
/// "System" follows Windows "Mouse pointer size" (Accessibility CursorSize 1..15),
/// where size n is 32 + 16 * (n - 1) pixels, i.e. (n + 1) / 2 times the default.
double remoteCursorSizeMultiplier() {
  final v = remoteCursorSize.value;
  if (v == kRemoteCursorSizeSystem) {
    if (!isWindows) return 1.0;
    return (getWindowsCursorSize_() + 1) / 2.0;
  }
  return (int.tryParse(v) ?? 100) / 100.0;
}
