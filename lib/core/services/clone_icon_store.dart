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

  /// The longest side a chosen picture is decoded at, before it is cropped and scaled.
  ///
  /// Four times [iconSize]: far more detail than the result can hold, so nothing is lost,
  /// while a picture of any size costs a few megabytes to decode rather than tens.
  ///
  /// The *longest* side, not the width, which is what this used to cap. Capping the
  /// width leaves the pixel count riding on the picture's shape: hold the width at the
  /// cap and scale the height to match, and the decode comes to `cap² × height/width` —
  /// which has no upper bound, because a picture can be as narrow as it likes. Capping
  /// the longest side instead puts a real ceiling on it, `cap²`, whatever the shape.
  ///
  /// The width cap also *raised* the cost for anything narrower than itself, since
  /// `targetWidth` is a target and not a maximum: a 64-pixel-wide strip was decoded at
  /// 1024 wide. Upscaling invents no detail, and the result is thrown away by the scale
  /// down to [iconSize] regardless.
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
    // risk on a cheap phone that is also hosting a container.
    //
    // `instantiateImageCodecWithSize` rather than `instantiateImageCodec`, because it is
    // the one that hands over the picture's own dimensions before any pixels are decoded.
    // That is what makes the cap a cap: the longer side is measured, and only ever
    // brought down. One target is given and the other follows the aspect ratio, so the
    // crop below still has something square to take.
    //
    // Worth saying what this is not: an extreme picture did not bring the old path down.
    // A 64x12000 strip, whose width cap asked for a 1024x192000 decode, produced an icon
    // on an API 35 device without an allocation failure — the engine did not hand back
    // the pixel count the arithmetic suggests. This is the cheaper and more predictable
    // way to ask, not a repair for a crash anyone has seen.
    final ui.Codec codec = await ui.instantiateImageCodecWithSize(
      await ui.ImmutableBuffer.fromUint8List(source),
      getTargetSize: (int width, int height) {
        final int longest = width > height ? width : height;
        // Already small enough: decode it as it is rather than resampling for nothing.
        if (longest <= _decodeCap) {
          return const ui.TargetImageSize();
        }
        return width >= height
            ? const ui.TargetImageSize(width: _decodeCap)
            : const ui.TargetImageSize(height: _decodeCap);
      },
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
