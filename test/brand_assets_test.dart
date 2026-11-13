import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// The official artwork is the only brand source. These checks fail if a
/// generated icon drifts from it or if the checked-in app asset is replaced.
void main() {
  final root = Directory.current;
  final source = File('store/brand/relay-icon.png');
  final packaged = File('assets/brand/relay-icon.png');

  test('the app asset is byte-identical to the official icon', () {
    expect(source.existsSync(), isTrue, reason: 'store/brand/relay-icon.png');
    expect(
      packaged.existsSync(),
      isTrue,
      reason: 'assets/brand/relay-icon.png',
    );
    expect(
      sha256.convert(packaged.readAsBytesSync()).toString(),
      sha256.convert(source.readAsBytesSync()).toString(),
    );
  });

  test('the brand manifest records the official source hash', () {
    final manifest =
        jsonDecode(File('store/brand-assets.json').readAsStringSync())
            as Map<String, dynamic>;
    final recorded = manifest['source'] as Map<String, dynamic>;
    expect(recorded['path'], 'store/brand/relay-icon.png');
    expect(
      recorded['sha256'],
      sha256.convert(source.readAsBytesSync()).toString(),
    );
    expect(recorded['size'], [1254, 1254]);
  });

  test('Android launcher and adaptive icons exist at every density', () {
    const legacy = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    const adaptive = {
      'mdpi': 108,
      'hdpi': 162,
      'xhdpi': 216,
      'xxhdpi': 324,
      'xxxhdpi': 432,
    };
    for (final entry in legacy.entries) {
      final png = PngInfo.read(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
      );
      expect(png.width, entry.value, reason: entry.key);
      expect(png.height, entry.value, reason: entry.key);
      final round = PngInfo.read(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher_round.png',
      );
      expect(round.width, entry.value, reason: entry.key);
      expect(round.hasAlpha, isTrue);
    }
    for (final entry in adaptive.entries) {
      final foreground = PngInfo.read(
        'android/app/src/main/res/drawable-${entry.key}/ic_launcher_foreground.png',
      );
      expect(foreground.width, entry.value, reason: entry.key);
      expect(foreground.hasAlpha, isTrue, reason: '${entry.key} foreground');
      final monochrome = PngInfo.read(
        'android/app/src/main/res/drawable-${entry.key}/ic_launcher_monochrome.png',
      );
      expect(monochrome.width, entry.value, reason: entry.key);
      expect(monochrome.hasAlpha, isTrue);
    }
  });

  test('splash marks exist for light and dark resources', () {
    for (final density in ['mdpi', 'hdpi', 'xhdpi', 'xxhdpi', 'xxxhdpi']) {
      for (final folder in ['drawable', 'drawable-night']) {
        final mark = PngInfo.read(
          'android/app/src/main/res/$folder-$density/splash_mark.png',
        );
        expect(mark.width, greaterThan(0), reason: '$folder-$density');
        final icon = PngInfo.read(
          'android/app/src/main/res/$folder-$density/splash_icon.png',
        );
        expect(icon.hasAlpha, isTrue, reason: '$folder-$density icon');
      }
    }
  });

  test('Play icon is an opaque 512px square', () {
    final info = PngInfo.read('store/icon-512.png');
    expect(info.width, 512);
    expect(info.height, 512);
    expect(info.hasAlpha, isFalse);
  });

  test('the Play icon background matches the official icon', () {
    final bytes = File('store/icon-512.png').readAsBytesSync();
    final decoded = _decodePng(bytes);
    final corner = decoded.pixel(4, 4);
    expect(corner.$1, 15);
    expect(corner.$2, 15);
    expect(corner.$3, 17);
  });

  test('workspace root is the Flutter project', () {
    expect(File('pubspec.yaml').existsSync(), isTrue);
    expect(Directory('${root.path}/lib').existsSync(), isTrue);
  });
}

class PngInfo {
  const PngInfo(this.width, this.height, this.colorType);

  final int width;
  final int height;
  final int colorType;

  bool get hasAlpha => colorType == 4 || colorType == 6;

  static PngInfo read(String path) {
    final bytes = File(path).readAsBytesSync();
    expect(bytes.length, greaterThan(33), reason: path);
    expect(bytes.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(ascii.decode(bytes.sublist(12, 16)), 'IHDR', reason: path);
    final data = ByteData.sublistView(bytes);
    return PngInfo(data.getUint32(16), data.getUint32(20), bytes[25]);
  }
}

/// Minimal PNG reader for 8-bit RGB/RGBA files written without interlacing.
class _DecodedPng {
  const _DecodedPng(this.width, this.bytesPerPixel, this.rows);

  final int width;
  final int bytesPerPixel;
  final List<Uint8List> rows;

  (int, int, int) pixel(int x, int y) {
    final row = rows[y];
    final offset = x * bytesPerPixel;
    return (row[offset], row[offset + 1], row[offset + 2]);
  }
}

_DecodedPng _decodePng(Uint8List bytes) {
  final data = ByteData.sublistView(bytes);
  final width = data.getUint32(16);
  final height = data.getUint32(20);
  final bitDepth = bytes[24];
  final colorType = bytes[25];
  var depth = 33;
  final compressed = BytesBuilder(copy: false);
  while (depth < bytes.length) {
    final length = data.getUint32(depth);
    final type = ascii.decode(bytes.sublist(depth + 4, depth + 8));
    if (type == 'IDAT') {
      compressed.add(bytes.sublist(depth + 8, depth + 8 + length));
    } else if (type == 'IEND') {
      break;
    }
    depth += length + 12;
  }

  final raw = ZLibCodec().decode(compressed.takeBytes());
  final channels = switch (colorType) {
    2 => 3,
    6 => 4,
    _ => throw StateError('Unsupported PNG color type $colorType'),
  };
  final bytesPerPixel = channels * (bitDepth ~/ 8);
  final stride = width * bytesPerPixel;
  final rows = <Uint8List>[];
  var previous = Uint8List(stride);
  var offset = 0;

  int paeth(int a, int b, int c) {
    final p = a + b - c;
    final pa = (p - a).abs();
    final pb = (p - b).abs();
    final pc = (p - c).abs();
    if (pa <= pb && pa <= pc) return a;
    if (pb <= pc) return b;
    return c;
  }

  for (var y = 0; y < height; y++) {
    final filter = raw[offset++];
    final row = Uint8List(stride);
    for (var x = 0; x < stride; x++) {
      final value = raw[offset++];
      final left = x >= bytesPerPixel ? row[x - bytesPerPixel] : 0;
      final up = previous[x];
      final upLeft = x >= bytesPerPixel ? previous[x - bytesPerPixel] : 0;
      row[x] = switch (filter) {
        0 => value,
        1 => value + left,
        2 => value + up,
        3 => value + ((left + up) >> 1),
        4 => value + paeth(left, up, upLeft),
        _ => throw StateError('Unsupported PNG filter $filter'),
      };
    }
    rows.add(row);
    previous = row;
  }
  return _DecodedPng(width, bytesPerPixel, rows);
}
