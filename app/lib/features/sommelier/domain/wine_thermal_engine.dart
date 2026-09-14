import 'dart:math' as math;
import '../../cellar/domain/wine.dart';

enum ThermalAction {
  putInFridge, // Mettre au frais
  leaveInRoom, // Laisser tempérer dans la pièce
  iceBucket, // Seau à glace (rafraîchissement express)
  alreadyIdeal, // Déjà à température idéale
}

class ThermalPlanResult {
  final ThermalAction action;
  final int durationMinutes;
  final int decantingMinutes;
  final double initialTemp;
  final double targetTemp;
  final double envTemp;
  final String actionTitle;
  final String actionDescription;
  final List<String> timelineSteps;
  final Map<int, double> temperatureCurve; // minute -> projected temp
  final String? warmRoomWarning;

  const ThermalPlanResult({
    required this.action,
    required this.durationMinutes,
    required this.decantingMinutes,
    required this.initialTemp,
    required this.targetTemp,
    required this.envTemp,
    required this.actionTitle,
    required this.actionDescription,
    required this.timelineSteps,
    required this.temperatureCurve,
    this.warmRoomWarning,
  });
}

class WineThermalEngine {
  // Constantes de transfert thermique (loi de Newton pour bouteille 75cl)
  static const double kAirStill = 0.022; // min^-1 en air ambiant ou réfrigérateur
  static const double kIceWater = 0.090; // min^-1 en seau d'eau et glaçons

  // Températures par défaut (statiques mais modifiables par l'utilisateur)
  static const double defaultFridgeTemp = 4.0;
  static const double defaultRoomTemp = 20.0;
  static const double defaultCellarTemp = 12.0;

  /// Détermine la température de service optimale selon le profil du vin.
  static double getIdealServiceTemp(Wine? wine) {
    if (wine == null) return 15.0;

    final nameLower = wine.name.toLowerCase();
    final appellationLower = (wine.appellation ?? '').toLowerCase();
    final typeLower = wine.type.toLowerCase();
    final regionLower = wine.region.toLowerCase();
    final grapesLower = wine.grapes.map((g) => g.name.toLowerCase()).join(' ');

    if (typeLower.contains('champagne') || typeLower.contains('effervescent') || typeLower.contains('sparkling')) {
      return 8.5;
    }

    if (typeLower.contains('blanc') || typeLower.contains('white')) {
      if (nameLower.contains('chablis') || appellationLower.contains('chablis') || regionLower.contains('chablis') || grapesLower.contains('sauvignon') || regionLower.contains('alsace') || nameLower.contains('sancerre')) {
        return 9.5; // Blanc vif & minéral
      }
      return 11.5; // Grand blanc boisé ou riche
    }

    if (typeLower.contains('rosé') || typeLower.contains('rose')) {
      return 9.5;
    }

    if (typeLower.contains('doux') || typeLower.contains('liquoreux') || typeLower.contains('sweet')) {
      return 8.0;
    }

    if (typeLower.contains('rouge') || typeLower.contains('red')) {
      if (grapesLower.contains('pinot') || grapesLower.contains('gamay') || regionLower.contains('beaujolais')) {
        return 14.5; // Rouge léger & croquant
      }
      if (grapesLower.contains('syrah') || grapesLower.contains('cabernet') || regionLower.contains('bordeaux') || regionLower.contains('rhône')) {
        return 16.5; // Grand rouge charpenté
      }
      return 15.5; // Rouge équilibré standard
    }

    return 14.0;
  }

  /// Détermine le temps d'aération/carafage optimal en minutes.
  static int getIdealDecantingMinutes(Wine? wine) {
    if (wine == null) return 0;

    final typeLower = wine.type.toLowerCase();
    final grapesLower = wine.grapes.map((g) => g.name.toLowerCase()).join(' ');
    final vintage = wine.vintage ?? 2020;
    final currentYear = DateTime.now().year;
    final age = currentYear - vintage;

    // Pas de carafage pour les effervescents
    if (typeLower.contains('champagne') || typeLower.contains('effervescent')) {
      return 0;
    }

    // Vins blancs
    if (typeLower.contains('blanc') || typeLower.contains('white')) {
      if (grapesLower.contains('chardonnay') && age <= 5) {
        return 25; // Aération douce pour blanc jeune boisé
      }
      return 0;
    }

    // Vins rouges
    if (typeLower.contains('rouge') || typeLower.contains('red')) {
      // Vins anciens (> 15 ans) : oxygénation délicate, déboucher sans carafage violent
      if (age >= 15) {
        return 15;
      }
      // Vins jeunes puissants (Syrah, Cabernet, Nebbiolo)
      if (grapesLower.contains('syrah') || grapesLower.contains('cabernet') || grapesLower.contains('nebbiolo')) {
        if (age <= 4) return 90; // Vin très jeune et fougueux
        if (age <= 8) return 60; // Pleine force
        return 35;
      }
      // Vins rouges légers (Pinot Noir, Gamay)
      return 20;
    }

    return 0;
  }

  /// Calcule le plan thermique précis basé sur la loi de Newton.
  static ThermalPlanResult calculatePlan({
    required Wine? wine,
    required double initialTemp,
    required double roomTemp,
    required double fridgeTemp,
    bool useIceBucket = false,
  }) {
    final targetTemp = getIdealServiceTemp(wine);
    final decantingMinutes = getIdealDecantingMinutes(wine);

    // Si l'écart est négligeable (< 0.8°C)
    if ((initialTemp - targetTemp).abs() <= 0.8) {
      final curve = <int, double>{0: initialTemp};
      return ThermalPlanResult(
        action: ThermalAction.alreadyIdeal,
        durationMinutes: 0,
        decantingMinutes: decantingMinutes,
        initialTemp: initialTemp,
        targetTemp: targetTemp,
        envTemp: initialTemp,
        actionTitle: 'Température parfaite !',
        actionDescription: 'La bouteille est déjà à sa température idéale de service (${targetTemp.toStringAsFixed(1)}°C).',
        timelineSteps: [
          'Température idéale atteinte (${targetTemp.toStringAsFixed(1)}°C).',
          if (decantingMinutes > 0) 'Déboucher ou carafer $decantingMinutes min avant service.',
          'Dégustez et savourez 🍷 !',
        ],
        temperatureCurve: curve,
      );
    }

    ThermalAction action;
    double envTemp;
    double k = kAirStill;

    if (initialTemp > targetTemp) {
      // Besoin de refroidir
      if (useIceBucket) {
        action = ThermalAction.iceBucket;
        envTemp = 1.0;
        k = kIceWater;
      } else {
        action = ThermalAction.putInFridge;
        envTemp = fridgeTemp;
        k = kAirStill;
      }
    } else {
      // Besoin de réchauffer / chambrer doucement
      action = ThermalAction.leaveInRoom;
      envTemp = roomTemp;
      k = kAirStill;
    }

    // Résolution analytique de t = -1/k * ln((T_target - T_env) / (T_init - T_env))
    final num = (targetTemp - envTemp).abs();
    final den = (initialTemp - envTemp).abs();
    int duration = 0;

    if (den > 0.001 && num > 0.001 && (num / den) < 1.0) {
      final t = - (1.0 / k) * math.log(num / den);
      duration = t.round().clamp(1, 240);
    }

    // Génération de la courbe de température minute par minute (échantillonnée)
    final curve = <int, double>{};
    final stepSize = math.max(1, (duration / 10).round());
    for (int m = 0; m <= duration; m += stepSize) {
      final tempAtM = envTemp + (initialTemp - envTemp) * math.exp(-k * m);
      curve[m] = double.parse(tempAtM.toStringAsFixed(1));
    }
    curve[duration] = targetTemp;

    String actionTitle;
    String actionDesc;
    final timeline = <String>[];

    switch (action) {
      case ThermalAction.putInFridge:
        actionTitle = 'Placer au réfrigérateur';
        actionDesc = 'Glissez la bouteille au frais pendant $duration min pour passer de ${initialTemp.toStringAsFixed(1)}°C à ${targetTemp.toStringAsFixed(1)}°C.';
        timeline.add('Mettre au réfrigérateur ($fridgeTemp°C) pendant $duration minutes.');
        if (decantingMinutes > 0) {
          timeline.add('Sortir et déboucher/carafer $decantingMinutes min avant de servir.');
        } else {
          timeline.add('Sortir et servir immédiatement à ${targetTemp.toStringAsFixed(1)}°C.');
        }
        break;
      case ThermalAction.iceBucket:
        actionTitle = 'Seau à glace express';
        actionDesc = 'Plongez le flacon dans un mélange d\'eau fraîche et de glaçons pendant $duration min.';
        timeline.add('Placer dans le seau à glace pendant $duration minutes.');
        timeline.add('Servir frais à ${targetTemp.toStringAsFixed(1)}°C.');
        break;
      case ThermalAction.leaveInRoom:
        actionTitle = 'Laisser tempérer dans la pièce';
        actionDesc = 'Laissez le vin s\'adoucir à température ambiante ($roomTemp°C) pendant $duration min.';
        timeline.add('Sortir de cave et laisser tempérer dans la pièce pendant $duration minutes.');
        if (decantingMinutes > 0) {
          timeline.add('Carafer pendant les $decantingMinutes dernières minutes pour oxygéner les tanins.');
        }
        break;
      case ThermalAction.alreadyIdeal:
        actionTitle = 'Prêt pour le service';
        actionDesc = 'Température idéale.';
        break;
    }

    final isRed = (wine?.type ?? '').toLowerCase().contains('rouge') || (wine?.type ?? '').toLowerCase().contains('red');
    String? warmRoomWarning;
    if (isRed && roomTemp >= 21.0) {
      if (initialTemp >= 20.0 && action == ThermalAction.putInFridge) {
        actionTitle = 'Coup de frais express pour votre rouge';
        actionDesc = 'Pièce chaude (${roomTemp.toStringAsFixed(0)}°C) : l\'alcool ressort et écrase le fruit. Un passage de $duration min au réfrigérateur rééquilibre la matière.';
      }
      warmRoomWarning = 'Dans une pièce à ${roomTemp.toStringAsFixed(0)}°C, ce vin rouge montera vite au-delà de 18°C. Servez-le légèrement plus frais (${(targetTemp - 1.0).toStringAsFixed(1)}°C) : il s\'ouvrira parfaitement dans le verre sans sensation d\'alcool brûlant.';
    }

    return ThermalPlanResult(
      action: action,
      durationMinutes: duration,
      decantingMinutes: decantingMinutes,
      initialTemp: initialTemp,
      targetTemp: targetTemp,
      envTemp: envTemp,
      actionTitle: actionTitle,
      actionDescription: actionDesc,
      timelineSteps: timeline,
      temperatureCurve: curve,
      warmRoomWarning: warmRoomWarning,
    );
  }
}
