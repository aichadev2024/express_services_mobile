import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/commande.dart';

class CommandeCard extends StatelessWidget {
  final Commande commande;
  final VoidCallback? onTap;

  const CommandeCard({super.key, required this.commande, this.onTap});

  @override
  Widget build(BuildContext context) {
    final statutColor = AppTheme.statutColor(commande.statut.value);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${commande.id} · ${commande.nomClient}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statutColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      commande.statut.label,
                      style: TextStyle(
                          color: statutColor, fontSize: 11.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              if (commande.motifAnnulation != null && commande.motifAnnulation!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 13, color: AppColors.danger),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Motif : ${commande.motifAnnulation}',
                          style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 4),
                  Text(commande.telephoneClient,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                ],
              ),
              if (commande.quartierNom != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.place_outlined, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(commande.quartierNom!,
                          style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(formatDateTime(commande.dateCreation),
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
                  Text(formatFcfa(commande.montantTotal),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
