import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:confetti/confetti.dart';
import '../models/auth_user.dart';
import '../providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late ConfettiController _confettiController;
  int _currentStep = 1; // 1: Info personnelle, 2: Profil thermique
  final int _totalSteps = 2;

  // Step 1 state
  DateTime? _selectedBirthDate;
  UserGender _selectedGender = UserGender.preferNotToSay;
  String? _birthDateError;

  // Step 2 state (HTML template)
  ThermalSensitivity _selectedThermal = ThermalSensitivity.balanced;
  bool _isSaving = false;

  // Design constants from HTML
  static const Color _bgDark = Color(0xFF10221F);
  static const Color _surfaceDark = Color(0xFF1A2C29);
  static const Color _borderDark = Color(0xFF283936);
  static const Color _primary = Color(0xFF0DF2CC);
  static const Color _textMuted = Color(0xFF9CBAB5);

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));

    // Prepopulate from current user if already partially filled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider);
      if (user != null) {
        if (user.dateOfBirth != null && user.dateOfBirth!.isNotEmpty) {
          try {
            _selectedBirthDate = DateTime.tryParse(user.dateOfBirth!);
          } catch (_) {}
        }
        if (user.gender != UserGender.preferNotToSay) {
          _selectedGender = user.gender;
        }
        _selectedThermal = user.thermalSensitivity;
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initialDate = _selectedBirthDate ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 12, now.month, now.day),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _primary,
              onPrimary: Color(0xFF10221F),
              surface: _surfaceDark,
              onSurface: Colors.white,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: _bgDark),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedBirthDate = picked;
        _birthDateError = null;
      });
    }
  }

  void _validateAndGoNext() {
    if (_selectedBirthDate == null) {
      setState(() {
        _birthDateError = 'Veuillez sélectionner votre date de naissance';
      });
      return;
    }

    setState(() {
      _birthDateError = null;
      _currentStep = 2;
    });
  }

  Future<void> _saveAndFinish() async {
    if (_selectedBirthDate == null) {
      setState(() {
        _currentStep = 1;
        _birthDateError = 'Date de naissance requise';
      });
      return;
    }

    setState(() => _isSaving = true);

    try {
      final formattedDob = DateFormat('yyyy-MM-dd').format(_selectedBirthDate!);

      await ref.read(authProvider.notifier).completeOnboarding(
        dateOfBirth: formattedDob,
        gender: _selectedGender,
        thermalSensitivity: _selectedThermal,
      );

      // Trigger celebratory confetti!
      _confettiController.play();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: _surfaceDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: _primary, width: 1.5),
            ),
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: _primary, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Profil configuré avec succès ! Vos itinéraires s\'adaptent à votre météo idéale.',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Allow confetti burst to be seen
        await Future.delayed(const Duration(milliseconds: 1400));
        if (mounted) {
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade900,
            content: Text('Erreur lors de l\'enregistrement: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Interdire tout retour arrière : Onboarding 100% obligatoire
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: _bgDark,
        body: Stack(
          children: [
            // Fond dégradé subtil thermique issu du template HTML
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0x1A3B82F6), // blue tint
                      Color(0x0E0DF2CC), // primary teal tint
                      Color(0x1AF97316), // orange tint
                    ],
                  ),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 820),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildProgressSection(),
                              const SizedBox(height: 24),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                transitionBuilder: (child, animation) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0.04, 0),
                                        end: Offset.zero,
                                      ).animate(animation),
                                      child: child,
                                    ),
                                  );
                                },
                                child: _currentStep == 1
                                    ? _buildPersonalInfoStep()
                                    : _buildThermalSensitivityStep(),
                              ),
                              const SizedBox(height: 36),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Confetti Cannon Overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  _primary,
                  Color(0xFF3B82F6),
                  Color(0xFFF97316),
                  Colors.amber,
                  Colors.white,
                  Color(0xFFE040FB),
                ],
                numberOfParticles: 45,
                gravity: 0.25,
                emissionFrequency: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Top Navigation Header ---
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: _bgDark,
        border: Border(bottom: BorderSide(color: _borderDark, width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.asset(
                  'assets/logo/logo.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.travel_explore,
                    color: _primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Smart Travel Companion',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          // Badge "Étape requise"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: _primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _primary.withValues(alpha: 0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_clock, size: 14, color: _primary),
                SizedBox(width: 5),
                Text(
                  'Étape obligatoire',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Progress Section matching HTML ---
  Widget _buildProgressSection() {
    final percent = _currentStep / _totalSteps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _currentStep == 1
                  ? 'Profil Voyageur'
                  : 'Profiling Complete',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Step $_currentStep of $_totalSteps',
              style: const TextStyle(
                color: _textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 8,
            color: const Color(0xFF3B5450),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                      width: constraints.maxWidth * percent,
                      decoration: BoxDecoration(
                        color: _primary,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            _currentStep == 1 ? 'Étape 1 sur 2' : 'Final Step',
            style: const TextStyle(
              color: _textMuted,
              fontSize: 12,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 1: Personal Profile (DOB & Gender) ---
  Widget _buildPersonalInfoStep() {
    final dobFormatted = _selectedBirthDate != null
        ? DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedBirthDate!)
        : 'Sélectionner votre date de naissance';

    final age = _selectedBirthDate != null
        ? DateTime.now().year - _selectedBirthDate!.year
        : null;

    return Column(
      key: const ValueKey('step_1'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Informations de Voyage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ces données permettent à l\'intelligence artificielle d\'ajuster le tempo de marche et les activités suggérées.',
          style: TextStyle(
            color: _textMuted,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        // Date de naissance Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _birthDateError != null ? Colors.redAccent : _borderDark,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.cake, color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Date de naissance *',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (age != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$age ans',
                        style: const TextStyle(
                          color: _primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: _bgDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedBirthDate != null ? _primary.withValues(alpha: 0.4) : _borderDark,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        color: _selectedBirthDate != null ? _primary : _textMuted,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          dobFormatted,
                          style: TextStyle(
                            color: _selectedBirthDate != null ? Colors.white : _textMuted,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down, color: _primary),
                    ],
                  ),
                ),
              ),
              if (_birthDateError != null) ...[
                const SizedBox(height: 8),
                Text(
                  _birthDateError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Genre / Identité Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _surfaceDark,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _borderDark, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.person, color: _primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Genre / Profil',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: UserGender.values.map((gender) {
                  final isSelected = _selectedGender == gender;
                  return InkWell(
                    onTap: () => setState(() => _selectedGender = gender),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? _primary.withValues(alpha: 0.15) : _bgDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? _primary : _borderDark,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _genderIcon(gender),
                            size: 18,
                            color: isSelected ? _primary : _textMuted,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            gender.label,
                            style: TextStyle(
                              color: isSelected ? Colors.white : _textMuted,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Bouton Continuer vers l'étape suivante
        Center(
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _validateAndGoNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: const Color(0xFF111817),
                elevation: 6,
                shadowColor: _primary.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CONTINUER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Step 2: Thermal Sensitivity Profile (Exact HTML layout & styling) ---
  Widget _buildThermalSensitivityStep() {
    return Column(
      key: const ValueKey('step_2'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        const Text(
          'Thermal Sensitivity Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'We\'ll adapt your AI clothing advice based on how you feel the temperature.',
          style: TextStyle(
            color: _textMuted,
            fontSize: 15,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Grid / Column of 3 cards (Responsive / mobile-friendly)
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 680;
            if (isWide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildThermalCard(ThermalSensitivity.cold)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildThermalCard(ThermalSensitivity.balanced)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildThermalCard(ThermalSensitivity.warm)),
                ],
              );
            }
            return Column(
              children: [
                _buildThermalCard(ThermalSensitivity.cold),
                const SizedBox(height: 16),
                _buildThermalCard(ThermalSensitivity.balanced),
                const SizedBox(height: 16),
                _buildThermalCard(ThermalSensitivity.warm),
              ],
            );
          },
        ),

        const SizedBox(height: 32),

        // Action Buttons Row (Retour + Save & Continue)
        Row(
          children: [
            // Bouton précédent
            IconButton(
              onPressed: () => setState(() => _currentStep = 1),
              icon: const Icon(Icons.arrow_back, color: _primary),
              style: IconButton.styleFrom(
                backgroundColor: _surfaceDark,
                padding: const EdgeInsets.all(14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: _borderDark),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Save & Continue Button
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAndFinish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: const Color(0xFF111817),
                    disabledBackgroundColor: _primary.withValues(alpha: 0.5),
                    elevation: 8,
                    shadowColor: _primary.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF111817)),
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'SAVE & CONTINUE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward, size: 20),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Thermal Card Component matching HTML template ---
  Widget _buildThermalCard(ThermalSensitivity item) {
    final isSelected = _selectedThermal == item;

    final Color accentColor;
    final Gradient bannerGradient;
    final IconData iconData;
    final String title;
    final String desc;
    final String emojiIcon;

    switch (item) {
      case ThermalSensitivity.cold:
        accentColor = const Color(0xFF3B82F6);
        bannerGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x331E3A8A), Color(0x1A1E40AF)],
        );
        iconData = Icons.ac_unit;
        title = 'Runs Cold';
        desc = 'You get cold easily and prefer extra layers.';
        emojiIcon = '❄️';
        break;
      case ThermalSensitivity.balanced:
        accentColor = _primary;
        bannerGradient = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary.withValues(alpha: 0.25), _primary.withValues(alpha: 0.08)],
        );
        iconData = Icons.checkroom;
        title = 'Balanced';
        desc = 'You are comfortable in most standard conditions.';
        emojiIcon = '🧥';
        break;
      case ThermalSensitivity.warm:
        accentColor = const Color(0xFFF97316);
        bannerGradient = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x337C2D12), Color(0x1A9A3412)],
        );
        iconData = Icons.wb_sunny;
        title = 'Runs Warm';
        desc = 'You overheat easily and prefer lighter clothing.';
        emojiIcon = '☀️';
        break;
    }

    return InkWell(
      onTap: () => setState(() => _selectedThermal = item),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? _primary.withValues(alpha: 0.08) : _surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? _primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Visual Banner with glowing accent circle & icon
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Container(
                height: 120,
                decoration: BoxDecoration(gradient: bannerGradient),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow blur circle top right
                    Positioned(
                      top: -15,
                      right: -15,
                      child: Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentColor.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(iconData, size: 44, color: accentColor),
                        const SizedBox(height: 6),
                        Text(
                          emojiIcon,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title & Checkmark Circle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? _primary : Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? _primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? _primary : const Color(0xFF3B5450),
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check,
                          color: Color(0xFF111817),
                          size: 16,
                          weight: 800,
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Description
            Text(
              desc,
              style: const TextStyle(
                color: _textMuted,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _genderIcon(UserGender gender) {
    switch (gender) {
      case UserGender.male:
        return Icons.male;
      case UserGender.female:
        return Icons.female;
      case UserGender.other:
        return Icons.transgender;
      case UserGender.preferNotToSay:
        return Icons.security;
    }
  }
}
