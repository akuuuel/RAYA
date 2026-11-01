import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../chat/presentation/controllers/chat_list_controller.dart';
import '../../../chat/presentation/screens/chat_room_screen.dart';
import '../../../moderation/domain/entities/report_ticket.dart';
import '../../../moderation/presentation/widgets/report_modal.dart';
import '../controllers/contacts_controller.dart';

/// Layar Manajemen Kontak & Permintaan Pertemanan (FR-06 s.d. FR-08, FR-41 & DESIGN.md 7.8).
class ContactsScreen extends ConsumerStatefulWidget {
  const ContactsScreen({super.key});

  @override
  ConsumerState<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends ConsumerState<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddContactModal() {
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final contactsState = ref.watch(contactsControllerProvider);
          final searchResult = contactsState.searchResult;

          return Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.screenMarginHorizontal,
              right: AppSpacing.screenMarginHorizontal,
              top: AppSpacing.s20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.s24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Text(
                  'Tambah Kontak Baru',
                  style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Cari teman Anda berdasarkan username unik atau alamat email (FR-06).',
                  style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.s16),
                TextField(
                  controller: searchController,
                  autofocus: true,
                  style: AppTextStyles.bodyLarge(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Masukkan @username atau email...',
                    hintStyle: AppTextStyles.bodyMedium(color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primaryGlow),
                      onPressed: () {
                        ref
                            .read(contactsControllerProvider.notifier)
                            .searchUser(searchController.text);
                      },
                    ),
                  ),
                  onSubmitted: (query) {
                    ref.read(contactsControllerProvider.notifier).searchUser(query);
                  },
                ),
                const SizedBox(height: AppSpacing.s16),

                if (contactsState.isSearching) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpacing.s16),
                      child: CircularProgressIndicator(color: AppColors.primaryGlow),
                    ),
                  ),
                ] else if (searchResult != null) ...[
                  // Kartu Hasil Pencarian
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1728),
                      borderRadius: AppSpacing.cardBorderRadius,
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: AppColors.primaryGradient,
                          ),
                          child: Center(
                            child: Text(
                              (searchResult.displayName?.isNotEmpty == true
                                      ? searchResult.displayName![0]
                                      : searchResult.username?[0] ?? 'U')
                                  .toUpperCase(),
                              style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                searchResult.displayName ?? searchResult.username ?? 'Pengguna',
                                style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                              ),
                              Text(
                                '@${searchResult.username ?? ''}',
                                style: AppTextStyles.labelSmall(color: AppColors.primaryGlow),
                              ),
                              Text(
                                searchResult.email,
                                style: AppTextStyles.labelSmall(color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            final success = await ref
                                .read(contactsControllerProvider.notifier)
                                .sendContactRequest(searchResult.id);
                            if (ctx.mounted && success) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Permintaan pertemanan berhasil dikirim.'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          },
                          child: const Text('Kirim'),
                        ),
                      ],
                    ),
                  ),
                ],

                if (contactsState.errorMessage != null) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    contactsState.errorMessage!,
                    style: AppTextStyles.labelSmall(color: AppColors.danger),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contactsState = ref.watch(contactsControllerProvider);
    final contacts = contactsState.contacts;
    final incomingRequests = contactsState.incomingRequests;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'Kontak',
          style: AppTextStyles.titleMedium(color: AppColors.textPrimary).copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Kontak',
            onPressed: () {
              ref.read(contactsControllerProvider.notifier).loadContactsAndRequests();
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            tooltip: 'Tambah Kontak',
            onPressed: _showAddContactModal,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primaryGlow,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: AppTextStyles.labelLarge(color: AppColors.primaryGlow),
          tabs: [
            Tab(text: 'Semua Kontak (${contacts.length})'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Permintaan (${incomingRequests.length})'),
                  if (incomingRequests.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Daftar Semua Kontak
          RefreshIndicator(
            color: AppColors.primaryGlow,
            backgroundColor: AppColors.surface,
            onRefresh: () => ref.read(contactsControllerProvider.notifier).loadContactsAndRequests(),
            child: contacts.isEmpty
                ? _buildEmptyContactsView()
                : _buildContactsListView(contacts),
          ),

          // Tab 2: Permintaan Kontak Masuk
          RefreshIndicator(
            color: AppColors.primaryGlow,
            backgroundColor: AppColors.surface,
            onRefresh: () => ref.read(contactsControllerProvider.notifier).loadContactsAndRequests(),
            child: incomingRequests.isEmpty
                ? _buildEmptyRequestsView()
                : _buildRequestsListView(incomingRequests),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyContactsView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMarginHorizontal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: const Icon(
                    Icons.people_outline_rounded,
                    size: 44,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                Text(
                  'Belum Ada Kontak',
                  style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Tambah teman untuk mulai percakapan terenkripsi dan berbagi lokasi dua arah.',
                  style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s24),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textPrimary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSpacing.buttonBorderRadius,
                    ),
                  ),
                  onPressed: _showAddContactModal,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                  label: const Text('Tambah Kontak'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContactsListView(List<dynamic> contacts) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMarginHorizontal,
        vertical: AppSpacing.s16,
      ),
      itemCount: contacts.length,
      itemBuilder: (context, index) {
        final contact = contacts[index];
        final user = contact.contactUser;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.s8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: contact.isBlocked ? AppColors.danger : AppColors.surfaceBorder,
            ),
          ),
          child: ListTile(
            onTap: () async {
              if (contact.isBlocked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Buka blokir kontak terlebih dahulu untuk mulai chat.'),
                  ),
                );
                return;
              }
              final conv = await ref
                  .read(chatRepositoryProvider)
                  .getOrCreateConversation(user);
              if (context.mounted) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ChatRoomScreen(conversation: conv),
                  ),
                );
              }
            },
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: Text(
                  (user.displayName?.isNotEmpty == true
                          ? user.displayName![0]
                          : user.username?[0] ?? 'K')
                      .toUpperCase(),
                  style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    contact.displayName,
                    style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                  ),
                ),
                if (contact.isBlocked)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Diblokir',
                      style: AppTextStyles.labelSmall(color: AppColors.danger),
                    ),
                  ),
              ],
            ),
            subtitle: Text(
              '@${user.username ?? ''}',
              style: AppTextStyles.labelSmall(color: AppColors.textMuted),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
              color: AppColors.surface,
              onSelected: (action) {
                if (action == 'block') {
                  ref
                      .read(contactsControllerProvider.notifier)
                      .toggleBlock(contact.id, !contact.isBlocked);
                } else if (action == 'delete') {
                  ref
                      .read(contactsControllerProvider.notifier)
                      .removeContact(contact.id);
                } else if (action == 'report') {
                  ReportModal.show(
                    context,
                    reportedUserId: user.id,
                    reportType: ReportType.profile,
                    targetId: user.id,
                  );
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'block',
                  child: Text(
                    contact.isBlocked ? 'Buka Blokir' : 'Blokir Kontak (FR-08)',
                    style: TextStyle(
                      color: contact.isBlocked ? AppColors.success : AppColors.warning,
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    'Hapus Kontak (FR-08)',
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.report_problem_outlined, color: AppColors.warning, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Laporkan Kontak (FR-41)',
                        style: TextStyle(color: AppColors.warning),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyRequestsView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.18),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenMarginHorizontal),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 44,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                Text(
                  'Tidak Ada Permintaan',
                  style: AppTextStyles.headlineMedium(color: AppColors.textPrimary),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Permintaan pertemanan baru yang masuk akan muncul di sini.\nTarik layar ke bawah untuk menyegarkan.',
                  style: AppTextStyles.bodyMedium(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsListView(List<dynamic> requests) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenMarginHorizontal,
        vertical: AppSpacing.s16,
      ),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final sender = req.sender;

        return Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.s12),
          padding: const EdgeInsets.all(AppSpacing.s16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                    ),
                    child: Center(
                      child: Text(
                        (sender.displayName?.isNotEmpty == true
                                ? sender.displayName![0]
                                : sender.username?[0] ?? 'P')
                            .toUpperCase(),
                        style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sender.displayName ?? sender.username ?? 'Pengguna',
                          style: AppTextStyles.titleMedium(color: AppColors.textPrimary),
                        ),
                        Text(
                          '@${sender.username ?? ''}',
                          style: AppTextStyles.labelSmall(color: AppColors.primaryGlow),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      ref
                          .read(contactsControllerProvider.notifier)
                          .rejectRequest(req.id);
                    },
                    child: Text(
                      'Tolak',
                      style: AppTextStyles.labelLarge(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(contactsControllerProvider.notifier)
                          .acceptRequest(req.id);
                    },
                    child: const Text('Terima (FR-07)'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
