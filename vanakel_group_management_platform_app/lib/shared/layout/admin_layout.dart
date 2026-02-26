import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/scaffold_with_navbar.dart';

class AdminLayout extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AdminLayout({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return ScaffoldWithNavBar(navigationShell: navigationShell);
  }
}
