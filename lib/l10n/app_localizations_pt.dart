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
  String get settingsSectionDelivery => 'Entrega';

  @override
  String get settingsBackgroundActivity => 'Atividade em segundo plano';

  @override
  String get settingsBackgroundActivitySubtitle =>
      'Permite que as apps clonadas recebam notificações enquanto estão fechadas';

  @override
  String get settingsBackgroundActivityAllowed => 'Permitida';

  @override
  String get settingsBackgroundActivityRestricted => 'Restringida';

  @override
  String get settingsBackgroundActivityNotAllowed => 'Não permitida';

  @override
  String get backgroundGuideAllowedStatus =>
      'A atividade em segundo plano está permitida, por isso as apps clonadas continuam a receber notificações enquanto estão fechadas.';

  @override
  String get backgroundGuideDone => 'Concluído';

  @override
  String get backgroundGuideTitle => 'Atividade em segundo plano';

  @override
  String get backgroundGuideWhy =>
      'O Android pode pausar o Duplika em segundo plano; as apps clonadas deixam de receber notificações até voltares a abrir o Duplika.';

  @override
  String get backgroundGuideStepsOem =>
      'Em Informações da app, toca em Utilização da bateria e ativa Permitir atividade em segundo plano.';

  @override
  String get backgroundGuideStepsStock =>
      'Toca em Permitir na pergunta do sistema que abre, para que possa ser executada em segundo plano.';

  @override
  String get backgroundGuideStepsUnknown =>
      'Em Informações da app, permite a atividade em segundo plano.';

  @override
  String get backgroundGuideOpenAppInfo => 'Abrir informações da app';

  @override
  String get backgroundGuideAllow => 'Permitir';

  @override
  String get backgroundGuideLater => 'Agora não';

  @override
  String get settingsBackgroundActivityFix =>
      'Toque aqui e permita a atividade em segundo plano';

  @override
  String get settingsBackgroundActivityFixBatteryUsage =>
      'Toque aqui, depois Utilização da bateria, depois Permitir atividade em segundo plano';

  @override
  String get settingsBackgroundActivityFailed =>
      'Não foi possível abrir as definições de atividade em segundo plano.';

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

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotNow => 'Agora não';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonMore => 'Mais';

  @override
  String get commonFailureTitle => 'Não foi possível';

  @override
  String get homePrivateSpaceTitle => 'Espaço privado';

  @override
  String get homeSubtitle => 'O teu espaço privado';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps ocultas',
      one: '1 app oculta',
      zero: 'Nenhuma app oculta',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'Bloquear e fechar';

  @override
  String get homeMenuSettings => 'Definições';

  @override
  String get homeMenuDeveloperTools => 'Ferramentas de programador';

  @override
  String get homeAddApp => 'Adicionar app';

  @override
  String get homeEmptyTitle => 'O teu espaço está vazio';

  @override
  String get homeEmptyMessage =>
      'Adiciona uma app para criar a tua primeira instância privada.';

  @override
  String get homeEmptyAction => 'Adiciona a tua primeira app';

  @override
  String get homePrivateEmptyTitle => 'Ainda não há nada oculto';

  @override
  String get homePrivateEmptyMessage =>
      'Mantém premida qualquer app na grelha principal e escolhe Ocultar para a mover para aqui.';

  @override
  String get homeSetUpPrivateSpaceTitle => 'Configurar o espaço privado?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'Ocultar um clone exige um espaço privado. Cria um com um PIN primeiro.';

  @override
  String get homeSetUpPrivateSpaceConfirm => 'Configurar';

  @override
  String get homeEngineInactive =>
      'O motor de virtualização não está ativo neste dispositivo, por isso os clones não podem correr em contentores isolados.';

  @override
  String get homeEngineUnavailable =>
      'O motor de virtualização não está disponível neste dispositivo.';

  @override
  String get homeBackgroundNudgeTitle =>
      'Os clones podem perder notificações enquanto estão fechados.';

  @override
  String get homeBackgroundNudgeMessage =>
      'Garante que a atividade em segundo plano é permitida para continuarem a recebê-las.';

  @override
  String get homeBackgroundNudgeAllow => 'Permitir';

  @override
  String get homeBackgroundNudgeDismiss => 'Dispensar';

  @override
  String cloneSpaceLabel(int index) {
    return 'Espaço $index';
  }

  @override
  String get cloneActionsCompatibility => 'Compatibilidade';

  @override
  String get cloneActionsManage => 'Gerir';

  @override
  String get cloneActionUninstall => 'Desinstalar';

  @override
  String get cloneActionClone => 'Clonar';

  @override
  String get cloneActionShortcut => 'Atalho';

  @override
  String get cloneActionSpaceInfo => 'Info do espaço';

  @override
  String get cloneActionEditName => 'Editar nome';

  @override
  String get cloneActionForceStop => 'Forçar paragem';

  @override
  String get cloneActionClearCache => 'Limpar cache';

  @override
  String get cloneActionClearStorage => 'Limpar dados';

  @override
  String get cloneActionHide => 'Ocultar';

  @override
  String get cloneActionUnhide => 'Mostrar';

  @override
  String get cloneActionShareApp => 'Partilhar app';

  @override
  String get cloneActionNotifications => 'Notificações';

  @override
  String get cloneActionPermissions => 'Permissões';

  @override
  String get cloneActionGoogleServicesInstalled =>
      'Serviços Google (microG) instalados';

  @override
  String get cloneActionInstallGoogleServices =>
      'Instalar serviços Google (microG)';

  @override
  String cloneTileSibling(int index, int count) {
    return ', clone $index de $count';
  }

  @override
  String get cloneTileOpening => ', a abrir';

  @override
  String get cloneTileRunning => ', em execução';

  @override
  String get cloneTileCannotLaunch => ', não pode ser aberta neste dispositivo';

  @override
  String get cloneForceStopTitle => 'Forçar a paragem desta app?';

  @override
  String get cloneForceStopMessage =>
      'A app deixa de correr até a voltares a abrir.';

  @override
  String get cloneForceStopConfirm => 'Forçar paragem';

  @override
  String get cloneClearCacheTitle => 'Limpar a cache da app?';

  @override
  String get cloneClearCacheMessage =>
      'Isto remove os ficheiros temporários deste clone.';

  @override
  String get cloneClearCacheConfirm => 'Limpar cache';

  @override
  String get cloneClearStorageTitle => 'Limpar os dados da app?';

  @override
  String get cloneClearStorageMessage =>
      'Isto elimina permanentemente as contas, definições e dados locais deste clone.';

  @override
  String get cloneClearStorageConfirm => 'Limpar dados';

  @override
  String get cloneInstallGoogleServicesTitle => 'Instalar os serviços Google?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return 'O $appName vai instalar o microG incluído neste clone como serviços Google Play. O clone mantém os seus dados. Pode demorar alguns segundos.';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'Instalar';

  @override
  String cloneStopped(String name) {
    return '$name parada.';
  }

  @override
  String cloneCacheCleared(String name) {
    return 'Cache limpa para $name.';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name foi reposta. O próximo arranque será um primeiro arranque.';
  }

  @override
  String cloneHidden(String name) {
    return '$name oculta no espaço privado.';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name voltou à grelha principal.';
  }

  @override
  String get cloneShortcutAdded =>
      'Confirma o atalho no teu ecrã principal para terminar de o adicionar.';

  @override
  String get cloneGoogleServicesInstalling => 'A instalar os serviços Google…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return 'Serviços Google instalados em $name.';
  }

  @override
  String get cloneCountTitle => 'Clonar app';

  @override
  String cloneCountMessage(String appName) {
    return 'Cria cópias adicionais de $appName.';
  }

  @override
  String get cloneCountLabel => 'Número de clones';

  @override
  String get cloneCountDecrease => 'Menos um';

  @override
  String get cloneCountIncrease => 'Mais um';

  @override
  String get cloneCountConfirm => 'Clonar';

  @override
  String cloneCreating(int created, int total) {
    return 'A criar $created de $total…';
  }

  @override
  String get cloneCreatingFinishing => 'A terminar…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Adicionadas mais $count cópias de $appName.',
      one: 'Adicionada mais uma cópia de $appName.',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return 'Criados $created de $total. $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return 'Escolhe de 1 a $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return 'Só há $free livres e o dispositivo reserva meio gigabyte.';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return 'Até $maximum — restam $free de espaço';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return 'Até $maximum de cada vez num dispositivo com $memory de memória';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return 'Não há espaço para outro clone de $appName. $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return 'Não há espaço suficiente para mais $count clones de $appName. $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return 'Permissões · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => 'Não foi possível ler as permissões';

  @override
  String get clonePermissionsEmptyTitle => 'Nada a limitar';

  @override
  String get clonePermissionsEmptyMessage =>
      'Esta app não declara permissões perigosas, por isso não há nada para permitir ou negar neste clone.';

  @override
  String clonePermissionsNote(String appName) {
    return 'Aplicam-se apenas a este clone. Uma app clonada costuma perguntar antes de usar uma permissão, e é aqui que essa resposta é limitada — uma app que salte a pergunta pode ainda assim chegar ao hardware através da permissão do próprio $appName.';
  }

  @override
  String get spaceInfoTitle => 'Info do espaço';

  @override
  String get spaceInfoIdentifiers => 'Identificadores do dispositivo';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'Motor indisponível';

  @override
  String get spaceInfoStateRunning => 'Em execução';

  @override
  String get spaceInfoStateActive => 'Ativo';

  @override
  String get spaceInfoStateRebuilds => 'Reconstrói ao abrir';

  @override
  String get spaceInfoNoContainer =>
      'Este espaço ainda não tem contentor, por isso não tem identificadores. Abre-o uma vez e aparecem aqui.';

  @override
  String get spaceInfoDeviceId => 'ID do dispositivo';

  @override
  String get spaceInfoAndroidId => 'ID Android';

  @override
  String get spaceInfoSerialNumber => 'Número de série';

  @override
  String get spaceInfoWifiMac => 'MAC Wi-Fi';

  @override
  String get spaceInfoBluetoothMac => 'MAC Bluetooth';

  @override
  String spaceInfoCopy(String label) {
    return 'Copiar $label';
  }

  @override
  String spaceInfoCopied(String label) {
    return '$label copiado.';
  }

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get pickerTitle => 'Adicionar app';

  @override
  String get pickerSearchHint => 'Procurar apps';

  @override
  String get pickerFilterTooltip => 'Filtrar e ordenar';

  @override
  String get pickerErrorTitle => 'Não foi possível listar as apps';

  @override
  String get pickerNoMatchesTitle => 'Nenhuma app corresponde';

  @override
  String get pickerNoMatchesMessage =>
      'Tenta outra pesquisa ou importa um APK.';

  @override
  String get pickerPopular => 'Populares';

  @override
  String get pickerQuickPicks => 'Escolhas rápidas';

  @override
  String get pickerInstalledApps => 'Apps instaladas';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => 'Sistema';

  @override
  String get pickerCannotClone =>
      'Esta app não pode ser clonada neste dispositivo.';

  @override
  String get pickerApkUnreadable => 'Não foi possível ler o APK selecionado.';

  @override
  String get filterTitle => 'Filtrar e ordenar';

  @override
  String get filterSort => 'Ordenar';

  @override
  String get filterSortName => 'Nome da app';

  @override
  String get filterSortRecentlyInstalled => 'Instaladas recentemente';

  @override
  String get filterSortRecentlyUpdated => 'Atualizadas recentemente';

  @override
  String get filterFilter => 'Filtrar';

  @override
  String get filterAllApps => 'Todas as apps';

  @override
  String get filterUserApps => 'Apps do utilizador';

  @override
  String get filterSystemApps => 'Apps do sistema';

  @override
  String get filterNotAdded => 'Não adicionadas';

  @override
  String get filterAlreadyAdded => 'Já adicionadas';

  @override
  String get filterArchitecture => 'Arquitetura';

  @override
  String get filterArch64 => '64 bits';

  @override
  String get filterArch32 => '32 bits';

  @override
  String get filterArchNoNativeCode => 'Sem código nativo';

  @override
  String get filterPackageType => 'Tipo de pacote';

  @override
  String get filterPackageSingle => 'APK único';

  @override
  String get filterPackageSplit => 'APK dividido';

  @override
  String filterImportApk(String appName) {
    return 'Abrir pacote de app do $appName';
  }

  @override
  String get appSheetAddClone => 'Adicionar clone';

  @override
  String get appSheetAddAnother => 'Adicionar outro';

  @override
  String get appSheetShareApp => 'Partilhar app';

  @override
  String get appSheetAppDetails => 'Detalhes da app';

  @override
  String get appDetailsTitle => 'Detalhes da app';

  @override
  String get appDetailsAdvanced => 'Detalhes avançados';

  @override
  String get appDetailsPackageName => 'Nome do pacote';

  @override
  String get appDetailsVersion => 'Versão';

  @override
  String get appDetailsArchitecture => 'Arquitetura';

  @override
  String get appDetailsBitness => 'Bits';

  @override
  String get appDetailsPackageType => 'Tipo de pacote';

  @override
  String get appDetailsApkComponents => 'Componentes do APK';

  @override
  String get appDetailsTotalApkSize => 'Tamanho total do APK';

  @override
  String get appDetailsSigningSha256 => 'SHA-256 do certificado de assinatura';

  @override
  String get appDetailsSigningUnreadable => 'não foi possível ler';

  @override
  String get appDetailsNoApkFiles =>
      'O gestor de pacotes não indicou ficheiros APK para esta app.';

  @override
  String get compatibilityNotAnalysed => 'Não analisada';

  @override
  String get compatibilitySupported => 'Compatível';

  @override
  String get compatibilityLimited => 'Limitada';

  @override
  String get compatibilityUnsupported => 'Não compatível';

  @override
  String get compatibilityUnexaminedMessage =>
      'Não foi possível examinar esta app, por isso não se sabe como vai funcionar. Pode ainda ser recusada ao criar o clone.';

  @override
  String get compatibilityNoProblems =>
      'Sem problemas de compatibilidade conhecidos.';

  @override
  String compatibilityExistingClones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Já tens $count clones desta app. O novo começa vazio com os seus próprios dados.',
      one:
          'Já tens 1 clone desta app. O novo começa vazio com os seus próprios dados.',
    );
    return '$_temp0';
  }

  @override
  String get compatibilityAddClone => 'Adicionar clone';

  @override
  String get compatibilityCannotClone => 'Não é possível clonar';

  @override
  String get findingAppNotFound =>
      'Esta aplicação não está instalada no dispositivo.';

  @override
  String get findingSecureEnvRequired =>
      'Esta aplicação exige um ambiente seguro e não pode ser virtualizada.';

  @override
  String findingSelfClone(String appName) {
    return 'O $appName não pode clonar-se a si próprio.';
  }

  @override
  String get findingSystemComponent =>
      'Os componentes do sistema não podem ser clonados.';

  @override
  String get findingAbiNotSupported =>
      'As bibliotecas nativas desta app não foram compiladas para uma arquitetura suportada pelo motor.';

  @override
  String get findingRequiresGms =>
      'Os serviços Google Play estão disponíveis dentro de um clone, mas as funcionalidades Google que precisam de verificar a identidade própria desta app não são suportadas — incluindo o início de sessão e as APIs ligadas à identidade, como a verificação por localização e por SMS.';

  @override
  String findingPushUnsupported(String appName) {
    return 'As notificações push não funcionam num clone. Os serviços Google Play não registam esta app para push enquanto ela correr sob a identidade do $appName, por isso as mensagens enviadas ao clone nunca chegam. De resto a app é utilizável, mas espera uma pausa no primeiro arranque enquanto aguarda um registo push que não pode ser concluído.';
  }

  @override
  String findingStorageUnavailable(String appName) {
    return 'Esta app usa o armazenamento partilhado e esta versão do $appName não declara o acesso a todos os ficheiros. Um clone dela não consegue chegar aos teus ficheiros e não vai funcionar.';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'Esta app usa o armazenamento partilhado. Concede ao $appName o «acesso a todos os ficheiros» em Definições → Acesso especial a apps antes de abrir o clone, ou pode ser recusado no arranque.';
  }

  @override
  String get factsNoNativeCode => 'Sem código nativo';

  @override
  String get factsAnyNoNativeCode => 'Qualquer — sem código nativo';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => 'APK único';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APK dividido · $count ficheiros',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => 'desconhecida';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'Importar pelo gestor de ficheiros';

  @override
  String get commonSave => 'Guardar';

  @override
  String get renameTitle => 'Mudar o nome do perfil';

  @override
  String get renameFieldLabel => 'Nome do perfil';

  @override
  String get uninstallTitle => 'Desinstalar este clone?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return 'Espaço $index de $count';
  }

  @override
  String get uninstallMessage =>
      'Isto remove a instância de app selecionada e os seus dados locais.';

  @override
  String get uninstallConfirm => 'Desinstalar';

  @override
  String get calculatorError => 'Erro';

  @override
  String get disclosureTitle => 'Antes de começares';

  @override
  String disclosureIntro(String appName) {
    return 'O $appName corre uma segunda cópia das apps que escolheres. Isto é exatamente o que lê e o que te vai pedir.';
  }

  @override
  String get disclosureAppsTitle => 'As tuas apps instaladas';

  @override
  String disclosureAppsBody(String appName) {
    return 'Para mostrar o seletor de clones, o $appName lê a lista de apps instaladas neste dispositivo — os nomes, ícones e versões. Esta lista fica no teu dispositivo. Nunca é enviada, vendida ou partilhada, e a app não tem anúncios, análises nem rastreadores.';
  }

  @override
  String get disclosurePermissionsTitle => 'Permissões em nome dos clones';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'As apps clonadas correm dentro do $appName, por isso algumas permissões Android aplicam-se a ele em nome delas. Podes ser solicitado uma vez para o isentares da otimização da bateria, para que os mensageiros clonados continuem a entregar. Só ao clonar uma app de ficheiros ou multimédia é que podes precisar de conceder o acesso a todos os ficheiros nas Definições.';
  }

  @override
  String get disclosureControlTitle => 'O controlo é teu';

  @override
  String get disclosureControlBody =>
      'Nada é pedido em silêncio. Podes recusar qualquer um destes pedidos e continuar a usar a app, e podes mudar de ideias nas Definições do Android a qualquer momento.';

  @override
  String get disclosureAccept => 'Aceitar e continuar';

  @override
  String get privateSpaceTitle => 'Espaço privado';

  @override
  String get privateSpaceOffTitle => 'O espaço privado está desligado';

  @override
  String get privateSpaceOffMessage =>
      'Liga-o para ocultar clones atrás de um PIN. As apps ocultas desaparecem da grelha principal e abrem apenas aqui.';

  @override
  String get privateSpaceSetUp => 'Configurar o espaço privado';

  @override
  String get privateSpaceChangePin => 'Mudar o PIN';

  @override
  String get privateSpaceUnlockSection => 'Desbloqueio';

  @override
  String get privateSpaceFingerprint => 'Desbloquear com impressão digital';

  @override
  String get privateSpaceFingerprintAvailable =>
      'Podes continuar a usar o teu PIN a qualquer momento.';

  @override
  String get privateSpaceFingerprintUnavailable =>
      'Não há impressão digital nem rosto configurados neste dispositivo.';

  @override
  String get privateSpaceDisguiseSection => 'Disfarce';

  @override
  String get privateSpaceDisguiseAsCalculator => 'Disfarçar de calculadora';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return 'Substitui o ícone do $appName por uma calculadora. Escreve o PIN do teu espaço privado e prime = para abrir a app.';
  }

  @override
  String get privateSpaceTurnOff => 'Desligar o espaço privado';

  @override
  String get privateSpaceTurnOffNote =>
      'Ao desligá-lo, todas as apps ocultas voltam à grelha principal. Os clones não são eliminados.';

  @override
  String get privateSpaceDisguiseOnTitle => 'Disfarçar de calculadora?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return 'Mostrar o $appName de novo?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return 'O ícone do $appName é substituído por uma calculadora chamada «Calculator». Para abrir o $appName, escreve o PIN do teu espaço privado e prime =. Se te esqueceres do PIN não vais conseguir abrir a app.';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return 'O $appName volta a mostrar o seu próprio ícone e nome no ecrã principal.';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => 'Disfarçar';

  @override
  String get privateSpaceDisguiseConfirmOff => 'Mostrar app';

  @override
  String get privateSpaceDisguiseFailed =>
      'Não foi possível mudar o aspeto da app.';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return 'O $appName parece agora uma calculadora no teu ecrã principal.';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return 'O $appName está de volta ao teu ecrã principal.';
  }

  @override
  String get privateSpaceTurnOffTitle => 'Desligar o espaço privado?';

  @override
  String get privateSpaceTurnOffMessage =>
      'Todas as apps ocultas voltam à grelha principal e o PIN é esquecido. Os clones são mantidos.';

  @override
  String get privateSpaceTurnOffConfirm => 'Desligar';

  @override
  String get privateSpaceTurnedOff => 'Espaço privado desligado.';

  @override
  String get pinCreateTitle => 'Criar PIN';

  @override
  String get pinChangeTitle => 'Mudar o PIN';

  @override
  String get pinCreateMessage =>
      'Este PIN bloqueia o espaço privado. Guarda-o num sítio que não esqueças: não há forma de recuperar um clone oculto sem ele.';

  @override
  String get pinChangeMessage =>
      'Introduz o teu PIN atual e depois escolhe um novo.';

  @override
  String get pinCurrentLabel => 'PIN atual';

  @override
  String get pinNewLabel => 'Novo PIN';

  @override
  String get pinConfirmLabel => 'Confirmar PIN';

  @override
  String get pinCreateConfirm => 'Criar espaço privado';

  @override
  String get pinSaveConfirm => 'Guardar PIN';

  @override
  String pinLengthError(int minimum, int maximum) {
    return 'Usa de $minimum a $maximum dígitos.';
  }

  @override
  String get pinMismatchError => 'Os dois PIN não coincidem.';

  @override
  String get pinCurrentIncorrect => 'O PIN atual está incorreto.';

  @override
  String get unlockTitle => 'Desbloquear o espaço privado';

  @override
  String get unlockPinLabel => 'PIN';

  @override
  String get unlockUseFingerprint => 'Usar impressão digital';

  @override
  String get unlockConfirm => 'Desbloquear';

  @override
  String get unlockIncorrectPin => 'PIN incorreto';

  @override
  String get unlockFingerprintUnavailable =>
      'O desbloqueio por impressão digital não está disponível neste momento.';

  @override
  String get unlockFingerprintNotRecognised =>
      'Impressão digital não reconhecida.';

  @override
  String get unlockBiometricReason => 'Desbloqueia o teu espaço privado';

  @override
  String get privateTileEmpty => 'Espaço privado, vazio';

  @override
  String privateTileHidden(int count) {
    return 'Espaço privado, $count ocultas';
  }

  @override
  String get settingsSectionPrivacy => 'Privacidade';

  @override
  String get settingsPrivateSpaceSubtitle => 'Oculta apps atrás de um PIN';

  @override
  String get settingsOn => 'Ligado';

  @override
  String get settingsOff => 'Desligado';

  @override
  String get componentBaseApk => 'APK base';

  @override
  String get componentSplitApk => 'APK dividido';

  @override
  String get componentNoNativeLibraries => 'Sem bibliotecas nativas';
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
  String get settingsSectionDelivery => 'Entrega';

  @override
  String get settingsBackgroundActivity => 'Atividade em segundo plano';

  @override
  String get settingsBackgroundActivitySubtitle =>
      'Permite que os apps clonados recebam notificações enquanto estão fechados';

  @override
  String get settingsBackgroundActivityAllowed => 'Permitida';

  @override
  String get settingsBackgroundActivityRestricted => 'Restringida';

  @override
  String get settingsBackgroundActivityNotAllowed => 'Não permitido';

  @override
  String get backgroundGuideAllowedStatus =>
      'A atividade em segundo plano está permitida, então os apps clonados continuam recebendo notificações enquanto estão fechados.';

  @override
  String get backgroundGuideDone => 'Concluído';

  @override
  String get backgroundGuideTitle => 'Atividade em segundo plano';

  @override
  String get backgroundGuideWhy =>
      'O Android pode pausar o Duplika em segundo plano; os apps clonados deixam de receber notificações até você abrir o Duplika novamente.';

  @override
  String get backgroundGuideStepsOem =>
      'Em Informações do app, toque em Uso de bateria e ative Permitir atividade em segundo plano.';

  @override
  String get backgroundGuideStepsStock =>
      'Toque em Permitir na pergunta do sistema que abrir, para que ele possa rodar em segundo plano.';

  @override
  String get backgroundGuideStepsUnknown =>
      'Em Informações do app, permita a atividade em segundo plano.';

  @override
  String get backgroundGuideOpenAppInfo => 'Abrir informações do app';

  @override
  String get backgroundGuideAllow => 'Permitir';

  @override
  String get backgroundGuideLater => 'Agora não';

  @override
  String get settingsBackgroundActivityFix =>
      'Toque aqui e permita a atividade em segundo plano';

  @override
  String get settingsBackgroundActivityFixBatteryUsage =>
      'Toque aqui, depois Uso de bateria, depois Permitir atividade em segundo plano';

  @override
  String get settingsBackgroundActivityFailed =>
      'Não foi possível abrir as configurações de atividade em segundo plano.';

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

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonOk => 'OK';

  @override
  String get commonNotNow => 'Agora não';

  @override
  String get commonClose => 'Fechar';

  @override
  String get commonMore => 'Mais';

  @override
  String get commonFailureTitle => 'Não foi possível';

  @override
  String get homePrivateSpaceTitle => 'Espaço privado';

  @override
  String get homeSubtitle => 'Seu espaço privado';

  @override
  String homeHiddenApps(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps ocultas',
      one: '1 app oculta',
      zero: 'Nenhuma app oculta',
    );
    return '$_temp0';
  }

  @override
  String get homeLockAndClose => 'Bloquear e fechar';

  @override
  String get homeMenuSettings => 'Configurações';

  @override
  String get homeMenuDeveloperTools => 'Ferramentas de desenvolvedor';

  @override
  String get homeAddApp => 'Adicionar app';

  @override
  String get homeEmptyTitle => 'Seu espaço está vazio';

  @override
  String get homeEmptyMessage =>
      'Adicione um app para criar sua primeira instância privada.';

  @override
  String get homeEmptyAction => 'Adicione seu primeiro app';

  @override
  String get homePrivateEmptyTitle => 'Ainda não há nada oculto';

  @override
  String get homePrivateEmptyMessage =>
      'Mantenha pressionado qualquer app na grade principal e escolha Ocultar para movê-lo para cá.';

  @override
  String get homeSetUpPrivateSpaceTitle => 'Configurar o espaço privado?';

  @override
  String get homeSetUpPrivateSpaceMessage =>
      'Ocultar um clone exige um espaço privado. Crie um com um PIN primeiro.';

  @override
  String get homeSetUpPrivateSpaceConfirm => 'Configurar';

  @override
  String get homeEngineInactive =>
      'O motor de virtualização não está ativo neste dispositivo, por isso os clones não podem correr em contentores isolados.';

  @override
  String get homeEngineUnavailable =>
      'O motor de virtualização não está disponível neste dispositivo.';

  @override
  String get homeBackgroundNudgeTitle =>
      'Os clones podem perder notificações enquanto estão fechados.';

  @override
  String get homeBackgroundNudgeMessage =>
      'Garanta que a atividade em segundo plano esteja permitida para que continuem a recebê-las.';

  @override
  String get homeBackgroundNudgeAllow => 'Permitir';

  @override
  String get homeBackgroundNudgeDismiss => 'Dispensar';

  @override
  String cloneSpaceLabel(int index) {
    return 'Espaço $index';
  }

  @override
  String get cloneActionsCompatibility => 'Compatibilidade';

  @override
  String get cloneActionsManage => 'Gerir';

  @override
  String get cloneActionUninstall => 'Desinstalar';

  @override
  String get cloneActionClone => 'Clonar';

  @override
  String get cloneActionShortcut => 'Atalho';

  @override
  String get cloneActionSpaceInfo => 'Info do espaço';

  @override
  String get cloneActionEditName => 'Editar nome';

  @override
  String get cloneActionForceStop => 'Forçar paragem';

  @override
  String get cloneActionClearCache => 'Limpar cache';

  @override
  String get cloneActionClearStorage => 'Limpar dados';

  @override
  String get cloneActionHide => 'Ocultar';

  @override
  String get cloneActionUnhide => 'Mostrar';

  @override
  String get cloneActionShareApp => 'Partilhar app';

  @override
  String get cloneActionNotifications => 'Notificações';

  @override
  String get cloneActionPermissions => 'Permissões';

  @override
  String get cloneActionGoogleServicesInstalled =>
      'Serviços Google (microG) instalados';

  @override
  String get cloneActionInstallGoogleServices =>
      'Instalar serviços Google (microG)';

  @override
  String cloneTileSibling(int index, int count) {
    return ', clone $index de $count';
  }

  @override
  String get cloneTileOpening => ', a abrir';

  @override
  String get cloneTileRunning => ', em execução';

  @override
  String get cloneTileCannotLaunch => ', não pode ser aberta neste dispositivo';

  @override
  String get cloneForceStopTitle => 'Forçar a paragem desta app?';

  @override
  String get cloneForceStopMessage =>
      'O app para de rodar até você abri-lo de novo.';

  @override
  String get cloneForceStopConfirm => 'Forçar paragem';

  @override
  String get cloneClearCacheTitle => 'Limpar a cache da app?';

  @override
  String get cloneClearCacheMessage =>
      'Isto remove os ficheiros temporários deste clone.';

  @override
  String get cloneClearCacheConfirm => 'Limpar cache';

  @override
  String get cloneClearStorageTitle => 'Limpar os dados da app?';

  @override
  String get cloneClearStorageMessage =>
      'Isso exclui permanentemente as contas, configurações e dados locais deste clone.';

  @override
  String get cloneClearStorageConfirm => 'Limpar dados';

  @override
  String get cloneInstallGoogleServicesTitle => 'Instalar os serviços Google?';

  @override
  String cloneInstallGoogleServicesMessage(String appName) {
    return 'O $appName vai instalar o microG incluído neste clone como serviços do Google Play. O clone mantém seus dados. Pode levar alguns segundos.';
  }

  @override
  String get cloneInstallGoogleServicesConfirm => 'Instalar';

  @override
  String cloneStopped(String name) {
    return '$name parada.';
  }

  @override
  String cloneCacheCleared(String name) {
    return 'Cache limpa para $name.';
  }

  @override
  String cloneStorageCleared(String name) {
    return '$name foi reposta. O próximo arranque será um primeiro arranque.';
  }

  @override
  String cloneHidden(String name) {
    return '$name oculta no espaço privado.';
  }

  @override
  String cloneUnhidden(String name) {
    return '$name voltou à grelha principal.';
  }

  @override
  String get cloneShortcutAdded =>
      'Confirme o atalho na sua tela inicial para terminar de adicioná-lo.';

  @override
  String get cloneGoogleServicesInstalling => 'A instalar os serviços Google…';

  @override
  String cloneGoogleServicesInstalled(String name) {
    return 'Serviços Google instalados em $name.';
  }

  @override
  String get cloneCountTitle => 'Clonar app';

  @override
  String cloneCountMessage(String appName) {
    return 'Crie cópias adicionais de $appName.';
  }

  @override
  String get cloneCountLabel => 'Número de clones';

  @override
  String get cloneCountDecrease => 'Menos um';

  @override
  String get cloneCountIncrease => 'Mais um';

  @override
  String get cloneCountConfirm => 'Clonar';

  @override
  String cloneCreating(int created, int total) {
    return 'A criar $created de $total…';
  }

  @override
  String get cloneCreatingFinishing => 'A terminar…';

  @override
  String cloneAdded(int count, String appName) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Adicionadas mais $count cópias de $appName.',
      one: 'Adicionada mais uma cópia de $appName.',
    );
    return '$_temp0';
  }

  @override
  String cloneCreatedPartly(int created, int total, String failure) {
    return 'Criados $created de $total. $failure';
  }

  @override
  String cloneBudgetRange(int maximum) {
    return 'Escolha de 1 a $maximum';
  }

  @override
  String cloneBudgetNoStorage(String free) {
    return 'Só há $free livres e o dispositivo reserva meio gigabyte.';
  }

  @override
  String cloneBudgetStorage(int maximum, String free) {
    return 'Até $maximum — restam $free de espaço';
  }

  @override
  String cloneBudgetMemory(int maximum, String memory) {
    return 'Até $maximum de cada vez num dispositivo com $memory de memória';
  }

  @override
  String cloneBudgetNoRoom(String appName, String reason) {
    return 'Não há espaço para outro clone de $appName. $reason';
  }

  @override
  String cloneBudgetNotEnoughRoom(int count, String appName, String reason) {
    return 'Não há espaço suficiente para mais $count clones de $appName. $reason.';
  }

  @override
  String clonePermissionsTitle(String appName) {
    return 'Permissões · $appName';
  }

  @override
  String get clonePermissionsErrorTitle => 'Não foi possível ler as permissões';

  @override
  String get clonePermissionsEmptyTitle => 'Nada a limitar';

  @override
  String get clonePermissionsEmptyMessage =>
      'Esta app não declara permissões perigosas, por isso não há nada para permitir ou negar neste clone.';

  @override
  String clonePermissionsNote(String appName) {
    return 'Aplicam-se apenas a este clone. Um app clonado costuma perguntar antes de usar uma permissão, e é aqui que essa resposta é limitada — um app que pule a pergunta ainda pode alcançar o hardware pela permissão do próprio $appName.';
  }

  @override
  String get spaceInfoTitle => 'Info do espaço';

  @override
  String get spaceInfoIdentifiers => 'Identificadores do dispositivo';

  @override
  String spaceInfoIdLabel(int index) {
    return 'ID $index';
  }

  @override
  String get spaceInfoStateEngineUnavailable => 'Motor indisponível';

  @override
  String get spaceInfoStateRunning => 'Em execução';

  @override
  String get spaceInfoStateActive => 'Ativo';

  @override
  String get spaceInfoStateRebuilds => 'Reconstrói ao abrir';

  @override
  String get spaceInfoNoContainer =>
      'Este espaço ainda não tem contêiner, então não tem identificadores. Abra-o uma vez e eles aparecem aqui.';

  @override
  String get spaceInfoDeviceId => 'ID do dispositivo';

  @override
  String get spaceInfoAndroidId => 'ID Android';

  @override
  String get spaceInfoSerialNumber => 'Número de série';

  @override
  String get spaceInfoWifiMac => 'MAC Wi-Fi';

  @override
  String get spaceInfoBluetoothMac => 'MAC Bluetooth';

  @override
  String spaceInfoCopy(String label) {
    return 'Copiar $label';
  }

  @override
  String spaceInfoCopied(String label) {
    return '$label copiado.';
  }

  @override
  String get commonBack => 'Voltar';

  @override
  String get commonApply => 'Aplicar';

  @override
  String get pickerTitle => 'Adicionar app';

  @override
  String get pickerSearchHint => 'Pesquisar apps';

  @override
  String get pickerFilterTooltip => 'Filtrar e ordenar';

  @override
  String get pickerErrorTitle => 'Não foi possível listar os apps';

  @override
  String get pickerNoMatchesTitle => 'Nenhum app corresponde';

  @override
  String get pickerNoMatchesMessage =>
      'Tente outra pesquisa ou importe um APK.';

  @override
  String get pickerPopular => 'Populares';

  @override
  String get pickerQuickPicks => 'Escolhas rápidas';

  @override
  String get pickerInstalledApps => 'Apps instalados';

  @override
  String pickerAppCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count apps',
      one: '1 app',
    );
    return '$_temp0';
  }

  @override
  String get pickerSystemChip => 'Sistema';

  @override
  String get pickerCannotClone =>
      'Este app não pode ser clonado neste dispositivo.';

  @override
  String get pickerApkUnreadable => 'Não foi possível ler o APK selecionado.';

  @override
  String get filterTitle => 'Filtrar e ordenar';

  @override
  String get filterSort => 'Ordenar';

  @override
  String get filterSortName => 'Nome do app';

  @override
  String get filterSortRecentlyInstalled => 'Instalados recentemente';

  @override
  String get filterSortRecentlyUpdated => 'Atualizados recentemente';

  @override
  String get filterFilter => 'Filtrar';

  @override
  String get filterAllApps => 'Todos os apps';

  @override
  String get filterUserApps => 'Apps do usuário';

  @override
  String get filterSystemApps => 'Apps do sistema';

  @override
  String get filterNotAdded => 'Não adicionados';

  @override
  String get filterAlreadyAdded => 'Já adicionados';

  @override
  String get filterArchitecture => 'Arquitetura';

  @override
  String get filterArch64 => '64 bits';

  @override
  String get filterArch32 => '32 bits';

  @override
  String get filterArchNoNativeCode => 'Sem código nativo';

  @override
  String get filterPackageType => 'Tipo de pacote';

  @override
  String get filterPackageSingle => 'APK único';

  @override
  String get filterPackageSplit => 'APK dividido';

  @override
  String filterImportApk(String appName) {
    return 'Abrir pacote de app do $appName';
  }

  @override
  String get appSheetAddClone => 'Adicionar clone';

  @override
  String get appSheetAddAnother => 'Adicionar outro';

  @override
  String get appSheetShareApp => 'Partilhar app';

  @override
  String get appSheetAppDetails => 'Detalhes do app';

  @override
  String get appDetailsTitle => 'Detalhes do app';

  @override
  String get appDetailsAdvanced => 'Detalhes avançados';

  @override
  String get appDetailsPackageName => 'Nome do pacote';

  @override
  String get appDetailsVersion => 'Versão';

  @override
  String get appDetailsArchitecture => 'Arquitetura';

  @override
  String get appDetailsBitness => 'Bits';

  @override
  String get appDetailsPackageType => 'Tipo de pacote';

  @override
  String get appDetailsApkComponents => 'Componentes do APK';

  @override
  String get appDetailsTotalApkSize => 'Tamanho total do APK';

  @override
  String get appDetailsSigningSha256 => 'SHA-256 do certificado de assinatura';

  @override
  String get appDetailsSigningUnreadable => 'não foi possível ler';

  @override
  String get appDetailsNoApkFiles =>
      'O gerenciador de pacotes não informou arquivos APK para este app.';

  @override
  String get compatibilityNotAnalysed => 'Não analisada';

  @override
  String get compatibilitySupported => 'Compatível';

  @override
  String get compatibilityLimited => 'Limitada';

  @override
  String get compatibilityUnsupported => 'Não compatível';

  @override
  String get compatibilityUnexaminedMessage =>
      'Não foi possível examinar este app, então não se sabe como ele vai funcionar. Ele ainda pode ser recusado ao criar o clone.';

  @override
  String get compatibilityNoProblems =>
      'Sem problemas de compatibilidade conhecidos.';

  @override
  String compatibilityExistingClones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Você já tem $count clones deste app. O novo começa vazio com seus próprios dados.',
      one:
          'Você já tem 1 clone deste app. O novo começa vazio com seus próprios dados.',
    );
    return '$_temp0';
  }

  @override
  String get compatibilityAddClone => 'Adicionar clone';

  @override
  String get compatibilityCannotClone => 'Não é possível clonar';

  @override
  String get findingAppNotFound =>
      'Esta aplicação não está instalada no dispositivo.';

  @override
  String get findingSecureEnvRequired =>
      'Esta aplicação exige um ambiente seguro e não pode ser virtualizada.';

  @override
  String findingSelfClone(String appName) {
    return 'O $appName não pode clonar a si mesmo.';
  }

  @override
  String get findingSystemComponent =>
      'Os componentes do sistema não podem ser clonados.';

  @override
  String get findingAbiNotSupported =>
      'As bibliotecas nativas deste app não foram compiladas para uma arquitetura suportada pelo motor.';

  @override
  String get findingRequiresGms =>
      'Os serviços do Google Play estão disponíveis dentro de um clone, mas os recursos do Google que precisam verificar a identidade própria deste app não têm suporte — incluindo o login e as APIs ligadas à identidade, como a verificação por localização e por SMS.';

  @override
  String findingPushUnsupported(String appName) {
    return 'As notificações push não funcionam em um clone. Os serviços do Google Play não registram este app para push enquanto ele roda sob a identidade do $appName, então as mensagens enviadas ao clone nunca chegam. No mais o app é utilizável, mas espere uma pausa no primeiro início enquanto ele aguarda um registro push que não pode ser concluído.';
  }

  @override
  String findingStorageUnavailable(String appName) {
    return 'Este app usa o armazenamento compartilhado e esta versão do $appName não declara o acesso a todos os arquivos. Um clone dele não consegue alcançar seus arquivos e não vai funcionar.';
  }

  @override
  String findingStorageNotGranted(String appName) {
    return 'Este app usa o armazenamento compartilhado. Conceda ao $appName o “acesso a todos os arquivos” em Configurações → Acesso especial de apps antes de abrir o clone, ou ele pode ser recusado ao iniciar.';
  }

  @override
  String get factsNoNativeCode => 'Sem código nativo';

  @override
  String get factsAnyNoNativeCode => 'Qualquer — sem código nativo';

  @override
  String get factsBits32And64 => '32 + 64';

  @override
  String get factsSingleApk => 'APK único';

  @override
  String factsSplitApk(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'APK dividido · $count arquivos',
    );
    return '$_temp0';
  }

  @override
  String get factsVersionUnknown => 'desconhecida';

  @override
  String get filterArchBoth => '32 + 64';

  @override
  String get filterImportFiles => 'Importar pelo gerenciador de arquivos';

  @override
  String get commonSave => 'Salvar';

  @override
  String get renameTitle => 'Renomear perfil';

  @override
  String get renameFieldLabel => 'Nome do perfil';

  @override
  String get uninstallTitle => 'Desinstalar este clone?';

  @override
  String uninstallSpaceOf(int index, int count) {
    return 'Espaço $index de $count';
  }

  @override
  String get uninstallMessage =>
      'Isso remove a instância de app selecionada e seus dados locais.';

  @override
  String get uninstallConfirm => 'Desinstalar';

  @override
  String get calculatorError => 'Erro';

  @override
  String get disclosureTitle => 'Antes de começar';

  @override
  String disclosureIntro(String appName) {
    return 'O $appName roda uma segunda cópia dos apps que você escolher. Veja exatamente o que ele lê e o que vai pedir a você.';
  }

  @override
  String get disclosureAppsTitle => 'Seus apps instalados';

  @override
  String disclosureAppsBody(String appName) {
    return 'Para mostrar o seletor de clones, o $appName lê a lista de apps instalados neste dispositivo — nomes, ícones e versões. Essa lista fica no seu dispositivo. Nunca é enviada, vendida ou compartilhada, e o app não tem anúncios, análises nem rastreadores.';
  }

  @override
  String get disclosurePermissionsTitle => 'Permissões em nome dos clones';

  @override
  String disclosurePermissionsBody(String appName) {
    return 'Os apps clonados rodam dentro do $appName, então algumas permissões do Android se aplicam a ele em nome deles. Você pode ser solicitado uma vez a isentá-lo da otimização de bateria, para que os mensageiros clonados continuem entregando. Só ao clonar um app de arquivos ou mídia você pode precisar conceder o acesso a todos os arquivos nas Configurações.';
  }

  @override
  String get disclosureControlTitle => 'Você continua no controle';

  @override
  String get disclosureControlBody =>
      'Nada é solicitado em silêncio. Você pode recusar qualquer um desses pedidos e continuar usando o app, e pode mudar de ideia nas Configurações do Android a qualquer momento.';

  @override
  String get disclosureAccept => 'Aceitar e continuar';

  @override
  String get privateSpaceTitle => 'Espaço privado';

  @override
  String get privateSpaceOffTitle => 'O espaço privado está desativado';

  @override
  String get privateSpaceOffMessage =>
      'Ative-o para ocultar clones atrás de um PIN. Os apps ocultos somem da grade principal e abrem só aqui.';

  @override
  String get privateSpaceSetUp => 'Configurar o espaço privado';

  @override
  String get privateSpaceChangePin => 'Mudar o PIN';

  @override
  String get privateSpaceUnlockSection => 'Desbloqueio';

  @override
  String get privateSpaceFingerprint => 'Desbloquear com digital';

  @override
  String get privateSpaceFingerprintAvailable =>
      'Você pode continuar usando seu PIN a qualquer momento.';

  @override
  String get privateSpaceFingerprintUnavailable =>
      'Nenhuma digital ou rosto está configurado neste dispositivo.';

  @override
  String get privateSpaceDisguiseSection => 'Disfarce';

  @override
  String get privateSpaceDisguiseAsCalculator => 'Disfarçar de calculadora';

  @override
  String privateSpaceDisguiseSubtitle(String appName) {
    return 'Substitui o ícone do $appName por uma calculadora. Digite o PIN do seu espaço privado e pressione = para abrir o app.';
  }

  @override
  String get privateSpaceTurnOff => 'Desativar o espaço privado';

  @override
  String get privateSpaceTurnOffNote =>
      'Ao desativá-lo, todos os apps ocultos voltam para a grade principal. Os clones não são excluídos.';

  @override
  String get privateSpaceDisguiseOnTitle => 'Disfarçar de calculadora?';

  @override
  String privateSpaceDisguiseOffTitle(String appName) {
    return 'Mostrar o $appName de novo?';
  }

  @override
  String privateSpaceDisguiseOnMessage(String appName) {
    return 'O ícone do $appName é substituído por uma calculadora chamada “Calculator”. Para abrir o $appName, digite o PIN do seu espaço privado e pressione =. Se esquecer o PIN, você não vai conseguir abrir o app.';
  }

  @override
  String privateSpaceDisguiseOffMessage(String appName) {
    return 'O $appName volta a mostrar o próprio ícone e nome na tela inicial.';
  }

  @override
  String get privateSpaceDisguiseConfirmOn => 'Disfarçar';

  @override
  String get privateSpaceDisguiseConfirmOff => 'Mostrar app';

  @override
  String get privateSpaceDisguiseFailed =>
      'Não foi possível mudar a aparência do app.';

  @override
  String privateSpaceDisguiseNowCalculator(String appName) {
    return 'O $appName agora parece uma calculadora na sua tela inicial.';
  }

  @override
  String privateSpaceDisguiseRestored(String appName) {
    return 'O $appName voltou para a sua tela inicial.';
  }

  @override
  String get privateSpaceTurnOffTitle => 'Desativar o espaço privado?';

  @override
  String get privateSpaceTurnOffMessage =>
      'Todos os apps ocultos voltam para a grade principal e o PIN é esquecido. Os clones são mantidos.';

  @override
  String get privateSpaceTurnOffConfirm => 'Desativar';

  @override
  String get privateSpaceTurnedOff => 'Espaço privado desativado.';

  @override
  String get pinCreateTitle => 'Criar PIN';

  @override
  String get pinChangeTitle => 'Mudar o PIN';

  @override
  String get pinCreateMessage =>
      'Este PIN bloqueia o espaço privado. Guarde-o em um lugar que você não esqueça: não há como recuperar um clone oculto sem ele.';

  @override
  String get pinChangeMessage => 'Digite seu PIN atual e escolha um novo.';

  @override
  String get pinCurrentLabel => 'PIN atual';

  @override
  String get pinNewLabel => 'Novo PIN';

  @override
  String get pinConfirmLabel => 'Confirmar PIN';

  @override
  String get pinCreateConfirm => 'Criar espaço privado';

  @override
  String get pinSaveConfirm => 'Guardar PIN';

  @override
  String pinLengthError(int minimum, int maximum) {
    return 'Use de $minimum a $maximum dígitos.';
  }

  @override
  String get pinMismatchError => 'Os dois PIN não coincidem.';

  @override
  String get pinCurrentIncorrect => 'O PIN atual está incorreto.';

  @override
  String get unlockTitle => 'Desbloquear o espaço privado';

  @override
  String get unlockPinLabel => 'PIN';

  @override
  String get unlockUseFingerprint => 'Usar digital';

  @override
  String get unlockConfirm => 'Desbloquear';

  @override
  String get unlockIncorrectPin => 'PIN incorreto';

  @override
  String get unlockFingerprintUnavailable =>
      'O desbloqueio por digital não está disponível agora.';

  @override
  String get unlockFingerprintNotRecognised => 'Digital não reconhecida.';

  @override
  String get unlockBiometricReason => 'Desbloqueie seu espaço privado';

  @override
  String get privateTileEmpty => 'Espaço privado, vazio';

  @override
  String privateTileHidden(int count) {
    return 'Espaço privado, $count ocultas';
  }

  @override
  String get settingsSectionPrivacy => 'Privacidade';

  @override
  String get settingsPrivateSpaceSubtitle => 'Oculte apps atrás de um PIN';

  @override
  String get settingsOn => 'Ativado';

  @override
  String get settingsOff => 'Desativado';

  @override
  String get componentBaseApk => 'APK base';

  @override
  String get componentSplitApk => 'APK dividido';

  @override
  String get componentNoNativeLibraries => 'Sem bibliotecas nativas';
}
