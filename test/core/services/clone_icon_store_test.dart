import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:duplika/core/services/clone_icon_store.dart';
import 'package:flutter_test/flutter_test.dart';

/// What a picture the user chose is allowed to become before it is drawn as a clone.
///
/// The pictures here are generated rather than checked in, so each test says in its own
/// body what shape and colours it is about. The two properties every case shares — the
/// result is [CloneIconStore.iconSize] square, and it is a PNG — are what the grid and the
/// launcher shortcut both depend on, so they are asserted even where the test is about
/// something else.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late CloneIconStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('clone-icons-test');
    store = CloneIconStore(directoryProvider: () async => root);
  });

  tearDown(() async {
    if (root.existsSync()) {
      await root.delete(recursive: true);
    }
  });

  group('save', () {
    test('normalises a square picture to the icon size', () async {
      final String path = await store.save(
        profileId: 'p1',
        source: await _solid(64, 64, _red),
      );

      final _Decoded icon = await _decode(File(path).readAsBytesSync());
      expect(icon.width, CloneIconStore.iconSize);
      expect(icon.height, CloneIconStore.iconSize);
    });

    test('writes a PNG, whatever was handed in', () async {
      final String path = await store.save(
        profileId: 'p1',
        source: await _solid(64, 64, _red),
      );

      // The first eight bytes of the PNG signature. The shortcut is drawn by
      // BitmapFactory.decodeFile on the Kotlin side, which is told nothing about the
      // format and works it out from these.
      expect(
        File(path).readAsBytesSync().take(8),
        <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
      );
    });

    test('takes the middle of a wide picture, not the left of it', () async {
      // Three equal bands. A centre crop can only come back green; a crop that started
      // at the origin would come back red.
      final Uint8List source = await _bands(300, 100, <ui.Color>[_red, _green, _blue]);

      final String path = await store.save(profileId: 'p1', source: source);

      final _Decoded icon = await _decode(File(path).readAsBytesSync());
      expect(icon.width, CloneIconStore.iconSize);
      expect(icon.height, CloneIconStore.iconSize);
      expect(icon.at(8, 128), _green, reason: 'left edge of the crop');
      expect(icon.at(128, 128), _green, reason: 'centre of the crop');
      expect(icon.at(247, 128), _green, reason: 'right edge of the crop');
    });

    test('takes the middle of a tall picture too', () async {
      final Uint8List source =
          await _bands(100, 300, <ui.Color>[_red, _green, _blue], vertical: true);

      final String path = await store.save(profileId: 'p1', source: source);

      final _Decoded icon = await _decode(File(path).readAsBytesSync());
      expect(icon.at(128, 8), _green);
      expect(icon.at(128, 247), _green);
    });

    test('scales rather than stretches', () async {
      // A circle drawn in a square that is four times as wide as it is tall. Cropping to
      // the middle square and scaling keeps it a circle; stretching the whole picture to
      // 256x256 would make it an ellipse, and the pixel above and below the centre would
      // stop matching the pixel left and right of it.
      final Uint8List source = await _centredCircle(400, 100);

      final String path = await store.save(profileId: 'p1', source: source);

      final _Decoded icon = await _decode(File(path).readAsBytesSync());
      const int centre = CloneIconStore.iconSize ~/ 2;
      for (final int offset in <int>[20, 60, 100]) {
        expect(
          icon.at(centre + offset, centre).opaque,
          icon.at(centre, centre + offset).opaque,
          reason: 'the circle is $offset px from the centre in both directions',
        );
      }
    });

    test('keeps transparency', () async {
      final Uint8List source = await _centredCircle(200, 200);

      final String path = await store.save(profileId: 'p1', source: source);

      final _Decoded icon = await _decode(File(path).readAsBytesSync());
      expect(icon.at(2, 2).opaque, isFalse, reason: 'the corner is outside the circle');
      expect(icon.at(128, 128).opaque, isTrue);
    });

    test('a picture far larger than the cap still comes back the icon size', () async {
      // Past the decode cap on both sides, so the resample runs and the crop is taken
      // from the resampled image rather than from the original's dimensions.
      final Uint8List source =
          await _bands(3000, 1500, <ui.Color>[_red, _green, _blue]);

      final String path = await store.save(profileId: 'p1', source: source);

      final _Decoded icon = await _decode(File(path).readAsBytesSync());
      expect(icon.width, CloneIconStore.iconSize);
      expect(icon.at(128, 128), _green, reason: 'the middle band, after resampling');
    });

    test('a narrow strip is capped on its long side and still crops square', () async {
      // The case the longest-side cap exists for: capping the width would have asked for
      // a decode taller than the source, and the shape must survive it either way.
      final Uint8List source =
          await _bands(64, 6000, <ui.Color>[_red, _green, _blue], vertical: true);

      final String path = await store.save(profileId: 'p1', source: source);

      final _Decoded icon = await _decode(File(path).readAsBytesSync());
      expect(icon.width, CloneIconStore.iconSize);
      expect(icon.height, CloneIconStore.iconSize);
      expect(icon.at(128, 128), _green);
    });

    test('an extremely long strip still becomes an icon', () async {
      // Longer than it is wide by more than the decode cap itself, which is where the
      // resampled short side falls below a whole pixel. The picture decodes perfectly
      // well at its own size, so asking for it smaller must not be what refuses it.
      final Uint8List source = await _solid(12000, 2, _green);

      final String path = await store.save(profileId: 'p1', source: source);

      final _Decoded icon = await _decode(File(path).readAsBytesSync());
      expect(icon.width, CloneIconStore.iconSize);
      expect(icon.height, CloneIconStore.iconSize);
      expect(icon.at(128, 128), _green);
    });

    test('the same strip the other way up', () async {
      final Uint8List source = await _solid(2, 12000, _green);

      final String path = await store.save(profileId: 'p1', source: source);

      final _Decoded icon = await _decode(File(path).readAsBytesSync());
      expect(icon.width, CloneIconStore.iconSize);
      expect(icon.at(128, 128), _green);
    });

    test('a photo that carries a rotation is stored the way it is displayed', () async {
      // A photo taken with the phone held sideways is stored in the sensor's orientation
      // with an EXIF tag saying how to turn it. The fixture is 40x20 -- red half, blue
      // half, side by side -- tagged to be rotated a quarter turn clockwise, so what a
      // gallery shows is 20x40 with red above blue.
      //
      // This is the engine's behaviour rather than this class's, and it is asserted here
      // because the icon pipeline leans on it: nothing below would notice a decoder that
      // stopped honouring the tag, and the first sign would be users' own photographs
      // coming out on their sides.
      final Uint8List source =
          File('test/fixtures/exif_rotated.jpg').readAsBytesSync();

      final String path = await store.save(profileId: 'p1', source: source);

      final _Decoded icon = await _decode(File(path).readAsBytesSync());
      expect(icon.at(40, 40).dominant, _red, reason: 'top left');
      expect(icon.at(215, 40).dominant, _red, reason: 'top right');
      expect(icon.at(40, 215).dominant, _blue, reason: 'bottom left');
      expect(icon.at(215, 215).dominant, _blue, reason: 'bottom right');
    });

    test('a one-pixel picture is scaled up rather than refused', () async {
      final String path = await store.save(
        profileId: 'p1',
        source: await _solid(1, 1, _blue),
      );

      final _Decoded icon = await _decode(File(path).readAsBytesSync());
      expect(icon.width, CloneIconStore.iconSize);
      expect(icon.at(128, 128), _blue);
    });

    test('a second picture replaces the first', () async {
      await store.save(profileId: 'p1', source: await _solid(64, 64, _red));
      final String path =
          await store.save(profileId: 'p1', source: await _solid(64, 64, _blue));

      final _Decoded icon = await _decode(File(path).readAsBytesSync());
      expect(icon.at(128, 128), _blue);
      expect(
        Directory('${root.path}/clone_icons').listSync().length,
        1,
        reason: 'one file per clone, and no staging file left behind',
      );
    });

    test('two clones keep separate pictures', () async {
      final String first =
          await store.save(profileId: 'p1', source: await _solid(64, 64, _red));
      final String second =
          await store.save(profileId: 'p2', source: await _solid(64, 64, _blue));

      expect(first, isNot(second));
      expect((await _decode(File(first).readAsBytesSync())).at(128, 128), _red);
      expect((await _decode(File(second).readAsBytesSync())).at(128, 128), _blue);
    });

    test('a file that is not a picture is refused, and nothing is written', () async {
      // What the caller turns into "The picture could not be used as an icon." A file
      // picker filtered to images still hands over whatever the provider claims is one.
      await expectLater(
        store.save(
          profileId: 'p1',
          source: Uint8List.fromList(<int>[1, 2, 3, 4, 5, 6, 7, 8]),
        ),
        throwsA(anything),
      );
      expect(Directory('${root.path}/clone_icons').existsSync(), isFalse);
    });

    test('an empty file is refused', () async {
      await expectLater(
        store.save(profileId: 'p1', source: Uint8List(0)),
        throwsA(anything),
      );
    });
  });

  group('read', () {
    test('returns null for a clone that has no picture', () async {
      expect(await store.read(null), isNull);
    });

    test('returns null when the file has gone', () async {
      // The grid falls back to the app's own icon on null. A throw here would be a hole
      // in the grid instead.
      final String path = await store.save(
        profileId: 'p1',
        source: await _solid(64, 64, _red),
      );
      File(path).deleteSync();

      expect(await store.read(path), isNull);
    });

    test('returns what was written', () async {
      final String path = await store.save(
        profileId: 'p1',
        source: await _solid(64, 64, _red),
      );

      expect(await store.read(path), File(path).readAsBytesSync());
    });
  });

  group('delete', () {
    test('removes the picture', () async {
      final String path = await store.save(
        profileId: 'p1',
        source: await _solid(64, 64, _red),
      );

      await store.delete('p1');

      expect(File(path).existsSync(), isFalse);
    });

    test('is not an error for a clone that never had one', () async {
      await store.delete('never-had-one');
    });

    test('leaves the other clones alone', () async {
      final String kept =
          await store.save(profileId: 'p1', source: await _solid(64, 64, _red));
      await store.save(profileId: 'p2', source: await _solid(64, 64, _blue));

      await store.delete('p2');

      expect(File(kept).existsSync(), isTrue);
    });
  });
}

const ui.Color _red = ui.Color(0xFFFF0000);
const ui.Color _green = ui.Color(0xFF00FF00);
const ui.Color _blue = ui.Color(0xFF0000FF);

Future<Uint8List> _solid(int width, int height, ui.Color color) =>
    _draw(width, height, (ui.Canvas canvas) {
      canvas.drawRect(
        ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
        ui.Paint()..color = color,
      );
    });

/// Equal bands across the picture, so a crop can be told from a stretch by colour alone.
Future<Uint8List> _bands(
  int width,
  int height,
  List<ui.Color> colors, {
  bool vertical = false,
}) {
  return _draw(width, height, (ui.Canvas canvas) {
    final double span =
        (vertical ? height : width) / colors.length;
    for (int i = 0; i < colors.length; i++) {
      final ui.Rect band = vertical
          ? ui.Rect.fromLTWH(0, i * span, width.toDouble(), span)
          : ui.Rect.fromLTWH(i * span, 0, span, height.toDouble());
      canvas.drawRect(band, ui.Paint()..color = colors[i]);
    }
  });
}

/// A circle filling the shorter side, on a transparent ground.
Future<Uint8List> _centredCircle(int width, int height) {
  return _draw(width, height, (ui.Canvas canvas) {
    final double side = (width < height ? width : height).toDouble();
    canvas.drawCircle(
      ui.Offset(width / 2, height / 2),
      side / 2,
      ui.Paint()..color = _red,
    );
  });
}

Future<Uint8List> _draw(
  int width,
  int height,
  void Function(ui.Canvas) paint,
) async {
  final ui.PictureRecorder recorder = ui.PictureRecorder();
  paint(ui.Canvas(recorder));
  final ui.Picture picture = recorder.endRecording();
  final ui.Image image = await picture.toImage(width, height);
  picture.dispose();
  final ByteData? png = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return png!.buffer.asUint8List();
}

/// A decoded picture with its pixels to hand, so a test can say what colour is where.
class _Decoded {
  _Decoded(this.width, this.height, this._rgba);

  final int width;
  final int height;
  final ByteData _rgba;

  ui.Color at(int x, int y) {
    final int offset = (y * width + x) * 4;
    return ui.Color.fromARGB(
      _rgba.getUint8(offset + 3),
      _rgba.getUint8(offset),
      _rgba.getUint8(offset + 1),
      _rgba.getUint8(offset + 2),
    );
  }
}

Future<_Decoded> _decode(Uint8List bytes) async {
  final ui.Codec codec = await ui.instantiateImageCodec(bytes);
  final ui.Image image = (await codec.getNextFrame()).image;
  codec.dispose();
  final ByteData rgba =
      (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  final _Decoded decoded = _Decoded(image.width, image.height, rgba);
  image.dispose();
  return decoded;
}

extension on ui.Color {
  /// Fully opaque, as against the transparent ground outside a circle.
  bool get opaque => a > 0.99;

  /// The primary this colour is nearest, for a sample that has been through JPEG and two
  /// resamples and so is no longer the exact value that was drawn.
  ui.Color get dominant {
    if (r >= g && r >= b) {
      return _red;
    }
    return g >= b ? _green : _blue;
  }
}
