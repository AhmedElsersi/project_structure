// Tests for lib/core/services/image_picker_service.dart. Source: new
//
// ImagePicker is mocked with mocktail; the compressor is a fake that records
// the tier it was asked for. Files are real temp files (sizes matter).
import 'dart:io';

import 'package:app_template/core/errors/failure.dart';
import 'package:app_template/core/result/result.dart';
import 'package:app_template/core/services/image_picker_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mocktail/mocktail.dart';

class _MockPicker extends Mock implements ImagePicker {}

class _FakeCompressor implements ImageCompressor {
  final List<(int quality, int minSide)> calls = [];
  int outputBytes = 1000;
  bool fail = false;

  @override
  Future<XFile?> compress(String sourcePath, String targetPath, {required int quality, required int minSide}) async {
    calls.add((quality, minSide));
    if (fail) return null;
    await File(targetPath).writeAsBytes(List<int>.filled(outputBytes, 1));
    return XFile(targetPath);
  }
}

void main() {
  late Directory temp;
  late _MockPicker picker;
  late _FakeCompressor compressor;
  late ImagePickerService service;

  Future<XFile> fileOf(int bytes) async {
    final file = File('${temp.path}/picked_$bytes.jpg');
    await file.writeAsBytes(List<int>.filled(bytes, 0));
    return XFile(file.path);
  }

  void pickerReturns(Future<XFile?> Function() answer) => when(
    () => picker.pickImage(
      source: any(named: 'source'),
      maxWidth: any(named: 'maxWidth'),
      maxHeight: any(named: 'maxHeight'),
      requestFullMetadata: any(named: 'requestFullMetadata'),
    ),
  ).thenAnswer((_) => answer());

  setUpAll(() => registerFallbackValue(ImageSource.gallery));

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('picker_test');
    picker = _MockPicker();
    compressor = _FakeCompressor();
    service = ImagePickerService(picker: picker, compressor: compressor, isAndroid: true);
  });

  tearDown(() => temp.delete(recursive: true));

  group('CompressionTier.forBytes', () {
    const kb = 1024;
    const mb = 1024 * 1024;
    test('≤300 KB untouched', () => expect(CompressionTier.forBytes(300 * kb), isNull));
    test('≤2 MB q85 / 1920', () => expect(CompressionTier.forBytes(2 * mb), const CompressionTier(85, 1920)));
    test('≤5 MB q75 / 1600', () => expect(CompressionTier.forBytes(5 * mb), const CompressionTier(75, 1600)));
    test('larger q65 / 1280', () => expect(CompressionTier.forBytes(5 * mb + 1), const CompressionTier(65, 1280)));
  });

  test('cancel → Ok(null)', () async {
    pickerReturns(() async => null);
    expect(await service.pick(ImageSource.camera), const Ok<XFile?>(null));
  });

  test('a small image is returned untouched', () async {
    final small = await fileOf(1000);
    pickerReturns(() async => small);
    final result = await service.pick(ImageSource.gallery);
    expect(result.valueOrNull?.path, small.path);
    expect(compressor.calls, isEmpty);
  });

  test('a large image is compressed with its tier, capped by maxDimension', () async {
    final large = await fileOf(600 * 1024);
    pickerReturns(() async => large);
    final result = await service.pick(ImageSource.gallery, maxDimension: 1080);
    expect(compressor.calls, [(85, 1080)]);
    expect(result.valueOrNull?.path, isNot(large.path));
    expect(await result.valueOrNull!.length(), 1000);
  });

  test('compression failure or growth keeps the original', () async {
    final large = await fileOf(600 * 1024);
    pickerReturns(() async => large);
    compressor.fail = true;
    expect((await service.pick(ImageSource.gallery)).valueOrNull?.path, large.path);

    compressor
      ..fail = false
      ..outputBytes = 700 * 1024;
    expect((await service.pick(ImageSource.gallery)).valueOrNull?.path, large.path);
  });

  test('camera_access_denied → PermissionFailure(permanentlyDenied)', () async {
    pickerReturns(() => throw PlatformException(code: 'camera_access_denied'));
    final failure = (await service.pick(ImageSource.camera)).failureOrNull;
    expect(failure, isA<PermissionFailure>().having((f) => f.permanentlyDenied, 'permanentlyDenied', isTrue));
  });

  test('other plugin errors → UnknownFailure; already_active → Ok(null)', () async {
    pickerReturns(() => throw PlatformException(code: 'no_available_camera'));
    expect((await service.pick(ImageSource.camera)).failureOrNull, isA<UnknownFailure>());

    pickerReturns(() => throw PlatformException(code: 'already_active'));
    expect(await service.pick(ImageSource.camera), const Ok<XFile?>(null));
  });

  group('retrieveLostData', () {
    test('returns the recovered file on Android', () async {
      final lost = await fileOf(1000);
      when(
        () => picker.retrieveLostData(),
      ).thenAnswer((_) async => LostDataResponse(file: lost, type: RetrieveType.image, files: [lost]));
      expect((await service.retrieveLostData()).valueOrNull?.path, lost.path);
    });

    test('nothing lost → Ok(null)', () async {
      when(() => picker.retrieveLostData()).thenAnswer((_) async => LostDataResponse.empty());
      expect(await service.retrieveLostData(), const Ok<XFile?>(null));
    });

    test('a lost permission error maps like pick()', () async {
      when(() => picker.retrieveLostData()).thenAnswer(
        (_) async => LostDataResponse(
          exception: PlatformException(code: 'photo_access_denied'),
          type: RetrieveType.image,
        ),
      );
      expect((await service.retrieveLostData()).failureOrNull, isA<PermissionFailure>());
    });

    test('not Android → Ok(null) without touching the plugin', () async {
      final ios = ImagePickerService(picker: picker, compressor: compressor, isAndroid: false);
      expect(await ios.retrieveLostData(), const Ok<XFile?>(null));
      verifyNever(() => picker.retrieveLostData());
    });
  });
}
