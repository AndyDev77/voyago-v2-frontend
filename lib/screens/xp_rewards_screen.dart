import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';
import '../theme.dart';

class XpRewardsScreen extends StatefulWidget {
  const XpRewardsScreen({super.key});

  @override
  State<XpRewardsScreen> createState() => _XpRewardsScreenState();
}

class _XpRewardsScreenState extends State<XpRewardsScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _data = {};

  // Default data if API fails
  static const Map<String, dynamic> _defaultData = {
    'actions': [
      {'action': 'generate_trip', 'xp': 20, 'emoji': '✈️', 'label': 'Générer un itinéraire'},
      {'action': 'share_trip', 'xp': 10, 'emoji': '📤', 'label': 'Partager un voyage'},
      {'action': 'daily_login', 'xp': 5, 'emoji': '🔥', 'label': 'Connexion quotidienne'},
      {'action': 'complete_profile', 'xp': 15, 'emoji': '👤', 'label': 'Compléter son profil'},
      {'action': 'first_trip', 'xp': 50, 'emoji': '🎉', 'label': 'Premier voyage'},
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
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.instance.getXpRewards();
      if (mounted) {
        setState(() {
          _data = data.isNotEmpty ? data : _defaultData;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _data = _defaultData;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: VoyagoColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Text('Récompenses XP'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: VoyagoColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [VoyagoColors.primaryDark, VoyagoColors.primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Row(
                      children: [
                        Text('⭐', style: TextStyle(fontSize: 40)),
                        SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Gagnez de l\'XP',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Progressez et débloquez des récompenses exclusives',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Actions section
                  const Text(
                    'Comment gagner de l\'XP',
                    style: TextStyle(
                      color: VoyagoColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildActions(),

                  const SizedBox(height: 28),

                  // Levels section
                  const Text(
                    'Paliers de niveaux',
                    style: TextStyle(
                      color: VoyagoColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._buildLevels(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildActions() {
    final actions = _data['actions'] as List? ?? [];
    if (actions.isEmpty) return [const SizedBox.shrink()];

    return actions.map((a) {
      final action = a as Map<String, dynamic>;
      final xp = action['xp'] as int? ?? 0;
      final emoji = action['emoji']?.toString() ?? '⭐';
      final label = action['label']?.toString() ?? action['action']?.toString() ?? '';

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VoyagoColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: VoyagoColors.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: VoyagoColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: VoyagoColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: VoyagoColors.yellow.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '+$xp XP',
                style: const TextStyle(
                  color: VoyagoColors.yellow,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildLevels() {
    final levels = _data['levels'] as List? ?? [];
    if (levels.isEmpty) return [const SizedBox.shrink()];

    return levels.asMap().entries.map((entry) {
      final i = entry.key;
      final level = entry.value as Map<String, dynamic>;
      final lvl = level['level'] as int? ?? (i + 1);
      final minXp = level['min_xp'] as int? ?? (i * 100);
      final title = level['title']?.toString() ?? 'Niveau $lvl';
      final reward = level['reward']?.toString() ?? '';

      final colors = [
        VoyagoColors.primary,
        VoyagoColors.blue,
        VoyagoColors.yellow,
        VoyagoColors.coral,
        const Color(0xFF9B59B6),
      ];
      final color = colors[i % colors.length];

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: VoyagoColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                '$lvl',
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: VoyagoColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$minXp XP requis',
                    style: const TextStyle(color: VoyagoColors.muted, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (reward.isNotEmpty)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reward,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }
}
