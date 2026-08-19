import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../models/partenaire.dart';
import '../../../models/produit.dart';
import '../providers/partenaire_stock_providers.dart';

class StockStatsTab extends ConsumerWidget {
  final Partenaire partenaire;
  const StockStatsTab({super.key, required this.partenaire});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(stockStatsProvider(partenaire.id));

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text(err.toString())),
      data: (stats) {
        if (stats.isEmpty) {
          return const Center(child: Text('Aucun produit pour cette boutique'));
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(stockStatsProvider(partenaire.id)),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stats.length,
            itemBuilder: (context, index) => _StatCard(stat: stats[index]),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final ProduitStockStats stat;
  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(stat.nom, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 12),
            Row(
              children: [
                _Metric(label: 'Restants', value: stat.restants, color: AppColors.success),
                _Metric(
                    label: 'Sortis', value: stat.sortisPourLivraison, color: const Color(0xFF3B82F6)),
                _Metric(label: 'Retournés', value: stat.retournes, color: AppColors.warning),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _Metric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text('$value',
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
