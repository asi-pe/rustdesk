import 'dart:typed_data';

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

const String kOptionRemoteCursorColor = 'remote-cursor-color';
const String kRemoteCursorColorDefault = 'default';

/// Choices for the remote cursor fill color, as (option value, label, ARGB).
const List<(String, String, int)> kRemoteCursorColors = [
  (kRemoteCursorColorDefault, 'Default', 0xFFFFFFFF),
  ('red', 'Red', 0xFFE53935),
  ('orange', 'Orange', 0xFFFB8C00),
  ('yellow', 'Yellow', 0xFFFFEB3B),
  ('green', 'Green', 0xFF43A047),
  ('blue', 'Blue', 0xFF1E88E5),
  ('pink', 'Pink', 0xFFE91E63),
];

final remoteCursorColor = _loadRemoteCursorColor().obs;

String _loadRemoteCursorColor() {
  final v = bind.mainGetLocalOption(key: kOptionRemoteCursorColor);
  return kRemoteCursorColors.any((e) => e.$1 == v)
      ? v
      : kRemoteCursorColorDefault;
}

Future<void> setRemoteCursorColor(String value) async {
  await bind.mainSetLocalOption(key: kOptionRemoteCursorColor, value: value);
  remoteCursorColor.value = value;
}

/// Paints the light fill of a remote cursor (straight RGBA) with the chosen
/// color, keeping the dark outline so the shape stays readable.
Uint8List recolorRemoteCursor(Uint8List rgba) {
  final choice = kRemoteCursorColors
      .firstWhereOrNull((e) => e.$1 == remoteCursorColor.value);
  if (choice == null || choice.$1 == kRemoteCursorColorDefault) return rgba;
  final r = (choice.$3 >> 16) & 0xFF;
  final g = (choice.$3 >> 8) & 0xFF;
  final b = choice.$3 & 0xFF;
  final out = Uint8List.fromList(rgba);
  for (var i = 0; i + 3 < out.length; i += 4) {
    if (out[i + 3] > 0 && out[i] > 200 && out[i + 1] > 200 && out[i + 2] > 200) {
      out[i] = r;
      out[i + 1] = g;
      out[i + 2] = b;
    }
  }
  return out;
}
