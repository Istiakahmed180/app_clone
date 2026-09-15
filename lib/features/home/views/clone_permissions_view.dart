import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/clone_permissions.dart';
import '../../../data/models/virtual_profile_model.dart';
import '../../../core/errors/app_error_text.dart';
import '../../../core/errors/app_exception.dart';
import '../../../l10n/app_localizations.dart';
import '../../../l10n/l10n_context.dart';
import '../../../widgets/empty_state.dart';
import '../controllers/home_controller.dart';

/// Which permissions one clone's app may use.
///
/// The control is a deny-list, so an untouched clone behaves as before: everything the host
/// holds is available. The user narrows from there.
class ClonePermissionsView extends StatefulWidget {
  const ClonePermissionsView({
    required this.controller,
    required this.profile,
    super.key,
  });

  final HomeController controller;
  final VirtualProfileModel profile;

  @override
  State<ClonePermissionsView> createState() => _ClonePermissionsViewState();
}

class _ClonePermissionsViewState extends State<ClonePermissionsView> {
  ClonePermissions? _data;
  bool _loading = true;
  String? _error;
  final Set<String> _denied = <String>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ClonePermissions permissions =
          await widget.controller.clonePermissions(widget.profile);
      if (!mounted) {
        return;
      }
      setState(() {
        _data = permissions;
        _denied
          ..clear()
          ..addAll(permissions.denied);
        _loading = false;
        _error = null;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '$error';
      });
    }
  }

  Future<void> _toggle(String permission, bool allowed) async {
    final bool wasDenied = _denied.contains(permission);
    setState(() {
      if (allowed) {
        _denied.remove(permission);
      } else {
        _denied.add(permission);
      }
    });

    final AppException? failure = await widget.controller.setClonePermission(
      widget.profile,
      permission,
      allowed,
    );
    if (failure == null || !mounted) {
      return;
    }
    // Put the switch back: the policy did not change, so the screen must not claim it did.
    setState(() {
      if (wasDenied) {
        _denied.add(permission);
      } else {
        _denied.remove(permission);
      }
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(appErrorMessage(context.l10n, failure))),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.clonePermissionsTitle(widget.profile.appName)),
      ),
      body: _body(context, theme),
    );
  }

  Widget _body(BuildContext context, ThemeData theme) {
    final AppLocalizations l10n = context.l10n;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: EmptyState(
          icon: Icons.error_outline,
          title: l10n.clonePermissionsErrorTitle,
          message: _error!,
        ),
      );
    }

    final ClonePermissions data = _data!;
    if (data.permissions.isEmpty) {
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: EmptyState(
          icon: Icons.lock_open_outlined,
          title: l10n.clonePermissionsEmptyTitle,
          message: l10n.clonePermissionsEmptyMessage,
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 28.h),
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 16.h),
          child: Text(
            l10n.clonePermissionsNote(AppConstants.appTitle),
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        Card(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: <Widget>[
              for (final String permission in data.permissions)
                SwitchListTile(
                  value: !_denied.contains(permission),
                  onChanged: (bool allowed) => _toggle(permission, allowed),
                  title: Text(ClonePermissions.label(permission)),
                  subtitle: Text(permission, style: theme.textTheme.bodySmall),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
