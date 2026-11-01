import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Layanan untuk mendapatkan koordinat GPS fisik perangkat secara akurat.
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  // Koordinat default (Jakarta Pusat / Monas) jika GPS sama sekali dimatikan / ditolak
  static const double defaultLatitude = -6.175392;
  static const double defaultLongitude = 106.827153;

  Position? _lastKnownPosition;
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Meminta izin lokasi dan mengambil posisi koordinat GPS terkini perangkat
  Future<Position?> getCurrentPosition() async {
    try {
      // 1. Cek apakah layanan GPS aktif di perangkat
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Layanan lokasi (GPS) tidak aktif di perangkat.');
        return _lastKnownPosition;
      }

      // 2. Cek status izin lokasi aplikasi
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Izin lokasi ditolak oleh pengguna.');
          return _lastKnownPosition;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Izin lokasi ditolak permanen.');
        return _lastKnownPosition;
      }

      // 3. Ambil posisi GPS fisik saat ini
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _lastKnownPosition = position;
      debugPrint('[LocationService] Koordinat GPS berhasil didapat: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('[LocationService] Gagal mengambil posisi lokasi: $e');
      // Coba ambil posisi terakhir yang pernah tersimpan di HP
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          _lastKnownPosition = last;
          return last;
        }
      } catch (_) {}
      return _lastKnownPosition;
    }
  }
}

