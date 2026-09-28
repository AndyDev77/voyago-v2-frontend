import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/trips_provider.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/xp_progress_bar.dart';
import '../widgets/badge_grid.dart';
import '../widgets/trip_card.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isLoggedIn) {
      return Scaffold(
        backgroundColor: VoyagoColors.background,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/'),
          ),
          title: const Text('Profil'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('👤', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 20),
                const Text(
                  'Connectez-vous pour voir votre profil',
                  style: TextStyle(
                    color: VoyagoColors.text,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/auth'),
                  child: const Text('Se connecter'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _ProfileContent(userId: authState.user!.userId);
  }
}

class _ProfileContent extends ConsumerStatefulWidget {
  final String userId;
  const _ProfileContent({required this.userId});

  @override
  ConsumerState<_ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends ConsumerState<_ProfileContent> {
  List<Map<String, dynamic>> _allBadges = [];
  bool _isEditing = false;

  final _pseudoCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  String? _editAvatarEmoji;
  String? _editCountry;
  bool _isSaving = false;

  static const List<String> _avatarEmojis = [
    '🦜', '🦁', '🐯', '🦊', '🐺', '🐻',
    '🦝', '🐸', '🦄', '🐉', '🦅', '🐬',
  ];

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  @override
  void dispose() {
    _pseudoCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBadges() async {
    try {
      final badges = await ApiService.instance.getBadges();
      if (mounted) setState(() => _allBadges = badges);
    } catch (_) {}
  }

  void _startEditing() {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    _pseudoCtrl.text = user.pseudo ?? '';
    _cityCtrl.text = user.city ?? '';
    _editAvatarEmoji = user.avatarEmoji;
    _editCountry = user.country;
    setState(() => _isEditing = true);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      await ref.read(authProvider.notifier).updateProfile({
        if (_pseudoCtrl.text.isNotEmpty) 'pseudo': _pseudoCtrl.text.trim(),
        if (_editAvatarEmoji != null) 'avatar_emoji': _editAvatarEmoji,
        if (_editCountry != null) 'country': _editCountry,
        if (_cityCtrl.text.isNotEmpty) 'city': _cityCtrl.text.trim(),
      });
      if (mounted) setState(() => _isEditing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: VoyagoColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Se déconnecter ?', style: TextStyle(color: VoyagoColors.text)),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: TextStyle(color: VoyagoColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: VoyagoColors.coral),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user!;
    final profileAsync = ref.watch(profileProvider(widget.userId));
    final tripsAsync = ref.watch(tripsProvider(widget.userId));

    return Scaffold(
      backgroundColor: VoyagoColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Mon Profil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: _startEditing,
            )
          else
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Sauvegarder'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Avatar
                  if (_isEditing)
                    _AvatarPicker(
                      emojis: _avatarEmojis,
                      selected: _editAvatarEmoji ?? user.avatarDisplay,
                      onSelect: (e) => setState(() => _editAvatarEmoji = e),
                    )
                  else
                    Text(user.avatarDisplay, style: const TextStyle(fontSize: 72)),

                  const SizedBox(height: 12),

                  if (_isEditing) ...[
                    TextField(
                      controller: _pseudoCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pseudo',
                        prefixIcon: Icon(Icons.alternate_email, color: VoyagoColors.muted),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Ville',
                        prefixIcon: Icon(Icons.location_city_outlined, color: VoyagoColors.muted),
                      ),
                    ),
                  ] else ...[
                    Text(
                      user.displayName,
                      style: const TextStyle(
                        color: VoyagoColors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user.pseudo != null && user.pseudo != user.name)
                      Text(
                        '@${user.pseudo}',
                        style: const TextStyle(color: VoyagoColors.muted, fontSize: 14),
                      ),
                    if (user.isPro) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: VoyagoColors.blue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: VoyagoColors.blue.withOpacity(0.4)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('💎', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              'Voyago Pro${user.proTier != null ? ' · ${user.proTier}' : ''}',
                              style: const TextStyle(
                                color: VoyagoColors.blue,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    if (user.city != null || user.country != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        [user.city, user.country].where((e) => e != null).join(', '),
                        style: const TextStyle(color: VoyagoColors.muted, fontSize: 13),
                      ),
                    ],
                  ],
                ],
              ),
            ),

            // XP Bar
            profileAsync.when(
              data: (profile) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: XpProgressBar(
                  xp: profile.xp,
                  level: profile.level,
                  streak: profile.streak,
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 24),

            // Stats
            profileAsync.when(
              data: (profile) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(child: _StatCard(label: 'Voyages', value: '${profile.tripsCount}', emoji: '✈️')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'XP Total', value: '${profile.xp}', emoji: '⭐')),
                    const SizedBox(width: 12),
                    Expanded(child: _StatCard(label: 'Badges', value: '${profile.badges.length}', emoji: '🏆')),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 28),

            // Badges
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Badges',
                style: TextStyle(
                  color: VoyagoColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            profileAsync.when(
              data: (profile) => BadgeGrid(
                earnedBadges: profile.badges,
                allBadges: _allBadges,
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 28),

            // Trips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                'Mes voyages',
                style: TextStyle(
                  color: VoyagoColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            tripsAsync.when(
              data: (trips) {
                if (trips.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Column(
                        children: [
                          Text('🦜', style: TextStyle(fontSize: 40)),
                          SizedBox(height: 12),
                          Text(
                            'Aucun voyage encore 🦜',
                            style: TextStyle(
                              color: VoyagoColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Lancez l\'IA Voyago pour créer votre première aventure !',
                            style: TextStyle(color: VoyagoColors.muted, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return Column(
                  children: trips
                      .map((t) => TripCard(
                            trip: t,
                            onTap: () => context.go('/itinerary/${t.id}', extra: t),
                          ))
                      .toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: LinearProgressIndicator(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Erreur: ${e.toString()}',
                  style: const TextStyle(color: VoyagoColors.coral),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _logout,
                  icon: const Icon(Icons.logout, color: VoyagoColors.coral),
                  label: const Text(
                    'Se déconnecter',
                    style: TextStyle(color: VoyagoColors.coral),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: VoyagoColors.coral),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _AvatarPicker extends StatelessWidget {
  final List<String> emojis;
  final String selected;
  final ValueChanged<String> onSelect;

  const _AvatarPicker({
    required this.emojis,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(selected, style: const TextStyle(fontSize: 56)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: emojis.map((e) {
            final isSelected = e == selected;
            return GestureDetector(
              onTap: () => onSelect(e),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? VoyagoColors.primary.withOpacity(0.2)
                      : VoyagoColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? VoyagoColors.primary : VoyagoColors.cardBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(e, style: const TextStyle(fontSize: 20)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _StatCard({
    required this.label,
    required this.value,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: VoyagoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: VoyagoColors.cardBorder),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: VoyagoColors.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: VoyagoColors.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
