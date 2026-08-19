class Quartier {
  final int id;
  final String nom;
  final double tarifLivraison;

  const Quartier({
    required this.id,
    required this.nom,
    required this.tarifLivraison,
  });

  factory Quartier.fromJson(Map<String, dynamic> json) {
    return Quartier(
      id: json['id'] as int,
      nom: json['nom'] as String,
      tarifLivraison: (json['tarifLivraison'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'tarifLivraison': tarifLivraison,
      };
}
