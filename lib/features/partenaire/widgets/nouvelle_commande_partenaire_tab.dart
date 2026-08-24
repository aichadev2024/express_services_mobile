import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/partenaire.dart';
import '../../../models/quartier.dart';
import '../../commandes/data/commande_repository.dart';
import '../../commandes/providers/commande_providers.dart';
import '../providers/partenaire_stock_providers.dart';
import '../providers/reference_data_providers.dart';

class NouvelleCommandePartenaireTab extends ConsumerStatefulWidget {
  final Partenaire partenaire;
  const NouvelleCommandePartenaireTab({super.key, required this.partenaire});

  @override
  ConsumerState<NouvelleCommandePartenaireTab> createState() =>
      _NouvelleCommandePartenaireTabState();
}

class _NouvelleCommandePartenaireTabState
    extends ConsumerState<NouvelleCommandePartenaireTab> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();

  final Map<int, int> _quantites = {};
  Quartier? _quartier;
  double? _lat;
  double? _lng;
  bool _livraisonGratuite = false;
  bool _locating = false;
  bool _submitting = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception("Permission de localisation refusée");
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception("Le service de localisation est désactivé");
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Position indisponible : $e')));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_quartier == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Choisissez un quartier de livraison')));
      return;
    }
    final lignes = _quantites.entries.where((e) => e.value > 0).toList();
    if (lignes.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Ajoutez au moins un produit')));
      return;
    }

    setState(() => _submitting = true);
    try {
      final commande = await ref.read(commandeRepositoryProvider).creerCommande(
            CommandeRequest(
              nomClient: _nomCtrl.text.trim(),
              telephoneClient: _telCtrl.text.trim(),
              emailClient: _emailCtrl.text.trim(),
              lignesProduits: lignes
                  .map((e) => {'produitId': e.key, 'quantite': e.value})
                  .toList(),
              quartierId: _quartier!.id,
              adressePrecise: _adresseCtrl.text.trim(),
              latitude: _lat,
              longitude: _lng,
              partenaireId: widget.partenaire.id,
              livraisonGratuite: _livraisonGratuite,
            ),
          );
      if (!mounted) return;
      _resetForm();
      ref.invalidate(produitsDuPartenaireProvider(widget.partenaire.id));
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Commande créée'),
          content: Text(
              'La commande #${commande.id} a bien été enregistrée pour ${commande.nomClient}.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.danger));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    _nomCtrl.clear();
    _telCtrl.clear();
    _emailCtrl.clear();
    _adresseCtrl.clear();
    setState(() {
      _quantites.clear();
      _quartier = null;
      _lat = null;
      _lng = null;
      _livraisonGratuite = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final produitsAsync = ref.watch(produitsDuPartenaireProvider(widget.partenaire.id));
    final quartiersAsync = ref.watch(quartiersProvider);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Produits en stock', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          produitsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => Text(err.toString()),
            data: (produits) {
              if (produits.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text('Aucun produit disponible pour cette boutique.'),
                );
              }
              return Card(
                child: Column(
                  children: produits.map((produit) {
                    final qty = _quantites[produit.id] ?? 0;
                    return ListTile(
                      title: Text(produit.nom),
                      subtitle: Text('${formatFcfa(produit.prix)} · Stock : ${produit.stock}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: qty > 0
                                ? () => setState(() => _quantites[produit.id] = qty - 1)
                                : null,
                          ),
                          SizedBox(
                              width: 24,
                              child: Text('$qty', textAlign: TextAlign.center)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: qty < produit.stock
                                ? () => setState(() => _quantites[produit.id] = qty + 1)
                                : null,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text('Destinataire', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nomCtrl,
            decoration: const InputDecoration(labelText: 'Nom du destinataire'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _telCtrl,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Téléphone'),
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'E-mail (optionnel)'),
          ),
          const SizedBox(height: 20),
          const Text('Livraison', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          quartiersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (err, _) => Text(err.toString()),
            data: (quartiers) => DropdownButtonFormField<Quartier>(
              initialValue: _quartier,
              decoration: const InputDecoration(labelText: 'Quartier de livraison'),
              items: quartiers
                  .map((q) => DropdownMenuItem(
                        value: q,
                        child: Text('${q.nom} · ${formatFcfa(q.tarifLivraison)}'),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _quartier = v),
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _livraisonGratuite,
            onChanged: (v) => setState(() => _livraisonGratuite = v ?? false),
            title: const Text('Offrir la livraison au client (Livraison Gratuite)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            subtitle: const Text('0 FCFA de frais de livraison facturés au client',
                style: TextStyle(fontSize: 11.5, color: AppColors.success)),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _adresseCtrl,
            decoration: const InputDecoration(labelText: 'Adresse précise'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _locating ? null : _useCurrentLocation,
            icon: _locating
                ? const SizedBox(
                    height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.my_location),
            label: Text(_lat != null
                ? 'Position enregistrée (${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)})'
                : 'Joindre ma position GPS (optionnel)'),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Déposer la commande'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
