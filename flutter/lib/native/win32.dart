import 'dart:ffi' hide Size;

import 'package:ffi/ffi.dart';

import 'package:win32/win32.dart' as win32;

/// Get windows target build number.
///
/// [Note]
/// Please use this function wrapped with `Platform.isWindows`.
int getWindowsTargetBuildNumber_() {
  final rtlGetVersion = DynamicLibrary.open('ntdll.dll').lookupFunction<
      Void Function(Pointer<win32.OSVERSIONINFOEX>),
      void Function(Pointer<win32.OSVERSIONINFOEX>)>('RtlGetVersion');
  final osVersionInfo = _getOSVERSIONINFOEXPointer();
  rtlGetVersion(osVersionInfo);
  int buildNumber = osVersionInfo.ref.dwBuildNumber;
  calloc.free(osVersionInfo);
  return buildNumber;
}

/// Get Windows OS version pointer
///
/// [Note]
/// Please use this function wrapped with `Platform.isWindows`.
Pointer<win32.OSVERSIONINFOEX> _getOSVERSIONINFOEXPointer() {
  final pointer = calloc<win32.OSVERSIONINFOEX>();
  pointer.ref
    ..dwOSVersionInfoSize = sizeOf<win32.OSVERSIONINFOEX>()
    ..dwBuildNumber = 0
    ..dwMajorVersion = 0
    ..dwMinorVersion = 0
    ..dwPlatformId = 0
    ..szCSDVersion = ''
    ..wServicePackMajor = 0
    ..wServicePackMinor = 0
    ..wSuiteMask = 0
    ..wProductType = 0
    ..wReserved = 0;
  return pointer;
}

/// Windows "Mouse pointer size" (Settings > Accessibility > Mouse pointer), 1..15.
///
/// [Note]
/// Please use this function wrapped with `Platform.isWindows`.
int getWindowsCursorSize_() {
  final regGetValue = DynamicLibrary.open('advapi32.dll').lookupFunction<
      Int32 Function(IntPtr, Pointer<Utf16>, Pointer<Utf16>, Uint32,
          Pointer<Uint32>, Pointer<Uint32>, Pointer<Uint32>),
      int Function(IntPtr, Pointer<Utf16>, Pointer<Utf16>, int, Pointer<Uint32>,
          Pointer<Uint32>, Pointer<Uint32>)>('RegGetValueW');
  const hkeyCurrentUser = 0x80000001;
  const rrfRtRegDword = 0x00000010;
  final subKey = r'Software\Microsoft\Accessibility'.toNativeUtf16();
  final valueName = 'CursorSize'.toNativeUtf16();
  final data = calloc<Uint32>();
  final dataSize = calloc<Uint32>()..value = sizeOf<Uint32>();
  try {
    final res = regGetValue(hkeyCurrentUser, subKey, valueName, rrfRtRegDword,
        nullptr, data, dataSize);
    if (res != 0) return 1;
    return data.value.clamp(1, 15).toInt();
  } finally {
    calloc.free(subKey);
    calloc.free(valueName);
    calloc.free(data);
    calloc.free(dataSize);
  }
}
