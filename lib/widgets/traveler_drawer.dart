import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/trip.dart';
import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/trips_provider.dart';
import '../theme.dart';

class TravelerDrawer extends ConsumerWidget {
  final String? currentTripId;
  final ValueChanged<Trip>? onTripSelected;

  const TravelerDrawer({
    super.key,
    this.currentTripId,
    this.onTripSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final profileAsync = user != null ? ref.watch(profileProvider(user.userId)) : null;
    final tripsAsync = user != null ? ref.watch(tripsProvider(user.userId)) : null;

    return Drawer(
      backgroundColor: VoyagoColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header / Brand
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: VoyagoColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: VoyagoColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.travel_explore,
                      color: VoyagoColors.primary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Voyago',
                          style: TextStyle(
                            color: VoyagoColors.text,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'TABLEAU DE BORD',
                          style: TextStyle(
                            color: VoyagoColors.muted.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: VoyagoColors.muted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(color: VoyagoColors.cardBorder, height: 1),

            // User Info Banner
            if (user != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: VoyagoColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VoyagoColors.cardBorder),
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: VoyagoColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            user.avatarDisplay,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                        Positioned(
                          right: -2,
                          bottom: -2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: VoyagoColors.primary,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: VoyagoColors.surface, width: 1.5),
                            ),
                            child: Text(
                              profileAsync?.valueOrNull != null
                                  ? 'Niv ${profileAsync!.valueOrNull!.level}'
                                  : 'Lvl 1',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name,
                            style: const TextStyle(
                              color: VoyagoColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            profileAsync?.valueOrNull != null
                                ? '${profileAsync!.valueOrNull!.xp} XP · ${profileAsync.valueOrNull!.streak}j streak'
                                : 'Explorateur',
                            style: const TextStyle(
                              color: VoyagoColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Navigation Links
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                children: [
                  _NavTile(
                    icon: Icons.home_outlined,
                    label: 'Accueil',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/');
                    },
                  ),
                  _NavTile(
                    icon: Icons.map_outlined,
                    label: 'Carte & Itinéraire',
                    isActive: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  _NavTile(
                    icon: Icons.add_location_alt_outlined,
                    label: 'Créer un voyage',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/swipe');
                    },
                  ),
                  _NavTile(
                    icon: Icons.stars_outlined,
                    label: 'Récompenses & Niveaux',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/xp-rewards');
                    },
                  ),
                  _NavTile(
                    icon: Icons.public_outlined,
                    label: 'Communauté',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/community');
                    },
                  ),
                  _NavTile(
                    icon: Icons.workspace_premium_outlined,
                    label: 'Voyago Pro',
                    badge: 'PRO',
                    onTap: () {
                      Navigator.of(context).pop();
                      context.go('/pricing');
                    },
                  ),

                  const SizedBox(height: 16),
                  const Divider(color: VoyagoColors.cardBorder, height: 1),
                  const SizedBox(height: 12),

                  // "My Trips" section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'MES VOYAGES',
                          style: TextStyle(
                            color: VoyagoColors.muted.withValues(alpha: 0.8),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go('/swipe');
                          },
                          child: const Icon(
                            Icons.add,
                            color: VoyagoColors.primary,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (tripsAsync != null)
                    tripsAsync.when(
                      data: (trips) {
                        if (trips.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              'Aucun voyage généré pour le moment',
                              style: TextStyle(
                                color: VoyagoColors.muted.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return Column(
                          children: trips.map((trip) {
                            final isCurrent = trip.id == currentTripId;
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 2),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? VoyagoColors.primary.withValues(alpha: 0.12)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: isCurrent
                                    ? Border.all(color: VoyagoColors.primary.withValues(alpha: 0.3))
                                    : null,
                              ),
                              child: ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                leading: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isCurrent ? VoyagoColors.green : VoyagoColors.muted.withValues(alpha: 0.4),
                                    boxShadow: isCurrent
                                        ? [
                                            BoxShadow(
                                              color: VoyagoColors.green.withValues(alpha: 0.5),
                                              blurRadius: 6,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                                title: Text(
                                  trip.destination,
                                  style: TextStyle(
                                    color: isCurrent ? VoyagoColors.primary : VoyagoColors.text,
                                    fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                                    fontSize: 13,
                                  ),
                                ),
                                trailing: Text(
                                  '${trip.durationDays}j',
                                  style: const TextStyle(
                                    color: VoyagoColors.muted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).pop();
                                  if (onTripSelected != null) {
                                    onTripSelected!(trip);
                                  } else {
                                    context.go('/itinerary/${trip.id}', extra: trip);
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        );
                      },
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Connectez-vous pour voir vos voyages',
                        style: TextStyle(
                          color: VoyagoColors.muted.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Footer
            const Divider(color: VoyagoColors.cardBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _NavTile(
                icon: Icons.settings_outlined,
                label: 'Profil & Paramètres',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go('/profile');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final String? badge;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? VoyagoColors.primary.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          color: isActive ? VoyagoColors.primary : VoyagoColors.muted,
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? VoyagoColors.primary : VoyagoColors.text,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: VoyagoColors.yellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: VoyagoColors.yellow,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : null,
        onTap: onTap,
      ),
    );
  }
}
