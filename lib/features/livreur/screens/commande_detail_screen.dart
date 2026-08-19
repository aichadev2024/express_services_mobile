import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/commande.dart';
import '../../../models/statut_commande.dart';
import '../../commandes/providers/commande_providers.dart';
import '../providers/livreur_providers.dart';

class CommandeDetailScreen extends ConsumerStatefulWidget {
  final int commandeId;
  const CommandeDetailScreen({super.key, required this.commandeId});

  @override
  ConsumerState<CommandeDetailScreen> createState() => _CommandeDetailScreenState();
}

class _CommandeDetailScreenState extends ConsumerState<CommandeDetailScreen> {
  bool _updating = false;

  Future<void> _changerStatut(StatutCommande statut) async {
    String? motif;

    // Prompt for cancellation / issue reason if status is ANNULEE, REJETEE or INJOIGNABLE
    if (statut == StatutCommande.annulee || statut == StatutCommande.rejetee || statut == StatutCommande.injoignable) {
      motif = await _showMotifDialog(statut);
      if (motif == null) return; // User cancelled the modal
    }

    setState(() => _updating = true);
    try {
      await ref.read(commandeRepositoryProvider).changerStatut(widget.commandeId, statut.value, motif: motif);
      ref.invalidate(commandeDetailProvider(widget.commandeId));
      ref.invalidate(livreurCommandesProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Statut mis à jour : ${statut.label}')),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<String?> _showMotifDialog(StatutCommande statut) async {
    final customCtrl = TextEditingController();
    String selectedPreset = 'Client a demandé l\'annulation';
    final presets = [
      'Client a demandé l\'annulation',
      'Client injoignable par téléphone',
      'Adresse ou quartier introuvable',
      'Colis ou produit refusé',
      'Autre motif'
    ];

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(
                'Motif pour "${statut.label}"',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.navy),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Veuillez indiquer la raison de cette modification afin d\'en informer l\'administration :',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 14),
                    ...presets.map((preset) => RadioListTile<String>(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(preset, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          value: preset,
                          groupValue: selectedPreset,
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedPreset = val);
                          },
                        )),
                    if (selectedPreset == 'Autre motif') ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: customCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Précisez la raison...',
                          hintStyle: const TextStyle(fontSize: 12),
                          contentPadding: const EdgeInsets.all(10),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    final result = selectedPreset == 'Autre motif'
                        ? customCtrl.text.trim()
                        : selectedPreset;
                    if (result.isEmpty) return;
                    Navigator.pop(ctx, result);
                  },
                  child: const Text('Valider', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openWhatsApp() async {
    try {
      final link = await ref.read(commandeRepositoryProvider).getWhatsAppLink(widget.commandeId);
      final uri = Uri.parse(link);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Impossible d'ouvrir WhatsApp")));
      }
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final commandeAsync = ref.watch(commandeDetailProvider(widget.commandeId));

    return Scaffold(
      appBar: AppBar(title: Text('Commande #${widget.commandeId}')),
      body: commandeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
        data: (commande) => _buildBody(commande),
      ),
    );
  }

  Widget _buildBody(Commande commande) {
    final statutColor = AppTheme.statutColor(commande.statut.value);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: statutColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 10, color: statutColor),
              const SizedBox(width: 8),
              Text(commande.statut.label,
                  style: TextStyle(color: statutColor, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Destinataire',
          children: [
            _InfoRow(icon: Icons.person_outline, label: commande.nomClient),
            _InfoRow(icon: Icons.phone_outlined, label: commande.telephoneClient),
            if (commande.emailClient != null && commande.emailClient!.isNotEmpty)
              _InfoRow(icon: Icons.email_outlined, label: commande.emailClient!),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Livraison',
          children: [
            _InfoRow(
              icon: Icons.place_outlined,
              label: '${commande.quartierNom ?? '-'} · ${formatFcfa(commande.tarifLivraison)}',
            ),
            if (commande.adressePrecise != null && commande.adressePrecise!.isNotEmpty)
              _InfoRow(icon: Icons.map_outlined, label: commande.adressePrecise!),
            if (commande.dateHeureSouhaitee != null)
              _InfoRow(
                icon: Icons.schedule_outlined,
                label: 'Souhaitée : ${formatDateTime(commande.dateHeureSouhaitee)}',
              ),
          ],
        ),
        const SizedBox(height: 12),
        _SectionCard(
          title: 'Article(s)',
          children: [
            if (commande.partenaireId != null) ...[
              _InfoRow(icon: Icons.storefront_outlined, label: commande.partenaireNom ?? '-'),
              const Divider(height: 20),
              ...commande.lignesProduits.map(
                (ligne) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${ligne.produitNom ?? 'Produit'} × ${ligne.quantite}'),
                      ),
                      Text(formatFcfa(ligne.sousTotal)),
                    ],
                  ),
                ),
              ),
            ] else
              Text(commande.descriptionArticle ?? 'Aucune description'),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                Text(formatFcfa(commande.montantTotal),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _openWhatsApp,
          icon: const Icon(Icons.chat_outlined),
          label: const Text('Contacter via WhatsApp'),
        ),
        const SizedBox(height: 24),
        const Text('Changer le statut', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: StatutCommande.values.map((s) {
            final isCurrent = s == commande.statut;
            return ChoiceChip(
              label: Text(s.label),
              selected: isCurrent,
              onSelected: _updating || isCurrent ? null : (_) => _changerStatut(s),
              selectedColor: AppTheme.statutColor(s.value),
              labelStyle: TextStyle(
                color: isCurrent ? Colors.white : const Color(0xFF334155),
                fontWeight: FontWeight.w600,
                fontSize: 12.5,
              ),
              backgroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFCBD5E1)),
            );
          }).toList(),
        ),
        if (_updating) ...[
          const SizedBox(height: 16),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF64748B))),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
