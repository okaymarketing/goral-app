import 'package:flutter/material.dart';
import '../../core/security/authorization_guard.dart';

class SecureWidget extends StatelessWidget {
  final Widget child;
  final String requiredPermission;
  final String userRole;

  const SecureWidget({
    super.key,
    required this.child,
    required this.requiredPermission,
    required this.userRole,
  });

  @override
  Widget build(BuildContext context) {
    if (AuthorizationGuard.checkPermission(requiredPermission, userRole)) {
      return child;
    }
    return const SizedBox.shrink();
  }
}