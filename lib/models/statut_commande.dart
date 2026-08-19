enum StatutCommande {
  enAttente('EN_ATTENTE', 'En attente'),
  enCours('EN_COURS', 'En cours'),
  livree('LIVREE', 'Livrée'),
  annulee('ANNULEE', 'Annulée'),
  injoignable('INJOIGNABLE', 'Injoignable'),
  reportee('REPORTEE', 'Reportée'),
  rejetee('REJETEE', 'Rejetée');

  final String value;
  final String label;

  const StatutCommande(this.value, this.label);

  static StatutCommande fromValue(String value) {
    return StatutCommande.values.firstWhere(
      (s) => s.value == value,
      orElse: () => StatutCommande.enAttente,
    );
  }
}
