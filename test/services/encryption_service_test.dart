import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_notes/services/crypto_service.dart';

void main() {
  late SharedPreferences prefs;
  late EncryptionService encryptionService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    encryptionService = EncryptionService(prefs);
  });

  group('EncryptionService', () {
    group('key management', () {
      test('generates and stores a key on first use', () {
        expect(prefs.containsKey('aes256_encryption_key'), isTrue);
      });

      test('hasKey returns true after initialization', () {
        expect(encryptionService.hasKey, isTrue);
      });

      test('reuses stored key on subsequent instances', () {
        final key1 = prefs.getString('aes256_encryption_key');

        // 创建新实例，应复用已存储的密钥
        final newService = EncryptionService(prefs);
        final key2 = prefs.getString('aes256_encryption_key');

        expect(key1, key2);
        expect(newService.hasKey, isTrue);
      });

      test('regenerateKey creates a different key', () async {
        final key1 = prefs.getString('aes256_encryption_key');

        await encryptionService.regenerateKey();

        final key2 = prefs.getString('aes256_encryption_key');
        expect(key1, isNot(key2));
      });
    });

    group('encrypt / decrypt', () {
      test('decrypt(encrypt(text)) returns original text', () {
        const plaintext = 'Hello, World! 你好，世界！🎉';

        final encrypted = encryptionService.encrypt(plaintext);
        final decrypted = encryptionService.decrypt(encrypted);

        expect(decrypted, plaintext);
      });

      test('encrypted output differs from plaintext', () {
        const plaintext = 'sensitive data';

        final encrypted = encryptionService.encrypt(plaintext);

        expect(encrypted, isNot(plaintext));
        expect(encrypted.contains(plaintext), isFalse);
      });

      test('each encryption produces different ciphertext (random IV)', () {
        const plaintext = 'same input';

        final encrypted1 = encryptionService.encrypt(plaintext);
        final encrypted2 = encryptionService.encrypt(plaintext);

        // 由于 IV 随机，相同明文的密文应不同
        expect(encrypted1, isNot(encrypted2));

        // 但两者都能正确解密
        expect(encryptionService.decrypt(encrypted1), plaintext);
        expect(encryptionService.decrypt(encrypted2), plaintext);
      });

      test('handles empty string', () {
        const plaintext = '';

        final encrypted = encryptionService.encrypt(plaintext);
        final decrypted = encryptionService.decrypt(encrypted);

        expect(decrypted, plaintext);
      });

      test('handles long text', () {
        final plaintext = 'A' * 10000;

        final encrypted = encryptionService.encrypt(plaintext);
        final decrypted = encryptionService.decrypt(encrypted);

        expect(decrypted, plaintext);
      });

      test('handles special characters', () {
        const plaintext = r'Special: `~!@#$%^&*()_+-={}[]|\/:";''<>?,. '
            'Unicode: 日本語 한국어 العربية עברית';

        final encrypted = encryptionService.encrypt(plaintext);
        final decrypted = encryptionService.decrypt(encrypted);

        expect(decrypted, plaintext);
      });

      test('handles JSON-like content', () {
        const plaintext = '{"token":"ghp_abcdef123456","scope":"repo"}';

        final encrypted = encryptionService.encrypt(plaintext);
        final decrypted = encryptionService.decrypt(encrypted);

        expect(decrypted, plaintext);
      });
    });

    group('decrypt error handling', () {
      test('throws FormatException for invalid format', () {
        expect(
          () => encryptionService.decrypt('invalid-format'),
          throwsA(isA<FormatException>()),
        );
      });

      test('throws FormatException for missing separator', () {
        expect(
          () => encryptionService.decrypt('justbase64data'),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('encryptBytes / decryptBytes', () {
      test('round-trips byte data', () {
        const text = 'Byte data test';
        final bytes = text.codeUnits;

        final encrypted = encryptionService.encryptBytes(bytes);
        final decrypted = encryptionService.decryptBytes(encrypted);

        expect(decrypted, bytes);
      });
    });

    group('cross-instance decryption', () {
      test('instance B can decrypt data encrypted by instance A', () {
        const plaintext = 'cross-instance secret';

        // 实例 A 加密
        final encrypted = encryptionService.encrypt(plaintext);

        // 实例 B（使用相同的 SharedPreferences）解密
        final instanceB = EncryptionService(prefs);
        final decrypted = instanceB.decrypt(encrypted);

        expect(decrypted, plaintext);
      });
    });
  });
}
