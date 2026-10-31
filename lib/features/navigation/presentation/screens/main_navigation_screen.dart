import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../chat/presentation/screens/chat_list_screen.dart';
import '../../../contacts/presentation/controllers/contacts_controller.dart';
import '../../../contacts/presentation/screens/contacts_screen.dart';
import '../../../explore/presentation/screens/explore_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../tracking/presentation/controllers/tracking_controller.dart';
import '../../../tracking/presentation/screens/tracking_screen.dart';

/// Shell Navigasi Utama 5 Tab RAYA sesuai PRD v0.3 Bagian 9 dan DESIGN.md 6.11.
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _currentTabIndex = 0;

  void _onTabSelected(int index) {
    setState(() => _currentTabIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final contactsState = ref.watch(contactsControllerProvider);
    final trackingState = ref.watch(trackingControllerProvider);

    final isAdult = authState.userProfile?.isAdult ?? false;
    final incomingRequestsCount = contactsState.incomingRequests.length;
    final isSharingLocation = trackingState.isSharingActive;

    final pages = [
      ChatListScreen(
        onStartNewChat: () => _onTabSelected(3), // Alihkan ke Tab Kontak
      ),
      TrackingScreen(
        isAdult: isAdult,
        onGoToContacts: () => _onTabSelected(3), // Alihkan ke Tab Kontak
      ),
      const ExploreScreen(),
      const ContactsScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentTabIndex,
        children: pages,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentTabIndex,
        onTap: _onTabSelected,
        items: [
          const AppNavItem(
            icon: Icons.chat_bubble_outline_rounded,
            activeIcon: Icons.chat_bubble_rounded,
            label: 'Chat',
          ),
          AppNavItem(
            icon: Icons.location_on_outlined,
            activeIcon: Icons.location_on_rounded,
            label: 'Pantau',
            showActiveDot: isSharingLocation,
          ),
          const AppNavItem(
            icon: Icons.explore_outlined,
            activeIcon: Icons.explore_rounded,
            label: 'Sekitar',
          ),
          AppNavItem(
            icon: Icons.people_outline_rounded,
            activeIcon: Icons.people_rounded,
            label: 'Kontak',
            badgeCount: incomingRequestsCount,
          ),
          const AppNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
