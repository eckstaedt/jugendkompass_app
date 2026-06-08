import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:jugendkompass_app/core/config/design_tokens.dart';
import 'package:jugendkompass_app/core/utils/snackbar_utils.dart';
import 'package:jugendkompass_app/domain/providers/string_translator_provider.dart';
import 'package:jugendkompass_app/domain/providers/supabase_provider.dart';

class SubscriptionFormScreen extends ConsumerStatefulWidget {
  const SubscriptionFormScreen({super.key});

  @override
  ConsumerState<SubscriptionFormScreen> createState() =>
      _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState
    extends ConsumerState<SubscriptionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController(text: 'Deutschland');
  final _addressExtraCtrl = TextEditingController();

  String _shippingMethod = 'standard'; // 'standard' | 'pickup'
  bool _isSubmitting = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _postalCodeCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _addressExtraCtrl.dispose();
    super.dispose();
  }

  String? _required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ist ein Pflichtfeld';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'E-Mail ist ein Pflichtfeld';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Bitte eine gültige E-Mail eingeben';
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final supabase = ref.read(supabaseProvider);

      await supabase.from('subscriptions').insert({
        'first_name': _firstNameCtrl.text.trim(),
        'last_name': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'street': _streetCtrl.text.trim(),
        'postal_code': _postalCodeCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'country': _countryCtrl.text.trim(),
        'address_extra': _addressExtraCtrl.text.trim().isEmpty
            ? null
            : _addressExtraCtrl.text.trim(),
        'shipping_method': _shippingMethod,
      });

      if (mounted) {
        // Pop form and show success on ShopScreen
        Navigator.pop(context);
        SnackBarUtils.showSuccess(
          context,
          'Bestellung erfolgreich! Du erhältst das Heft bald. 🎉',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Fehler beim Absenden. Bitte versuche es erneut.',
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final translate = ref.watch(stringTranslatorProvider);

    final inputDecoration = InputDecoration(
      filled: true,
      fillColor: DesignTokens.getGlassBackground(brightness, 0.18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
        borderSide: BorderSide(
          color: brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
        borderSide: BorderSide(
          color: brightness == Brightness.dark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.black.withValues(alpha: 0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
        borderSide: BorderSide(color: DesignTokens.primaryRed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(DesignTokens.radiusMiddleContainers),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 8),
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: DesignTokens.primaryRed,
              letterSpacing: 0.8,
            ),
          ),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(translate('Heft bestellen')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.only(
            left: DesignTokens.paddingHorizontal,
            right: DesignTokens.paddingHorizontal,
            top: 8,
            bottom: DesignTokens.overlayPaddingBase + 24,
          ),
          children: [
            // ── Persönliche Daten ────────────────────────────────────
            sectionTitle('PERSÖNLICHE DATEN'),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _firstNameCtrl,
                    decoration: inputDecoration.copyWith(labelText: 'Vorname *'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => _required(v, 'Vorname'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lastNameCtrl,
                    decoration: inputDecoration.copyWith(labelText: 'Nachname *'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => _required(v, 'Nachname'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _emailCtrl,
              decoration: inputDecoration.copyWith(
                labelText: 'E-Mail *',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: _validateEmail,
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _phoneCtrl,
              decoration: inputDecoration.copyWith(
                labelText: 'Telefon (optional)',
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),

            // ── Lieferadresse ────────────────────────────────────────
            sectionTitle('LIEFERADRESSE'),

            TextFormField(
              controller: _streetCtrl,
              decoration: inputDecoration.copyWith(
                labelText: 'Straße & Hausnummer *',
                prefixIcon: const Icon(Icons.location_on_outlined),
              ),
              validator: (v) => _required(v, 'Straße & Hausnummer'),
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _addressExtraCtrl,
              decoration: inputDecoration.copyWith(
                labelText: 'Adresszusatz (optional)',
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _postalCodeCtrl,
                    decoration: inputDecoration.copyWith(labelText: 'PLZ *'),
                    keyboardType: TextInputType.number,
                    validator: (v) => _required(v, 'PLZ'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cityCtrl,
                    decoration: inputDecoration.copyWith(labelText: 'Ort *'),
                    textCapitalization: TextCapitalization.words,
                    validator: (v) => _required(v, 'Ort'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _countryCtrl,
              decoration: inputDecoration.copyWith(
                labelText: 'Land *',
                prefixIcon: const Icon(Icons.flag_outlined),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, 'Land'),
            ),

            // ── Versandart ───────────────────────────────────────────
            sectionTitle('VERSANDART'),

            _ShippingMethodSelector(
              selected: _shippingMethod,
              onChanged: (val) => setState(() => _shippingMethod = val),
              brightness: brightness,
            ),

            const SizedBox(height: 32),

            // ── Submit Button ────────────────────────────────────────
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: DesignTokens.primaryRed,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      DesignTokens.primaryRed.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.radiusButtons),
                  ),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSubmitting ? 'Wird gesendet...' : 'Bestellung aufgeben',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Text(
              '* Pflichtfelder. Deine Daten werden nur für den Versand verwendet.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: DesignTokens.getTextSecondary(brightness),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Versandart-Selector ──────────────────────────────────────────────────────

class _ShippingMethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  final Brightness brightness;

  const _ShippingMethodSelector({
    required this.selected,
    required this.onChanged,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ShippingOption(
          value: 'standard',
          selected: selected,
          icon: Icons.local_shipping_outlined,
          title: 'Standardversand',
          subtitle: 'Kostenlos per Post zu dir nach Hause',
          onChanged: onChanged,
          brightness: brightness,
        ),
        const SizedBox(height: 10),
        _ShippingOption(
          value: 'pickup',
          selected: selected,
          icon: Icons.store_outlined,
          title: 'Selbstabholung',
          subtitle: 'Abholung vor Ort',
          onChanged: onChanged,
          brightness: brightness,
        ),
      ],
    );
  }
}

class _ShippingOption extends StatelessWidget {
  final String value;
  final String selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final ValueChanged<String> onChanged;
  final Brightness brightness;

  const _ShippingOption({
    required this.value,
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onChanged,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? DesignTokens.primaryRed.withValues(alpha: 0.08)
              : DesignTokens.getGlassBackground(brightness, 0.18),
          borderRadius:
              BorderRadius.circular(DesignTokens.radiusMiddleContainers),
          border: Border.all(
            color: isSelected
                ? DesignTokens.primaryRed
                : (brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.12)
                    : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color:
                  isSelected ? DesignTokens.primaryRed : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isSelected ? DesignTokens.primaryRed : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: DesignTokens.getTextSecondary(brightness),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected
                  ? DesignTokens.primaryRed
                  : DesignTokens.getTextSecondary(brightness),
            ),
          ],
        ),
      ),
    );
  }
}
