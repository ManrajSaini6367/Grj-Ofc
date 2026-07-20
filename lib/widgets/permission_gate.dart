import 'package:flutter/material.dart';
import 'package:grjoffice_apps/services/permission_service.dart';

/// Shows [child] only when the user has [permission] (or any of [anyOf]).
class PermissionGate extends StatelessWidget {
  const PermissionGate({
    super.key,
    this.permission,
    this.anyOf,
    required this.child,
    this.fallback = const SizedBox.shrink(),
  }) : assert(
          permission != null || (anyOf != null && anyOf.length > 0),
          'Provide permission or anyOf',
        );

  final String? permission;
  final Iterable<String>? anyOf;
  final Widget child;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: PermissionService.instance,
      builder: (context, _) {
        final allowed = permission != null
            ? PermissionService.instance.can(permission!)
            : PermissionService.instance.canAny(anyOf!);
        return allowed ? child : fallback;
      },
    );
  }
}
