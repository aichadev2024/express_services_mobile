import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/commande.dart';
import '../../../models/partenaire.dart';
import '../../commandes/providers/commande_providers.dart';
import '../../commandes/widgets/commande_card.dart';

class SuiviPartenaireTab extends ConsumerStatefulWidget {
  final Partenaire partenaire;
  const SuiviPartenaireTab({super.key, required this.partenaire});

  @override
  ConsumerState<SuiviPartenaireTab> createState() => _SuiviPartenaireTabState();
}

class _SuiviPartenaireTabState extends ConsumerState<SuiviPartenaireTab> {
  late final TextEditingController _queryCtrl =
      TextEditingController(text: widget.partenaire.nom);
  List<Commande>? _results;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryCtrl.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref.read(commandeRepositoryProvider).suivre(query);
      if (mounted) setState(() => _results = results);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Nom de boutique ou téléphone',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _loading ? null : _search,
                child: const Text('Chercher'),
              ),
            ],
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
          ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : (_results == null || _results!.isEmpty)
                  ? const Center(child: Text('Aucune commande trouvée'))
                  : RefreshIndicator(
                      onRefresh: _search,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        itemCount: _results!.length,
                        itemBuilder: (context, index) =>
                            CommandeCard(commande: _results![index]),
                      ),
                    ),
        ),
      ],
    );
  }
}
