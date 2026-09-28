import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/trip.dart';
import '../providers/community_provider.dart';
import '../theme.dart';
import '../widgets/trip_card.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(communityFeedProvider);

    return Scaffold(
      backgroundColor: VoyagoColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🦜', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('Communauté Voyago'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: () => ref.invalidate(communityFeedProvider),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.refresh(communityFeedProvider.future),
        color: VoyagoColors.primary,
        backgroundColor: VoyagoColors.surface,
        child: feedAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🦜', style: TextStyle(fontSize: 56)),
                      SizedBox(height: 20),
                      Text(
                        'Aucun voyage partagé pour le moment 🦜',
                        style: TextStyle(
                          color: VoyagoColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Soyez le premier explorateur à partager votre aventure avec Voyago !',
                        style: TextStyle(color: VoyagoColors.muted),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return TripCard(
                  trip: item.trip,
                  authorInfo: {
                    'name': item.authorName,
                    'pseudo': item.authorPseudo,
                    'avatar_emoji': item.authorAvatarEmoji,
                    'picture': item.authorPicture,
                    'is_pro': item.authorIsPro,
                  },
                  onTap: () => context.go('/itinerary/${item.trip.id}', extra: item.trip),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: VoyagoColors.primary),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😕', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text(
                    e.toString(),
                    style: const TextStyle(color: VoyagoColors.muted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(communityFeedProvider),
                    child: const Text('Réessayer'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
