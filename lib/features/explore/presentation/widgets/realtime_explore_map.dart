import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/public_status.dart';
import 'nearby_note_pin.dart';

/// Komponen Peta Nyata Realtime (Real Map) untuk Tab Sekitar.
/// Menggunakan OpenStreetMap / CartoDB Dark Matter tile layer dengan rendering peta jalanan asli,
/// dan menempatkan pin catatan Instagram Notes langsung pada koordinat geografis nyata.
class RealtimeExploreMap extends StatefulWidget {
  final List<PublicStatus> statuses;
  final PublicStatus? myStatus;
  final Function(PublicStatus) onStatusSelected;
  final VoidCallback onMyStatusTap;
  final int radiusKm;
  final double centerLatitude;
  final double centerLongitude;

  const RealtimeExploreMap({
    super.key,
    required this.statuses,
    this.myStatus,
    required this.onStatusSelected,
    required this.onMyStatusTap,
    required this.radiusKm,
    this.centerLatitude = -6.175392, // Default Monas / Jakarta Pusat
    this.centerLongitude = 106.827153,
  });

  @override
  State<RealtimeExploreMap> createState() => _RealtimeExploreMapState();
}

class _RealtimeExploreMapState extends State<RealtimeExploreMap> {
  late final MapController _mapController;
  double _currentRotation = 0.0; // Track rotasi peta saat ini (dalam derajat)

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void didUpdateWidget(covariant RealtimeExploreMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.radiusKm != widget.radiusKm) {
      _adjustZoomForRadius(widget.radiusKm);
    } else if (oldWidget.centerLatitude != widget.centerLatitude ||
        oldWidget.centerLongitude != widget.centerLongitude) {
      _mapController.move(
        LatLng(widget.centerLatitude, widget.centerLongitude),
        _mapController.camera.zoom,
      );
    }
  }

  void _adjustZoomForRadius(int radiusKm) {
    double targetZoom = 14.5;
    if (radiusKm <= 1) {
      targetZoom = 15.2;
    } else if (radiusKm <= 5) {
      targetZoom = 13.5;
    } else {
      targetZoom = 12.0;
    }

    _mapController.move(
      LatLng(widget.centerLatitude, widget.centerLongitude),
      targetZoom,
    );
  }

  Future<void> _recenterToMyPosition() async {
    try {
      final pos = await LocationService.instance.getCurrentPosition();
      if (pos != null) {
        _mapController.move(LatLng(pos.latitude, pos.longitude), 15.0);
        return;
      }
    } catch (_) {}
    _mapController.move(
      LatLng(widget.centerLatitude, widget.centerLongitude),
      15.0,
    );
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  /// Reset rotasi peta ke arah Utara (North-up)
  void _resetRotation() {
    _mapController.rotate(0);
  }

  @override
  Widget build(BuildContext context) {
    final myCenter = LatLng(widget.centerLatitude, widget.centerLongitude);
    final hasMyStatus = widget.myStatus != null && !widget.myStatus!.isExpired;

    return Stack(
      children: [
        // ==========================================================
        // 1. PETA NYATA INTERAKTIF (DARK MAP TILES)
        // ==========================================================
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: myCenter,
            initialZoom: 14.0,
            minZoom: 3.0,
            maxZoom: 18.0,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all,
            ),
            // Lacak rotasi peta untuk tombol kompas
            onMapEvent: (event) {
              if (event is MapEventRotate || event is MapEventRotateEnd) {
                final newRotation = _mapController.camera.rotation;
                if ((newRotation - _currentRotation).abs() > 0.5) {
                  setState(() => _currentRotation = newRotation);
                }
              }
            },
          ),
          children: [
            // Peta Ubin OpenStreetMap Bebas API Key dengan Efek Dark Mode OLED RAYA
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'id.raya.connect',
              maxZoom: 19,
              tileBuilder: (context, tileWidget, tile) {
                return ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    -0.25, -0.25, -0.25, 0.0, 215, // Invert ke Dark OLED
                    -0.25, -0.25, -0.25, 0.0, 215,
                    -0.18, -0.18, -0.18, 0.0, 230, // Nuansa keunguan lembut
                     0.0,   0.0,   0.0,  1.0,   0,
                  ]),
                  child: tileWidget,
                );
              },
            ),

            // Lingkaran Radius Pencarian Sekitar (1km, 5km, 10km)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: myCenter,
                  color: const Color(0xFF6C5CE7).withValues(alpha: 0.12),
                  borderColor: const Color(0xFF00CEC9).withValues(alpha: 0.6),
                  borderStrokeWidth: 1.5,
                  useRadiusInMeter: true,
                  radius: (widget.radiusKm * 1000).toDouble(),
                ),
              ],
            ),

            // Lapisan Marker Catatan Instagram Notes di Peta
            // rotate: true → marker selalu tegak lurus walau peta diputar
            MarkerLayer(
              rotate: true, // Counter-rotate semua marker sesuai rotasi peta
              markers: [
                // Marker Catatan Saya di Titik Pusat
                Marker(
                  point: myCenter,
                  width: 160,
                  height: 110,
                  alignment: Alignment.bottomCenter,
                  rotate: true, // Ikon tetap lurus saat peta diputar
                  child: _buildMyNoteMarker(hasMyStatus),
                ),

                // Marker Catatan Pengguna Sekitar
                ...widget.statuses
                    .where((s) => !s.isMine)
                    .map((status) {
                  return Marker(
                    point: LatLng(status.fuzzedLatitude, status.fuzzedLongitude),
                    width: 160,
                    height: 110,
                    alignment: Alignment.bottomCenter,
                    rotate: true, // Ikon tetap lurus saat peta diputar
                    child: NearbyNotePin(
                      status: status,
                      onTap: () => widget.onStatusSelected(status),
                    ),
                  );
                }),
              ],
            ),
          ],
        ),

        // ==========================================================
        // 2. TOMBOL KONTROL PETA (ZOOM & MY LOCATION)
        // ==========================================================
        Positioned(
          right: 16,
          bottom: 96,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tombol Kompas — muncul saat peta diputar, tap untuk reset ke North-up
              if (_currentRotation.abs() > 1.0) ...[
                Tooltip(
                  message: 'Reset ke arah Utara',
                  child: GestureDetector(
                    onTap: _resetRotation,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF140F24).withValues(alpha: 0.92),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primaryGlow, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Transform.rotate(
                          // Ikon panah utara berputar berlawanan dengan rotasi peta
                          angle: -_currentRotation * pi / 180,
                          child: const Icon(
                            Icons.navigation_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Tombol Pusatkan ke Lokasi Saya
              _buildMapControlButton(
                icon: Icons.my_location_rounded,
                tooltip: 'Pusatkan ke lokasi saya',
                onPressed: _recenterToMyPosition,
              ),
              const SizedBox(height: 8),

              // Tombol Zoom In
              _buildMapControlButton(
                icon: Icons.add,
                tooltip: 'Perbesar peta',
                onPressed: _zoomIn,
              ),
              const SizedBox(height: 6),

              // Tombol Zoom Out
              _buildMapControlButton(
                icon: Icons.remove,
                tooltip: 'Perkecil peta',
                onPressed: _zoomOut,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF140F24).withValues(alpha: 0.9),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.surfaceBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildMyNoteMarker(bool hasMyStatus) {
    return GestureDetector(
      onTap: widget.onMyStatusTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Balon Catatan Saya
          Container(
            constraints: const BoxConstraints(maxWidth: 150, minWidth: 60),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C5CE7), Color(0xFF4834D4)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryGlow, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              hasMyStatus ? widget.myStatus!.text : '+ Catatan Anda',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 2),

          // Avatar Saya dengan Indikator Pulsa
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Center(
                  child: Icon(Icons.person, color: Colors.white, size: 22),
                ),
              ),
              if (!hasMyStatus)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 15,
                    height: 15,
                    decoration: const BoxDecoration(
                      color: Color(0xFF00CEC9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 11),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Anda',
              style: TextStyle(
                color: AppColors.primaryGlow,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

