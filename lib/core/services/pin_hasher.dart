import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// PBKDF2-HMAC-SHA256 for the Private space PIN.
///
/// A four-to-six digit PIN has so little entropy that a single hash is brute-forceable
/// in milliseconds, so the PIN is never stored, only a salted key derived from it. The
/// salt makes two spaces with the same PIN produce different hashes, and the iteration
/// count is what turns a millisecond guess into a multi-second one.
///
/// This is the same construction every password store uses; it is deliberately not
/// home-grown.
class PinHasher {
  const PinHasher({this.iterations = defaultIterations});

  /// Roughly a tenth of a second on a mid-range phone, which is invisible on a PIN
  /// entry but makes offline guessing expensive.
  static const int defaultIterations = 120000;

  static const int saltLength = 16;
  static const int keyLength = 32;

  final int iterations;

  /// A fresh random salt. [Random.secure] is what keeps two devices' hashes distinct.
  Uint8List generateSalt([Random? random]) {
    final Random source = random ?? Random.secure();
    return Uint8List.fromList(
      List<int>.generate(saltLength, (_) => source.nextInt(256)),
    );
  }

  Uint8List derive(String pin, List<int> salt, {int? iterations}) {
    return Uint8List.fromList(
      _pbkdf2(
        utf8.encode(pin),
        salt,
        iterations ?? this.iterations,
        keyLength,
      ),
    );
  }

  String deriveHex(String pin, List<int> salt, {int? iterations}) =>
      _toHex(derive(pin, salt, iterations: iterations));

  /// Constant-time comparison, so a wrong PIN reveals nothing through timing.
  bool verify(
    String pin, {
    required List<int> salt,
    required String hashHex,
    required int iterations,
  }) {
    final List<int>? expected = _fromHex(hashHex);
    if (expected == null || expected.length != keyLength) {
      return false;
    }
    final Uint8List actual = derive(pin, salt, iterations: iterations);
    return _constantTimeEquals(actual, expected);
  }

  static List<int> _pbkdf2(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLength,
  ) {
    final Hmac hmac = Hmac(sha256, password);
    const int digestLength = 32;
    final int blocks = (keyLength / digestLength).ceil();
    final List<int> output = <int>[];

    for (int block = 1; block <= blocks; block++) {
      final List<int> seed = <int>[
        ...salt,
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ];
      List<int> u = hmac.convert(seed).bytes;
      final List<int> accumulator = List<int>.of(u);

      for (int round = 1; round < iterations; round++) {
        u = hmac.convert(u).bytes;
        for (int i = 0; i < accumulator.length; i++) {
          accumulator[i] ^= u[i];
        }
      }
      output.addAll(accumulator);
    }

    return output.sublist(0, keyLength);
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) {
      return false;
    }
    int difference = 0;
    for (int i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }

  static String _toHex(List<int> bytes) {
    final StringBuffer buffer = StringBuffer();
    for (final int byte in bytes) {
      buffer.write(byte.toRadixString(16).padLeft(2, '0'));
    }
    return buffer.toString();
  }

  static List<int>? _fromHex(String value) {
    if (value.length.isOdd) {
      return null;
    }
    final List<int> bytes = <int>[];
    for (int i = 0; i < value.length; i += 2) {
      final int? byte = int.tryParse(value.substring(i, i + 2), radix: 16);
      if (byte == null) {
        return null;
      }
      bytes.add(byte);
    }
    return bytes;
  }
}
