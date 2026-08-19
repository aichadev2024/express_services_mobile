import 'statut_commande.dart';

class LigneProduit {
  final int produitId;
  final String? produitNom;
  final int quantite;
  final double? prixUnitaire;
  final double? sousTotal;

  const LigneProduit({
    required this.produitId,
    this.produitNom,
    required this.quantite,
    this.prixUnitaire,
    this.sousTotal,
  });

  factory LigneProduit.fromJson(Map<String, dynamic> json) {
    return LigneProduit(
      produitId: json['produitId'] as int,
      produitNom: json['produitNom'] as String?,
      quantite: json['quantite'] as int,
      prixUnitaire: (json['prixUnitaire'] as num?)?.toDouble(),
      sousTotal: (json['sousTotal'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toRequestJson() => {
        'produitId': produitId,
        'quantite': quantite,
      };
}

class Commande {
  final int id;
  final String nomClient;
  final String telephoneClient;
  final String? emailClient;
  final List<LigneProduit> lignesProduits;
  final int quartierId;
  final String? quartierNom;
  final double? tarifLivraison;
  final String? adressePrecise;
  final double? latitude;
  final double? longitude;
  final DateTime? dateHeureSouhaitee;
  final StatutCommande statut;
  final DateTime? dateCreation;
  final int? livreurId;
  final String? livreurUsername;
  final String? livreurNom;
  final String? livreurPrenom;
  final double? montantProduits;
  final double? montantTotal;
  final int? partenaireId;
  final String? partenaireNom;
  final String? descriptionArticle;
  final String? motifAnnulation;

  const Commande({
    required this.id,
    required this.nomClient,
    required this.telephoneClient,
    this.emailClient,
    required this.lignesProduits,
    required this.quartierId,
    this.quartierNom,
    this.tarifLivraison,
    this.adressePrecise,
    this.latitude,
    this.longitude,
    this.dateHeureSouhaitee,
    required this.statut,
    this.dateCreation,
    this.livreurId,
    this.livreurUsername,
    this.livreurNom,
    this.livreurPrenom,
    this.montantProduits,
    this.montantTotal,
    this.partenaireId,
    this.partenaireNom,
    this.descriptionArticle,
    this.motifAnnulation,
  });

  factory Commande.fromJson(Map<String, dynamic> json) {
    return Commande(
      id: json['id'] as int,
      nomClient: json['nomClient'] as String? ?? '',
      telephoneClient: json['telephoneClient'] as String? ?? '',
      emailClient: json['emailClient'] as String?,
      lignesProduits: (json['lignesProduits'] as List<dynamic>? ?? [])
          .map((e) => LigneProduit.fromJson(e as Map<String, dynamic>))
          .toList(),
      quartierId: json['quartierId'] as int? ?? 0,
      quartierNom: json['quartierNom'] as String?,
      tarifLivraison: (json['tarifLivraison'] as num?)?.toDouble(),
      adressePrecise: json['adressePrecise'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      dateHeureSouhaitee: json['dateHeureSouhaitee'] != null
          ? DateTime.tryParse(json['dateHeureSouhaitee'] as String)
          : null,
      statut: StatutCommande.fromValue(json['statut'] as String? ?? 'EN_ATTENTE'),
      dateCreation: json['dateCreation'] != null
          ? DateTime.tryParse(json['dateCreation'] as String)
          : null,
      livreurId: json['livreurId'] as int?,
      livreurUsername: json['livreurUsername'] as String?,
      livreurNom: json['livreurNom'] as String?,
      livreurPrenom: json['livreurPrenom'] as String?,
      montantProduits: (json['montantProduits'] as num?)?.toDouble(),
      montantTotal: (json['montantTotal'] as num?)?.toDouble(),
      partenaireId: json['partenaireId'] as int?,
      partenaireNom: json['partenaireNom'] as String?,
      descriptionArticle: json['descriptionArticle'] as String?,
      motifAnnulation: json['motifAnnulation'] as String?,
    );
  }
}
