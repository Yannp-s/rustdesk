import 'package:flutter/material.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/models/platform_model.dart';

/// Tablet (pad) first-run profile.
///
/// RustDesk upstream ships phone-oriented defaults: `view_style = adaptive`
/// (the remote frame is scaled to fit the screen with interpolation) and
/// `image_quality = balanced` (a low bitrate ratio).  On a 3200x2136 tablet
/// that combination is what makes a remote desktop look soft, because the
/// picture is both upscaled and bitrate-starved.
///
/// This profile runs once on the first launch on a large-screen Android
/// device and switches the defaults to "1:1 pixels + high bitrate + 60fps".
/// It is guarded by a marker key so any later user change is never
/// overwritten.
const String kPadProfileMarker = 'pad4k-profile-v1';

/// Custom image quality value. `custom_image_quality` is mapped by the
/// server to a bitrate ratio of `quality * 2 / 100` (see
/// `src/server/video_qos.rs`), clamped to `BR_MAX = 40.0`, so 200 means a
/// 4x bitrate ratio, which is the "ultra" preset used by this build.
const int kPadImageQuality = 200;

const int kPadFps = 60;

/// Android large-screen threshold in dp, the same one the platform uses to
/// distinguish a tablet from a phone.
const double kPadMinShortestSideDp = 600;

bool get isTabletScreen {
  final view = WidgetsBinding.instance.platformDispatcher.implicitView;
  if (view == null) return false;
  final size = view.physicalSize / view.devicePixelRatio;
  return size.shortestSide >= kPadMinShortestSideDp;
}

/// Applies the ultra-clear tablet profile once. Safe to call on every start.
Future<void> applyTabletProfileIfNeeded() async {
  if (!isAndroid || !isTabletScreen) return;
  final applied = await bind.mainGetUserDefaultOption(key: kPadProfileMarker);
  if (applied == 'Y') return;

  await bind.mainSetUserDefaultOption(
      key: kOptionViewStyle, value: kRemoteViewStyleOriginal);
  await bind.mainSetUserDefaultOption(
      key: kOptionImageQuality, value: kRemoteImageQualityCustom);
  await bind.mainSetUserDefaultOption(
      key: 'custom_image_quality', value: '$kPadImageQuality');
  await bind.mainSetUserDefaultOption(key: 'custom-fps', value: '$kPadFps');
  await bind.mainSetUserDefaultOption(key: kPadProfileMarker, value: 'Y');
  debugPrint('[pad] ultra-clear tablet profile applied');
}
