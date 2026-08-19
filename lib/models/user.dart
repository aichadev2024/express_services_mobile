class AppUser {
  final int id;
  final String username;
  final String email;
  final String nom;
  final String prenom;
  final String role;
  final String? photoUrl;

  const AppUser({
    required this.id,
    required this.username,
    required this.email,
    required this.nom,
    required this.prenom,
    required this.role,
    this.photoUrl,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      role: json['role'] as String,
      photoUrl: json['photoUrl'] as String?,
    );
  }
}
