import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/app_language.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_context.dart';
import '../controllers/settings_controller.dart';
import '../widgets/settings_section.dart';

/// Which language the app runs in.
///
/// Searchable because the list is long enough that scrolling to find your own language
/// is the slow way, and a speaker who cannot read the interface language needs to be
/// able to type their own name for it. The search therefore matches the native name,
/// the English name and the locale tag.
class LanguageView extends StatefulWidget {
  const LanguageView({super.key});

  @override
  State<LanguageView> createState() => _LanguageViewState();
}

class _LanguageViewState extends State<LanguageView> {
  final TextEditingController _search = TextEditingController();
  final SettingsController _controller = Get.find<SettingsController>();

  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final List<AppLanguage> matches = AppLanguages.all
        .where((AppLanguage language) => language.matches(_query))
        .toList(growable: false);
    // 'System default' is a row in the list, so it has to answer the search too --
    // otherwise typing 'sys' empties a list that does contain a match. Searched in the
    // current language, not in English, so the row is findable by what it actually says.
    final bool showSystem = _query.trim().isEmpty ||
        '${l10n.languageSystem} ${l10n.languageSystemSubtitle}'
            .toLowerCase()
            .contains(_query.trim().toLowerCase());

    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageTitle)),
      body: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
            child: _searchField(context, l10n),
          ),
          Expanded(
            child: Obx(() {
              final AppLanguage? chosen = _controller.language.value;

              return ListView(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                children: <Widget>[
                  _note(context, l10n),
                  SizedBox(height: 18.h),
                  if (!showSystem && matches.isEmpty)
                    _noMatches(context, l10n)
                  else
                    SettingsSection(
                      title: l10n.languageSectionHeader,
                      children: <Widget>[
                        if (showSystem)
                          _LanguageRow(
                            badge: null,
                            title: l10n.languageSystem,
                            subtitle: l10n.languageSystemSubtitle,
                            selected: chosen == null,
                            onSelect: () => _controller.setLanguage(null),
                          ),
                        for (final AppLanguage language in matches)
                          _LanguageRow(
                            badge: language.badge,
                            title: language.nativeName,
                            subtitle: language.englishName,
                            selected: chosen?.tag == language.tag,
                            onSelect: () => _controller.setLanguage(language),
                          ),
                      ],
                    ),
                ],
              );
            }),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 12.h),
            child: Text(
              l10n.languageInstantNote,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchField(BuildContext context, AppLocalizations l10n) {
    return TextField(
      controller: _search,
      onChanged: (String value) => setState(() => _query = value),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: l10n.languageSearchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _query.isEmpty
            ? null
            : IconButton(
                tooltip: l10n.languageClearSearch,
                icon: const Icon(Icons.close),
                onPressed: () {
                  _search.clear();
                  setState(() => _query = '');
                },
              ),
      ),
    );
  }

  /// Says what the choice governs. 'Language' alone leaves it ambiguous whether this is
  /// the app's language or the language of the apps it clones.
  Widget _note(BuildContext context, AppLocalizations l10n) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        Icon(Icons.language, size: 18.r, color: theme.colorScheme.primary),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            l10n.languageNote(AppConstants.appTitle),
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _noMatches(BuildContext context, AppLocalizations l10n) {
    final ThemeData theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 28.h),
        child: Text(
          l10n.languageNoMatches(_search.text.trim()),
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// One language. The whole row is the target, not just the radio.
class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onSelect,
  });

  /// The characters for the medallion, or null for the globe that stands for the
  /// device's own language — which has no script of its own to show.
  final String? badge;

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String? badge = this.badge;

    return InkWell(
      onTap: onSelect,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        child: Row(
          children: <Widget>[
            Container(
              width: 34.r,
              height: 34.r,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: badge == null
                  ? Icon(
                      Icons.language,
                      size: 18.r,
                      color: theme.colorScheme.primary,
                    )
                  // Scaled down to fit rather than allowed to overflow: the badges are
                  // two characters in scripts of very different widths, and 'Ру' in
                  // Cyrillic is wider than '日' at the same point size.
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4.w),
                        child: Text(
                          badge,
                          // The medallion must not grow with the text scale, or the
                          // rows stop lining up with each other.
                          textScaler: TextScaler.noScaling,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: theme.textTheme.titleSmall),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            RadioGroup<bool>(
              groupValue: selected,
              onChanged: (bool? _) => onSelect(),
              child: Radio<bool>(
                value: true,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
