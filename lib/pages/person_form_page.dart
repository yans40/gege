import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/family_member.dart';
import '../state/family_tree_store.dart';
import '../widgets/person_avatar.dart';

class PersonFormPage extends StatefulWidget {
  PersonFormPage({super.key, this.member});

  final FamilyMember? member;

  @override
  State<PersonFormPage> createState() => _PersonFormPageState();
}

class _PersonFormPageState extends State<PersonFormPage> {
  final _formKey = GlobalKey<FormState>();
  late FamilyMember _draft;
  final _nameCtrl = TextEditingController();
  final _photoCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    if (widget.member != null) {
      _draft = widget.member!;
    } else {
      _draft = FamilyMember(id: _uuid.v4(), displayName: '');
    }
    _nameCtrl.text = _draft.displayName;
    _photoCtrl.text = _draft.photoUrl ?? '';
    _notesCtrl.text = _draft.notes ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _photoCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FamilyTreeStore>();
    final others = store.members.where((m) => m.id != _draft.id).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.member == null ? 'Nouvelle personne' : 'Modifier la personne'),
        actions: [
          IconButton(
            onPressed: _save,
            icon: const Icon(Icons.save),
            tooltip: 'Enregistrer',
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                PersonAvatar(initials: _draft.initials, photoUrl: _draft.photoUrl, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nom et prénom'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
                    onChanged: (v) => setState(() => _draft.displayName = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _photoCtrl,
              decoration: const InputDecoration(labelText: 'URL de la photo (optionnel)'),
              onChanged: (v) => setState(() => _draft.photoUrl = v.trim().isEmpty ? null : v.trim()),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<FamilyGender>(
              decoration: const InputDecoration(labelText: 'Genre'),
              value: _draft.gender,
              items: const [
                DropdownMenuItem(value: FamilyGender.male, child: Text('Homme')),
                DropdownMenuItem(value: FamilyGender.female, child: Text('Femme')),
                DropdownMenuItem(value: FamilyGender.other, child: Text('Autre')),
                DropdownMenuItem(value: FamilyGender.unknown, child: Text('Inconnu')),
              ],
              onChanged: (g) => setState(() => _draft.gender = g ?? FamilyGender.unknown),
            ),
            const SizedBox(height: 16),
            _DateField(
              label: 'Date de naissance',
              value: _draft.birthDate,
              onChanged: (d) => setState(() => _draft.birthDate = d),
            ),
            const SizedBox(height: 8),
            _DateField(
              label: 'Date de décès (optionnel)',
              value: _draft.deathDate,
              onChanged: (d) => setState(() => _draft.deathDate = d),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
              onChanged: (v) => setState(() => _draft.notes = v.trim().isEmpty ? null : v.trim()),
            ),
            const SizedBox(height: 16),
            // Parents
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _draft.motherId,
                    decoration: const InputDecoration(labelText: 'Mère (optionnel)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Non défini')),
                      ...others.map((m) => DropdownMenuItem<String?>(value: m.id, child: Text(m.displayName)))
                    ],
                    onChanged: (id) => setState(() => _draft.motherId = id),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String?>(
                    value: _draft.fatherId,
                    decoration: const InputDecoration(labelText: 'Père (optionnel)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('Non défini')),
                      ...others.map((m) => DropdownMenuItem<String?>(value: m.id, child: Text(m.displayName)))
                    ],
                    onChanged: (id) => setState(() => _draft.fatherId = id),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Partners
            InputDecorator(
              decoration: const InputDecoration(labelText: 'Partenaires (optionnel)', border: OutlineInputBorder()),
              child: Wrap(
                spacing: 8,
                runSpacing: -8,
                children: [
                  ..._draft.partnerIds.map((id) {
                    final person = others.firstWhere((m) => m.id == id, orElse: () => _draft);
                    return Chip(
                      label: Text(person.id == _draft.id ? 'Inconnu' : person.displayName),
                      onDeleted: () => setState(() => _draft.partnerIds.remove(id)),
                    );
                  }),
                  PopupMenuButton<String>(
                    itemBuilder: (_) => [
                      for (final p in others)
                        PopupMenuItem<String>(
                          value: p.id,
                          child: Text(p.displayName),
                        )
                    ],
                    onSelected: (id) {
                      if (!_draft.partnerIds.contains(id)) {
                        setState(() => _draft.partnerIds.add(id));
                      }
                    },
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                      child: Chip(avatar: Icon(Icons.add, size: 18), label: Text('Ajouter')),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            )
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final store = context.read<FamilyTreeStore>();

    // Sync draft with controllers
    _draft
      ..displayName = _nameCtrl.text.trim()
      ..photoUrl = _photoCtrl.text.trim().isEmpty ? null : _photoCtrl.text.trim()
      ..notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();

    store.upsert(_draft);

    // Also link partners symmetrically via store API
    for (final pid in _draft.partnerIds) {
      store.linkPartners(_draft.id, pid);
    }

    Navigator.of(context).pop();
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.label, required this.value, required this.onChanged});

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat.yMMMd();
    return Row(
      children: [
        Expanded(
          child: InputDecorator(
            decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
            child: Text(value != null ? fmt.format(value!) : 'Non défini'),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () async {
            final now = DateTime.now();
            final initial = value ?? DateTime(now.year - 20, now.month, now.day);
            final picked = await showDatePicker(
              context: context,
              firstDate: DateTime(1800),
              lastDate: DateTime(now.year + 1),
              initialDate: initial,
            );
            onChanged(picked);
          },
          icon: const Icon(Icons.event),
          tooltip: 'Choisir une date',
        ),
        IconButton(
          onPressed: () => onChanged(null),
          icon: const Icon(Icons.clear),
          tooltip: 'Effacer',
        ),
      ],
    );
  }
}
