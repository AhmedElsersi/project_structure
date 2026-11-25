// "Take a photo / Choose from gallery" picker that only RETURNS the choice.
//
// Source: chinaparts-seller lib/core/utilities/widgets/image_handelers/image_picker_bottom_sheet.dart
//         (camera + gallery ListTiles in the app sheet).
// Merged: chinaparts-customer lib/core/utilities/widgets/image_picker_bottom_sheet.dart,
//         brgr lib/core/utilities/widgets/image_picker_bottom_sheet.dart —
//         rewritten to return an ImageSource instead of picking inside the
//         sheet with a context that was already popped (permission handling
//         and picking belong to the caller / a picker service).
// See docs/WIDGETS.md#media.
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/localization/generated/locale_keys.g.dart';
import '../feedback/app_bottom_sheet.dart';

/// Asks where an image should come from. Resolves to [ImageSource.camera],
/// [ImageSource.gallery], or null when dismissed. [title] is already
/// translated; defaults to "Add a photo".
Future<ImageSource?> showImageSourceSheet(BuildContext context, {String? title}) => showAppBottomSheet<ImageSource>(
  context,
  title: title ?? LocaleKeys.widgets_image_source_title.tr(),
  builder: (sheetContext) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ListTile(
        leading: const Icon(Icons.photo_camera_outlined),
        title: Text(LocaleKeys.widgets_camera.tr()),
        onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
      ),
      ListTile(
        leading: const Icon(Icons.photo_library_outlined),
        title: Text(LocaleKeys.widgets_gallery.tr()),
        onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
      ),
    ],
  ),
);
