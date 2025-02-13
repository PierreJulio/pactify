class ConsequenceGenerator {
  static final List<String> _consequences = [
    'Préparer un repas pour tous les participants',
    'Faire le ménage chez un participant au choix',
    'Organiser une soirée jeux de société',
    'Offrir le café pendant une semaine',
    'Faire une danse TikTok choisie par les autres',
    'Être le chauffeur désigné pour la prochaine sortie',
    'Porter un t-shirt choisi par les autres pendant une journée',
    'Faire un karaoké en public',
    'Apporter les croissants au bureau pendant 3 jours',
    'Faire 20 pompes à chaque demande pendant une journée',
    'Parler avec un accent choisi par les autres pendant une journée',
    'Être le serveur personnel des autres pendant une soirée',
    'Faire une déclaration d\'amour en public à un arbre',
    'Manger un piment fort devant tout le monde',
    'Poster une photo embarrassante sur les réseaux sociaux'
  ];

  static String generateConsequence() {
    _consequences.shuffle();
    return _consequences.first;
  }

  static List<String> generateMultipleConsequences(int count) {
    _consequences.shuffle();
    return _consequences.take(count).toList();
  }
}
