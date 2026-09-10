// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsSectionSupport => 'Suporte';

  @override
  String get settingsSectionLegal => 'Jurídico';

  @override
  String get settingsSectionAbout => 'Sobre';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsContact => 'Fale com a gente';

  @override
  String get settingsContactSubtitle => 'Dúvidas ou comentários';

  @override
  String get settingsRate => 'Avalie o app';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Gostando do $appName? Deixe uma avaliação';
  }

  @override
  String get settingsPrivacyPolicy => 'Política de Privacidade';

  @override
  String get settingsTermsOfService => 'Termos de Serviço';

  @override
  String get settingsVersion => 'Versão';

  @override
  String get settingsArchitecture => 'Arquitetura do dispositivo';

  @override
  String get settingsArchitectureSubtitle => 'Compatibilidade de apps';

  @override
  String get settingsBits64 => '64 bits';

  @override
  String get settingsBits32 => '32 bits';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'ABIs compatíveis';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Ainda não publicado';

  @override
  String get settingsNotListedYet => 'Ainda não está na loja';

  @override
  String get settingsNotSetUpYet => 'Ainda não configurado';

  @override
  String get commonUnavailable => 'indisponível';

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get appearancePreview => 'Prévia';

  @override
  String get appearanceChooseTheme => 'Escolha um tema';

  @override
  String get appearanceSystem => 'Padrão do sistema';

  @override
  String get appearanceSystemSubtitle =>
      'Seguir as configurações do dispositivo';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceLightSubtitle => 'Sempre usar o tema claro';

  @override
  String get appearanceDark => 'Escuro';

  @override
  String get appearanceDarkSubtitle => 'Sempre usar o tema escuro';

  @override
  String appearanceInstantNote(String appName) {
    return 'As mudanças de tema valem na hora em todo o $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Prévia do tema $theme';
  }

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSearchHint => 'Buscar idiomas';

  @override
  String get languageClearSearch => 'Limpar busca';

  @override
  String languageNote(String appName) {
    return 'Escolha o idioma usado no $appName.';
  }

  @override
  String get languageSectionHeader => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get languageSystemSubtitle => 'Usar o idioma do dispositivo';

  @override
  String get languageInstantNote => 'As mudanças de idioma valem na hora.';

  @override
  String languageNoMatches(String query) {
    return 'Nenhum idioma corresponde a “$query”.';
  }

  @override
  String get contactTitle => 'Fale com a gente';

  @override
  String get contactHeroTitle => 'Como podemos ajudar?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Escolha como prefere falar com a equipe do $appName.';
  }

  @override
  String get contactSectionOptions => 'Formas de contato';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Converse com nosso suporte';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Fale com a gente no Telegram';

  @override
  String get contactEmail => 'E-mail';

  @override
  String get contactEmailSubtitle => 'Envie um e-mail';

  @override
  String get contactResponseTime => 'Tempo de resposta';

  @override
  String get contactResponseTimeValue =>
      'Normalmente respondemos em 1–2 dias úteis.';

  @override
  String get contactPrivacyNote =>
      'Usaremos sua mensagem apenas para dar suporte.';

  @override
  String contactNoMailApp(String email) {
    return 'Nenhum app de e-mail pôde ser aberto. Escreva para $email.';
  }

  @override
  String get contactWhatsAppFailed => 'Não foi possível abrir o WhatsApp.';

  @override
  String get contactTelegramFailed => 'Não foi possível abrir o Telegram.';

  @override
  String get contactPlayStoreFailed => 'Não foi possível abrir a Play Store.';

  @override
  String contactLegalOpenFailed(String document) {
    return 'Não foi possível abrir $document.';
  }
}

/// The translations for Portuguese, as used in Brazil (`pt_BR`).
class AppLocalizationsPtBr extends AppLocalizationsPt {
  AppLocalizationsPtBr() : super('pt_BR');

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get settingsSectionSupport => 'Suporte';

  @override
  String get settingsSectionLegal => 'Jurídico';

  @override
  String get settingsSectionAbout => 'Sobre';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsAppearance => 'Aparência';

  @override
  String get settingsContact => 'Fale com a gente';

  @override
  String get settingsContactSubtitle => 'Dúvidas ou comentários';

  @override
  String get settingsRate => 'Avalie o app';

  @override
  String settingsRateSubtitle(String appName) {
    return 'Gostando do $appName? Deixe uma avaliação';
  }

  @override
  String get settingsPrivacyPolicy => 'Política de Privacidade';

  @override
  String get settingsTermsOfService => 'Termos de Serviço';

  @override
  String get settingsVersion => 'Versão';

  @override
  String get settingsArchitecture => 'Arquitetura do dispositivo';

  @override
  String get settingsArchitectureSubtitle => 'Compatibilidade de apps';

  @override
  String get settingsBits64 => '64 bits';

  @override
  String get settingsBits32 => '32 bits';

  @override
  String settingsArchitectureValue(String width, String abi) {
    return '$width · $abi';
  }

  @override
  String get settingsSupportedAbis => 'ABIs compatíveis';

  @override
  String settingsCopyright(int year, String appName) {
    return '© $year $appName';
  }

  @override
  String get settingsNotPublishedYet => 'Ainda não publicado';

  @override
  String get settingsNotListedYet => 'Ainda não está na loja';

  @override
  String get settingsNotSetUpYet => 'Ainda não configurado';

  @override
  String get commonUnavailable => 'indisponível';

  @override
  String get appearanceTitle => 'Aparência';

  @override
  String get appearancePreview => 'Prévia';

  @override
  String get appearanceChooseTheme => 'Escolha um tema';

  @override
  String get appearanceSystem => 'Padrão do sistema';

  @override
  String get appearanceSystemSubtitle =>
      'Seguir as configurações do dispositivo';

  @override
  String get appearanceLight => 'Claro';

  @override
  String get appearanceLightSubtitle => 'Sempre usar o tema claro';

  @override
  String get appearanceDark => 'Escuro';

  @override
  String get appearanceDarkSubtitle => 'Sempre usar o tema escuro';

  @override
  String appearanceInstantNote(String appName) {
    return 'As mudanças de tema valem na hora em todo o $appName.';
  }

  @override
  String appearancePreviewLabel(String theme) {
    return 'Prévia do tema $theme';
  }

  @override
  String get languageTitle => 'Idioma';

  @override
  String get languageSearchHint => 'Buscar idiomas';

  @override
  String get languageClearSearch => 'Limpar busca';

  @override
  String languageNote(String appName) {
    return 'Escolha o idioma usado no $appName.';
  }

  @override
  String get languageSectionHeader => 'Idioma';

  @override
  String get languageSystem => 'Padrão do sistema';

  @override
  String get languageSystemSubtitle => 'Usar o idioma do dispositivo';

  @override
  String get languageInstantNote => 'As mudanças de idioma valem na hora.';

  @override
  String languageNoMatches(String query) {
    return 'Nenhum idioma corresponde a “$query”.';
  }

  @override
  String get contactTitle => 'Fale com a gente';

  @override
  String get contactHeroTitle => 'Como podemos ajudar?';

  @override
  String contactHeroSubtitle(String appName) {
    return 'Escolha como prefere falar com a equipe do $appName.';
  }

  @override
  String get contactSectionOptions => 'Formas de contato';

  @override
  String get contactWhatsApp => 'WhatsApp';

  @override
  String get contactWhatsAppSubtitle => 'Converse com nosso suporte';

  @override
  String get contactTelegram => 'Telegram';

  @override
  String get contactTelegramSubtitle => 'Fale com a gente no Telegram';

  @override
  String get contactEmail => 'E-mail';

  @override
  String get contactEmailSubtitle => 'Envie um e-mail';

  @override
  String get contactResponseTime => 'Tempo de resposta';

  @override
  String get contactResponseTimeValue =>
      'Normalmente respondemos em 1–2 dias úteis.';

  @override
  String get contactPrivacyNote =>
      'Usaremos sua mensagem apenas para dar suporte.';

  @override
  String contactNoMailApp(String email) {
    return 'Nenhum app de e-mail pôde ser aberto. Escreva para $email.';
  }

  @override
  String get contactWhatsAppFailed => 'Não foi possível abrir o WhatsApp.';

  @override
  String get contactTelegramFailed => 'Não foi possível abrir o Telegram.';

  @override
  String get contactPlayStoreFailed => 'Não foi possível abrir a Play Store.';

  @override
  String contactLegalOpenFailed(String document) {
    return 'Não foi possível abrir $document.';
  }
}
