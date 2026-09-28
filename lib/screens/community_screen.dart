import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/trip.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/trip_card.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _feed = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final feed = await ApiService.instance.getCommunityFeed();
      if (mounted) setState(() => _feed = feed);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = 'Erreur de chargement');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: const Text('Communauté'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_outlined),
            onPressed: _loadFeed,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        color: VoyagoColors.primary,
        backgroundColor: VoyagoColors.surface,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: VoyagoColors.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('😕', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: VoyagoColors.muted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadFeed,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_feed.isEmpty) {
      return const Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 32),
      itemCount: _feed.length,
      itemBuilder: (context, index) {
        final item = _feed[index];
        final tripData = item['trip'] as Map<String, dynamic>?;
        final authorData = item['author'] as Map<String, dynamic>?;

        if (tripData == null) return const SizedBox.shrink();

        final trip = Trip.fromJson(tripData);

        return TripCard(
          trip: trip,
          authorInfo: authorData,
          onTap: () => context.go('/itinerary/${trip.id}', extra: trip),
        );
      },
    );
  }
}
