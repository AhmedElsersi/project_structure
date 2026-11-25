// Picks one image from the camera or gallery, shrinks it by size tier, and
// recovers a capture lost when Android killed the app behind the camera.
//
// Source: brgr lib/core/services/image_picker_service.dart (size tiers: ≤300 KB
//         untouched, ≤2 MB q85/1920, ≤5 MB q75/1600, larger q65/1280;
//         retrieveLostData on Android).
// Merged: instaops lib/core/services/pending_capture_service.dart (recover the
//         lost capture at startup); baytna compression_plan.dart (pure,
//         testable plan). Rejected: brgr's SnackBars on a popped context — this
//         returns Result and the caller decides what to show.
// See docs/SERVICES.md#imagepickerservice.
import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../errors/failure.dart';
import '../result/result.dart';

/// Re-encodes an image. Behind an interface so tests don't need the plugin.
abstract interface class ImageCompressor {
  /// Writes a JPEG of [sourcePath] at [quality] (0–100) to [targetPath],
  /// scaled down so its shorter side is about [minSide] px (never upscaled).
  /// Returns the new file, or null when compression failed.
  Future<XFile?> compress(String sourcePath, String targetPath, {required int quality, required int minSide});
}

/// flutter_image_compress implementation (EXIF stripped, orientation fixed).
class FlutterImageCompressor implements ImageCompressor {
  const FlutterImageCompressor();

  @override
  Future<XFile?> compress(String sourcePath, String targetPath, {required int quality, required int minSide}) =>
      FlutterImageCompress.compressAndGetFile(
        sourcePath,
        targetPath,
        quality: quality,
        minWidth: minSide,
        minHeight: minSide,
        format: CompressFormat.jpeg,
      );
}

/// One compression tier: JPEG [quality] and target [dimension] in px.
@immutable
class CompressionTier {
  const CompressionTier(this.quality, this.dimension);
  final int quality;
  final int dimension;

  static const int _kb = 1024;
  static const int _mb = 1024 * 1024;

  /// Tier for a file of [bytes]; null means "small enough, keep it".
  static CompressionTier? forBytes(int bytes) {
    if (bytes <= 300 * _kb) return null;
    if (bytes <= 2 * _mb) return const CompressionTier(85, 1920);
    if (bytes <= 5 * _mb) return const CompressionTier(75, 1600);
    return const CompressionTier(65, 1280);
  }

  @override
  bool operator ==(Object other) =>
      other is CompressionTier && other.quality == quality && other.dimension == dimension;

  @override
  int get hashCode => Object.hash(quality, dimension);

  @override
  String toString() => 'CompressionTier(q$quality, ${dimension}px)';
}

class ImagePickerService {
  ImagePickerService({ImagePicker? picker, ImageCompressor? compressor, bool? isAndroid})
    : _picker = picker ?? ImagePicker(),
      _compressor = compressor ?? const FlutterImageCompressor(),
      _isAndroid = isAndroid ?? (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  final ImagePicker _picker;
  final ImageCompressor _compressor;
  final bool _isAndroid;

  /// Opens the camera or gallery. `Ok(null)` = the user cancelled.
  /// `Err(PermissionFailure(permanentlyDenied: true))` = access is off in
  /// Settings (offer `PermissionService.openSettings`).
  Future<Result<XFile?>> pick(ImageSource source, {double maxDimension = 1920}) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: maxDimension,
        maxHeight: maxDimension,
        requestFullMetadata: false,
      );
      if (picked == null) return const Ok<XFile?>(null);
      return Ok<XFile?>(await optimize(picked, maxDimension: maxDimension));
    } on PlatformException catch (e) {
      return _fromPlatform(e);
    } on Object catch (e) {
      return Err<XFile?>(UnknownFailure(debugMessage: 'pickImage: $e'));
    }
  }

  /// Android may kill the app while the camera is open; the picked file then
  /// arrives here on the next launch. Call once at startup (or when the
  /// screen that started the capture opens again). `Ok(null)` = nothing lost.
  Future<Result<XFile?>> retrieveLostData({double maxDimension = 1920}) async {
    if (!_isAndroid) return const Ok<XFile?>(null);
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return const Ok<XFile?>(null);
      final error = response.exception;
      if (error != null) return _fromPlatform(error);
      final file = response.file ?? response.files?.firstOrNull;
      if (file == null) return const Ok<XFile?>(null);
      return Ok<XFile?>(await optimize(file, maxDimension: maxDimension));
    } on Object catch (e) {
      return Err<XFile?>(UnknownFailure(debugMessage: 'retrieveLostData: $e'));
    }
  }

  /// Applies the size tier to [file]. Any compression problem returns the
  /// original: a large upload is better than a lost photo.
  Future<XFile> optimize(XFile file, {double maxDimension = 1920}) async {
    if (kIsWeb) return file;
    try {
      final tier = CompressionTier.forBytes(await file.length());
      if (tier == null) return file;
      final side = tier.dimension < maxDimension ? tier.dimension : maxDimension.round();
      final compressed = await _compressor.compress(
        file.path,
        _targetPath(file.path),
        quality: tier.quality,
        minSide: side,
      );
      if (compressed == null) return file;
      // Keep whichever is smaller (re-encoding an optimized JPEG can grow it).
      return await compressed.length() < await file.length() ? compressed : file;
    } on Object {
      return file;
    }
  }

  static String _targetPath(String source) {
    final dir = File(source).parent.path;
    return '$dir${Platform.pathSeparator}img_${DateTime.now().microsecondsSinceEpoch}.jpg';
  }

  static Result<XFile?> _fromPlatform(PlatformException e) => switch (e.code) {
    'camera_access_denied' ||
    'photo_access_denied' => Err<XFile?>(PermissionFailure(permanentlyDenied: true, debugMessage: e.code)),
    // A second tap while the picker is already open: nothing to report.
    'already_active' => const Ok<XFile?>(null),
    _ => Err<XFile?>(UnknownFailure(debugMessage: 'image_picker ${e.code}: ${e.message}')),
  };
}
