import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../models/commande.dart';

/// Payload for creating or updating a commande — shared by the Partenaire
/// (product lines) and Particulier (free-text description) flows, and by
/// the Livreur/Admin update paths.
class CommandeRequest {
  final String nomClient;
  final String telephoneClient;
  final String? emailClient;
  final List<Map<String, dynamic>>? lignesProduits;
  final int quartierId;
  final String? adressePrecise;
  final double? latitude;
  final double? longitude;
  final DateTime? dateHeureSouhaitee;
  final int? partenaireId;
  final String? descriptionArticle;
  final bool? livraisonGratuite;
  
  // Frictionless auto-registration fields
  final String? nomExpediteur;
  final String? telephoneExpediteur;
  final String? adresseExpediteur;

  const CommandeRequest({
    required this.nomClient,
    required this.telephoneClient,
    this.emailClient,
    this.lignesProduits,
    required this.quartierId,
    this.adressePrecise,
    this.latitude,
    this.longitude,
    this.dateHeureSouhaitee,
    this.partenaireId,
    this.descriptionArticle,
    this.livraisonGratuite,
    this.nomExpediteur,
    this.telephoneExpediteur,
    this.adresseExpediteur,
  });

  Map<String, dynamic> toJson() => {
        'nomClient': nomClient,
        'telephoneClient': telephoneClient,
        if (emailClient != null && emailClient!.isNotEmpty) 'emailClient': emailClient,
        if (lignesProduits != null) 'lignesProduits': lignesProduits,
        'quartierId': quartierId,
        if (adressePrecise != null) 'adressePrecise': adressePrecise,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (dateHeureSouhaitee != null)
          'dateHeureSouhaitee': dateHeureSouhaitee!.toIso8601String(),
        if (partenaireId != null) 'partenaireId': partenaireId,
        if (descriptionArticle != null && descriptionArticle!.isNotEmpty)
          'descriptionArticle': descriptionArticle,
        if (livraisonGratuite != null) 'livraisonGratuite': livraisonGratuite,
        if (nomExpediteur != null && nomExpediteur!.isNotEmpty) 'nomExpediteur': nomExpediteur,
        if (telephoneExpediteur != null && telephoneExpediteur!.isNotEmpty) 'telephoneExpediteur': telephoneExpediteur,
        if (adresseExpediteur != null && adresseExpediteur!.isNotEmpty) 'adresseExpediteur': adresseExpediteur,
      };
}

class CommandeRepository {
  final Dio _dio = DioClient.instance.dio;

  Future<Commande> creerCommande(CommandeRequest request) async {
    try {
      final response = await _dio.post('/api/commandes', data: request.toJson());
      return Commande.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Public tracking by phone number or partner name — no auth required.
  Future<List<Commande>> suivre(String query) async {
    try {
      final response = await _dio.get('/api/commandes/track', queryParameters: {
        'query': query,
      });
      return (response.data as List<dynamic>)
          .map((e) => Commande.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Livreur (authenticated): commandes assigned to the logged-in driver.
  Future<List<Commande>> mesCommandes({String? statut}) async {
    try {
      final response = await _dio.get('/api/commandes', queryParameters: {
        if (statut != null) 'statut': statut,
      });
      return (response.data as List<dynamic>)
          .map((e) => Commande.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Commande> getById(int id) async {
    try {
      final response = await _dio.get('/api/commandes/$id');
      return Commande.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<Commande> changerStatut(int id, String statut, {String? motif}) async {
    try {
      final response = await _dio.put('/api/commandes/$id/status', data: {
        'statut': statut,
        if (motif != null && motif.trim().isNotEmpty) 'motif': motif.trim(),
      });
      return Commande.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<String> getWhatsAppLink(int id) async {
    try {
      final response = await _dio.get('/api/commandes/$id/whatsapp');
      return (response.data as Map<String, dynamic>)['link'] as String;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }
}
