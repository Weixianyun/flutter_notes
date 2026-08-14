import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AES-256 加密服务
///
/// 使用 AES-256-CBC 模式 + PKCS7 填充，为敏感数据（如 GitHub OAuth
/// Token）提供加密/解密能力。
///
/// 密钥管理：
/// - 首次使用时通过 `Random.secure()` 生成 32 字节随机密钥
/// - 密钥以 Base64 编码存储在 `SharedPreferences` 中
/// - 每次加密生成独立 16 字节随机 IV
///
/// 密文格式：`base64(IV):base64(ciphertext)`
class EncryptionService {
  EncryptionService(this._prefs) {
    _key = _loadOrCreateKey();
    _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
  }

  final SharedPreferences _prefs;

  static const _keyStorageKey = 'aes256_encryption_key';
  static const _keyLength = 32; // 256 bits
  static const _ivLength = 16; // 128 bits (AES block size)

  late Key _key;
  late Encrypter _encrypter;

  /// 加载或生成 AES-256 密钥
  Key _loadOrCreateKey() {
    final stored = _prefs.getString(_keyStorageKey);
    if (stored != null) {
      return Key.fromBase64(stored);
    }
    final newKey = Key.fromLength(_keyLength);
    _prefs.setString(_keyStorageKey, newKey.base64);
    return newKey;
  }

  /// 加密字符串
  ///
  /// 返回 `base64(IV):base64(ciphertext)` 格式的密文。
  /// 空字符串密文格式为 `base64(IV):`（ciphertext 部分为空）。
  String encrypt(String plaintext) {
    final iv = IV.fromLength(_ivLength);
    if (plaintext.isEmpty) {
      return '${iv.base64}:';
    }
    final encrypted = _encrypter.encrypt(plaintext, iv: iv);
    return '${iv.base64}:${encrypted.base64}';
  }

  /// 解密字符串
  ///
  /// 接受 `base64(IV):base64(ciphertext)` 格式的密文，返回明文。
  String decrypt(String ciphertext) {
    final parts = ciphertext.split(':');
    if (parts.length != 2) {
      throw const FormatException('无效的密文格式，期望 `IV:ciphertext`');
    }
    if (parts[1].isEmpty) {
      return '';
    }
    final iv = IV.fromBase64(parts[0]);
    return _encrypter.decrypt64(parts[1], iv: iv);
  }

  /// 加密字节数据（适用于二进制内容）
  String encryptBytes(List<int> bytes) {
    return encrypt(utf8.decode(bytes));
  }

  /// 解密为字节数据
  List<int> decryptBytes(String ciphertext) {
    return utf8.encode(decrypt(ciphertext));
  }

  /// 判断密钥是否已存在（用于设置页展示加密状态）
  bool get hasKey => _prefs.containsKey(_keyStorageKey);

  /// 重新生成密钥（警告：已加密的数据将无法解密）
  Future<void> regenerateKey() async {
    final newKey = Key.fromLength(_keyLength);
    await _prefs.setString(_keyStorageKey, newKey.base64);
    _key = newKey;
    _encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
  }
}
