import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/partenaire.dart';
import '../providers/reference_data_providers.dart';

class PartenaireSelectScreen extends ConsumerStatefulWidget {
  const PartenaireSelectScreen({super.key});

  @override
  ConsumerState<PartenaireSelectScreen> createState() => _PartenaireSelectScreenState();
}

class _PartenaireSelectScreenState extends ConsumerState<PartenaireSelectScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final partenairesAsync = ref.watch(partenairesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choisissez votre boutique'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher une boutique partenaire...',
                prefixIcon: const Icon(Icons.search, color: AppColors.navy),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: partenairesAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    SizedBox(height: 12),
                    Text('Chargement des boutiques...', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  ],
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.danger),
                      const SizedBox(height: 12),
                      const Text(
                        'Impossible de charger les boutiques',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 16),
                      ),
                      const SizedBox(height: 4),
                      Text(err.toString().replaceAll('ApiException: ', ''), textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(partenairesProvider),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Réessayer'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (partenaires) {
                final filtered = _query.isEmpty
                    ? partenaires
                    : partenaires
                        .where((p) => p.nom.toLowerCase().contains(_query))
                        .toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.storefront_outlined, size: 48, color: Color(0xFF94A3B8)),
                        const SizedBox(height: 12),
                        const Text('Aucune boutique trouvée', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy)),
                        const SizedBox(height: 4),
                        const Text('Rechargez la liste ou modifiez votre recherche.', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(partenairesProvider),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Rafraîchir'),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () async {
                    ref.invalidate(partenairesProvider);
                    await ref.read(partenairesProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    itemBuilder: (context, index) {
                      final Partenaire partenaire = filtered[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.navy,
                          child: Icon(Icons.storefront, color: Colors.white, size: 20),
                        ),
                        title: Text(partenaire.nom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.navy)),
                        subtitle: Text(partenaire.telephone, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                        onTap: () => context.go('/partenaire/home', extra: partenaire),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
