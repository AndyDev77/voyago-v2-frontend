import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/interest.dart';
import '../providers/interests_provider.dart';
import '../services/storage_service.dart';
import '../theme.dart';
import '../widgets/interest_card.dart';

class SwipeScreen extends ConsumerStatefulWidget {
  const SwipeScreen({super.key});

  @override
  ConsumerState<SwipeScreen> createState() => _SwipeScreenState();
}

class _SwipeScreenState extends ConsumerState<SwipeScreen>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  final Set<String> _selectedIds = {};
  double _dragOffset = 0.0;
  bool _isSwiping = false;
  late AnimationController _snapController;
  late Animation<double> _snapAnimation;
  double _swipeStartOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _snapAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _snapController, curve: Curves.easeOut),
    )..addListener(() {
        if (mounted) setState(() => _dragOffset = _snapAnimation.value);
      });
  }

  @override
  void dispose() {
    _snapController.dispose();
    super.dispose();
  }

  void _onDragStart(DragStartDetails details) {
    _swipeStartOffset = _dragOffset;
    _isSwiping = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_isSwiping) return;
    setState(() => _dragOffset += details.delta.dx);
  }

  void _onDragEnd(DragEndDetails details, List<Interest> interests) {
    _isSwiping = false;
    const threshold = 100.0;

    if (_dragOffset > threshold) {
      _swipeRight(interests);
    } else if (_dragOffset < -threshold) {
      _swipeLeft(interests);
    } else {
      // Snap back
      _snapAnimation = Tween<double>(
        begin: _dragOffset,
        end: 0,
      ).animate(CurvedAnimation(parent: _snapController, curve: Curves.elasticOut));
      _snapController.forward(from: 0);
    }
  }

  void _swipeRight(List<Interest> interests) {
    if (_currentIndex >= interests.length) return;
    final interest = interests[_currentIndex];
    setState(() => _selectedIds.add(interest.id));
    _animateOut(positive: true, interests: interests);
  }

  void _swipeLeft(List<Interest> interests) {
    _animateOut(positive: false, interests: interests);
  }

  void _animateOut({required bool positive, required List<Interest> interests}) {
    final targetOffset = positive ? 500.0 : -500.0;
    _snapAnimation = Tween<double>(
      begin: _dragOffset,
      end: targetOffset,
    ).animate(CurvedAnimation(parent: _snapController, curve: Curves.easeIn));

    _snapController.forward(from: 0).then((_) {
      if (mounted) {
        setState(() {
          _currentIndex++;
          _dragOffset = 0;
        });
      }
    });
  }

  Future<void> _continue(List<Interest> interests) async {
    await StorageService.instance.setSelectedInterests(_selectedIds.toList());
    if (mounted) {
      context.go('/configure', extra: _selectedIds.toList());
    }
  }

  @override
  Widget build(BuildContext context) {
    final interestsAsync = ref.watch(interestsProvider);

    return Scaffold(
      backgroundColor: VoyagoColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Vos intérêts'),
      ),
      body: interestsAsync.when(
        data: (interests) => _buildSwiper(interests),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: VoyagoColors.primary),
              SizedBox(height: 16),
              Text(
                'Chargement des intérêts...',
                style: TextStyle(color: VoyagoColors.muted),
              ),
            ],
          ),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                'Impossible de charger les intérêts',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                e.toString(),
                style: const TextStyle(color: VoyagoColors.muted, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(interestsProvider),
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwiper(List<Interest> interests) {
    final isDone = _currentIndex >= interests.length;

    return Column(
      children: [
        // Progress bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isDone
                        ? 'Terminé !'
                        : '${_currentIndex + 1} / ${interests.length}',
                    style: const TextStyle(
                      color: VoyagoColors.muted,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      const Text('✓', style: TextStyle(color: VoyagoColors.primary)),
                      const SizedBox(width: 4),
                      Text(
                        '${_selectedIds.length} sélectionné(s)',
                        style: const TextStyle(
                          color: VoyagoColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: interests.isEmpty
                      ? 0
                      : _currentIndex / interests.length,
                  minHeight: 6,
                  backgroundColor: VoyagoColors.cardBorder,
                  valueColor: const AlwaysStoppedAnimation(VoyagoColors.primary),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Swipe hint
        if (!isDone)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.arrow_back, color: VoyagoColors.coral, size: 16),
                SizedBox(width: 4),
                Text(
                  'Passer',
                  style: TextStyle(color: VoyagoColors.coral, fontSize: 12),
                ),
                SizedBox(width: 24),
                Text(
                  'J\'aime',
                  style: TextStyle(color: VoyagoColors.primary, fontSize: 12),
                ),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward, color: VoyagoColors.primary, size: 16),
              ],
            ),
          ),

        // Card stack
        Expanded(
          child: Center(
            child: isDone ? _buildDoneCard() : _buildCardStack(interests),
          ),
        ),

        // Bottom buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            children: [
              if (!isDone)
                Row(
                  children: [
                    // Skip button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _swipeLeft(interests),
                        icon: const Icon(Icons.close, color: VoyagoColors.coral),
                        label: const Text(
                          'Passer',
                          style: TextStyle(color: VoyagoColors.coral),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: VoyagoColors.coral),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Like button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _swipeRight(interests),
                        icon: const Icon(Icons.check),
                        label: const Text('J\'aime'),
                      ),
                    ),
                  ],
                ),
              if (!isDone) const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedIds.isEmpty ? null : () => _continue(interests),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedIds.isEmpty
                        ? VoyagoColors.cardBorder
                        : VoyagoColors.primary,
                  ),
                  child: Text(
                    _selectedIds.isEmpty
                        ? 'Sélectionnez au moins 1 intérêt'
                        : 'Continuer (${_selectedIds.length} sélectionné${_selectedIds.length > 1 ? 's' : ''})',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardStack(List<Interest> interests) {
    final remaining = interests.length - _currentIndex;
    final showCards = remaining.clamp(0, 3);

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      height: 420,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background cards (behind)
          for (int i = showCards - 1; i >= 1; i--)
            if (_currentIndex + i < interests.length)
              Positioned(
                top: (i * 8).toDouble(),
                child: Transform.scale(
                  scale: 1.0 - (i * 0.04),
                  child: Opacity(
                    opacity: 1.0 - (i * 0.2),
                    child: InterestCard(
                      interest: interests[_currentIndex + i],
                      dragOffset: 0,
                      isTop: false,
                    ),
                  ),
                ),
              ),

          // Top card (draggable)
          Positioned(
            child: GestureDetector(
              onHorizontalDragStart: _onDragStart,
              onHorizontalDragUpdate: _onDragUpdate,
              onHorizontalDragEnd: (d) => _onDragEnd(d, interests),
              child: Transform.translate(
                offset: Offset(_dragOffset, 0),
                child: InterestCard(
                  interest: interests[_currentIndex],
                  dragOffset: _dragOffset,
                  isTop: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDoneCard() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: VoyagoColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: VoyagoColors.primary.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 20),
          const Text(
            'Super !',
            style: TextStyle(
              color: VoyagoColors.text,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Vous avez sélectionné ${_selectedIds.length} intérêt${_selectedIds.length > 1 ? 's' : ''}',
            style: const TextStyle(color: VoyagoColors.muted, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
