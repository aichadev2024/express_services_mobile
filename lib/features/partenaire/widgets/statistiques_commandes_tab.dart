import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/commande.dart';
import '../../../models/partenaire.dart';
import '../../../models/statut_commande.dart';
import '../../commandes/providers/commande_providers.dart';

class StatistiquesCommandesTab extends ConsumerStatefulWidget {
  final Partenaire partenaire;
  const StatistiquesCommandesTab({super.key, required this.partenaire});

  @override
  ConsumerState<StatistiquesCommandesTab> createState() => _StatistiquesCommandesTabState();
}

class _StatistiquesCommandesTabState extends ConsumerState<StatistiquesCommandesTab> {
  List<Commande>? _commandes;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref.read(commandeRepositoryProvider).suivre(widget.partenaire.telephone);
      if (mounted) setState(() => _commandes = results);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppColors.danger)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchStats, child: const Text('Réessayer'))
          ],
        ),
      );
    }
    if (_commandes == null) return const SizedBox.shrink();

    final total = _commandes!.length;
    if (total == 0) {
      return const Center(child: Text('Aucune commande enregistrée pour le moment.'));
    }

    final livrees = _commandes!.where((c) => c.statut == StatutCommande.livree).length;
    
    // Considérons les retours comme rejets
    final retours = _commandes!.where((c) => c.statut == StatutCommande.rejetee).length;
    
    // Echouées : annulées ou injoignables
    final echouees = _commandes!.where((c) => 
      c.statut == StatutCommande.annulee || 
      c.statut == StatutCommande.injoignable
    ).length;

    // En cours / en attente
    final enAttente = _commandes!.where((c) => 
      c.statut == StatutCommande.enAttente || 
      c.statut == StatutCommande.enCours || 
      c.statut == StatutCommande.reportee
    ).length;

    // Motifs d'échec / rejets (Stats détaillées)
    final Map<String, int> motifs = {};
    for (var c in _commandes!) {
      if (c.statut == StatutCommande.annulee || c.statut == StatutCommande.injoignable || c.statut == StatutCommande.rejetee) {
        final reason = (c.motifAnnulation != null && c.motifAnnulation!.trim().isNotEmpty)
            ? c.motifAnnulation!.trim()
            : (c.statut == StatutCommande.injoignable ? 'Client injoignable' : 'Autre raison non spécifiée');
        
        motifs[reason] = (motifs[reason] ?? 0) + 1;
      }
    }
    var sortedMotifs = motifs.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      onRefresh: _fetchStats,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Aperçu Global', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatCard('Total\nCommandes', total.toString(), Colors.blueAccent),
              const SizedBox(width: 10),
              _buildStatCard('En cours / Report', enAttente.toString(), Colors.orange),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Performance de Livraison', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 12),
          
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPercentageRow('Livrées', livrees, total, AppColors.success),
                  const Divider(height: 24),
                  _buildPercentageRow('Échouées', echouees, total, AppColors.danger),
                  const Divider(height: 24),
                  _buildPercentageRow('Retours (Rejet)', retours, total, Colors.purple),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          const Text('Analyse des Échecs & Retours', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.navy)),
          const SizedBox(height: 4),
          const Text('Les motifs principaux affectant la logistique e-commerce', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 12),
          
          if (sortedMotifs.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                children: [
                  Icon(Icons.thumb_up, color: AppColors.success),
                  SizedBox(width: 8),
                  Expanded(child: Text("Félicitations, vous n'avez enregistré aucun échec ou retour de marchandise !")),
                ],
              ),
            )
          else
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              elevation: 0,
              child: Column(
                children: sortedMotifs.map((entry) {
                  final totalEchecs = echouees + retours;
                  final pct = (entry.value / totalEchecs * 100).toStringAsFixed(1);
                  return ListTile(
                    leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                    title: Text(entry.key, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('$pct%', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                    ),
                    subtitle: Text('${entry.value} commande(s)', style: const TextStyle(fontSize: 11)),
                  );
                }).toList(),
              ),
            ),
          
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.8))),
          ],
        ),
      ),
    );
  }

  Widget _buildPercentageRow(String label, int count, int total, Color color) {
    final double pct = total > 0 ? (count / total * 100) : 0;
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        Text('${pct.toStringAsFixed(1)} %', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
        const SizedBox(width: 8),
        Text('($count)', style: const TextStyle(color: Color(0xFF64748B), fontSize: 11)),
      ],
    );
  }
}
