import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../domain/blind_battle_models.dart';
import '../data/blind_battle_service.dart';

class BlindBattleGuestScreen extends StatefulWidget {
  final String? initialSessionId;

  const BlindBattleGuestScreen({super.key, this.initialSessionId});

  @override
  State<BlindBattleGuestScreen> createState() => _BlindBattleGuestScreenState();
}

class _BlindBattleGuestScreenState extends State<BlindBattleGuestScreen> {
  late TextEditingController _sessionCtrl;
  final TextEditingController _pseudoCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _grapeCtrl = TextEditingController();
  final TextEditingController _regionCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  int _step = 0; // 0: Onboarding, 1: Robe, 2: Nez & Arômes, 3: Bouche, 4: Grand Pari, 5: Résultat / Podium
  String? _participantId;
  BlindBattleSession? _session;

  // Formulaire de dégustation
  String _color = 'Rouge';
  final Set<String> _selectedAromaIds = {};
  String _sweetness = 'Sec';
  String _acidity = 'Équilibrée';
  String _tannins = 'Soyeux / Fondus';
  double _caudalies = 6.0;
  int _vintage = 2018;
  bool _includeVintage = true;

  @override
  void initState() {
    super.initState();
    _sessionCtrl = TextEditingController(text: widget.initialSessionId ?? '');
  }

  @override
  void dispose() {
    _sessionCtrl.dispose();
    _pseudoCtrl.dispose();
    _emailCtrl.dispose();
    _grapeCtrl.dispose();
    _regionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _launchStoreUrl(String store) async {
    final String url;
    if (store == 'play') {
      url = 'https://play.google.com/store/apps/details?id=com.chatmelier.app';
    } else {
      url = 'https://apps.apple.com/app/chatmelier/id6741234567';
    }
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _joinSession() {
    final pseudo = _pseudoCtrl.text.trim();
    final sessionCode = _sessionCtrl.text.trim().toUpperCase();

    if (pseudo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Veuillez renseigner un pseudo pour participer à la dégustation.'),
        ),
      );
      return;
    }

    if (sessionCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Veuillez renseigner le code de la table (ex: CHAT-408).'),
        ),
      );
      return;
    }

    final participant = BlindBattleManager.joinSession(
      sessionId: sessionCode,
      pseudo: pseudo,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
    );

    final session = BlindBattleManager.getSession(sessionCode);

    setState(() {
      _participantId = participant?.id;
      _session = session;
      _step = 1; // Passe à l'étape 1 (Robe)
    });
  }

  void _submitGuess() {
    if (_session == null || _participantId == null) return;

    final guess = BlindGuess(
      color: _color,
      selectedAromaIds: _selectedAromaIds.toList(),
      sweetness: _sweetness,
      acidity: _acidity,
      tannins: _tannins,
      caudaliesSeconds: _caudalies.round(),
      grape: _grapeCtrl.text.trim(),
      region: _regionCtrl.text.trim(),
      vintage: _includeVintage ? _vintage : null,
      personalNote: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
    );

    BlindBattleManager.submitGuess(
      sessionId: _session!.id,
      participantId: _participantId!,
      guess: guess,
    );

    final updated = BlindBattleManager.getSession(_session!.id);
    setState(() {
      _session = updated;
      _step = 5; // Écran d'attente / Podium
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140F1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1424),
        title: Row(
          children: [
            Image.asset('assets/images/logo_transparent_64.png', height: 26, errorBuilder: (c, o, s) => const Icon(Icons.wine_bar, color: Color(0xFFD4AF37))),
            const SizedBox(width: 8),
            const Text(
              'Blind Battle Invité',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Bandeau de téléchargement store en haut
            _buildStoreDownloadBanner(),
            // Contenu principal selon l'étape
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildCurrentStepContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreDownloadBanner() {
    final isIos = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF23162C),
        border: Border(bottom: BorderSide(color: Color(0xFFD4AF37), width: 0.8)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wine_bar_rounded, color: Color(0xFFD4AF37), size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Tu aimes l\'expérience ? Télécharge l\'application Chatmelier :',
              style: TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          if (isIos || kIsWeb)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _launchStoreUrl('apple'),
              child: const Text('App Store', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          if (isAndroid || kIsWeb)
            TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => _launchStoreUrl('play'),
              child: const Text('Google Play', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_step) {
      case 0:
        return _buildStep0Onboarding();
      case 1:
        return _buildStep1Color();
      case 2:
        return _buildStep2Aromas();
      case 3:
        return _buildStep3Palate();
      case 4:
        return _buildStep4GrandGuess();
      case 5:
      default:
        return _buildStep5Podium();
    }
  }

  // STEP 0: ONBOARDING INVITÉ
  Widget _buildStep0Onboarding() {
    return ListView(
      key: const ValueKey('step0'),
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 10),
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B1E3F).withOpacity(0.25),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
            ),
            child: const Icon(Icons.sports_esports_rounded, color: Color(0xFFD4AF37), size: 48),
          ),
        ),
        const SizedBox(height: 18),
        const Center(
          child: Text(
            'Bienvenue dans la Dégustation !',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Rejoignez la table de votre hôte et faites parler vos sens.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ),
        const SizedBox(height: 28),

        // Code session
        TextField(
          controller: _sessionCtrl,
          style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, letterSpacing: 2),
          decoration: InputDecoration(
            labelText: 'Code de la table *',
            hintText: 'Ex: CHAT-408',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.qr_code_2_rounded, color: Color(0xFFD4AF37)),
            filled: true,
            fillColor: const Color(0xFF1F1626),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),

        // Pseudo obligatoire
        TextField(
          controller: _pseudoCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Votre pseudo / prénom * (Obligatoire)',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.person_outline_rounded, color: Color(0xFFD4AF37)),
            filled: true,
            fillColor: const Color(0xFF1F1626),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 16),

        // Email facultatif
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Adresse email (Facultatif - pour recevoir la fiche)',
            labelStyle: const TextStyle(color: Colors.white60),
            prefixIcon: const Icon(Icons.email_outlined, color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1F1626),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 28),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B1E3F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            onPressed: _joinSession,
            child: const Text('Rejoindre la table 🍷', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  // STEP 1: ROBE
  Widget _buildStep1Color() {
    final colors = [
      {'name': 'Rouge', 'emoji': '🍷', 'desc': 'Rubis, pourpre, grenat ou tuilé'},
      {'name': 'Blanc', 'emoji': '🥂', 'desc': 'Or pâle, doré, reflets verts ou ambré'},
      {'name': 'Rosé', 'emoji': '🌸', 'desc': 'Pétale de rose, saumon ou corail'},
      {'name': 'Effervescent', 'emoji': '🍾', 'desc': 'Bulles fines, champagne, crémant'},
    ];

    return ListView(
      key: const ValueKey('step1'),
      padding: const EdgeInsets.all(20),
      children: [
        _buildProgressBar(1, 4),
        const SizedBox(height: 16),
        const Text('Étape 1/4 : La Robe', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Quelle est la robe du vin dans votre verre ?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        ...colors.map((c) {
          final isSelected = _color == c['name'];
          return InkWell(
            onTap: () => setState(() => _color = c['name']!),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF8B1E3F).withOpacity(0.4) : const Color(0xFF1E1726),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? const Color(0xFFD4AF37) : Colors.white12,
                  width: isSelected ? 1.8 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(c['emoji']!, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['name']!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(c['desc']!, style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ],
                    ),
                  ),
                  if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFFD4AF37)),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B1E3F),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => setState(() => _step = 2),
          child: const Text('Passer au Nez 👃', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  // STEP 2: NEZ & ARÔMES
  Widget _buildStep2Aromas() {
    final categories = <String, List<BlindAromaItem>>{};
    for (final item in BlindAromaCatalog.allAromas) {
      categories.putIfAbsent(item.category, () => []).add(item);
    }

    return ListView(
      key: const ValueKey('step2'),
      padding: const EdgeInsets.all(20),
      children: [
        _buildProgressBar(2, 4),
        const SizedBox(height: 16),
        const Text('Étape 2/4 : Le Nez & les Arômes', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Quelles notes décelez-vous au nez ?', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Sélectionnez toutes les fragrances perçues (${_selectedAromaIds.length} retenues)', style: const TextStyle(color: Colors.white60, fontSize: 12)),
        const SizedBox(height: 18),
        ...categories.entries.map((cat) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                cat.key.toUpperCase(),
                style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: cat.value.map((aroma) {
                  final isSel = _selectedAromaIds.contains(aroma.id);
                  return FilterChip(
                    backgroundColor: const Color(0xFF1E1726),
                    selectedColor: const Color(0xFF8B1E3F),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : Colors.white70,
                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    label: Text('${aroma.emoji} ${aroma.label}'),
                    selected: isSel,
                    onSelected: (val) {
                      setState(() {
                        if (val) {
                          _selectedAromaIds.add(aroma.id);
                        } else {
                          _selectedAromaIds.remove(aroma.id);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        }),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                onPressed: () => setState(() => _step = 1),
                child: const Text('Retour', style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                onPressed: () => setState(() => _step = 3),
                child: const Text('Passer en Bouche 👅', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 3: BOUCHE & CAUDALIES
  Widget _buildStep3Palate() {
    return ListView(
      key: const ValueKey('step3'),
      padding: const EdgeInsets.all(20),
      children: [
        _buildProgressBar(3, 4),
        const SizedBox(height: 16),
        const Text('Étape 3/4 : En Bouche', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Structure, fraîcheur et tanins', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 18),

        // Douceur / Sucre
        _buildSegmentTitle('Niveau de sucrosité'),
        _buildChoiceRow(['Sec', 'Demi-sec', 'Moelleux', 'Liquoreux'], _sweetness, (v) => setState(() => _sweetness = v)),
        const SizedBox(height: 16),

        // Acidité
        _buildSegmentTitle('Tension & Acidité'),
        _buildChoiceRow(['Basse', 'Équilibrée', 'Tranchante / Vive'], _acidity, (v) => setState(() => _acidity = v)),
        const SizedBox(height: 16),

        // Tanins
        _buildSegmentTitle('Structure des Tanins'),
        _buildChoiceRow(['Nuls (Blanc/Rosé)', 'Soyeux / Fondus', 'Puissants / Serrés'], _tannins, (v) => setState(() => _tannins = v)),
        const SizedBox(height: 18),

        // Caudalies (longueur)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSegmentTitle('Caudalies (Persistance en bouche)'),
            Text('${_caudalies.round()} secondes', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: _caudalies,
          min: 2.0,
          max: 15.0,
          divisions: 13,
          activeColor: const Color(0xFFD4AF37),
          inactiveColor: Colors.white12,
          onChanged: (v) => setState(() => _caudalies = v),
        ),
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                onPressed: () => setState(() => _step = 2),
                child: const Text('Retour', style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                onPressed: () => setState(() => _step = 4),
                child: const Text('Le Grand Pari 🎯', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 4: GRAND PARI (CÉPAGE, RÉGION, MILLÉSIME)
  Widget _buildStep4GrandGuess() {
    return ListView(
      key: const ValueKey('step4'),
      padding: const EdgeInsets.all(20),
      children: [
        _buildProgressBar(4, 4),
        const SizedBox(height: 16),
        const Text('Étape 4/4 : Le Grand Pari', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        const Text('Devinez l\'origine secrète du vin', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),

        // Cépage
        TextField(
          controller: _grapeCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Cépage principal',
            hintText: 'Ex: Pinot Noir, Syrah, Chardonnay...',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.grass_rounded, color: Color(0xFFD4AF37)),
            filled: true,
            fillColor: const Color(0xFF1F1626),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 14),

        // Région / Appellation
        TextField(
          controller: _regionCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Région ou Appellation',
            hintText: 'Ex: Bordeaux, Bourgogne, Vallée du Rhône...',
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: const Icon(Icons.place_outlined, color: Color(0xFFD4AF37)),
            filled: true,
            fillColor: const Color(0xFF1F1626),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 14),

        // Millésime
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: const Color(0xFFD4AF37),
          title: const Text('Deviner le Millésime', style: TextStyle(color: Colors.white, fontSize: 14)),
          value: _includeVintage,
          onChanged: (v) => setState(() => _includeVintage = v ?? true),
        ),
        if (_includeVintage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Année estimée :', style: TextStyle(color: Colors.white70, fontSize: 13)),
              Text('$_vintage', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          Slider(
            value: _vintage.toDouble(),
            min: 1990,
            max: DateTime.now().year.toDouble(),
            divisions: DateTime.now().year - 1990,
            activeColor: const Color(0xFF8B1E3F),
            inactiveColor: Colors.white12,
            onChanged: (v) => setState(() => _vintage = v.round()),
          ),
        ],
        const SizedBox(height: 14),

        // Notes libres
        TextField(
          controller: _notesCtrl,
          maxLines: 2,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Votre impression de dégustation (optionnel)',
            labelStyle: const TextStyle(color: Colors.white60),
            prefixIcon: const Icon(Icons.edit_note_rounded, color: Colors.white38),
            filled: true,
            fillColor: const Color(0xFF1F1626),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                onPressed: () => setState(() => _step = 3),
                child: const Text('Retour', style: TextStyle(color: Colors.white70)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD4AF37),
                  foregroundColor: const Color(0xFF140F1A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _submitGuess,
                child: const Text('Valider mon Pronostic 🍷', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // STEP 5: PODIUM & RÉSULTATS
  Widget _buildStep5Podium() {
    final session = _session;
    if (session == null) {
      return const Center(child: Text('Session introuvable', style: TextStyle(color: Colors.white)));
    }

    final myParticipant = session.participants.firstWhere(
      (p) => p.id == _participantId,
      orElse: () => session.participants.first,
    );
    final breakdown = myParticipant.scoreBreakdown;
    final isRevealed = session.status == BlindSessionStatus.revealed;

    return RefreshIndicator(
      onRefresh: () async {
        final updated = BlindBattleManager.getSession(session.id);
        if (updated != null) setState(() => _session = updated);
      },
      color: const Color(0xFFD4AF37),
      child: ListView(
        key: const ValueKey('step5'),
        padding: const EdgeInsets.all(20),
        children: [
          // Carte Félicitations & Score Personnel
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF321D38), Color(0xFF181020)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
            ),
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 44),
                const SizedBox(height: 10),
                Text(
                  'Pronostic Enregistré, ${myParticipant.pseudo} !',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isRevealed ? 'La bouteille est révélée !' : 'En attente de la révélation finale par l\'hôte...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: isRevealed ? const Color(0xFFD4AF37) : Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B1E3F),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Score obtenu : ${myParticipant.totalScore} / 140 pts',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Détail du verdict sommelier
          if (breakdown != null) ...[
            const Text(
              'Détail de votre analyse sensorielle :',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 10),
            ...breakdown.feedbackItems.map((fb) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1626),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(fb, style: const TextStyle(color: Colors.white, fontSize: 13)),
              );
            }),
            const SizedBox(height: 20),
          ],

          // Carte téléchargement de l'appli complète
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF22162A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                const Text(
                  'Installe Chatmelier pour gérer ta propre cave !',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Accords mets-vins, IA sommelier, analyse de cartes de restaurant et suivi de cave.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B1E3F)),
                        icon: const Icon(Icons.shop_outlined, size: 16),
                        label: const Text('Google Play', style: TextStyle(fontSize: 12)),
                        onPressed: () => _launchStoreUrl('play'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1E1A24), side: const BorderSide(color: Color(0xFFD4AF37))),
                        icon: const Icon(Icons.apple, size: 16),
                        label: const Text('App Store', style: TextStyle(fontSize: 12, color: Color(0xFFD4AF37))),
                        onPressed: () => _launchStoreUrl('apple'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(int current, int total) {
    return LinearProgressIndicator(
      value: current / total,
      backgroundColor: Colors.white12,
      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD4AF37)),
      minHeight: 4,
    );
  }

  Widget _buildSegmentTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildChoiceRow(List<String> options, String current, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSel = opt == current;
        return InkWell(
          onTap: () => onSelect(opt),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? const Color(0xFF8B1E3F) : const Color(0xFF1E1726),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSel ? const Color(0xFFD4AF37) : Colors.white12),
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isSel ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
