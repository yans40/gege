import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/family_member.dart';
import '../state/family_tree_store.dart';
import '../widgets/person_avatar.dart';
import 'person_form_page.dart';

class PeoplePage extends StatefulWidget {
  const PeoplePage({super.key});

  @override
  State<PeoplePage> createState() => _PeoplePageState();
}

class _PeoplePageState extends State<PeoplePage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FamilyTreeStore>();
    final members = store.members
        .where((m) => m.displayName.toLowerCase().contains(_query.toLowerCase()))
        .toList()
      ..sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Rechercher une personne',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PersonFormPage()),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
          ),
        ),
        Expanded(
          child: members.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  itemCount: members.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final m = members[index];
                    return ListTile(
                      leading: PersonAvatar(initials: m.initials, photoUrl: m.photoUrl),
                      title: Text(m.displayName),
                      subtitle: Text(_personSubtitle(m)),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PersonFormPage(member: m)),
                            );
                          } else if (value == 'delete') {
                            _confirmDelete(context, m);
                          } else if (value == 'set_root') {
                            store.selectedRoot = m;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                          const PopupMenuItem(value: 'set_root', child: Text("Définir comme racine")),
                          const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
                        ],
                      ),
                    );
                  },
                ),
        )
      ],
    );
  }

  String _personSubtitle(FamilyMember m) {
    final fmt = DateFormat.yMMMd();
    final b = m.birthDate != null ? fmt.format(m.birthDate!) : null;
    final d = m.deathDate != null ? fmt.format(m.deathDate!) : null;
    if (b != null && d != null) return '$b — $d';
    if (b != null) return 'Né(e) le $b';
    if (d != null) return 'Décédé(e) le $d';
    return 'Sans dates';
  }

  void _confirmDelete(BuildContext context, FamilyMember m) async {
    final store = context.read<FamilyTreeStore>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la personne ?'),
        content: Text('Êtes-vous sûr de vouloir supprimer ${m.displayName} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer')),
        ],
      ),
    );

    if (ok == true) {
      store.deleteById(m.id);
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            const Text(
              'Aucune personne pour le moment',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text('Ajoutez une première personne pour commencer votre arbre.'),
          ],
        ),
      ),
    );
  }
}
