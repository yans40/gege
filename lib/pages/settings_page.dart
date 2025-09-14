import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../state/family_tree_store.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sauvegarde et Export',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _exportData(context),
                          icon: const Icon(Icons.download),
                          label: const Text('Exporter les données'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _importData(context),
                          icon: const Icon(Icons.upload),
                          label: const Text('Importer des données'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Exportez vos données pour les sauvegarder ou les partager. Importez des données depuis un fichier JSON.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gestion des données',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Consumer<FamilyTreeStore>(
                    builder: (context, store, _) {
                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.people),
                            title: const Text('Nombre de membres'),
                            subtitle: Text('${store.members.length} personnes'),
                          ),
                          const Divider(),
                          ListTile(
                            leading: const Icon(Icons.account_tree),
                            title: const Text('Racine actuelle'),
                            subtitle: Text(
                              store.selectedRoot?.displayName ?? 'Aucune racine définie',
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmClearData(context),
                      icon: const Icon(Icons.delete_forever),
                      label: const Text('Effacer toutes les données'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attention : Cette action supprimera définitivement toutes vos données.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _exportData(BuildContext context) {
    final store = context.read<FamilyTreeStore>();
    final jsonData = store.exportData();
    
    // Copy to clipboard
    Clipboard.setData(ClipboardData(text: jsonData));
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Données exportées et copiées dans le presse-papiers !'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _importData(BuildContext context) {
    // Create file input element
    final input = html.FileUploadInputElement()
      ..accept = '.json'
      ..click();
    
    input.onChange.listen((event) {
      final file = input.files?.first;
      if (file != null) {
        final reader = html.FileReader();
        reader.onLoad.listen((event) {
          final content = reader.result as String;
          _processImportData(context, content);
        });
        reader.readAsText(file);
      }
    });
  }

  Future<void> _processImportData(BuildContext context, String jsonData) async {
    final store = context.read<FamilyTreeStore>();
    final success = await store.importData(jsonData);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Données importées avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'importation des données.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer toutes les données'),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer définitivement toutes vos données ? '
          'Cette action ne peut pas être annulée.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final store = context.read<FamilyTreeStore>();
      await store.clearAllData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Toutes les données ont été supprimées.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }
}
