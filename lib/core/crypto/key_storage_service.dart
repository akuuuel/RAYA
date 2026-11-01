import 'package:shared_preferences/shared_preferences.dart';
import 'crypto_service.dart';

/// Layanan penyimpanan kunci privat E2EE secara persisten di perangkat (FR-09).
/// Kunci privat TIDAK PERNAH dikirim ke server.
class KeyStorageService {
  static const _privateKeyPrefKey = 'raya_e2ee_private_key';
  static const _publicKeyPrefKey = 'raya_e2ee_public_key';

  /// Mengambil kunci privat yang tersimpan di perangkat.
  /// Jika belum ada, membuat pasangan kunci baru dan menyimpannya.
  static Future<Map<String, String>> getOrGenerateKeyPair() async {
    final prefs = await SharedPreferences.getInstance();
    final existingPriv = prefs.getString(_privateKeyPrefKey);
    final existingPub = prefs.getString(_publicKeyPrefKey);

    if (existingPriv != null && existingPriv.isNotEmpty &&
        existingPub != null && existingPub.isNotEmpty) {
      return {
        'privateKey': existingPriv,
        'publicKey': existingPub,
      };
    }

    // Buat pasangan kunci baru dan simpan secara persisten
    final keys = CryptoService.generateKeyPair();
    await prefs.setString(_privateKeyPrefKey, keys['privateKey']!);
    await prefs.setString(_publicKeyPrefKey, keys['publicKey']!);

    return keys;
  }

  /// Mengambil kunci privat saja (untuk dekripsi).
  static Future<String> getPrivateKey() async {
    final keys = await getOrGenerateKeyPair();
    return keys['privateKey']!;
  }

  /// Mengambil kunci publik saja (untuk diunggah ke server).
  static Future<String> getPublicKey() async {
    final keys = await getOrGenerateKeyPair();
    return keys['publicKey']!;
  }
}

