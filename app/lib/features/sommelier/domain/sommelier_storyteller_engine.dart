import '../../cellar/domain/wine.dart';

class SommelierStory {
  final String title;
  final String subtitle;
  final String act1Terroir;
  final String act2Vinification;
  final String act3Degustation;
  final int estimatedSeconds;

  const SommelierStory({
    required this.title,
    required this.subtitle,
    required this.act1Terroir,
    required this.act2Vinification,
    required this.act3Degustation,
    this.estimatedSeconds = 45,
  });

  String get fullText => '$act1Terroir\n\n$act2Vinification\n\n$act3Degustation';
}

class SommelierStorytellerEngine {
  /// Génère une capsule audio-sommelier immersive de ~45 secondes.
  static SommelierStory generateStory(Wine wine) {
    final name = wine.name;
    final producer = wine.producer ?? 'le vigneron';
    final region = wine.region.isNotEmpty ? wine.region : 'sa terre d\'origine';
    final appellation = wine.appellation ?? wine.region;
    final vintage = wine.vintage != null ? '${wine.vintage}' : 'les plus beaux millésimes';
    final grapes = wine.grapes.isNotEmpty
        ? wine.grapes.map((g) => g.name).join(' et ')
        : 'ses cépages signatures';

    final isWhite = wine.type.toLowerCase().contains('blanc') ||
        wine.type.toLowerCase().contains('white');
    final isChampagne = wine.type.toLowerCase().contains('champ') ||
        wine.type.toLowerCase().contains('efferv');

    // Act 1 : Terroir & Origine
    String act1;
    if (isChampagne) {
      act1 = 'Bienvenue au cœur des terroirs crayeux de Champagne. Ici, chaque parcelle puise dans la profondeur du sous-sol calcaire une fraîcheur et une tension exceptionnelles. $name incarne cette quête séculaire de la bulle parfaite.';
    } else if (isWhite) {
      act1 = 'Fermez les yeux et respirez le vent frais qui caresse les coteaux de $region. Sur ces pentes baignées de lumière, les racines plongent dans une matrice minérale unique pour donner naissance à $name, millésime $vintage.';
    } else {
      act1 = 'Prenez le temps d\'écouter la terre de $appellation, au cœur de $region. C\'est sur ce terroir d\'exception façonné par les millénaires que $producer cultive avec passion $grapes.';
    }

    // Act 2 : Vinification & Patience
    String act2;
    if (isChampagne) {
      act2 = 'En cave, le temps suspend son vol. Après une prise de mousse lente dans l\'obscurité fraîche des crayères, le vin a mûri sur ses lies fines, développant ce crémeux inimitable et cette effervescence d\'orfèvre.';
    } else if (isWhite) {
      act2 = 'Au chai, le respect du raisin est absolu. Pressurage délicat, fermentation maîtrisée et élevage soigné permettent à la pureté cristalline du fruit de s\'exprimer sans fard, révélant toute la noblesse du terroir.';
    } else {
      act2 = 'Ici, rien n\'est précipité. Les baies ont été cueillies à parfaite maturité phénolique, puis élevées avec une infinie patience sous bois pour patiner les tanins tout en préservant l\'éclat vibrant du fruit.';
    }

    // Act 3 : Émotion de la Dégustation
    String act3;
    if (isChampagne) {
      act3 = 'Portez maintenant la coupe à vos lèvres : la bulle caresse le palais, des notes de brioche tiède et d\'agrumes confits s\'élèvent... Un grand moment de fête et d\'émotion partagée vous attend.';
    } else if (isWhite) {
      act3 = 'Dans votre verre, la robe scintille. Le nez dévoile des arômes vivifiants de fleurs blanches et de fruits mûrs, suivis d\'une bouche traçante d\'une longueur saline inoubliable. Bonne dégustation.';
    } else {
      act3 = 'Approchez le calice : une symphonie de fruits noirs mûrs, de velours et d\'épices nobles s\'offre à vous. Laissez ce flacon respirer quelques instants et savourez l\'âme de cette grande bouteille.';
    }

    return SommelierStory(
      title: name,
      subtitle: '$appellation • $vintage',
      act1Terroir: act1,
      act2Vinification: act2,
      act3Degustation: act3,
      estimatedSeconds: 45,
    );
  }
}
