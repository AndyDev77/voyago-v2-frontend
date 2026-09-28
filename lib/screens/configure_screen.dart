import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../api/api.dart';
import '../core/utils/form_validators.dart';
import '../providers/auth_provider.dart';
import '../providers/trips_provider.dart';
import '../theme.dart';

class ConfigureScreen extends ConsumerStatefulWidget {
  final List<String> selectedInterests;

  const ConfigureScreen({super.key, required this.selectedInterests});

  @override
  ConsumerState<ConfigureScreen> createState() => _ConfigureScreenState();
}

class _ConfigureScreenState extends ConsumerState<ConfigureScreen> {
  final _destinationCtrl = TextEditingController();
  double _durationDays = 5;
  String _pace = 'equilibre';
  final Set<String> _transports = {'marche'};
  String _budget = 'moyen';
  bool _isGenerating = false;
  String? _error;

  static const _paces = [
    ('tranquille', 'Tranquille', '🚶'),
    ('equilibre', 'Équilibré', '🚴'),
    ('intensif', 'Intensif', '🏃'),
  ];

  static const _transportOptions = [
    ('marche', 'Marche', '🚶'),
    ('velo', 'Vélo', '🚲'),
    ('transport', 'Transport', '🚌'),
    ('voiture', 'Voiture', '🚗'),
    ('bateau', 'Bateau', '⛵'),
  ];

  static const _budgets = [
    ('economique', 'Économique', '💰'),
    ('moyen', 'Moyen', '💳'),
    ('luxe', 'Luxe', '💎'),
  ];

  @override
  void dispose() {
    _destinationCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final destError = FormValidators.validateDestination(_destinationCtrl.text);
    if (destError != null) {
      setState(() => _error = destError);
      return;
    }
    if (_transports.isEmpty) {
      setState(() => _error = 'Veuillez sélectionner au moins un moyen de transport');
      return;
    }

    setState(() {
      _isGenerating = true;
      _error = null;
    });

    try {
      final authState = ref.read(authProvider);
      final userId = authState.user?.userId;

      final trip = await ref.read(tripGeneratorProvider.notifier).generate(
        destination: _destinationCtrl.text.trim(),
        durationDays: _durationDays.round(),
        pace: _pace,
        budget: _budget,
        transports: _transports.toList(),
        interests: widget.selectedInterests,
        userId: userId,
      );

      if (mounted) {
        context.go('/itinerary/${trip.id}', extra: trip);
      }
    } on ApiException catch (e) {
      if (e.statusCode == 402) {
        if (mounted) context.go('/pricing');
        return;
      }
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Erreur lors de la génération: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoyagoColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/swipe'),
        ),
        title: const Text('Configurez votre voyage'),
      ),
      body: _isGenerating ? _buildLoading() : _buildForm(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('🦜', style: TextStyle(fontSize: 64)),
          SizedBox(height: 24),
          CircularProgressIndicator(color: VoyagoColors.primary),
          SizedBox(height: 20),
          Text(
            'Voyago prépare votre voyage ! 🦜',
            style: TextStyle(
              color: VoyagoColors.text,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Notre mascotte et l\'IA créent votre itinéraire personnalisé...',
            style: TextStyle(color: VoyagoColors.muted, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.selectedInterests.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '${widget.selectedInterests.length} intérêt${widget.selectedInterests.length > 1 ? 's' : ''} sélectionné${widget.selectedInterests.length > 1 ? 's' : ''}',
                style: const TextStyle(
                  color: VoyagoColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          if (_error != null) ...[
            _ErrorBox(message: _error!),
            const SizedBox(height: 16),
          ],

          // Destination
          _SectionTitle(title: '📍 Destination'),
          const SizedBox(height: 12),
          TextField(
            controller: _destinationCtrl,
            decoration: const InputDecoration(
              hintText: 'Ex: Paris, Tokyo, New York...',
              prefixIcon: Icon(Icons.location_on_outlined, color: VoyagoColors.muted),
            ),
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 28),

          // Duration
          _SectionTitle(title: '📅 Durée du voyage'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '1 jour',
                style: TextStyle(color: VoyagoColors.muted, fontSize: 12),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: VoyagoColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_durationDays.round()} jour${_durationDays.round() > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: VoyagoColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const Text(
                '30 jours',
                style: TextStyle(color: VoyagoColors.muted, fontSize: 12),
              ),
            ],
          ),
          Slider(
            value: _durationDays,
            min: 1,
            max: 30,
            divisions: 29,
            label: '${_durationDays.round()} j',
            onChanged: (v) => setState(() => _durationDays = v),
          ),
          const SizedBox(height: 28),

          // Pace
          _SectionTitle(title: '⚡ Rythme'),
          const SizedBox(height: 12),
          Row(
            children: _paces.map((p) {
              final (id, label, emoji) = p;
              final isSelected = _pace == id;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _pace = id),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? VoyagoColors.primary.withOpacity(0.15)
                          : VoyagoColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? VoyagoColors.primary
                            : VoyagoColors.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? VoyagoColors.primary
                                : VoyagoColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Transports
          _SectionTitle(title: '🚌 Transports'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _transportOptions.map((t) {
              final (id, label, emoji) = t;
              final isSelected = _transports.contains(id);
              return FilterChip(
                label: Text('$emoji $label'),
                selected: isSelected,
                onSelected: (v) {
                  setState(() {
                    if (v) {
                      _transports.add(id);
                    } else {
                      _transports.remove(id);
                    }
                  });
                },
                selectedColor: VoyagoColors.primary.withOpacity(0.2),
                checkmarkColor: VoyagoColors.primary,
                backgroundColor: VoyagoColors.surface,
                side: BorderSide(
                  color: isSelected ? VoyagoColors.primary : VoyagoColors.cardBorder,
                  width: isSelected ? 2 : 1,
                ),
                labelStyle: TextStyle(
                  color: isSelected ? VoyagoColors.primary : VoyagoColors.muted,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Budget
          _SectionTitle(title: '💰 Budget'),
          const SizedBox(height: 12),
          Row(
            children: _budgets.map((b) {
              final (id, label, emoji) = b;
              final isSelected = _budget == id;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _budget = id),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? VoyagoColors.primary.withOpacity(0.15)
                          : VoyagoColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? VoyagoColors.primary
                            : VoyagoColors.cardBorder,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 22)),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            color: isSelected
                                ? VoyagoColors.primary
                                : VoyagoColors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generate,
              icon: const Text('🗺', style: TextStyle(fontSize: 18)),
              label: const Text(
                'Générer mon itinéraire',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: VoyagoColors.text,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: VoyagoColors.coral.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: VoyagoColors.coral.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: VoyagoColors.coral, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: VoyagoColors.coral, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
