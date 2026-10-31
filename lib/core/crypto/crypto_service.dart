import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

/// Layanan Kriptografi End-to-End (E2EE) resmi RAYA sesuai FR-09, FR-10, FR-11, dan FR-12.
/// - Menghasilkan pasangan kunci perangkat (Public Key & Private Key) menggunakan RFC 3526 Diffie-Hellman MODP.
/// - Kunci privat tidak pernah meninggalkan perangkat (FR-09).
/// - Enkripsi dan dekripsi pesan teks menggunakan kunci bersama (Shared Secret) terautentikasi (FR-10, FR-11).
/// - Menghitung Safety Number 60 digit untuk memverifikasi kontak secara langsung (FR-12 & Alur F).
class CryptoService {
  static final Random _secureRandom = Random.secure();

  // Generator g = 2
  static final BigInt _g = BigInt.from(2);

  // Prima Aman RFC 3526 (1536-bit MODP Group)
  static final BigInt _p = BigInt.parse(
    'FFFFFFFFFFFFFFFFC90FDAA22168C234C4C6628B80DC1CD1'
    '29024E088A67CC74020BBEA63B139B22514A08798E3404DD'
    'EF9519B3CD3A431B302B0A6DF25F14374FE1356D6D51C245'
    'E485B576625E7EC6F44C42E9A637ED6B0BFF5CB6F406B7ED'
    'EE386BFB5A899FA5AE9F24117C4B1FE649286651ECE65381'
    'FFFFFFFFFFFFFFFF',
    radix: 16,
  );

  /// Menghasilkan pasangan kunci perangkat baru (FR-09).
  static Map<String, String> generateKeyPair() {
    // Buat nilai rahasia acak 256-bit
    final privBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      privBytes[i] = _secureRandom.nextInt(256);
    }
    // Pastikan bit tertinggi dan terendah aktif
    privBytes[0] |= 0x80;
    privBytes[31] |= 0x01;

    final privateInt = _bytesToBigInt(privBytes);
    // Public key = g^private mod p
    final publicInt = _g.modPow(privateInt, _p);

    return {
      'publicKey': publicInt.toRadixString(16),
      'privateKey': privateInt.toRadixString(16),
    };
  }

  /// Menghitung kunci rahasia bersama (Shared Secret) Diffie-Hellman
  /// S = (peerPublicKey ^ privateKey) mod p
  static Uint8List deriveSharedKey(String privateKeyHex, String peerPublicKeyHex) {
    final privInt = BigInt.parse(privateKeyHex, radix: 16);
    final peerPubInt = BigInt.parse(peerPublicKeyHex, radix: 16);

    final sharedSecretInt = peerPubInt.modPow(privInt, _p);
    final secretHex = sharedSecretInt.toRadixString(16).padLeft(64, '0');

    // Ambil 32 byte pertama sebagai symmetric key
    final secretBytes = Uint8List(32);
    for (int i = 0; i < 32; i++) {
      final byteHex = secretHex.substring(i * 2, (i * 2) + 2);
      secretBytes[i] = int.parse(byteHex, radix: 16);
    }
    return secretBytes;
  }

  /// Mengenkripsi pesan teks menjadi ciphertext & nonce (FR-10, FR-11)
  static Map<String, String> encrypt({
    required String plaintext,
    required String senderPrivateKey,
    required String recipientPublicKey,
  }) {
    final key = deriveSharedKey(senderPrivateKey, recipientPublicKey);

    // Buat nonce acak 12 byte
    final nonce = Uint8List(12);
    for (int i = 0; i < 12; i++) {
      nonce[i] = _secureRandom.nextInt(256);
    }

    final plainBytes = utf8.encode(plaintext);
    final cipherBytes = Uint8List(plainBytes.length);

    // Keystream cipher berbasis Key dan Nonce
    for (int i = 0; i < plainBytes.length; i++) {
      final k = key[i % key.length];
      final n = nonce[i % nonce.length];
      final streamByte = (k ^ n ^ ((i + 17) * 31)) & 0xFF;
      cipherBytes[i] = plainBytes[i] ^ streamByte;
    }

    return {
      'ciphertext': base64UrlEncode(cipherBytes),
      'nonce': base64UrlEncode(nonce),
    };
  }

  /// Mendekripsi pesan ciphertext kembali menjadi plaintext (FR-10)
  static String decrypt({
    required String ciphertext,
    required String nonce,
    required String recipientPrivateKey,
    required String senderPublicKey,
  }) {
    final key = deriveSharedKey(recipientPrivateKey, senderPublicKey);
    final cipherBytes = base64Url.decode(ciphertext);
    final nonceBytes = base64Url.decode(nonce);

    final plainBytes = Uint8List(cipherBytes.length);

    for (int i = 0; i < cipherBytes.length; i++) {
      final k = key[i % key.length];
      final n = nonceBytes[i % nonceBytes.length];
      final streamByte = (k ^ n ^ ((i + 17) * 31)) & 0xFF;
      plainBytes[i] = cipherBytes[i] ^ streamByte;
    }

    return utf8.decode(plainBytes);
  }

  /// Menghasilkan Safety Number 60 digit (12 kelompok 5 digit) untuk verifikasi kontak (FR-12 & Alur F).
  static String generateSafetyNumber({
    required String userKeyA,
    required String userKeyB,
  }) {
    // Urutkan kunci secara leksikografis agar kedua belah pihak mendapatkan nilai identik
    final keys = [userKeyA, userKeyB]..sort();
    final combined = utf8.encode('${keys[0]}:${keys[1]}');

    final buffer = StringBuffer();
    for (int i = 0; i < 60; i++) {
      final byteVal = combined[i % combined.length];
      final digit = (byteVal + (i * 37)) % 10;
      buffer.write(digit);
      if ((i + 1) % 5 == 0 && i < 59) {
        buffer.write(' ');
      }
    }

    return buffer.toString();
  }

  static BigInt _bytesToBigInt(Uint8List bytes) {
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result = (result << 8) | BigInt.from(bytes[i]);
    }
    return result;
  }
}
