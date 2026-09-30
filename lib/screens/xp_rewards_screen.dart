import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../services/api_service.dart';

class XpRewardsScreen extends ConsumerStatefulWidget {
  const XpRewardsScreen({super.key});

  @override
  ConsumerState<XpRewardsScreen> createState() => _XpRewardsScreenState();
}

class _XpRewardsScreenState extends ConsumerState<XpRewardsScreen>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  late final AnimationController _shimmerController;

  bool _isLoading = true;
  Map<String, dynamic> _apiData = {};

  // Palette fidèle au composant Onboarding Success
  static const Color _primaryGold = Color(0xFFF4C025);
  static const Color _goldLight = Color(0xFFFFCF33);
  static const Color _bgDark = Color(0xFF16130B);
  static const Color _glassBg = Color(0xCC221E10);
  static const Color _glassBorder = Color(0x1AFFFFFF);

  // Image officielle du composant
  static const String _chestImageUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCxNp68FyeOMA1qRvTRIxnbv_uPmkh53SzFlNjAz95t--p5kYSrW9HUV_7y6BwJKFhi6639_EAjp6mR8S6wGqQSGdabk7f0QAVbCuhlLzjU0ioBbRgo0DKM94G_qzm55CSXG28zHZNHDGAHIxj2fJrwZ-2zBIRX-CTQVkHXUBcVfOHSiIhB507DX5v1ozewB-LXDioTVE5u5gR7YHcVxjkWaqhlEfUgbvbBmjRtkiBXNNr9GXBKhjrIBDRmkYhaSFARShK2ZthmMu6H';

  static const String _mapBgUrl =
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBCaBMRmRj1SezYsp2kxF9J0nYpVY0S6O8-X3TZ8dYaKfD76CjXZT81kVuAV0H2wsHkW2jMfA5uCIKDYWy4hO4zw0Qx93jupQig0Mmbo_0Pe7Tv9B8cRF3-3GE3UlU_CIO1g7u5eeFgWnShiu3CiDe9OtedMS0chgLrkzsWUSFAJCCsGjVua9SFrxNmOkASVIaH-9rjSqydVJWKL5UbC5Ieb4aryy330fBExlYtBCCZzn42nvEScQv_j6b6S3Wljx5IXlyxWSs73ik-';

  // Actions de base conformes à l'existant
  static const Map<String, dynamic> _defaultData = {
    'total_xp': 200,
    'level': 3,
    'current_level_xp': 0,
    'next_level_xp': 100,
    'xp_to_next_level': 100,
    'progress_ratio': 0.0,
    'current_level_title': 'Aventurier',
    'next_level_title': 'Globe-trotteur',
    'actions': [
      {
        'action': 'generate_trip',
        'xp': 3,
        'emoji': '✈️',
        'icon_name': 'flight',
        'label': 'Générer un itinéraire',
        'completed': true,
        'progress_label': 'Voyages créés',
      },
      {
        'action': 'first_trip',
        'xp': 7,
        'emoji': '🎉',
        'icon_name': 'celebration',
        'label': 'Premier voyage',
        'completed': true,
        'progress_label': 'Accompli',
      },
      {
        'action': 'complete_profile',
        'xp': 1,
        'emoji': '👤',
        'icon_name': 'person',
        'label': 'Compléter son profil',
        'completed': true,
        'progress_label': 'Profil renseigné',
      },
      {
        'action': 'select_interests',
        'xp': 1,
        'emoji': '🎯',
        'icon_name': 'interests',
        'label': 'Sélectionner ses envies',
        'completed': true,
        'progress_label': 'Préférences définies',
      },
      {
        'action': 'thermal_setup',
        'xp': 1,
        'emoji': '🌡️',
        'icon_name': 'thermostat',
        'label': 'Sensibilité thermique',
        'completed': true,
        'progress_label': 'Météo calibrée',
      },
      {
        'action': 'share_trip',
        'xp': 1,
        'emoji': '📤',
        'icon_name': 'share',
        'label': 'Partager un voyage',
        'completed': false,
        'progress_label': null,
      },
      {
        'action': 'daily_login',
        'xp': 1,
        'emoji': '🔥',
        'icon_name': 'local_fire_department',
        'label': 'Connexion quotidienne',
        'completed': true,
        'progress_label': 'Actif aujourd\'hui',
      },
      {
        'action': 'first_swipe',
        'xp': 1,
        'emoji': '👆',
        'icon_name': 'touch_app',
        'label': 'Premier swipe découverte',
        'completed': true,
        'progress_label': 'Découvert',
      },
    ],
    'levels': [
      {'level': 1, 'min_xp': 0, 'title': 'Explorateur', 'reward': 'Badge Débutant'},
      {'level': 2, 'min_xp': 100, 'title': 'Voyageur', 'reward': 'Badge Voyageur'},
      {'level': 3, 'min_xp': 200, 'title': 'Aventurier', 'reward': 'Badge Aventurier'},
      {'level': 5, 'min_xp': 400, 'title': 'Globe-trotteur', 'reward': 'Badge Globe-trotteur'},
      {'level': 10, 'min_xp': 900, 'title': 'Légende', 'reward': 'Badge Légendaire + Pro 1 mois'},
    ],
  };

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    _loadData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final authState = ref.read(authProvider);
    final userId = authState.user?.userId;
    if (userId != null) {
      ref.invalidate(profileProvider(userId));
    }

    try {
      final data = await ApiService.instance.getXpRewards(userId);
      if (mounted) {
        setState(() {
          _apiData = data.isNotEmpty ? data : _defaultData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _apiData = _defaultData;
          _isLoading = false;
        });
      }
    }
  }

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'flight':
        return Icons.flight_takeoff_rounded;
      case 'celebration':
        return Icons.celebration_rounded;
      case 'person':
        return Icons.person_rounded;
      case 'interests':
        return Icons.interests_rounded;
      case 'thermostat':
        return Icons.thermostat_rounded;
      case 'share':
        return Icons.share_rounded;
      case 'local_fire_department':
        return Icons.local_fire_department_rounded;
      case 'touch_app':
        return Icons.touch_app_rounded;
      default:
        return Icons.stars_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final userId = user?.userId;

    // Profil temps réel via Riverpod si disponible
    final userProfileAsync = userId != null ? ref.watch(profileProvider(userId)) : null;
    final liveProfile = userProfileAsync?.valueOrNull;

    // Récupérer l'XP cumulé dynamiquement
    final totalXp = _apiData['total_xp'] as int? ??
        liveProfile?.xp ??
        _defaultData['total_xp'] as int;

    final currentLevel = _apiData['level'] as int? ??
        liveProfile?.level ??
        (totalXp ~/ 100 + 1);

    final currentLevelXp = _apiData['current_level_xp'] as int? ?? (totalXp % 100);
    final nextLevelXp = _apiData['next_level_xp'] as int? ?? 100;
    final xpToNextLevel = _apiData['xp_to_next_level'] as int? ?? (nextLevelXp - currentLevelXp);
    final progressRatio = (_apiData['progress_ratio'] as num?)?.toDouble() ??
        ((currentLevelXp / (nextLevelXp > 0 ? nextLevelXp : 100)).clamp(0.05, 1.0));

    final currentLevelTitle = _apiData['current_level_title']?.toString() ??
        (currentLevel >= 10
            ? 'Légende'
            : currentLevel >= 5
                ? 'Globe-trotteur'
                : currentLevel >= 3
                    ? 'Aventurier'
                    : currentLevel >= 2
                        ? 'Voyageur'
                        : 'Explorateur');

    final nextLevelTitle = _apiData['next_level_title']?.toString() ?? 'Niveau ${currentLevel + 1}';

    final actions = (_apiData['actions'] as List<dynamic>?) ??
        (_defaultData['actions'] as List<dynamic>);

    final levels = (_apiData['levels'] as List<dynamic>?) ??
        (_defaultData['levels'] as List<dynamic>);

    return Scaffold(
      backgroundColor: _bgDark,
      body: Stack(
        children: [
          // 1. Fond Carte du monde texturé avec fondu radial
          Positioned.fill(
            child: Opacity(
              opacity: 0.18,
              child: Image.network(
                _mapBgUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.1,
                  colors: [
                    Colors.transparent,
                    Color(0x9916130B),
                    _bgDark,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // 2. Contenu principal défilable
          SafeArea(
            child: Column(
              children: [
                // Top Header / Navigation
                _buildHeader(context, user),

                // Corps défilable
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _primaryGold),
                        )
                      : RefreshIndicator(
                          color: _primaryGold,
                          backgroundColor: _bgDark,
                          onRefresh: () async {
                            if (userId != null) {
                              ref.invalidate(profileProvider(userId));
                            }
                            await _loadData();
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            child: Column(
                              children: [
                                // Hero Visual avec Coffre & Halo Doré
                                _buildHeroVisual(),
                                const SizedBox(height: 12),

                                // XP Gagnés / Titre héroïque
                                _buildHeroText(totalXp),
                                const SizedBox(height: 24),

                                // Carte Glassmorphism principale
                                _buildGlassCard(
                                  actions: actions,
                                  currentLevel: currentLevel,
                                  currentLevelTitle: currentLevelTitle,
                                  nextLevelTitle: nextLevelTitle,
                                  currentLevelXp: currentLevelXp,
                                  nextLevelXp: nextLevelXp,
                                  xpToNextLevel: xpToNextLevel,
                                  progressRatio: progressRatio,
                                ),
                                const SizedBox(height: 28),

                                // Paliers de Niveaux
                                _buildLevelsMilestones(levels, totalXp, currentLevel),
                                const SizedBox(height: 36),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 1. HEADER DE NAVIGATION ---
  Widget _buildHeader(BuildContext context, dynamic user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x14FFFFFF), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                onPressed: () => context.go('/'),
                visualDensity: VisualDensity.compact,
                splashRadius: 22,
              ),
              const SizedBox(width: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _primaryGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.explore_rounded, color: _primaryGold, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Récompenses XP',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          // User Avatar / Badge
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _primaryGold.withValues(alpha: 0.4), width: 1.5),
              color: const Color(0x33221E10),
            ),
            clipBehavior: Clip.antiAlias,
            child: user?.picture != null && user!.picture!.isNotEmpty
                ? Image.network(
                    user.picture!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text('👤', style: TextStyle(fontSize: 18)),
                    ),
                  )
                : Center(
                    child: Text(
                      user?.avatarEmoji ?? '🧭',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // --- 2. HERO VISUAL (COFFRE & HALO DORÉ) ---
  Widget _buildHeroVisual() {
    return SizedBox(
      height: 220,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Halo doré lumineux animé avec pulsation
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        _primaryGold.withValues(alpha: 0.45),
                        _primaryGold.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),
          // Image du coffre aux trésors magique
          Image.network(
            _chestImageUrl,
            height: 190,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _primaryGold.withValues(alpha: 0.15),
                border: Border.all(color: _primaryGold.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.inventory_2_rounded, color: _primaryGold, size: 70),
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. HEADER TEXT & XP ---
  Widget _buildHeroText(int totalXp) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: _primaryGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primaryGold.withValues(alpha: 0.25)),
          ),
          child: const Text(
            'ONBOARDING & AVENTURES',
            style: TextStyle(
              color: _goldLight,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '+$totalXp XP',
          style: const TextStyle(
            color: _primaryGold,
            fontSize: 48,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.0,
            height: 1.05,
            shadows: [
              Shadow(
                color: Color(0x99F4C025),
                blurRadius: 28,
              ),
              Shadow(
                color: Color(0x66F4C025),
                blurRadius: 14,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Gagnés',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  // --- 4. GLASS PANEL PRINCIPAL ---
  Widget _buildGlassCard({
    required List<dynamic> actions,
    required int currentLevel,
    required String currentLevelTitle,
    required String nextLevelTitle,
    required int currentLevelXp,
    required int nextLevelXp,
    required int xpToNextLevel,
    required double progressRatio,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _glassBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: _glassBorder, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 30,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre section XP Breakdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comment gagner de l\'XP',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${actions.where((a) => a['completed'] == true).length}/${actions.length} validées',
                      style: const TextStyle(
                        color: _goldLight,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Liste dynamique des actions XP
              ...actions.map((act) => _buildActionRow(act as Map<String, dynamic>)),

              const SizedBox(height: 24),
              const Divider(color: Color(0x1AFFFFFF), height: 1),
              const SizedBox(height: 24),

              // Barre de progression du niveau
              _buildLevelProgressBar(
                currentLevel: currentLevel,
                currentLevelTitle: currentLevelTitle,
                nextLevelTitle: nextLevelTitle,
                currentLevelXp: currentLevelXp,
                nextLevelXp: nextLevelXp,
                xpToNextLevel: xpToNextLevel,
                progressRatio: progressRatio,
              ),

              const SizedBox(height: 24),

              // Bouton CTA principal
              _buildCtaButton(),

              const SizedBox(height: 18),

              // Texte d'accroche / footer
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome_rounded, color: _primaryGold, size: 16),
                  SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Vous êtes maintenant prêt pour la génération magique !',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 5. LIGNE D'ACTION XP ---
  Widget _buildActionRow(Map<String, dynamic> action) {
    final xp = action['xp'] as int? ?? 10;
    final label = action['label']?.toString() ?? action['description']?.toString() ?? 'Action';
    final isCompleted = action['completed'] == true;
    final progressLabel = action['progress_label']?.toString();
    final iconName = action['icon_name']?.toString();
    final emoji = action['emoji']?.toString() ?? '⭐';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCompleted
            ? _primaryGold.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? _primaryGold.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icône circulaire dorée
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted
                  ? _primaryGold
                  : _primaryGold.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: isCompleted
                ? const Icon(Icons.check_rounded, color: _bgDark, size: 22)
                : (iconName != null
                    ? Icon(_getIconData(iconName), color: _primaryGold, size: 20)
                    : Text(emoji, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),

          // Libellé et sous-titre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isCompleted ? Colors.white : Colors.white.withValues(alpha: 0.88),
                    fontSize: 14,
                    fontWeight: isCompleted ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                if (progressLabel != null && progressLabel.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    progressLabel,
                    style: const TextStyle(
                      color: _goldLight,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else if (isCompleted) ...[
                  const SizedBox(height: 2),
                  const Text(
                    'Complété',
                    style: TextStyle(
                      color: Color(0xFF4ADE80),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Badge XP
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: isCompleted
                  ? const Color(0xFF22C55E).withValues(alpha: 0.15)
                  : _primaryGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCompleted
                    ? const Color(0xFF22C55E).withValues(alpha: 0.3)
                    : _primaryGold.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '+$xp XP',
              style: TextStyle(
                color: isCompleted ? const Color(0xFF4ADE80) : _primaryGold,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. BARRE DE PROGRESSION DU NIVEAU ---
  Widget _buildLevelProgressBar({
    required int currentLevel,
    required String currentLevelTitle,
    required String nextLevelTitle,
    required int currentLevelXp,
    required int nextLevelXp,
    required int xpToNextLevel,
    required double progressRatio,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête des niveaux
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'NIVEAU $currentLevel ($currentLevelTitle)',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              nextLevelTitle.toUpperCase(),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Barre stylisée avec effet shimmer
        Container(
          height: 24,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Remplissage avec dégradé doré
              if (progressRatio > 0.0)
                FractionallySizedBox(
                  widthFactor: progressRatio.clamp(0.0, 1.0),
                  child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFE5A910),
                        _primaryGold,
                        Color(0xFFFFDF70),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66F4C025),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: AnimatedBuilder(
                    animation: _shimmerController,
                    builder: (context, child) {
                      return ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: const Alignment(-1.0, 0.0),
                            end: const Alignment(1.0, 0.0),
                            colors: const [
                              Colors.transparent,
                              Color(0x99FFFFFF),
                              Colors.transparent,
                            ],
                            stops: [
                              (_shimmerController.value - 0.25).clamp(0.0, 1.0),
                              _shimmerController.value,
                              (_shimmerController.value + 0.25).clamp(0.0, 1.0),
                            ],
                          ).createShader(bounds);
                        },
                        blendMode: BlendMode.srcATop,
                        child: Container(color: Colors.transparent),
                      );
                    },
                  ),
                ),
              ),

              // Texte indicateur dans la barre (ex: 0 / 200 XP)
              Positioned(
                right: 10,
                child: Text(
                  '$currentLevelXp / $nextLevelXp XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Message XP restant
        Center(
          child: Text(
            '$xpToNextLevel XP requis pour le palier $nextLevelTitle',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // --- 7. BOUTON D'ACTION PRINCIPAL ---
  Widget _buildCtaButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: () {
          // Naviguer vers la création d'itinéraire ou l'accueil
          context.go('/');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryGold,
          foregroundColor: _bgDark,
          elevation: 8,
          shadowColor: _primaryGold.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Commencer une aventure',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  // --- 8. PALIERS DE NIVEAUX ---
  Widget _buildLevelsMilestones(List<dynamic> levels, int totalXp, int currentLevel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Paliers de niveaux',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...levels.map((lvl) {
          final levelMap = lvl as Map<String, dynamic>;
          final levelNum = levelMap['level'] as int? ?? 1;
          final minXp = levelMap['min_xp'] as int? ?? 0;
          final title = levelMap['title']?.toString() ?? 'Niveau $levelNum';
          final reward = levelMap['reward']?.toString() ?? '';
          final isReached = levelMap['is_reached'] as bool? ?? (totalXp >= minXp);
          final isCurrent = levelMap['is_current'] as bool? ?? (levelNum == currentLevel);

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCurrent
                  ? _primaryGold.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCurrent
                    ? _primaryGold
                    : isReached
                        ? _primaryGold.withValues(alpha: 0.3)
                        : Colors.white.withValues(alpha: 0.06),
                width: isCurrent ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Numéro de niveau
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isReached
                        ? _primaryGold.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isReached ? _primaryGold : Colors.white12,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$levelNum',
                    style: TextStyle(
                      color: isReached ? _primaryGold : Colors.white54,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Titre et XP requis
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: _primaryGold,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'ACTUEL',
                                style: TextStyle(
                                  color: _bgDark,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$minXp XP requis',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge de récompense
                if (reward.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isReached
                          ? _primaryGold.withValues(alpha: 0.15)
                          : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isReached
                            ? _primaryGold.withValues(alpha: 0.3)
                            : Colors.white12,
                      ),
                    ),
                    child: Text(
                      reward,
                      style: TextStyle(
                        color: isReached ? _goldLight : Colors.white38,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
