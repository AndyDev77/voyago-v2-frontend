import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import '../providers/auth_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;
  final ScrollController _scrollController = ScrollController();

  static const Color primaryCyan = Color(0xFF0DF2CC);
  static const Color darkBackground = Color(0xFF10221F);
  static const Color cardDark = Color(0xFF1B2725);
  static const Color cardBorder = Color(0xFF3B5450);
  static const Color textMuted = Color(0xFF9CBAB5);

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset(
        'assets/medias/media_logo_voyago_2.mp4',
      );
      await _videoController.initialize();
      _videoController.setLooping(true);
      _videoController.setVolume(0.0); // Vidéo en fond muet
      await _videoController.play();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement vidéo de fond: $e');
    }
  }

  @override
  void dispose() {
    _videoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToFeatures() {
    _scrollController.animateTo(
      650,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: [
          // 1. Fond Vidéo avec dégradé cinématique
          Positioned.fill(
            child: _buildVideoBackground(),
          ),

          // 2. Dégradé sombre pour lisibilité optimale
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.40),
                    darkBackground.withValues(alpha: 0.90),
                    darkBackground,
                  ],
                  stops: const [0.0, 0.4, 0.75, 1.0],
                ),
              ),
            ),
          ),

          // 3. Contenu principal défilable
          SafeArea(
            child: Column(
              children: [
                // En-tête simplifié sans menus superflus
                _buildHeader(context, user != null),

                // Corps défilable
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),

                        // Section Héro
                        _buildHeroSection(context, user != null),

                        const SizedBox(height: 56),

                        // Section Fonctionnalités Intelligentes
                        _buildFeaturesSection(context),

                        const SizedBox(height: 48),

                        // Section Appel à l'action (CTA)
                        _buildCtaSection(context, user != null),

                        const SizedBox(height: 40),

                        // Pied de page synthétique
                        _buildFooter(),

                        const SizedBox(height: 24),
                      ],
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

  /// Fond vidéo avec animation de transition et solution de repli esthétique
  Widget _buildVideoBackground() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: _isVideoInitialized && _videoController.value.isInitialized
          ? SizedBox.expand(
              key: const ValueKey('video_ready'),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController.value.size.width > 0
                      ? _videoController.value.size.width
                      : 1080,
                  height: _videoController.value.size.height > 0
                      ? _videoController.value.size.height
                      : 1920,
                  child: VideoPlayer(_videoController),
                ),
              ),
            )
          : Container(
              key: const ValueKey('fallback_gradient'),
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.3),
                  radius: 1.2,
                  colors: [
                    Color(0xFF1B3833),
                    darkBackground,
                  ],
                ),
              ),
            ),
    );
  }

  /// En-tête sans les menus de navigation traditionnels
  Widget _buildHeader(BuildContext context, bool isLoggedIn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: darkBackground.withValues(alpha: 0.75),
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF283936).withValues(alpha: 0.6),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo officiel et nom
          InkWell(
            onTap: () {
              if (_scrollController.hasClients) {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                );
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/logo/voyago_parrot.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primaryCyan.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Icon(Icons.flight_takeoff_rounded, color: primaryCyan, size: 22),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Voyago',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Bouton d'action directe (Connexion ou Espace Voyageur)
          if (!isLoggedIn)
            OutlinedButton(
              onPressed: () => context.go('/auth'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: primaryCyan, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                minimumSize: const Size(84, 38),
              ),
              child: Text(
                'Connexion',
                style: GoogleFonts.spaceGrotesk(
                  color: primaryCyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.dashboard_rounded, size: 16, color: darkBackground),
              label: Text(
                'Mon Espace',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: darkBackground,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryCyan,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                minimumSize: const Size(90, 38),
              ),
            ),
        ],
      ),
    );
  }

  /// Section Héro avec typographie percutante et boutons d'action
  Widget _buildHeroSection(BuildContext context, bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Tag d'accroche IA
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: primaryCyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryCyan.withValues(alpha: 0.35),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, color: primaryCyan, size: 16),
                const SizedBox(width: 8),
                Text(
                  'COMPAGNON DE VOYAGE INTELLIGENT',
                  style: GoogleFonts.spaceGrotesk(
                    color: primaryCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Titre principal
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: GoogleFonts.spaceGrotesk(
                fontSize: 38,
                fontWeight: FontWeight.w800,
                height: 1.15,
                color: Colors.white,
                letterSpacing: -1.0,
              ),
              children: [
                const TextSpan(text: 'Voyagez Plus Malin,\n'),
                WidgetSpan(
                  child: ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [primaryCyan, Color(0xFF2DD4BF)],
                    ).createShader(bounds),
                    child: Text(
                      'Explorez Sans Limite.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sous-titre synthétique
          Text(
            'Votre guide IA pour révéler les pépites secrètes, ajuster vos trajets selon la météo et transformer chaque escapade en aventure gamifiée.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFD1E3DF),
              height: 1.5,
            ),
          ),

          const SizedBox(height: 32),

          // Boutons d'action principaux
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLoggedIn) {
                      context.go('/swipe');
                    } else {
                      context.go('/swipe');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryCyan,
                    foregroundColor: darkBackground,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    shadowColor: primaryCyan.withValues(alpha: 0.4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Commencer l\'Aventure',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: darkBackground,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20, color: darkBackground),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _scrollToFeatures,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Découvrir les fonctionnalités',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Colors.white70),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Section des 3 fonctionnalités majeures synthétisées
  Widget _buildFeaturesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de section
          Text(
            'Fonctionnalités Intelligentes',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Conçu pour s\'adapter dynamiquement à vos envies et aux conditions du monde réel.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textMuted,
            ),
          ),

          const SizedBox(height: 20),

          // 1. Itinéraires IA
          _buildFeatureCard(
            icon: Icons.psychology_rounded,
            title: 'Itinéraires IA Sur-Mesure',
            description:
                'Plans générés en quelques secondes selon votre style, votre budget et le rythme souhaité.',
            badgeText: 'Instant & Personnalisé',
          ),

          const SizedBox(height: 14),

          // 2. Météo & Confort thermique
          _buildFeatureCard(
            icon: Icons.thunderstorm_rounded,
            title: 'Adaptation Météo en Direct',
            description:
                'Ajustement instantané des activités en cas de pluie, canicule ou selon votre sensibilité thermique.',
            badgeText: 'Temps Réel & Thermosensible',
          ),

          const SizedBox(height: 14),

          // 3. Exploration Gamifiée
          _buildFeatureCard(
            icon: Icons.sports_esports_rounded,
            title: 'Exploration Gamifiée',
            description:
                'Gagnez des points d\'XP, progressez dans les niveaux et débloquez des badges exclusifs en voyageant.',
            badgeText: 'XP & Badges Uniques',
          ),
        ],
      ),
    );
  }

  /// Carte de fonctionnalité unifiée avec esthétique dark moderne
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required String badgeText,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
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
                  color: primaryCyan.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: primaryCyan.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(icon, color: primaryCyan, size: 24),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeText,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: primaryCyan,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w400,
              color: textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Section d'appel à l'action finale (CTA)
  Widget _buildCtaSection(BuildContext context, bool isLoggedIn) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFF142C28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primaryCyan.withValues(alpha: 0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryCyan.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primaryCyan.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.explore_rounded,
              color: primaryCyan,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Prêt à voyager autrement ?',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rejoignez la communauté Voyago et commencez à explorer le monde à votre manière dès maintenant.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: textMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (isLoggedIn) {
                  context.go('/swipe');
                } else {
                  context.go('/auth');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryCyan,
                foregroundColor: darkBackground,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isLoggedIn ? 'Créer mon itinéraire' : 'Créer un compte gratuit',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: darkBackground,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pied de page
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Divider(color: const Color(0xFF283936).withValues(alpha: 0.6), height: 1),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/logo/voyago_parrot.png',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.flight_takeoff_rounded,
                  color: primaryCyan,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Voyago • Smart Travel Companion',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '© 2026 Voyago. Tous droits réservés.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 11,
              color: const Color(0xFF5A706B),
            ),
          ),
        ],
      ),
    );
  }
}
