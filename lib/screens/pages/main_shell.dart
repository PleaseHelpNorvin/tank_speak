import 'package:flutter/material.dart';

import '../../models/me_response.dart';
import '../../services/auth_service.dart';
import 'home_screen.dart';
import 'invitations_screen.dart';
import 'profile_screen.dart';

/// Signed-in home with bottom navigation: Home, Invitations, Profile.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.me, this.initialIndex = 0});

  final MeResponse me;
  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  // Bumped to make a tab reload when it is selected again.
  final List<int> _generation = [0, 0, 0];

  @override
  Widget build(BuildContext context) {
    final me = AuthService.instance.me ?? widget.me;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          HomeScreen(key: ValueKey('home-${_generation[0]}'), me: me, inShell: true),
          InvitationsScreen(
              key: ValueKey('inv-${_generation[1]}'), me: me, inShell: true),
          ProfileScreen(
              key: ValueKey('me-${_generation[2]}'), me: me, inShell: true),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) {
          setState(() {
            if (i == _index || i == 1) _generation[i]++;
            _index = i;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.mail_outline),
            selectedIcon: Icon(Icons.mail),
            label: 'Invitations',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
