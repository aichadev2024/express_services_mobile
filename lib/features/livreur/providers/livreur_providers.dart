import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../models/commande.dart';
import '../../commandes/providers/commande_providers.dart';

/// null = "Toutes" (actives), otherwise a StatutCommande.value filter.
final livreurStatutFilterProvider = StateProvider<String?>((ref) => null);

final livreurCommandesProvider = FutureProvider.autoDispose<List<Commande>>((ref) async {
  final statut = ref.watch(livreurStatutFilterProvider);
  return ref.read(commandeRepositoryProvider).mesCommandes(statut: statut);
});

final commandeDetailProvider =
    FutureProvider.autoDispose.family<Commande, int>((ref, id) async {
  return ref.read(commandeRepositoryProvider).getById(id);
});
