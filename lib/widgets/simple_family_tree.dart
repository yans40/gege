import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/family_member.dart';
import '../state/family_tree_store.dart';
import 'person_avatar.dart';

class SimpleFamilyTree extends StatelessWidget {
  const SimpleFamilyTree({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<FamilyTreeStore>();
    final root = store.selectedRoot;

    if (store.members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun arbre à visualiser'),
            Text('Ajoutez des membres de famille pour voir la visualisation'),
          ],
        ),
      );
    }

    if (root == null) {
      return const Center(child: Text('Sélectionnez une racine pour visualiser l\'arbre'));
    }

    return Column(
      children: [
        // Contrôles de zoom et navigation
        _buildControls(context),
        const SizedBox(height: 8),
        // Zone de visualisation
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InteractiveViewer(
              minScale: 0.1,
              maxScale: 3.0,
              child: CustomPaint(
                size: Size.infinite,
                painter: SimpleTreePainter(
                  root: root,
                  store: store,
                ),
                child: _buildTreeNodes(root, store),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.center_focus_strong),
              tooltip: 'Centrer la vue',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Zoomer',
            ),
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Dézoomer',
            ),
          ],
        ),
        Text(
          'Visualisation simplifiée',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTreeNodes(FamilyMember root, FamilyTreeStore store) {
    final positions = _calculatePositions(root, store);
    
    return Stack(
      children: positions.entries.map((entry) {
        final member = entry.key;
        final position = entry.value;
        
        return Positioned(
          left: position.dx - 60,
          top: position.dy - 40,
          child: _buildMemberNode(member, store),
        );
      }).toList(),
    );
  }

  Map<FamilyMember, Offset> _calculatePositions(FamilyMember root, FamilyTreeStore store) {
    final positions = <FamilyMember, Offset>{};
    final baseX = 500.0;
    final baseY = 250.0;
    
    // Position de la racine au centre
    positions[root] = Offset(baseX, baseY);
    
    // Parents au-dessus
    final parents = store.parentsOf(root);
    if (parents.isNotEmpty) {
      final parentY = baseY - 120.0;
      final parentSpacing = 180.0;
      final startX = baseX - (parents.length - 1) * parentSpacing / 2;
      
      for (int i = 0; i < parents.length; i++) {
        positions[parents[i]] = Offset(startX + i * parentSpacing, parentY);
      }
    }
    
    // Partenaires à côté
    final partners = store.partnersOf(root);
    if (partners.isNotEmpty) {
      final partnerY = baseY;
      final partnerSpacing = 160.0;
      final startX = baseX + 200.0;
      
      for (int i = 0; i < partners.length; i++) {
        positions[partners[i]] = Offset(startX + i * partnerSpacing, partnerY);
      }
    }
    
    // Enfants en dessous
    final children = store.childrenOf(root);
    if (children.isNotEmpty) {
      final childY = baseY + 120.0;
      final childSpacing = 160.0;
      final startX = baseX - (children.length - 1) * childSpacing / 2;
      
      for (int i = 0; i < children.length; i++) {
        positions[children[i]] = Offset(startX + i * childSpacing, childY);
      }
    }
    
    return positions;
  }

  Widget _buildMemberNode(FamilyMember member, FamilyTreeStore store) {
    final isRoot = member.id == store.selectedRoot?.id;
    
    return Builder(
      builder: (context) => GestureDetector(
        onTap: () => _showMemberDetails(context, member, store),
        child: Container(
          width: 120,
          height: 80,
          decoration: BoxDecoration(
            color: isRoot 
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isRoot 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
              width: isRoot ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PersonAvatar(
                initials: member.initials,
                photoUrl: member.photoUrl,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                member.displayName,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: isRoot ? FontWeight.bold : FontWeight.normal,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberDetails(BuildContext context, FamilyMember member, FamilyTreeStore store) {
    // Simple dialog pour les détails
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Genre: ${_getGenderText(member.gender)}'),
            if (member.birthDate != null)
              Text('Né(e): ${_formatDate(member.birthDate!)}'),
            if (member.deathDate != null)
              Text('Décédé(e): ${_formatDate(member.deathDate!)}'),
            const SizedBox(height: 16),
            Text('Relations:', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Text('Parents: ${store.parentsOf(member).length}'),
            Text('Partenaires: ${store.partnersOf(member).length}'),
            Text('Enfants: ${store.childrenOf(member).length}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () {
              store.selectedRoot = member;
              Navigator.pop(context);
            },
            child: const Text('Définir comme racine'),
          ),
        ],
      ),
    );
  }

  String _getGenderText(FamilyGender gender) {
    switch (gender) {
      case FamilyGender.male:
        return 'Homme';
      case FamilyGender.female:
        return 'Femme';
      case FamilyGender.other:
        return 'Autre';
      case FamilyGender.unknown:
        return 'Non spécifié';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class SimpleTreePainter extends CustomPainter {
  final FamilyMember root;
  final FamilyTreeStore store;

  SimpleTreePainter({
    required this.root,
    required this.store,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final positions = _calculatePositions();
    
    // Dessiner les connexions parents-enfants
    final parentChildPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    // Dessiner les connexions partenaires
    final partnerPaint = Paint()
      ..color = Colors.pink.withValues(alpha: 0.8)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    
    for (final member in store.members) {
      final memberPos = positions[member];
      if (memberPos == null) continue;
      
      // Connexion vers les parents
      if (member.motherId != null) {
        final mother = store.byId(member.motherId);
        if (mother != null) {
          final motherPos = positions[mother];
          if (motherPos != null) {
            canvas.drawLine(memberPos, motherPos, parentChildPaint);
          }
        }
      }
      
      if (member.fatherId != null) {
        final father = store.byId(member.fatherId);
        if (father != null) {
          final fatherPos = positions[father];
          if (fatherPos != null) {
            canvas.drawLine(memberPos, fatherPos, parentChildPaint);
          }
        }
      }
      
      // Connexion vers les partenaires
      for (final partnerId in member.partnerIds) {
        final partner = store.byId(partnerId);
        if (partner != null) {
          final partnerPos = positions[partner];
          if (partnerPos != null) {
            // Dessiner une courbe simple
            final path = Path();
            final midX = (memberPos.dx + partnerPos.dx) / 2;
            final midY = (memberPos.dy + partnerPos.dy) / 2;
            final controlPoint = Offset(midX, midY - 30);
            
            path.moveTo(memberPos.dx, memberPos.dy);
            path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, partnerPos.dx, partnerPos.dy);
            
            canvas.drawPath(path, partnerPaint);
          }
        }
      }
    }
  }

  Map<FamilyMember, Offset> _calculatePositions() {
    final positions = <FamilyMember, Offset>{};
    final baseX = 500.0;
    final baseY = 250.0;
    
    // Position de la racine au centre
    positions[root] = Offset(baseX, baseY);
    
    // Parents au-dessus
    final parents = store.parentsOf(root);
    if (parents.isNotEmpty) {
      final parentY = baseY - 120.0;
      final parentSpacing = 180.0;
      final startX = baseX - (parents.length - 1) * parentSpacing / 2;
      
      for (int i = 0; i < parents.length; i++) {
        positions[parents[i]] = Offset(startX + i * parentSpacing, parentY);
      }
    }
    
    // Partenaires à côté
    final partners = store.partnersOf(root);
    if (partners.isNotEmpty) {
      final partnerY = baseY;
      final partnerSpacing = 160.0;
      final startX = baseX + 200.0;
      
      for (int i = 0; i < partners.length; i++) {
        positions[partners[i]] = Offset(startX + i * partnerSpacing, partnerY);
      }
    }
    
    // Enfants en dessous
    final children = store.childrenOf(root);
    if (children.isNotEmpty) {
      final childY = baseY + 120.0;
      final childSpacing = 160.0;
      final startX = baseX - (children.length - 1) * childSpacing / 2;
      
      for (int i = 0; i < children.length; i++) {
        positions[children[i]] = Offset(startX + i * childSpacing, childY);
      }
    }
    
    return positions;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
