import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/produit.dart';
import 'reference_data_providers.dart';

final produitsDuPartenaireProvider =
    FutureProvider.autoDispose.family<List<Produit>, int>((ref, partenaireId) {
  return ref.read(referenceDataRepositoryProvider).getProduitsDuPartenaire(partenaireId);
});

final stockStatsProvider =
    FutureProvider.autoDispose.family<List<ProduitStockStats>, int>((ref, partenaireId) async {
  return ref.read(referenceDataRepositoryProvider).getStockStats(partenaireId);
});
