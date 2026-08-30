import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/utils/app_logger.dart';
import '../../auth/data/taste_profile_service.dart';
import '../../auth/domain/taste_profile.dart';
import '../domain/tasting_questionnaire_result.dart';

/// A 4-step paginated bottom sheet for structured post-tasting feedback.
///
/// Adapts to wine type (hides tannins for whites, shows effervescence for sparkling).
/// Supports multi-profile: each selected taster answers in turn.
class TastingQuestionnaireSheet extends ConsumerStatefulWidget {
  final String wineName;
  final int? vintage;
  final String? producer;
  final String? region;
  final String? wineType; // 'red', 'white', 'rose', 'sparkling', etc.
  final List<String>? wineGrapes;

  const TastingQuestionnaireSheet({
    super.key,
    required this.wineName,
    this.vintage,
    this.producer,
    this.region,
    this.wineType,
    this.wineGrapes,
  });

  /// Show the questionnaire as a full-screen modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String wineName,
    int? vintage,
    String? producer,
    String? region,
    String? wineType,
    List<String>? wineGrapes,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) => TastingQuestionnaireSheet(
        wineName: wineName,
        vintage: vintage,
        producer: producer,
        region: region,
        wineType: wineType,
        wineGrapes: wineGrapes,
      ),
    );
  }

  @override
  ConsumerState<TastingQuestionnaireSheet> createState() => _TastingQuestionnaireSheetState();
}

class _TastingQuestionnaireSheetState extends ConsumerState<TastingQuestionnaireSheet> {
  final _pageController = PageController();
  int _currentStep = 0;

  // Profile selection
  List<TasteProfile> _allProfiles = [];
  Set<String> _selectedProfileIds = {};
  bool _profilesLoaded = false;

  // Current answering profile index (for multi-profile flow)
  int _currentProfileIndex = 0;
  List<TasteProfile> _selectedProfiles = [];

  // Step 1: Impression
  int _emojiIndex = 3; // default 😊
  double _noteSlider = 7.0;

  // Step 2: Nez
  Set<String> _selectedAromas = {};
  double _aromaIntensity = 0.5;

  // Step 3: Bouche
  double _acidity = 0.5;
  double _tannins = 0.5;
  double _body = 0.5;
  double _length = 0.5;
  double _effervescence = 0.5;

  // Step 4: Verdict
  String _wouldBuyAgain = 'maybe';
  String _idealMoment = 'repas';
  Set<String> _whatLiked = {};
  Set<String> _whatDisliked = {};

  bool _isSaving = false;

  bool get _isRed => widget.wineType?.toLowerCase() == 'red';
  bool get _isSparkling => widget.wineType?.toLowerCase() == 'sparkling';
  bool get _showTannins => _isRed || widget.wineType == null;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    final service = ref.read(tasteProfileServiceProvider);
    final profiles = await service.getProfiles();
    if (mounted) {
      setState(() {
        _allProfiles = profiles;
        // Pre-select the primary profile
        _selectedProfileIds = {profiles.firstWhere((p) => p.isPrimary, orElse: () => profiles.first).id};
        _profilesLoaded = true;
      });
    }
  }

  void _resetAnswers() {
    _emojiIndex = 3;
    _noteSlider = 7.0;
    _selectedAromas = {};
    _aromaIntensity = 0.5;
    _acidity = 0.5;
    _tannins = 0.5;
    _body = 0.5;
    _length = 0.5;
    _effervescence = 0.5;
    _wouldBuyAgain = 'maybe';
    _idealMoment = 'repas';
    _whatLiked = {};
    _whatDisliked = {};
  }

  void _nextStep() {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      HapticFeedback.selectionClick();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitCurrentProfile() async {
    final profile = _selectedProfiles[_currentProfileIndex];
    final result = TastingQuestionnaireResult(
      emojiImpression: _emojiIndex,
      noteOutOf10: _noteSlider,
      perceivedAromas: Set<String>.from(_selectedAromas),
      aromaIntensity: _aromaIntensity,
      acidity: _acidity,
      tannins: _tannins,
      body: _body,
      length: _length,
      effervescence: _isSparkling ? _effervescence : null,
      wouldBuyAgain: _wouldBuyAgain,
      idealMoment: _idealMoment,
      whatLikedMost: Set<String>.from(_whatLiked),
      whatDislikedMost: Set<String>.from(_whatDisliked),
      profileId: profile.id,
      profileName: profile.name,
    );

    setState(() => _isSaving = true);
    try {
      final service = ref.read(tasteProfileServiceProvider);
      await service.applyQuestionnaireResult(
        result: result,
        wineRegion: widget.region,
        wineGrapes: widget.wineGrapes,
        wineType: widget.wineType,
      );
      AppLogger.info('QUESTIONNAIRE', 'Saved answers for ${profile.name}');
    } catch (e) {
      AppLogger.error('QUESTIONNAIRE', 'Error saving answers', e);
    }

    // Move to next profile or finish
    if (_currentProfileIndex < _selectedProfiles.length - 1) {
      setState(() {
        _currentProfileIndex++;
        _currentStep = 0;
        _isSaving = false;
        _resetAnswers();
      });
      _pageController.jumpToPage(0);
    } else {
      // All done
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text('✨ ', style: TextStyle(fontSize: 18)),
                Expanded(
                  child: Text(
                    _selectedProfiles.length > 1
                        ? 'Profils de ${_selectedProfiles.map((p) => p.name).join(" & ")} enrichis !'
                        : 'Profil de ${_selectedProfiles.first.name} enrichi !',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF8B1E3F),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final vintageStr = widget.vintage != null ? ' ${widget.vintage}' : '';

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1520) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Handle bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header: Wine name + profile selector or current profile indicator
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('🍷', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Questionnaire Dégustation',
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${widget.wineName}$vintageStr',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8B1E3F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _confirmClose(context),
                    ),
                  ],
                ),

                // Profile indicator for multi-profile flow
                if (_selectedProfiles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 16, color: Color(0xFFD4AF37)),
                          const SizedBox(width: 6),
                          Text(
                            'Réponses de ${_selectedProfiles[_currentProfileIndex].name}'
                            '${_selectedProfiles.length > 1 ? " (${_currentProfileIndex + 1}/${_selectedProfiles.length})" : ""}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFFD4AF37),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              children: List.generate(5, (i) {
                final labels = ['Dégustateurs', 'Impression', 'Le Nez', 'La Bouche', 'Verdict'];
                final isActive = i == _currentStep;
                final isDone = i < _currentStep;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < 4 ? 4 : 0),
                    child: Column(
                      children: [
                        Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDone
                                ? const Color(0xFFD4AF37)
                                : isActive
                                    ? const Color(0xFF8B1E3F)
                                    : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive ? const Color(0xFF8B1E3F) : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),

          // Page content
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildProfileSelector(),
                _buildStep1Impression(),
                _buildStep2Nez(),
                _buildStep3Bouche(),
                _buildStep4Verdict(),
              ],
            ),
          ),

          // Navigation buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    OutlinedButton.icon(
                      onPressed: _prevStep,
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Retour'),
                    ),
                  const Spacer(),
                  if (_currentStep == 0)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E3F),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _selectedProfileIds.isEmpty
                          ? null
                          : () {
                              _selectedProfiles = _allProfiles
                                  .where((p) => _selectedProfileIds.contains(p.id))
                                  .toList();
                              _currentProfileIndex = 0;
                              _resetAnswers();
                              _nextStep();
                            },
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: Text('Commencer (${_selectedProfileIds.length})'),
                    ),
                  if (_currentStep > 0 && _currentStep < 4)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B1E3F),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _nextStep,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Suivant'),
                    ),
                  if (_currentStep == 4)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFD4AF37),
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: _isSaving ? null : _submitCurrentProfile,
                      icon: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.check, size: 16),
                      label: Text(
                        _currentProfileIndex < _selectedProfiles.length - 1
                            ? 'Valider → Profil suivant'
                            : 'Valider & Terminer ✨',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Step 0: Profile Selector ("Qui a dégusté ?")
  // ===========================================================================
  Widget _buildProfileSelector() {
    final theme = Theme.of(context);
    if (!_profilesLoaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '👥 Qui a dégusté ce vin ?',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Sélectionnez tous les dégustateurs. Chacun répondra au questionnaire à son tour.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ..._allProfiles.map((profile) {
          final isSelected = _selectedProfileIds.contains(profile.id);
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: isSelected ? const Color(0xFF8B1E3F) : Colors.transparent,
                width: 2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedProfileIds.remove(profile.id);
                  } else {
                    _selectedProfileIds.add(profile.id);
                  }
                });
                HapticFeedback.selectionClick();
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF8B1E3F).withValues(alpha: 0.15)
                            : Colors.grey.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isSelected ? Icons.check_circle : Icons.person_outline,
                        color: isSelected ? const Color(0xFF8B1E3F) : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.name,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          if (profile.questionnairesCompleted > 0)
                            Text(
                              '${profile.questionnairesCompleted} questionnaire${profile.questionnairesCompleted > 1 ? "s" : ""} complété${profile.questionnairesCompleted > 1 ? "s" : ""}',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                            ),
                          if (profile.isPrimary)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Profil principal',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ===========================================================================
  // Step 1: Impression Générale 🎯
  // ===========================================================================
  Widget _buildStep1Impression() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '🎯 Impression Générale',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),

        // Emoji selector
        Text('Votre ressenti global :', style: theme.textTheme.titleSmall),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (i) {
            final isSelected = _emojiIndex == i;
            return GestureDetector(
              onTap: () {
                setState(() => _emojiIndex = i);
                HapticFeedback.selectionClick();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF8B1E3F).withValues(alpha: 0.15)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? const Color(0xFF8B1E3F) : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      TastingQuestionnaireResult.emojiLabels[i],
                      style: TextStyle(fontSize: isSelected ? 36 : 28),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      TastingQuestionnaireResult.emojiDescriptions[i],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFF8B1E3F) : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),

        const SizedBox(height: 32),

        // Note slider
        Text('Note sur 10 :', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('😐', style: TextStyle(fontSize: 20)),
            Expanded(
              child: Slider(
                value: _noteSlider,
                min: 1,
                max: 10,
                divisions: 18,
                activeColor: const Color(0xFF8B1E3F),
                label: _noteSlider.toStringAsFixed(1),
                onChanged: (v) => setState(() => _noteSlider = v),
              ),
            ),
            const Text('🤩', style: TextStyle(fontSize: 20)),
          ],
        ),
        Center(
          child: Text(
            '${_noteSlider.toStringAsFixed(1)} / 10',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF8B1E3F),
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // Step 2: Le Nez (Arômes) 🍇
  // ===========================================================================
  Widget _buildStep2Nez() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '🍇 Le Nez — Arômes',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Quels arômes avez-vous perçus ? (Plusieurs choix possibles)',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 16),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: TastingQuestionnaireResult.aromaOptions.map((aroma) {
            final isSelected = _selectedAromas.contains(aroma.id);
            return FilterChip(
              selected: isSelected,
              label: Text('${aroma.emoji} ${aroma.label}'),
              selectedColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
              checkmarkColor: const Color(0xFF8B1E3F),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _selectedAromas.add(aroma.id);
                  } else {
                    _selectedAromas.remove(aroma.id);
                  }
                });
                HapticFeedback.selectionClick();
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        Text('Intensité aromatique :', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _buildSliderRow(
          leftLabel: '🤫 Discret',
          rightLabel: '💥 Explosif',
          value: _aromaIntensity,
          onChanged: (v) => setState(() => _aromaIntensity = v),
        ),
      ],
    );
  }

  // ===========================================================================
  // Step 3: La Bouche (Équilibre) ⚖️
  // ===========================================================================
  Widget _buildStep3Bouche() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '⚖️ La Bouche — Équilibre',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Décrivez la texture et l\'équilibre du vin en bouche.',
          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
        ),
        const SizedBox(height: 20),

        // Acidité
        Text('Acidité :', style: theme.textTheme.titleSmall),
        _buildSliderRow(
          leftLabel: '🫠 Mou / Plat',
          rightLabel: '⚡ Vif / Tranchant',
          value: _acidity,
          onChanged: (v) => setState(() => _acidity = v),
        ),
        const SizedBox(height: 16),

        // Tanins (only for reds or unknown)
        if (_showTannins) ...[
          Text('Tanins :', style: theme.textTheme.titleSmall),
          _buildSliderRow(
            leftLabel: '🧶 Fondus / Soyeux',
            rightLabel: '💪 Puissants / Astringents',
            value: _tannins,
            onChanged: (v) => setState(() => _tannins = v),
          ),
          const SizedBox(height: 16),
        ],

        // Effervescence (only for sparkling)
        if (_isSparkling) ...[
          Text('Effervescence :', style: theme.textTheme.titleSmall),
          _buildSliderRow(
            leftLabel: '🫧 Fine / Délicate',
            rightLabel: '🎆 Vive / Crémeuse',
            value: _effervescence,
            onChanged: (v) => setState(() => _effervescence = v),
          ),
          const SizedBox(height: 16),
        ],

        // Corps
        Text('Corps / Volume :', style: theme.textTheme.titleSmall),
        _buildSliderRow(
          leftLabel: '🍃 Léger / Aérien',
          rightLabel: '🏋️ Puissant / Charnu',
          value: _body,
          onChanged: (v) => setState(() => _body = v),
        ),
        const SizedBox(height: 16),

        // Longueur
        Text('Longueur en bouche :', style: theme.textTheme.titleSmall),
        _buildSliderRow(
          leftLabel: '⏱️ Courte',
          rightLabel: '♾️ Interminable',
          value: _length,
          onChanged: (v) => setState(() => _length = v),
        ),
      ],
    );
  }

  // ===========================================================================
  // Step 4: Verdict Final ✅
  // ===========================================================================
  Widget _buildStep4Verdict() {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          '✅ Verdict Final',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Would buy again
        Text('Rachèteriez-vous cette bouteille ?', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildChoiceChip('🤩 Absolument !', 'yes', _wouldBuyAgain, (v) => setState(() => _wouldBuyAgain = v)),
            const SizedBox(width: 8),
            _buildChoiceChip('🤔 Peut-être', 'maybe', _wouldBuyAgain, (v) => setState(() => _wouldBuyAgain = v)),
            const SizedBox(width: 8),
            _buildChoiceChip('👎 Non merci', 'no', _wouldBuyAgain, (v) => setState(() => _wouldBuyAgain = v)),
          ],
        ),
        const SizedBox(height: 20),

        // Ideal moment
        Text('Quel moment idéal pour ce vin ?', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildChoiceChip('🥂 Apéro', 'apero', _idealMoment, (v) => setState(() => _idealMoment = v)),
            _buildChoiceChip('🍽️ Repas du quotidien', 'repas', _idealMoment, (v) => setState(() => _idealMoment = v)),
            _buildChoiceChip('🎩 Grand dîner', 'grand_diner', _idealMoment, (v) => setState(() => _idealMoment = v)),
            _buildChoiceChip('🧘 Solo / Méditation', 'solo', _idealMoment, (v) => setState(() => _idealMoment = v)),
          ],
        ),
        const SizedBox(height: 20),

        // What liked most
        Text('Ce que vous avez le plus aimé :', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: TastingQuestionnaireResult.likedOptions.map((opt) {
            final isSelected = _whatLiked.contains(opt.id);
            return FilterChip(
              selected: isSelected,
              label: Text(opt.label, style: const TextStyle(fontSize: 12)),
              selectedColor: const Color(0xFFD4AF37).withValues(alpha: 0.2),
              checkmarkColor: const Color(0xFFD4AF37),
              onSelected: (val) {
                setState(() {
                  if (val) {
                    _whatLiked.add(opt.id);
                  } else {
                    _whatLiked.remove(opt.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        // What disliked
        Text('Ce qui vous a le moins plu :', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: TastingQuestionnaireResult.dislikedOptions.map((opt) {
            final isSelected = _whatDisliked.contains(opt.id);
            return FilterChip(
              selected: isSelected,
              label: Text(opt.label, style: const TextStyle(fontSize: 12)),
              selectedColor: Colors.red.withValues(alpha: 0.15),
              checkmarkColor: Colors.red,
              onSelected: (val) {
                setState(() {
                  if (val) {
                    // If "rien" is selected, clear everything else
                    if (opt.id == 'rien') {
                      _whatDisliked = {'rien'};
                    } else {
                      _whatDisliked.remove('rien');
                      _whatDisliked.add(opt.id);
                    }
                  } else {
                    _whatDisliked.remove(opt.id);
                  }
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  // ===========================================================================
  // Shared widgets
  // ===========================================================================

  Widget _buildSliderRow({
    required String leftLabel,
    required String rightLabel,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(leftLabel, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: const Color(0xFF8B1E3F),
                inactiveTrackColor: const Color(0xFF8B1E3F).withValues(alpha: 0.15),
                thumbColor: const Color(0xFF8B1E3F),
                overlayColor: const Color(0xFF8B1E3F).withValues(alpha: 0.1),
                trackHeight: 5,
              ),
              child: Slider(
                value: value,
                min: 0,
                max: 1,
                divisions: 10,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(rightLabel, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, String value, String currentValue, ValueChanged<String> onChanged) {
    final isSelected = currentValue == value;
    return GestureDetector(
      onTap: () {
        onChanged(value);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF8B1E3F).withValues(alpha: 0.15)
              : Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF8B1E3F) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? const Color(0xFF8B1E3F) : null,
          ),
        ),
      ),
    );
  }

  void _confirmClose(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter le questionnaire ?'),
        content: const Text('Vos réponses ne seront pas sauvegardées.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Continuer'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Quitter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
