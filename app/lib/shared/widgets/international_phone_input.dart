import 'package:flutter/material.dart';
import '../utils/phone_dial_code.dart';

class InternationalPhoneInput extends StatefulWidget {
  final String? initialValue;
  final ValueChanged<String> onChanged;
  final String? labelText;
  final String? helperText;
  final bool autoDetectGps;
  final FormFieldValidator<String>? validator;

  const InternationalPhoneInput({
    super.key,
    this.initialValue,
    required this.onChanged,
    this.labelText,
    this.helperText,
    this.autoDetectGps = true,
    this.validator,
  });

  @override
  State<InternationalPhoneInput> createState() => _InternationalPhoneInputState();
}

class _InternationalPhoneInputState extends State<InternationalPhoneInput> {
  late CountryDialCode _selectedCountry;
  CountryDialCode? _gpsDetectedCountry;
  final _nationalNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Parse existing number if any
    final (parsedCountry, parsedNumber) = PhoneDialCodeHelper.parseExisting(widget.initialValue);
    _selectedCountry = parsedCountry;
    _nationalNumberController.text = parsedNumber;

    if (widget.autoDetectGps && (widget.initialValue == null || widget.initialValue!.isEmpty)) {
      _detectGpsCountry();
    }
  }

  @override
  void dispose() {
    _nationalNumberController.dispose();
    super.dispose();
  }

  Future<void> _detectGpsCountry() async {
    final detected = await PhoneDialCodeHelper.detectCountryFromGps();
    if (mounted && detected != null) {
      setState(() {
        _gpsDetectedCountry = detected;
        // If user hasn't typed anything yet, pre-select the detected country
        if (_nationalNumberController.text.isEmpty) {
          _selectedCountry = detected;
          _notifyChange();
        }
      });
    }
  }

  void _notifyChange() {
    final raw = _nationalNumberController.text.trim();
    if (raw.isEmpty) {
      widget.onChanged('');
      return;
    }
    final full = PhoneDialCodeHelper.formatInternational(
      dialCode: _selectedCountry.dialCode,
      nationalNumber: raw,
    );
    widget.onChanged(full);
  }

  void _openCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CountryPickerSheet(
        selectedCountry: _selectedCountry,
        gpsDetectedCountry: _gpsDetectedCountry,
        onSelected: (country) {
          setState(() {
            _selectedCountry = country;
            _notifyChange();
          });
          Navigator.of(ctx).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null) ...[
          Row(
            children: [
              Text(
                widget.labelText!,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (_gpsDetectedCountry != null &&
                  _selectedCountry.isoCode == _gpsDetectedCountry!.isoCode &&
                  _selectedCountry.isoCode != 'FR' &&
                  _selectedCountry.isoCode != 'GB') ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, size: 10, color: Colors.blue),
                      const SizedBox(width: 2),
                      Text(
                        'GPS: ${_gpsDetectedCountry!.name}',
                        style: const TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],

        // Input Row with Country Selector Prefix & National Number Field
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
          ),
          child: Row(
            children: [
              // Country Dial Code Button
              InkWell(
                onTap: _openCountryPicker,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                    ),
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedCountry.flag,
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _selectedCountry.dialCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      const Icon(Icons.arrow_drop_down, size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),

              // National Number TextField
              Expanded(
                child: TextFormField(
                  controller: _nationalNumberController,
                  keyboardType: TextInputType.phone,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    hintText: _selectedCountry.example,
                    hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.6), fontSize: 13.5),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                  onChanged: (_) => _notifyChange(),
                  validator: (val) {
                    if (widget.validator != null) {
                      final raw = _nationalNumberController.text.trim();
                      final full = raw.isNotEmpty
                          ? PhoneDialCodeHelper.formatInternational(
                              dialCode: _selectedCountry.dialCode,
                              nationalNumber: raw,
                            )
                          : '';
                      return widget.validator!(full);
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
        ),

        if (widget.helperText != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.helperText!,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey, fontSize: 11),
          ),
        ],
      ],
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  final CountryDialCode selectedCountry;
  final CountryDialCode? gpsDetectedCountry;
  final ValueChanged<CountryDialCode> onSelected;

  const _CountryPickerSheet({
    required this.selectedCountry,
    this.gpsDetectedCountry,
    required this.onSelected,
  });

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final _searchController = TextEditingController();
  List<CountryDialCode> _filtered = PhoneDialCodeHelper.supportedCountries;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = PhoneDialCodeHelper.supportedCountries);
      return;
    }
    setState(() {
      _filtered = PhoneDialCodeHelper.supportedCountries.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.isoCode.toLowerCase().contains(q) ||
            c.dialCode.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Presuggested list:
    // 1. France (FR +33) [Default]
    // 2. UK (GB +44)
    // 3. GPS Detected Country (if different from FR and UK)
    final preSuggested = <CountryDialCode>[
      PhoneDialCodeHelper.defaultCountry,
      PhoneDialCodeHelper.ukCountry,
      if (widget.gpsDetectedCountry != null &&
          widget.gpsDetectedCountry!.isoCode != 'FR' &&
          widget.gpsDetectedCountry!.isoCode != 'GB')
        widget.gpsDetectedCountry!,
    ];

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1A26) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Title
          const Row(
            children: [
              Icon(Icons.public, color: Color(0xFF8B1E3F), size: 22),
              SizedBox(width: 8),
              Text(
                'Choisir l\'indicatif national',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un pays ou un indicatif (+33, Italie...)',
              prefixIcon: const Icon(Icons.search, size: 20),
              isDense: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onChanged: _onSearch,
          ),
          const SizedBox(height: 12),

          // Scrollable List
          Expanded(
            child: ListView(
              children: [
                // PRÉSUGGÉRÉS (FR, UK, GPS)
                if (_searchController.text.isEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Text(
                      'PRÉSUGGÉRÉS (FR, UK & GPS)',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F), letterSpacing: 0.5),
                    ),
                  ),
                  ...preSuggested.map((c) {
                    final isGps = widget.gpsDetectedCountry?.isoCode == c.isoCode && c.isoCode != 'FR' && c.isoCode != 'GB';
                    final isSelected = widget.selectedCountry.isoCode == c.isoCode;

                    return ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      tileColor: isSelected ? const Color(0xFF8B1E3F).withValues(alpha: 0.1) : null,
                      leading: Text(c.flag, style: const TextStyle(fontSize: 22)),
                      title: Row(
                        children: [
                          Text(c.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
                          if (isGps) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('📍 GPS Détecté', style: TextStyle(fontSize: 9, color: Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                      trailing: Text(
                        c.dialCode,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B1E3F)),
                      ),
                      onTap: () => widget.onSelected(c),
                    );
                  }),
                  const Divider(height: 20),
                ],

                // TOUS LES PAYS
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: Text(
                    'TOUS LES PAYS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                  ),
                ),
                ..._filtered.map((c) {
                  final isSelected = widget.selectedCountry.isoCode == c.isoCode;

                  return ListTile(
                    dense: true,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    tileColor: isSelected ? const Color(0xFF8B1E3F).withValues(alpha: 0.08) : null,
                    leading: Text(c.flag, style: const TextStyle(fontSize: 20)),
                    title: Text(c.name, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                    trailing: Text(
                      c.dialCode,
                      style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF8B1E3F) : null),
                    ),
                    onTap: () => widget.onSelected(c),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
