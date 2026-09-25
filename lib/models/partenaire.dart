class Partenaire {
  final int id;
  final String nom;
  final String telephone;
  final bool livraisonGratuite;

  const Partenaire({
    required this.id,
    required this.nom,
    required this.telephone,
    this.livraisonGratuite = false,
  });

  factory Partenaire.fromJson(Map<String, dynamic> json) {
    return Partenaire(
      id: json['id'] as int,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String,
      livraisonGratuite: json['livraisonGratuite'] as bool? ?? false,
    );
  }
}
