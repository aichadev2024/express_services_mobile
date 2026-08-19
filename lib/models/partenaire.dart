class Partenaire {
  final int id;
  final String nom;
  final String telephone;

  const Partenaire({
    required this.id,
    required this.nom,
    required this.telephone,
  });

  factory Partenaire.fromJson(Map<String, dynamic> json) {
    return Partenaire(
      id: json['id'] as int,
      nom: json['nom'] as String,
      telephone: json['telephone'] as String,
    );
  }
}
