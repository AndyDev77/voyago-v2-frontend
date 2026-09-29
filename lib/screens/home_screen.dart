import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../theme.dart';
import '../widgets/xp_progress_bar.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    // Redirection automatique pour tout utilisateur connecté qui n'a pas validé l'onboarding
    if (authState.sessionLoaded && user != null && !user.onboardingCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go('/onboarding');
        }
      });
    }

    return Scaffold(
      backgroundColor: VoyagoColors.background,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/logo/logo.png',
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) => const Text('🦜', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 8),
            const Text(
              'Voyago',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: VoyagoColors.primary,
              ),
            ),
          ],
        ),
        actions: [
          if (user != null)
            IconButton(
              icon: Text(
                user.avatarDisplay,
                style: const TextStyle(fontSize: 22),
              ),
              onPressed: () => context.go('/profile'),
            )
          else
            TextButton(
              onPressed: () => context.go('/auth'),
              child: const Text('Connexion'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // XP / Auth banner
            if (user != null)
              _UserBanner(userId: user.userId)
            else
              _AuthBanner(onTap: () => context.go('/auth')),

            const SizedBox(height: 28),

            // Hero section
            _HeroSection(onStart: () => context.go('/swipe')),

            const SizedBox(height: 20),

            // Map & Dashboard banner
            GestureDetector(
              onTap: () => context.go('/itinerary'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      VoyagoColors.primary.withValues(alpha: 0.15),
                      VoyagoColors.blue.withValues(alpha: 0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: VoyagoColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: VoyagoColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: VoyagoColors.primary.withValues(alpha: 0.4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.map_rounded, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tableau de Bord & Carte',
                            style: TextStyle(
                              color: VoyagoColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Carte Leaflet interactive, météo en direct et itinéraire',
                            style: TextStyle(
                              color: VoyagoColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, color: VoyagoColors.primary, size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Cards grid
            Text(
              'Explorer',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _NavCard(
                    emoji: '🌍',
                    title: 'Communauté',
                    subtitle: 'Voyages partagés',
                    color: VoyagoColors.blue,
                    onTap: () => context.go('/community'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _NavCard(
                    emoji: '⭐',
                    title: 'Récompenses',
                    subtitle: 'Niveaux & XP',
                    color: VoyagoColors.yellow,
                    onTap: () => context.go('/xp-rewards'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _NavCard(
                    emoji: '💎',
                    title: 'Voyago Pro',
                    subtitle: 'Accès illimité',
                    color: VoyagoColors.primary,
                    onTap: () => context.go('/pricing'),
                  ),
                ),
                if (user != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _NavCard(
                      emoji: '👤',
                      title: 'Profil',
                      subtitle: 'Mes voyages',
                      color: VoyagoColors.coral,
                      onTap: () => context.go('/profile'),
                    ),
                  ),
                ] else
                  const Expanded(child: SizedBox()),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _UserBanner extends ConsumerWidget {
  final String userId;
  const _UserBanner({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider(userId));

    return profileAsync.when(
      data: (profile) => XpProgressBar(
        xp: profile.xp,
        level: profile.level,
        streak: profile.streak,
      ),
      loading: () => const SizedBox(
        height: 64,
        child: Center(
          child: LinearProgressIndicator(),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _AuthBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _AuthBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [VoyagoColors.primaryDark, VoyagoColors.primary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bienvenue sur Voyago ! 🦜',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Connecte-toi pour sauvegarder tes voyages',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: VoyagoColors.primary,
            ),
            child: const Text('Connexion'),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  final VoidCallback onStart;
  const _HeroSection({required this.onStart});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: VoyagoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VoyagoColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text('🦜', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text(
            'Voyage. Joue. Découvre.',
            style: TextStyle(
              color: VoyagoColors.text,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Laissez Voyago et l\'IA concevoir votre\nitinéraire personnalisé en quelques secondes',
            style: TextStyle(color: VoyagoColors.muted, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onStart,
              icon: const Text('🗺', style: TextStyle(fontSize: 18)),
              label: const Text('Commencer un voyage'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VoyagoColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: VoyagoColors.text,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(color: VoyagoColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
