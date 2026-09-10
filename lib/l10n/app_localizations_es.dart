// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsSectionSupport => 'Soporte';

  @override
  String get settingsSectionLegal => 'Legal';

  @override
  String get settingsSectionAbout => 'Acerca de';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsContact => 'Contáctanos';

  @override
  String get settingsContactSubtitle => 'Preguntas o comentarios';

  @override
  String get settingsRate => 'Valóranos';

  @override
  String settingsRateSubtitle(String appName) {
    return '¿Te gusta $appName? Déjanos una reseña';
  }

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsTermsOfService => 'Términos del servicio';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsArchitecture => 'Arquitectura del dispositivo';

  @override
  String get settingsArchitectureSubtitle => 'Compatibilidad de apps';

  @override
  String get settingsBits64 => '64 bits';

  @override
  String get settingsBits32 => '32 bits';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'ABIs compatibles';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Aún no publicado';

  @override
  String get settingsNotListedYet => 'Aún no está en la tienda';

  @override
  String get settingsNotSetUpYet => 'Aún no configurado';

  @override
  String get commonUnavailable => 'no disponible';

  @override
  String get appearanceTitle => 'Apariencia';

  @override
  String get appearancePreview => 'Vista previa';

  @override
  String get appearanceChooseTheme => 'Elige un tema';

  @override
  String get appearanceSystem => 'Predeterminado del sistema';

  @override
  String get appearanceSystemSubtitle => 'Seguir los ajustes del dispositivo';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceLightSubtitle => 'Usar siempre el tema claro';

  @override
  String get appearanceDark => 'Oscuro';

  @override
  String get appearanceDarkSubtitle => 'Usar siempre el tema oscuro';

  @override
  String appearanceInstantNote(String appName) {
    return 'Los cambios de tema se aplican al instante en todo $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Vista previa del tema $theme';
  }

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSearchHint => 'Buscar idiomas';

  @override
  String get languageClearSearch => 'Borrar búsqueda';

  @override
  String languageNote(String appName) {
    return 'Elige el idioma que se usa en $appName.';
  }

  @override
  String get languageSectionHeader => 'Idioma';

  @override
  String get languageSystem => 'Predeterminado del sistema';

  @override
  String get languageSystemSubtitle => 'Usar el idioma del dispositivo';

  @override
  String get languageInstantNote =>
      'Los cambios de idioma se aplican de inmediato.';

  @override
  String languageNoMatches(String query) {
    return 'Ningún idioma coincide con «$query».';
  }

  @override
  String get contactTitle => 'Contáctanos';

  @override
  String get contactHeroTitle => '¿Cómo podemos ayudarte?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Elige cómo prefieres contactar con el equipo de $appName.';
  }

  @override
  String get contactSectionOptions => 'Opciones de contacto';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Chatea con nuestro equipo de soporte';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Escríbenos por Telegram';

  @override
  String get contactEmail => 'Correo electrónico';

  @override
  String get contactEmailSubtitle => 'Envíanos un correo';

  @override
  String get contactResponseTime => 'Tiempo de respuesta';

  @override
  String get contactResponseTimeValue =>
      'Normalmente respondemos en 1–2 días laborables.';

  @override
  String get contactPrivacyNote =>
      'Solo usaremos tu mensaje para brindarte soporte.';

  @override
  String contactNoMailApp(String email) {
    return 'No se pudo abrir ninguna app de correo. Escribe a $email en su lugar.';
  }

  @override
  String get contactWhatsAppFailed => 'No se pudo abrir WhatsApp.';

  @override
  String get contactTelegramFailed => 'No se pudo abrir Telegram.';

  @override
  String get contactPlayStoreFailed => 'No se pudo abrir Play Store.';

  @override
  String contactLegalOpenFailed(String document) {
    return 'No se pudo abrir $document.';
  }
}
