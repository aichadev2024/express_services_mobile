class Produit {
  final int id;
  final String nom;
  final double prix;
  final String? description;
  final int stock;
  final bool actif;
  final int? partenaireId;
  final String? partenaireNom;

  const Produit({
    required this.id,
    required this.nom,
    required this.prix,
    this.description,
    required this.stock,
    required this.actif,
    this.partenaireId,
    this.partenaireNom,
  });

  factory Produit.fromJson(Map<String, dynamic> json) {
    return Produit(
      id: json['id'] as int,
      nom: json['nom'] as String,
      prix: (json['prix'] as num).toDouble(),
      description: json['description'] as String?,
      stock: json['stock'] as int,
      actif: json['actif'] as bool? ?? true,
      partenaireId: json['partenaireId'] as int?,
      partenaireNom: json['partenaireNom'] as String?,
    );
  }
}

class ProduitStockStats {
  final int id;
  final String nom;
  final int stockDisponible;
  final int sortisPourLivraison;
  final int restants;
  final int retournes;

  const ProduitStockStats({
    required this.id,
    required this.nom,
    required this.stockDisponible,
    required this.sortisPourLivraison,
    required this.restants,
    required this.retournes,
  });

  factory ProduitStockStats.fromJson(Map<String, dynamic> json) {
    return ProduitStockStats(
      id: json['id'] as int,
      nom: json['nom'] as String,
      stockDisponible: json['stockDisponible'] as int? ?? 0,
      sortisPourLivraison: json['sortisPourLivraison'] as int? ?? 0,
      restants: json['restants'] as int? ?? 0,
      retournes: json['retournes'] as int? ?? 0,
    );
  }
}
