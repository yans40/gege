import 'package:flutter/material.dart';
import 'package:gege/theme.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'state/family_tree_store.dart';

void main() {
  debugPrint('BOOT: main() entered');
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => FamilyTreeStore(),
      child: MaterialApp(
        title: 'Généalogie',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: ThemeMode.system,
        home: const HomePage(),
      ),
    );
  }
}


