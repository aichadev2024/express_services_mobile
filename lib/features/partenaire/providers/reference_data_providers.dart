import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/partenaire.dart';
import '../../../models/produit.dart';
import '../../../models/quartier.dart';
import '../data/reference_data_repository.dart';

final referenceDataRepositoryProvider = Provider<ReferenceDataRepository>(
  (ref) => ReferenceDataRepository(),
);

final quartiersProvider = FutureProvider<List<Quartier>>((ref) {
  return ref.read(referenceDataRepositoryProvider).getQuartiers();
});

final partenairesProvider = FutureProvider<List<Partenaire>>((ref) {
  return ref.read(referenceDataRepositoryProvider).getPartenaires();
});

final produitsProvider = FutureProvider<List<Produit>>((ref) {
  return ref.read(referenceDataRepositoryProvider).getAllProduits();
});
