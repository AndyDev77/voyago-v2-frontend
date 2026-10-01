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

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const Color primaryCyan = Color(0xFF0DF2CC);
  static const Color darkBackground = Color(0xFF10221F);
  static const Color cardDark = Color(0xFF1B2725);
  static const Color cardBorder = Color(0xFF3B5450);
  static const Color textMuted = Color(0xFF9CBAB5);

  final List<_WelcomeSlideData> _slides = const [
    _WelcomeSlideData(
      tag: 'INTELLIGENCE ARTIFICIELLE',
      icon: Icons.auto_awesome_rounded,
      title: 'Itinéraires IA\nSur-Mesure',
      subtitle:
          'Notre IA experte conçoit votre voyage complet en quelques secondes selon vos goûts, votre rythme et votre budget.',
      features: [
        'Plans personnalisés jour par jour',
        'Coordonnées GPS & vrais lieux',
        'Génération ultra-rapide',
      ],
    ),
    _WelcomeSlideData(
      tag: 'CONFORT & TEMPS RÉEL',
      icon: Icons.wb_sunny_rounded,
      title: 'Adaptation Météo &\nSensibilité Thermique',
      subtitle:
          'Vos étapes s\'ajustent automatiquement selon les prévisions météo et votre profil thermique (frileux ou sensible à la chaleur).',
      features: [
        'Météo locale en direct sur 16 jours',
        'Conseils vestimentaires d\'initiés',
        'Lieux abrités ou climatisés adaptés',
      ],
    ),
    _WelcomeSlideData(
      tag: 'GAMIFICATION & XP',
      icon: Icons.emoji_events_rounded,
      title: 'Voyagez, Jouez et\nDébloquez des Badges',
      subtitle:
          'Swipez vos envies, accumulez de l\'XP à chaque découverte, progressez dans les niveaux et partagez vos exploits.',
      features: [
        'Swipe interactif pour choisir vos envies',
        'Points d\'XP & niveaux d\'explorateur',
        'Badges exclusifs à collectionner',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeVideo();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_videoController == null || !_videoController!.value.isInitialized) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _videoController?.pause();
    } else if (state == AppLifecycleState.resumed) {
      _videoController?.play();
    }
  }

  Future<void> _initializeVideo() async {
    try {
      final controller = VideoPlayerController.asset(
        'assets/medias/media_logo_voyago_2.mp4',
      );
      _videoController = controller;
      await controller.initialize();
      controller.setLooping(true);
      controller.setVolume(0.0);
      await controller.play();
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
    WidgetsBinding.instance.removeObserver(this);
    _videoController?.pause();
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _onStart();
    }
  }

  void _onStart() {
    _videoController?.pause();
    // Connecté ou non, la bienvenue mène à l'accueil : il gère le mode invité
    // (bannière de connexion) et l'onboarding est imposé par le routeur.
    context.go('/');
  }

  void _onSkip() {
    _pageController.animateToPage(
      _slides.length - 1,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isLastSlide = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: darkBackground,
      body: Stack(
        children: [
          // 1. Fond Vidéo cinématique en boucle
          Positioned.fill(
            child: _buildVideoBackground(),
          ),

          // 2. Filtre sombre et dégradé pour contraste parfait
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.70),
                    Colors.black.withValues(alpha: 0.45),
                    darkBackground.withValues(alpha: 0.88),
                    darkBackground.withValues(alpha: 0.98),
                  ],
                  stops: const [0.0, 0.35, 0.70, 1.0],
                ),
              ),
            ),
          ),

          // 3. Contenu au premier plan (Header + Carrousel 3 slides + Controls)
          SafeArea(
            child: Column(
              children: [
                // En-tête simplifié sans menus superflus
                _buildHeader(context, user != null, isLastSlide),

                // Carrousel de 3 slides explicatifs
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _slides.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildSlide(_slides[index]);
                    },
                  ),
                ),

                // Indicateurs et Boutons d'action en bas
                _buildBottomControls(isLastSlide, user != null),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fond vidéo fluide avec fallback dégradé
  Widget _buildVideoBackground() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: _isVideoInitialized &&
              _videoController != null &&
              _videoController!.value.isInitialized
          ? SizedBox.expand(
              key: const ValueKey('video_ready'),
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width > 0
                      ? _videoController!.value.size.width
                      : 1080,
                  height: _videoController!.value.size.height > 0
                      ? _videoController!.value.size.height
                      : 1920,
                  child: VideoPlayer(_videoController!),
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

  /// En-tête minimaliste avec logo officiel et action Passer / Connexion
  Widget _buildHeader(BuildContext context, bool isLoggedIn, bool isLastSlide) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo & Titre
          Row(
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
                      child: Icon(Icons.flight_takeoff_rounded, color: primaryCyan, size: 20),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Voyago',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),

          // Action en haut à droite
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isLastSlide)
                TextButton(
                  onPressed: _onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: textMuted,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Passer',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textMuted,
                    ),
                  ),
                ),
              if (!isLoggedIn)
                TextButton(
                  onPressed: () => context.go('/auth'),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryCyan,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    'Connexion',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: primaryCyan,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construction d'un slide du carrousel
  Widget _buildSlide(_WelcomeSlideData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Badge thématique
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
                Icon(data.icon, color: primaryCyan, size: 14),
                const SizedBox(width: 8),
                Text(
                  data.tag,
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

          const SizedBox(height: 24),

          // Icône centrale dans un conteneur verre néon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: cardDark.withValues(alpha: 0.9),
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryCyan.withValues(alpha: 0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryCyan.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(data.icon, color: primaryCyan, size: 40),
            ),
          ),

          const SizedBox(height: 28),

          // Titre principal du slide
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 14),

          // Sous-titre explicatif synthétique
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: const Color(0xFFD1E3DF),
              height: 1.45,
            ),
          ),

          const SizedBox(height: 26),

          // Liste des 3 points clés dans une carte semi-transparente
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: cardDark.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder, width: 1),
            ),
            child: Column(
              children: data.features.map((feat) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: primaryCyan.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.check_rounded, color: primaryCyan, size: 12),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          feat,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }

  /// Contrôles du bas : Indicateurs de page + Bouton Suivant / Commencer
  Widget _buildBottomControls(bool isLastSlide, bool isLoggedIn) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Indicateurs de page (Pills animés)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_slides.length, (index) {
              final isActive = index == _currentPage;
              return GestureDetector(
                onTap: () {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: isActive ? 30 : 8,
                  decoration: BoxDecoration(
                    color: isActive ? primaryCyan : const Color(0xFF3B5450),
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: primaryCyan.withValues(alpha: 0.6),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 20),

          // 2. Bouton d'action principal
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: isLastSlide ? _onStart : _onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryCyan,
                foregroundColor: darkBackground,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                shadowColor: primaryCyan.withValues(alpha: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastSlide
                        ? (isLoggedIn ? 'Accéder à mon espace' : 'Commencer')
                        : 'Suivant',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: darkBackground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLastSlide ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                    size: 20,
                    color: darkBackground,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WelcomeSlideData {
  final String tag;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> features;

  const _WelcomeSlideData({
    required this.tag,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.features,
  });
}
