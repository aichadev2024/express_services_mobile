import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/quartier.dart';
import '../../commandes/data/commande_repository.dart';
import '../../commandes/providers/commande_providers.dart';
import '../../partenaire/providers/reference_data_providers.dart';

enum ModeCommandeParticulier { envoi, recuperation }

class NouvelleCommandeParticulierTab extends ConsumerStatefulWidget {
  const NouvelleCommandeParticulierTab({super.key});

  @override
  ConsumerState<NouvelleCommandeParticulierTab> createState() =>
      _NouvelleCommandeParticulierTabState();
}

class _NouvelleCommandeParticulierTabState
    extends ConsumerState<NouvelleCommandeParticulierTab> {
  final _formKey = GlobalKey<FormState>();

  ModeCommandeParticulier _mode = ModeCommandeParticulier.envoi;

  // Champs Expéditeur / Ramassage
  final _expediteurNomCtrl = TextEditingController();
  final _expediteurTelCtrl = TextEditingController();
  final _expediteurQuartierCtrl = TextEditingController();
  final _expediteurAdresseCtrl = TextEditingController();

  // Champs Destinataire / Livraison
  final _destinataireNomCtrl = TextEditingController();
  final _destinataireTelCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _destinataireAdresseCtrl = TextEditingController();

  // Champ Description du colis
  final _descriptionCtrl = TextEditingController();

  Quartier? _quartierLivraison;
  double? _lat;
  double? _lng;
  bool _locating = false;
  bool _submitting = false;

  @override
  void dispose() {
    _expediteurNomCtrl.dispose();
    _expediteurTelCtrl.dispose();
    _expediteurQuartierCtrl.dispose();
    _expediteurAdresseCtrl.dispose();
    _destinataireNomCtrl.dispose();
    _destinataireTelCtrl.dispose();
    _emailCtrl.dispose();
    _destinataireAdresseCtrl.dispose();
    _descriptionCtrl.dispose();
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
        throw Exception("Permission de géolocalisation refusée.");
      }
      
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📍 Position GPS enregistrée avec succès !'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Géolocalisation : $e. Vous pouvez continuer avec l\'adresse précise.'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_quartierLivraison == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un quartier de livraison')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final isEnvoi = _mode == ModeCommandeParticulier.envoi;

      final nomFinal = _destinataireNomCtrl.text.trim();
      final telFinal = _destinataireTelCtrl.text.trim();

      final String detailRamassage = isEnvoi
          ? "📍 RAMASSAGE CHEZ EXPÉDITEUR : ${_expediteurNomCtrl.text.trim()} (Tél: ${_expediteurTelCtrl.text.trim()}) - Adresse: ${_expediteurAdresseCtrl.text.trim()}"
          : "📍 RÉCUPÉRATION CHEZ VENDEUR/PROCHE : ${_expediteurNomCtrl.text.trim()} (Tél: ${_expediteurTelCtrl.text.trim()}) - Quartier: ${_expediteurQuartierCtrl.text.trim()} - Adresse: ${_expediteurAdresseCtrl.text.trim()}";

      final String fullDescription =
          "[MODE: ${isEnvoi ? 'ENVOI DE COLIS' : 'RÉCUPÉRATION DE COLIS'}]\n"
          "📦 ARTICLE: ${_descriptionCtrl.text.trim()}\n"
          "💳 TARIF LIVRAISON: ${formatFcfa(_quartierLivraison!.tarifLivraison)}\n"
          "$detailRamassage";

      final commande = await ref.read(commandeRepositoryProvider).creerCommande(
            CommandeRequest(
              nomClient: nomFinal,
              telephoneClient: telFinal,
              emailClient: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
              descriptionArticle: fullDescription,
              quartierId: _quartierLivraison!.id,
              adressePrecise: _destinataireAdresseCtrl.text.trim(),
              latitude: _lat,
              longitude: _lng,
            ),
          );

      if (!mounted) return;
      _resetForm();

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: const [
              Icon(Icons.check_circle, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Text('Commande Enregistrée'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Votre demande de livraison #${commande.id} a été créée avec succès.'),
              const SizedBox(height: 10),
              Text(
                'Montant à régler à la livraison : ${formatFcfa(_quartierLivraison?.tarifLivraison ?? 0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy),
              ),
              const SizedBox(height: 6),
              const Text(
                'Un livreur prendra en charge votre colis incessamment.',
                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _resetForm() {
    _expediteurNomCtrl.clear();
    _expediteurTelCtrl.clear();
    _expediteurQuartierCtrl.clear();
    _expediteurAdresseCtrl.clear();
    _destinataireNomCtrl.clear();
    _destinataireTelCtrl.clear();
    _emailCtrl.clear();
    _destinataireAdresseCtrl.clear();
    _descriptionCtrl.clear();
    setState(() {
      _quartierLivraison = null;
      _lat = null;
      _lng = null;
    });
  }

  Widget _buildGpsWidget() {
    if (_lat != null && _lng != null) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFA7F3D0)),
        ),
        child: Row(
          children: [
            const Icon(Icons.my_location, color: AppColors.success, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Position GPS activée : ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 16, color: Color(0xFF065F46)),
              onPressed: () => setState(() {
                _lat = null;
                _lng = null;
              }),
              tooltip: 'Effacer la position GPS',
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _locating ? null : _useCurrentLocation,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        side: const BorderSide(color: AppColors.navy),
      ),
      icon: _locating
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.my_location),
      label: Text(_locating ? 'Recherche du signal GPS...' : 'Joindre ma position GPS actuelle'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final quartiersAsync = ref.watch(quartiersProvider);
    final isEnvoi = _mode == ModeCommandeParticulier.envoi;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Mode Selector
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _mode = ModeCommandeParticulier.envoi),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isEnvoi ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.unarchive,
                              size: 18, color: isEnvoi ? Colors.white : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            "J'envoie un colis",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isEnvoi ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _mode = ModeCommandeParticulier.recuperation),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: !isEnvoi ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.archive,
                              size: 18, color: !isEnvoi ? Colors.white : const Color(0xFF64748B)),
                          const SizedBox(width: 6),
                          Text(
                            "Je fais récupérer",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: !isEnvoi ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Section 1: Ramassage (Point A)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            color: Colors.amber.shade50.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primaryAccent, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isEnvoi
                              ? "📍 Point de Ramassage (Chez vous / Expéditeur)"
                              : "📍 Point de Ramassage (Vendeur / Origine)",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _expediteurNomCtrl,
                    decoration: InputDecoration(
                      labelText: isEnvoi ? 'Votre nom (Expéditeur)' : 'Nom du vendeur / boutique',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _expediteurTelCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: isEnvoi ? 'Votre téléphone' : 'Téléphone du vendeur / origine',
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  if (!isEnvoi) ...[
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _expediteurQuartierCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Quartier du vendeur / origine',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                  ],
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _expediteurAdresseCtrl,
                    decoration: InputDecoration(
                      labelText: isEnvoi ? 'Votre adresse précise' : 'Adresse précise du vendeur',
                      prefixIcon: const Icon(Icons.home_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  if (isEnvoi) ...[
                    const SizedBox(height: 10),
                    _buildGpsWidget(),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section 2: Livraison (Point B)
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            color: Colors.blue.shade50.withOpacity(0.5),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flag, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        isEnvoi
                            ? "🎯 Point de Livraison (Destinataire / Proche)"
                            : "🎯 Point de Livraison (Chez vous / Destinataire)",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _destinataireNomCtrl,
                    decoration: InputDecoration(
                      labelText: isEnvoi ? 'Nom du destinataire / client' : 'Votre nom (Destinataire)',
                      prefixIcon: const Icon(Icons.person),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _destinataireTelCtrl,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: isEnvoi ? 'Téléphone du destinataire' : 'Votre téléphone',
                      prefixIcon: const Icon(Icons.phone),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'E-mail (optionnel)',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  quartiersAsync.when(
                    loading: () => const LinearProgressIndicator(),
                    error: (err, _) => Text(err.toString()),
                    data: (quartiers) => DropdownButtonFormField<Quartier>(
                      initialValue: _quartierLivraison,
                      decoration: const InputDecoration(
                        labelText: 'Quartier de livraison',
                        prefixIcon: Icon(Icons.location_city),
                      ),
                      items: quartiers
                          .map((q) => DropdownMenuItem(
                                value: q,
                                child: Text('${q.nom} · ${formatFcfa(q.tarifLivraison)}'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _quartierLivraison = v),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _destinataireAdresseCtrl,
                    decoration: InputDecoration(
                      labelText: isEnvoi ? 'Adresse précise du destinataire' : 'Votre adresse précise',
                      prefixIcon: const Icon(Icons.place_outlined),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  if (!isEnvoi) ...[
                    const SizedBox(height: 10),
                    _buildGpsWidget(),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section 3: Article / Colis
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 22),
                      SizedBox(width: 8),
                      Text(
                        "📦 Détails du Colis",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descriptionCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Décrivez l\'article à livrer (ex: Sac de vêtements, Clés, Documents...)',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Section 4: Récapitulatif du Tarif de Livraison
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            color: const Color(0xFFF1F5F9),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.payments_outlined, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Tarif de livraison estimé",
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _quartierLivraison != null
                              ? formatFcfa(_quartierLivraison!.tarifLivraison)
                              : "Sélectionnez un quartier",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.navy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send_rounded),
              label: Text(
                _submitting ? 'Traitement...' : 'Soumettre ma demande de livraison',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
