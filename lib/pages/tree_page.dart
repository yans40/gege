import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/family_member.dart';
import '../state/family_tree_store.dart';
import '../widgets/person_avatar.dart';
import 'person_form_page.dart';

class TreePage extends StatelessWidget {
  const TreePage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FamilyTreeStore>();
    final root = store.selectedRoot;

    if (store.members.isEmpty) {
      return _EmptyTree(onAdd: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => PersonFormPage()));
      });
    }

    if (root == null) {
      return const Center(child: Text('Sélectionnez une personne comme racine.'));
    }

    final parents = store.parentsOf(root);
    final children = store.childrenOf(root);
    final partners = store.partnersOf(root);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Racine', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        _PersonCard(member: root, highlight: true),
        const SizedBox(height: 16),
        if (partners.isNotEmpty) ...[
          Text('Partenaires', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final p in partners) _PersonCard(member: p),
          ]),
          const SizedBox(height: 16),
        ],
        Text('Parents', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        parents.isEmpty
            ? const Text('Aucun parent défini')
            : Wrap(spacing: 8, runSpacing: 8, children: [
                for (final p in parents) _PersonCard(member: p),
              ]),
        const SizedBox(height: 16),
        Text('Enfants', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        children.isEmpty
            ? const Text('Aucun enfant')
            : Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in children) _PersonCard(member: c),
              ]),
        const SizedBox(height: 16),
        Row(
          children: [
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PersonFormPage())),
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Ajouter une personne'),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () async {
                final selected = await _selectRootDialog(context, store);
                if (selected != null) store.selectedRoot = selected;
              },
              icon: const Icon(Icons.account_tree),
              label: const Text('Changer la racine'),
            ),
          ],
        )
      ],
    );
  }

  Future<FamilyMember?> _selectRootDialog(BuildContext context, FamilyTreeStore store) async {
    return showDialog<FamilyMember>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Choisir une racine'),
        content: SizedBox(
          width: 400,
          height: 400,
          child: ListView.builder(
            itemCount: store.members.length,
            itemBuilder: (context, index) {
              final m = store.members[index];
              return ListTile(
                leading: PersonAvatar(initials: m.initials, photoUrl: m.photoUrl),
                title: Text(m.displayName),
                onTap: () => Navigator.pop(context, m),
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.member, this.highlight = false});

  final FamilyMember member;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bg = highlight ? theme.colorScheme.primaryContainer : theme.colorScheme.surface;
    final border = Border.all(
      color: highlight ? theme.colorScheme.primary : theme.dividerColor,
    );

    return Container(
      constraints: const BoxConstraints(minWidth: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PersonAvatar(initials: member.initials, photoUrl: member.photoUrl),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(member.displayName, style: theme.textTheme.titleMedium),
              if (member.notes != null && member.notes!.isNotEmpty)
                Text(
                  member.notes!,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 2,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyTree extends StatelessWidget {
  const _EmptyTree({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.account_tree_outlined, size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            const Text('Votre arbre est vide.'),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Ajouter une première personne'),
            )
          ],
        ),
      ),
    );
  }
}
