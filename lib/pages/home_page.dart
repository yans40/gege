import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/family_tree_store.dart';
import 'people_page.dart';
import 'settings_page.dart';
import 'tree_page.dart';
import 'visual_tree_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  void initState() {
    super.initState();
    // Load local data when page is created
    Future.microtask(() => context.read<FamilyTreeStore>().load());
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const TreePage(),
      const VisualTreePage(),
      const PeoplePage(),
      const SettingsPage(),
    ];

    final titles = <String>['Arbre', 'Visualisation', 'Personnes', 'Paramètres'];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[_index]),
      ),
      body: Consumer<FamilyTreeStore>(
        builder: (context, store, _) {
          if (!store.initialized) {
            return const Center(child: CircularProgressIndicator());
          }
          return pages[_index];
        },
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_tree_outlined), selectedIcon: Icon(Icons.account_tree), label: 'Arbre'),
          NavigationDestination(icon: Icon(Icons.visibility_outlined), selectedIcon: Icon(Icons.visibility), label: 'Visualisation'),
          NavigationDestination(icon: Icon(Icons.people_outline), selectedIcon: Icon(Icons.people), label: 'Personnes'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }
}
