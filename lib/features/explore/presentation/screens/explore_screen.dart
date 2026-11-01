import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/public_status.dart';
import '../controllers/explore_controller.dart';
import '../widgets/create_nearby_note_modal.dart';
import '../widgets/nearby_note_detail_modal.dart';
import '../widgets/realtime_explore_map.dart';

/// Layar Catatan Sekitar (Nearby Notes) di atas Peta Nyata (Real Map).
/// Menampilkan peta jalanan kota nyata (CartoDB Dark Matter) dengan pin-pin catatan
/// gaya Instagram Notes yang mengambang di atas lokasi geografis pengguna (FR-29 s.d. FR-40).
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  @override
  Widget build(BuildContext context) {
    final exploreState = ref.watch(exploreControllerProvider);
    final isPublicVisible = exploreState.isPublicVisible;
    final myStatus = exploreState.myStatus;
    final nearbyStatuses = exploreState.nearbyStatuses;
    final selectedRadius = exploreState.selectedRadiusKm;

    return Scaffold(
      backgroundColor: const Color(0xFF08060F),
      body: SafeArea(
        child: Stack(
          children: [
            // ==========================================================
            // 1. PETA JALANAN NYATA REALTIME DENGAN MARKER CATATAN
            // ==========================================================
            Positioned.fill(
              child: RealtimeExploreMap(
                statuses: nearbyStatuses,
                myStatus: myStatus,
                radiusKm: selectedRadius,
                centerLatitude: exploreState.userLatitude,
                centerLongitude: exploreState.userLongitude,
                onStatusSelected: (status) {
                  NearbyNoteDetailModal.show(context, ref, status);
                },
                onMyStatusTap: () {
                  if (myStatus != null && !myStatus.isExpired) {
                    NearbyNoteDetailModal.show(context, ref, myStatus);
                  } else {
                    CreateNearbyNoteModal.show(context, ref);
                  }
                },
              ),
            ),

            // ==========================================================
            // 2. HEADER BAR MELAYANG (FLOATING TOP BAR)
            // ==========================================================
            Positioned(
              top: 12,
              left: AppSpacing.screenMarginHorizontal,
              right: AppSpacing.screenMarginHorizontal,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bar Utama: Judul, Status Radar, Refresh & Visibilitas
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF140F24).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.surfaceBorder),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Indikator Titik Hijau Radar
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPublicVisible
                                ? const Color(0xFF00E676)
                                : AppColors.textMuted,
                            boxShadow: isPublicVisible
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF00E676).withValues(alpha: 0.6),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Judul & Jumlah Catatan
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Catatan Sekitar',
                                style: AppTextStyles.titleMedium(color: AppColors.textPrimary)
                                    .copyWith(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                isPublicVisible
                                    ? '${nearbyStatuses.length} catatan dalam $selectedRadius km'
                                    : 'Mode Senyap (Tampil Publik Mati)',
                                style: TextStyle(
                                  color: isPublicVisible
                                      ? const Color(0xFF00CEC9)
                                      : AppColors.textMuted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Tombol Refresh Peta & GPS
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white70, size: 20),
                          tooltip: 'Segarkan lokasi & catatan sekitar',
                          onPressed: () =>
                              ref.read(exploreControllerProvider.notifier).initExploreWithLocation(),
                        ),

                        // Sakelar Visibilitas Publik (Ghost Mode)
                        Transform.scale(
                          scale: 0.82,
                          child: Switch(
                            value: isPublicVisible,
                            activeColor: const Color(0xFF00CEC9),
                            activeTrackColor: const Color(0xFF00CEC9).withValues(alpha: 0.3),
                            onChanged: (val) {
                              ref
                                  .read(exploreControllerProvider.notifier)
                                  .togglePublicVisibility(val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Filter Radius Mengambang (1 km, 5 km, 10 km)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [1, 5, 10].map((radius) {
                      final isSelected = selectedRadius == radius;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: GestureDetector(
                          onTap: () =>
                              ref.read(exploreControllerProvider.notifier).setRadius(radius),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF6C5CE7)
                                  : const Color(0xFF140F24).withValues(alpha: 0.88),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryGlow
                                    : AppColors.surfaceBorder,
                              ),
                            ),
                            child: Text(
                              '$radius km',
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // ==========================================================
            // 3. TOMBOL MENGAMBANG "TINGGALKAN CATATAN" (FAB)
            // ==========================================================
            Positioned(
              bottom: 24,
              left: AppSpacing.screenMarginHorizontal + 20,
              right: AppSpacing.screenMarginHorizontal + 20,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C5CE7),
                  foregroundColor: Colors.white,
                  elevation: 6,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  shadowColor: const Color(0xFF6C5CE7).withValues(alpha: 0.5),
                ),
                icon: const Icon(Icons.maps_ugc_rounded, size: 20),
                label: Text(
                  myStatus != null && !myStatus.isExpired
                      ? 'Kelola Catatan Saya'
                      : 'Tinggalkan Catatan di Peta',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                onPressed: () {
                  if (myStatus != null && !myStatus.isExpired) {
                    NearbyNoteDetailModal.show(context, ref, myStatus);
                  } else {
                    CreateNearbyNoteModal.show(context, ref);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
