import 'package:encrypt/encrypt.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EncryptionService {
  late final Key key;
  late final Encrypter encrypter;
  
  // Singleton pattern
  static final EncryptionService _instance = EncryptionService._internal();
  
  factory EncryptionService() {
    return _instance;
  }

  EncryptionService._internal() {
    final keyString = dotenv.env['ENCRYPTION_KEY'];
    if (keyString == null || keyString.length != 32) {
      print('WARNING: Encryption Key is not set or invalid length in .env. Using fallback (NOT SECURE).');
      // Fallback for development only - in prod this should crash
      key = Key.fromUtf8('a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6');
    } else {
      key = Key.fromUtf8(keyString);
    }
    encrypter = Encrypter(AES(key));
  }

  String encrypt(String plainText) {
    if (plainText.isEmpty) return plainText;
    try {
      final iv = IV.fromLength(16);
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '${iv.base64}:${encrypted.base64}';
    } catch (e) {
      print('Encryption error: $e');
      return plainText; // Fail open to avoid data loss, or handle differently
    }
  }

  String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return encryptedText;
    if (!encryptedText.contains(':')) return encryptedText; // Not encrypted format
    
    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return encryptedText;
      
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      print('Decryption error: $e');
      return encryptedText; // Return original if decryption fails (backward compatibility)
    }
  }
}
