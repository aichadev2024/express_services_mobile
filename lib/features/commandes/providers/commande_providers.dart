import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/commande_repository.dart';

final commandeRepositoryProvider = Provider<CommandeRepository>(
  (ref) => CommandeRepository(),
);
