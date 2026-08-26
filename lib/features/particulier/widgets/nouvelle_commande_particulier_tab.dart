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

  String _typeUser = 'e-commercant'; // 'e-commercant' ou 'particulier'
  ModeCommandeParticulier _mode = ModeCommandeParticulier.envoi;

  // Référence auto-générée
  late String _referenceCommande;

  // E-Commerce Champs
  final _nomProduitCtrl = TextEditingController();
  final _quantiteCtrl = TextEditingController(text: '1');
  final _montantCommandeCtrl = TextEditingController();
  String _modePaiement = 'livraison'; // 'livraison' ou 'deja_paye'
  bool _isFragile = false;

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
  final _instructionsCtrl = TextEditingController();

  // Champ Description, Valeur & Prix du colis
  final _descriptionCtrl = TextEditingController();
  final _valeurColisCtrl = TextEditingController();
  final _prixColisCtrl = TextEditingController();

  Quartier? _quartierLivraison;
  double? _lat;
  double? _lng;
  bool _locating = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _referenceCommande = 'EXP-${DateTime.now().year}-${1000 + (DateTime.now().millisecondsSinceEpoch % 8999)}';
  }

  @override
  void dispose() {
    _nomProduitCtrl.dispose();
    _quantiteCtrl.dispose();
    _montantCommandeCtrl.dispose();
    _expediteurNomCtrl.dispose();
    _expediteurTelCtrl.dispose();
    _expediteurQuartierCtrl.dispose();
    _expediteurAdresseCtrl.dispose();
    _destinataireNomCtrl.dispose();
    _destinataireTelCtrl.dispose();
    _emailCtrl.dispose();
    _destinataireAdresseCtrl.dispose();
    _instructionsCtrl.dispose();
    _descriptionCtrl.dispose();
    _valeurColisCtrl.dispose();
    _prixColisCtrl.dispose();
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
      final isEcommercant = _typeUser == 'e-commercant';
      final isEnvoi = _mode == ModeCommandeParticulier.envoi;

      final nomFinal = _destinataireNomCtrl.text.trim();
      final telFinal = _destinataireTelCtrl.text.trim();

      String fullDescription = '';
      if (isEcommercant) {
        final double montantCmd = double.tryParse(_montantCommandeCtrl.text.trim()) ?? 0.0;
        final double totalAEncaisser = _modePaiement == 'livraison'
            ? (montantCmd + _quartierLivraison!.tarifLivraison)
            : _quartierLivraison!.tarifLivraison;

        fullDescription =
            "📌 RÉFÉRENCE: $_referenceCommande\n"
            "📦 PRODUIT: ${_nomProduitCtrl.text.trim()} (Qté: ${_quantiteCtrl.text.trim()})\n"
            "💰 MONTANT COMMANDE: ${formatFcfa(montantCmd)}\n"
            "💳 MODE PAIEMENT: ${_modePaiement == 'livraison' ? '💵 Paiement à la livraison' : '✅ Déjà payé'}\n"
            "⚠️ FRAGILE: ${_isFragile ? 'OUI 🍷' : 'NON 📦'}\n"
            "📍 RAMASSAGE BOUTIQUE: ${_expediteurNomCtrl.text.trim()} (Tél: ${_expediteurTelCtrl.text.trim()}) - ${_expediteurAdresseCtrl.text.trim()}\n"
            "📝 INSTRUCTIONS LIVREUR: ${_instructionsCtrl.text.trim().isEmpty ? 'Aucune' : _instructionsCtrl.text.trim()}\n"
            "💵 TOTAL À ENCAISSER: ${formatFcfa(totalAEncaisser)}";
      } else {
        final double valColis = double.tryParse(_valeurColisCtrl.text.trim()) ?? 0.0;
        fullDescription =
            "[MODE: ${isEnvoi ? 'ENVOI DE COLIS' : 'RÉCUPÉRATION DE COLIS'}]\n"
            "📦 CONTENU: ${_descriptionCtrl.text.trim()}\n"
            "💰 VALEUR ESTIMÉE: ${formatFcfa(valColis)}\n"
            "📍 POINT DE RÉCUPÉRATION: ${_expediteurNomCtrl.text.trim()} (Tél: ${_expediteurTelCtrl.text.trim()}) - Adresse: ${_expediteurAdresseCtrl.text.trim()}\n"
            "📝 INSTRUCTIONS PARTICULIÈRES: ${_instructionsCtrl.text.trim().isEmpty ? 'Aucune' : _instructionsCtrl.text.trim()}";
      }

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
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Commande Enregistrée',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre demande #${commande.id} a été créée avec succès.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments, size: 18, color: AppColors.navy),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Montant livraison : ${formatFcfa(_quartierLivraison?.tarifLivraison ?? 0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.navy, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Un livreur prendra en charge votre colis sous peu.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
              ],
            ),
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
    _nomProduitCtrl.clear();
    _quantiteCtrl.text = '1';
    _montantCommandeCtrl.clear();
    _expediteurNomCtrl.clear();
    _expediteurTelCtrl.clear();
    _expediteurQuartierCtrl.clear();
    _expediteurAdresseCtrl.clear();
    _destinataireNomCtrl.clear();
    _destinataireTelCtrl.clear();
    _emailCtrl.clear();
    _destinataireAdresseCtrl.clear();
    _instructionsCtrl.clear();
    _descriptionCtrl.clear();
    _valeurColisCtrl.clear();
    _prixColisCtrl.clear();
    setState(() {
      _referenceCommande = 'EXP-${DateTime.now().year}-${1000 + (DateTime.now().millisecondsSinceEpoch % 8999)}';
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
          // 1. Title: Que souhaitez-vous faire ?
          const Text(
            'Que souhaitez-vous faire ?',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.navy),
          ),
          const SizedBox(height: 10),

          // 2. Profile Choice Cards
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _typeUser = 'e-commercant'),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _typeUser == 'e-commercant' ? AppColors.navy : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _typeUser == 'e-commercant' ? AppColors.navy : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.storefront_rounded,
                                color: _typeUser == 'e-commercant' ? Colors.white : AppColors.primary, size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Je suis e-commerçant',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _typeUser == 'e-commercant' ? Colors.white : AppColors.navy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Je veux faire livrer une commande à mon client.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: _typeUser == 'e-commercant' ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _typeUser = 'particulier'),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _typeUser == 'particulier' ? AppColors.navy : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _typeUser == 'particulier' ? AppColors.navy : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.person_pin_circle_rounded,
                                color: _typeUser == 'particulier' ? Colors.white : AppColors.primary, size: 20),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Je suis un particulier',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _typeUser == 'particulier' ? Colors.white : AppColors.navy,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Je veux envoyer ou faire récupérer un colis.',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: _typeUser == 'particulier' ? Colors.white70 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Type de demande Label & Tabs
          const Text(
            'Type de demande',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 8),

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
                    onTap: () => setState(() => _typeUser = 'e-commercant'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _typeUser == 'e-commercant' ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "1- Nouvelle commande",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _typeUser == 'e-commercant' ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            "Pour les e-commerçants",
                            style: TextStyle(
                              fontSize: 9.5,
                              color: _typeUser == 'e-commercant' ? Colors.white70 : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _typeUser = 'particulier'),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _typeUser == 'particulier' ? AppColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "2- Envoyer / Récupérer",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _typeUser == 'particulier' ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                          Text(
                            "Pour les particuliers",
                            style: TextStyle(
                              fontSize: 9.5,
                              color: _typeUser == 'particulier' ? Colors.white70 : const Color(0xFF94A3B8),
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

          const SizedBox(height: 16),

          // Conditional Particulier Envoi vs Récupération toggle
          if (_typeUser == 'particulier')
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _mode = ModeCommandeParticulier.envoi),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isEnvoi ? AppColors.navy : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.unarchive,
                                size: 16, color: isEnvoi ? Colors.white : const Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              "J'envoie un colis",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: !isEnvoi ? AppColors.navy : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.archive,
                                size: 16, color: !isEnvoi ? Colors.white : const Color(0xFF64748B)),
                            const SizedBox(width: 6),
                            Text(
                              "Je fais récupérer",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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

          // ==========================================
          // 1. FORMULAIRE E-COMMERÇANT
          // ==========================================
          if (_typeUser == 'e-commercant') ...[
            // Section A: Informations sur la commande
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              color: Colors.blue.shade50.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "Informations sur la commande",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: _referenceCommande,
                      readOnly: true,
                      decoration: const InputDecoration(
                        labelText: 'Référence de commande (auto)',
                        prefixIcon: Icon(Icons.qr_code),
                        filled: true,
                        fillColor: Color(0xFFF1F5F9),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _nomProduitCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Produit / article',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (v) => (_typeUser == 'e-commercant' && (v == null || v.trim().isEmpty)) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantiteCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Quantité',
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            validator: (v) => (_typeUser == 'e-commercant' && (v == null || v.trim().isEmpty)) ? 'Champ requis' : null,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _montantCommandeCtrl,
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            decoration: const InputDecoration(
                              labelText: 'Montant commande (FCFA)',
                              prefixIcon: Icon(Icons.payments_outlined),
                              suffixText: 'FCFA',
                            ),
                            validator: (v) => (_typeUser == 'e-commercant' && (v == null || v.trim().isEmpty)) ? 'Champ requis' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('Mode de paiement :', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _modePaiement = 'livraison'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _modePaiement == 'livraison' ? AppColors.primary.withValues(alpha: 0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _modePaiement == 'livraison' ? AppColors.primary : Colors.grey.shade300, width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('💵 ', style: TextStyle(fontSize: 14)),
                                  Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text('Paiement à la livraison', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _modePaiement == 'livraison' ? AppColors.primary : Colors.black87)))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _modePaiement = 'deja_paye'),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                              decoration: BoxDecoration(
                                color: _modePaiement == 'deja_paye' ? AppColors.success.withValues(alpha: 0.1) : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: _modePaiement == 'deja_paye' ? AppColors.success : Colors.grey.shade300, width: 1.5),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('✅ ', style: TextStyle(fontSize: 14)),
                                  Text('Déjà payé', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _modePaiement == 'deja_paye' ? AppColors.success : Colors.black87)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Section B: 📍 Récupération du colis
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              color: Colors.amber.shade50.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: AppColors.primaryAccent, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "📍 Récupération du colis",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _expediteurNomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom du commerçant / boutique',
                        prefixIcon: Icon(Icons.store),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _expediteurTelCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone commerçant',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _expediteurAdresseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Adresse de récupération',
                        prefixIcon: Icon(Icons.home_work_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    _buildGpsWidget(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Section C: 🎯 Livraison au client
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              color: Colors.teal.shade50.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flag, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "🎯 Livraison au client",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _destinataireNomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom du client',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _destinataireTelCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone du client',
                        prefixIcon: Icon(Icons.phone_android),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    quartiersAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (err, _) => Text(err.toString()),
                      data: (quartiers) => DropdownButtonFormField<Quartier>(
                        initialValue: _quartierLivraison,
                        decoration: const InputDecoration(
                          labelText: 'Quartier du client',
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
                      decoration: const InputDecoration(
                        labelText: 'Adresse précise client',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _instructionsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Instruction pour le livreur (facultatif)',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Section D: 📦 Informations complémentaires
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
                    const Row(
                      children: [
                        Icon(Icons.inventory_outlined, color: AppColors.navy, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "📦 Informations complémentaires",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.navy),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description du colis',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Fragile ?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('Oui'),
                              selected: _isFragile,
                              onSelected: (val) => setState(() => _isFragile = val),
                              selectedColor: Colors.amber.shade200,
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Non'),
                              selected: !_isFragile,
                              onSelected: (val) => setState(() => _isFragile = !val),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Section E: Résumé Financier
            Builder(
              builder: (context) {
                final double mCmd = double.tryParse(_montantCommandeCtrl.text.trim()) ?? 0.0;
                final double fLiv = _quartierLivraison?.tarifLivraison ?? 0.0;
                final double totalEncaisser = _modePaiement == 'livraison' ? (mCmd + fLiv) : fLiv;

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Montant commande :', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(formatFcfa(mCmd), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Frais livraison :', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text(formatFcfa(fLiv), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const Divider(color: Colors.white24, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Montant à encaisser :', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(formatFcfa(totalEncaisser), style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Bouton E-Commerçant
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.check_circle_outline, color: Colors.white),
                label: Text(
                  _submitting ? 'Traitement...' : 'CONFIRMER LA COMMANDE',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],

          // ==========================================
          // 2. FORMULAIRE PARTICULIER
          // ==========================================
          if (_typeUser == 'particulier') ...[
            // Section A: 📍 Point de récupération
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              color: Colors.amber.shade50.withValues(alpha: 0.4),
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
                            isEnvoi ? "📍 Point de Récupération (Votre adresse)" : "📍 Point de Récupération (Origine colis)",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _expediteurNomCtrl,
                      decoration: InputDecoration(
                        labelText: isEnvoi ? 'Votre nom' : 'Nom de l\'expéditeur / vendeur',
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _expediteurTelCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _expediteurQuartierCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Quartier',
                        prefixIcon: Icon(Icons.map_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _expediteurAdresseCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Adresse précise',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    _buildGpsWidget(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Section B: 🎯 Destinataire
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              color: Colors.blue.shade50.withValues(alpha: 0.4),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.flag, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "🎯 Destinataire",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _destinataireNomCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nom du destinataire',
                        prefixIcon: Icon(Icons.person),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _destinataireTelCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Téléphone destinataire',
                        prefixIcon: Icon(Icons.phone),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
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
                      decoration: const InputDecoration(
                        labelText: 'Adresse précise destinataire',
                        prefixIcon: Icon(Icons.place_outlined),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Section C: 📦 Votre colis
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
                    const Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "📦 Votre colis",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Que contient le colis ?',
                        alignLabelWithHint: true,
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _valeurColisCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Valeur approximative du colis (FCFA)',
                        prefixIcon: Icon(Icons.payments_outlined),
                        suffixText: 'FCFA',
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _instructionsCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Instructions particulières',
                        prefixIcon: Icon(Icons.note_alt_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Bouton Particulier
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white),
                label: Text(
                  _submitting ? 'Traitement...' : 'DEMANDER LA LIVRAISON',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
