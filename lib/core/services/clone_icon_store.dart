import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:path_provider/path_provider.dart';

/// Keeps the pictures users pick as their clones' icons.
///
/// Stored as files rather than in the profile record: a profile is a small JSON row that
/// is read and rewritten on every change, and a few hundred kilobytes of PNG in each one
/// would turn every rename into a rewrite of every icon.
///
/// One file per clone, named by profile id, so a clone can only ever have one and
/// deleting the clone has an obvious file to delete.
class CloneIconStore {
  CloneIconStore({Future<Directory> Function()? directoryProvider})
      : _directoryProvider = directoryProvider ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _directoryProvider;

  /// The size icons are normalised to.
  ///
  /// 256 rather than the 192 a launcher shortcut needs: the grid draws them larger on a
  /// dense screen, and a picture stored at exactly the smallest useful size is the one
  /// that looks soft everywhere else.
  static const int iconSize = 256;

  /// The width a chosen picture is decoded at, before it is cropped and scaled down.
  ///
  /// Four times [iconSize]: far more detail than the result can hold, so nothing is lost,
  /// while a picture of any size costs a few megabytes to decode rather than tens.
  static const int _decodeCap = iconSize * 4;

  /// Normalises [source] and stores it as this clone's icon, returning the file's path.
  ///
  /// The picture is centre-cropped to a square and scaled, never stretched: an icon that
  /// is subtly the wrong shape reads as a bug in the app rather than as the picture the
  /// user chose.
  Future<String> save({
    required String profileId,
    required Uint8List source,
  }) async {
    final Uint8List png = await _square(source);
    final File file = await _fileFor(profileId);
    await file.parent.create(recursive: true);
    // Written beside the target and renamed, so a failure part-way through cannot leave a
    // half-written icon where a whole one used to be.
    final File staging = File('${file.path}.tmp');
    await staging.writeAsBytes(png, flush: true);
    await staging.rename(file.path);
    return file.path;
  }

  /// This clone's icon, or null when it has none or the file has gone.
  Future<Uint8List?> read(String? path) async {
    if (path == null) {
      return null;
    }
    final File file = File(path);
    if (!await file.exists()) {
      return null;
    }
    return file.readAsBytes();
  }

  /// Forgets this clone's icon. Safe to call when there is none.
  Future<void> delete(String profileId) async {
    final File file = await _fileFor(profileId);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<File> _fileFor(String profileId) async {
    final Directory root = await _directoryProvider();
    return File('${root.path}/clone_icons/$profileId.png');
  }

  /// Centre-crops to a square and scales to [iconSize], as PNG.
  static Future<Uint8List> _square(Uint8List source) async {
    // Decoded at a cap rather than at full size. A photo straight from a camera is
    // twelve megapixels, which is about 48 MB of RGBA before anything is drawn -- a real
    // risk on a cheap phone that is also hosting a container. Only the width is given, so
    // the aspect ratio is kept and the crop below still has something square to take.
    final ui.Codec codec = await ui.instantiateImageCodec(
      source,
      targetWidth: _decodeCap,
    );
    final ui.Image image;
    try {
      image = (await codec.getNextFrame()).image;
    } finally {
      // The codec holds native memory of its own, separate from the frame's image, and
      // is of no further use once the first frame is out.
      codec.dispose();
    }

    try {
      final double side =
          image.width < image.height ? image.width.toDouble() : image.height.toDouble();
      final ui.Rect src = ui.Rect.fromLTWH(
        (image.width - side) / 2,
        (image.height - side) / 2,
        side,
        side,
      );
      const ui.Rect dst = ui.Rect.fromLTWH(0, 0, iconSize * 1.0, iconSize * 1.0);

      final ui.PictureRecorder recorder = ui.PictureRecorder();
      ui.Canvas(recorder, dst).drawImageRect(
        image,
        src,
        dst,
        ui.Paint()..filterQuality = ui.FilterQuality.high,
      );
      // The picture is native memory too, and is finished with the moment it has been
      // rasterised.
      final ui.Picture picture = recorder.endRecording();
      final ui.Image output;
      try {
        output = await picture.toImage(iconSize, iconSize);
      } finally {
        picture.dispose();
      }
      try {
        final ByteData? png =
            await output.toByteData(format: ui.ImageByteFormat.png);
        if (png == null) {
          throw const FileSystemException('The chosen picture could not be encoded.');
        }
        return png.buffer.asUint8List();
      } finally {
        output.dispose();
      }
    } finally {
      image.dispose();
    }
  }
}
