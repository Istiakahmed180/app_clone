import 'dart:convert';
import 'dart:math';

import 'package:duplika/core/services/pin_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PBKDF2-HMAC-SHA256', () {
    // The RFC 6070 vectors, keyed by iteration count, for password 'password' and
    // salt 'salt'. Pinning the output is what proves the derivation is the real
    // construction rather than a hash of the right shape.
    const Map<int, String> vectors = <int, String>{
      1: '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
      2: 'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
      4096: 'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
    };

    const PinHasher hasher = PinHasher();

    vectors.forEach((int iterations, String expected) {
      test('matches the published vector at $iterations iterations', () {
        expect(
          hasher.deriveHex(
            'password',
            utf8.encode('salt'),
            iterations: iterations,
          ),
          expected,
        );
      });
    });
  });

  group('salt', () {
    test('is the expected length and is not all zeroes', () {
      final List<int> salt = const PinHasher().generateSalt();

      expect(salt, hasLength(PinHasher.saltLength));
      expect(salt.any((int byte) => byte != 0), isTrue);
    });

    test('changes between calls', () {
      const PinHasher hasher = PinHasher();
      expect(hasher.generateSalt(), isNot(hasher.generateSalt()));
    });
  });

  group('verify', () {
    const PinHasher hasher = PinHasher(iterations: 1000);

    test('accepts the right PIN and rejects a wrong one', () {
      final List<int> salt = hasher.generateSalt(Random(7));
      final String hash = hasher.deriveHex('1234', salt);

      expect(
        hasher.verify('1234', salt: salt, hashHex: hash, iterations: 1000),
        isTrue,
      );
      expect(
        hasher.verify('4321', salt: salt, hashHex: hash, iterations: 1000),
        isFalse,
      );
    });

    test('rejects a stored hash that is not valid hex', () {
      expect(
        hasher.verify(
          '1234',
          salt: hasher.generateSalt(),
          hashHex: 'zz',
          iterations: 1000,
        ),
        isFalse,
      );
    });

    test('rejects a truncated stored hash', () {
      expect(
        hasher.verify(
          '1234',
          salt: hasher.generateSalt(),
          hashHex: 'abcd',
          iterations: 1000,
        ),
        isFalse,
      );
    });
  });
}
