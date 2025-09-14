import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/family_member.dart';
import '../state/family_tree_store.dart';
import 'person_avatar.dart';

class FamilyTreeVisualization extends StatefulWidget {
  const FamilyTreeVisualization({super.key});

  @override
  State<FamilyTreeVisualization> createState() => _FamilyTreeVisualizationState();
}

class _FamilyTreeVisualizationState extends State<FamilyTreeVisualization> {
  final TransformationController _transformationController = TransformationController();
  double _scale = 1.0;
  Offset _offset = Offset.zero;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

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
        _buildControls(),
        const SizedBox(height: 8),
        // Zone de visualisation
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).dividerColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.1,
              maxScale: 3.0,
              onInteractionUpdate: (details) {
                setState(() {
                  _scale = _transformationController.value.getMaxScaleOnAxis();
                  _offset = Offset(
                    _transformationController.value.getTranslation().x,
                    _transformationController.value.getTranslation().y,
                  );
                });
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: FamilyTreePainter(
                  root: root,
                  store: store,
                  scale: _scale,
                ),
                child: _buildTreeNodes(root, store),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: () => _resetView(),
              icon: const Icon(Icons.center_focus_strong),
              tooltip: 'Centrer la vue',
            ),
            IconButton(
              onPressed: () => _zoomIn(),
              icon: const Icon(Icons.zoom_in),
              tooltip: 'Zoomer',
            ),
            IconButton(
              onPressed: () => _zoomOut(),
              icon: const Icon(Icons.zoom_out),
              tooltip: 'Dézoomer',
            ),
          ],
        ),
        Text(
          'Zoom: ${(_scale * 100).toInt()}%',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  void _resetView() {
    _transformationController.value = Matrix4.identity();
    setState(() {
      _scale = 1.0;
      _offset = Offset.zero;
    });
  }

  void _zoomIn() {
    _transformationController.value = Matrix4.identity()..scale(1.2);
  }

  void _zoomOut() {
    _transformationController.value = Matrix4.identity()..scale(0.8);
  }

  Widget _buildTreeNodes(FamilyMember root, FamilyTreeStore store) {
    final positions = _calculatePositions(root, store);
    
    return Stack(
      children: positions.entries.map((entry) {
        final member = entry.key;
        final position = entry.value;
        
        return Positioned(
          left: position.dx - 60, // Centrer le nœud
          top: position.dy - 40,
          child: _buildMemberNode(member, store),
        );
      }).toList(),
    );
  }

  Map<FamilyMember, Offset> _calculatePositions(FamilyMember root, FamilyTreeStore store) {
    final positions = <FamilyMember, Offset>{};
    final visited = <String>{};
    
    // Position de la racine au centre
    positions[root] = const Offset(400, 200);
    visited.add(root.id);
    
    // Calculer les positions des parents (au-dessus)
    final parents = store.parentsOf(root);
    if (parents.isNotEmpty) {
      final parentY = 100.0;
      final parentSpacing = 200.0;
      final startX = 400.0 - (parents.length - 1) * parentSpacing / 2;
      
      for (int i = 0; i < parents.length; i++) {
        positions[parents[i]] = Offset(startX + i * parentSpacing, parentY);
        visited.add(parents[i].id);
      }
    }
    
    // Calculer les positions des partenaires (à côté)
    final partners = store.partnersOf(root);
    if (partners.isNotEmpty) {
      final partnerY = 200.0;
      final partnerSpacing = 150.0;
      final startX = 600.0; // À droite de la racine
      
      for (int i = 0; i < partners.length; i++) {
        positions[partners[i]] = Offset(startX + i * partnerSpacing, partnerY);
        visited.add(partners[i].id);
      }
    }
    
    // Calculer les positions des enfants (en dessous)
    final children = store.childrenOf(root);
    if (children.isNotEmpty) {
      final childY = 350.0;
      final childSpacing = 180.0;
      final startX = 400.0 - (children.length - 1) * childSpacing / 2;
      
      for (int i = 0; i < children.length; i++) {
        positions[children[i]] = Offset(startX + i * childSpacing, childY);
        visited.add(children[i].id);
      }
    }
    
    return positions;
  }

  Widget _buildMemberNode(FamilyMember member, FamilyTreeStore store) {
    final isRoot = member.id == store.selectedRoot?.id;
    
    return GestureDetector(
      onTap: () => _showMemberDetails(member, store),
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
              color: Colors.black.withOpacity(0.1),
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
    );
  }

  void _showMemberDetails(FamilyMember member, FamilyTreeStore store) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(member.displayName),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PersonAvatar(initials: member.initials, photoUrl: member.photoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Genre: ${_getGenderText(member.gender)}'),
                      if (member.birthDate != null)
                        Text('Né(e): ${_formatDate(member.birthDate!)}'),
                      if (member.deathDate != null)
                        Text('Décédé(e): ${_formatDate(member.deathDate!)}'),
                    ],
                  ),
                ),
              ],
            ),
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

class FamilyTreePainter extends CustomPainter {
  final FamilyMember root;
  final FamilyTreeStore store;
  final double scale;

  FamilyTreePainter({
    required this.root,
    required this.store,
    required this.scale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Dessiner les connexions entre les membres
    _drawConnections(canvas, paint);
  }

  void _drawConnections(Canvas canvas, Paint paint) {
    final positions = _calculatePositions();
    final drawnConnections = <String>{};
    
    // Dessiner les connexions parents-enfants avec des lignes droites
    final parentChildPaint = Paint()
      ..color = Colors.blue.withOpacity(0.8)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;
    
    // Dessiner les connexions partenaires avec des lignes courbes
    final partnerPaint = Paint()
      ..color = Colors.pink.withOpacity(0.8)
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
            final connectionKey = '${member.id}-${mother.id}';
            if (!drawnConnections.contains(connectionKey)) {
              _drawSimpleLine(canvas, parentChildPaint, memberPos, motherPos, 'M');
              drawnConnections.add(connectionKey);
            }
          }
        }
      }
      
      if (member.fatherId != null) {
        final father = store.byId(member.fatherId);
        if (father != null) {
          final fatherPos = positions[father];
          if (fatherPos != null) {
            final connectionKey = '${member.id}-${father.id}';
            if (!drawnConnections.contains(connectionKey)) {
              _drawSimpleLine(canvas, parentChildPaint, memberPos, fatherPos, 'F');
              drawnConnections.add(connectionKey);
            }
          }
        }
      }
      
      // Connexion vers les partenaires
      for (final partnerId in member.partnerIds) {
        final partner = store.byId(partnerId);
        if (partner != null) {
          final partnerPos = positions[partner];
          if (partnerPos != null) {
            final connectionKey = '${member.id}-${partner.id}';
            final reverseKey = '${partner.id}-${member.id}';
            if (!drawnConnections.contains(connectionKey) && !drawnConnections.contains(reverseKey)) {
              _drawCurvedLine(canvas, partnerPaint, memberPos, partnerPos);
              drawnConnections.add(connectionKey);
              drawnConnections.add(reverseKey);
            }
          }
        }
      }
    }
  }

  void _drawSimpleLine(Canvas canvas, Paint paint, Offset pos1, Offset pos2, String gender) {
    // Ligne simple entre les deux positions
    canvas.drawLine(pos1, pos2, paint);
    
    // Ajouter un petit indicateur de genre au milieu
    final midPoint = Offset((pos1.dx + pos2.dx) / 2, (pos1.dy + pos2.dy) / 2);
    _drawGenderIndicator(canvas, paint, midPoint, gender);
  }

  void _drawCurvedLine(Canvas canvas, Paint paint, Offset pos1, Offset pos2) {
    final path = Path();
    
    // Créer une courbe simple entre les deux positions
    final midX = (pos1.dx + pos2.dx) / 2;
    final midY = (pos1.dy + pos2.dy) / 2;
    final controlPoint = Offset(midX, midY - 30);
    
    path.moveTo(pos1.dx, pos1.dy);
    path.quadraticBezierTo(controlPoint.dx, controlPoint.dy, pos2.dx, pos2.dy);
    
    canvas.drawPath(path, paint);
    
    // Ajouter un petit cœur au milieu de la ligne
    _drawHeart(canvas, paint, Offset(midX, midY - 15));
  }


  void _drawGenderIndicator(Canvas canvas, Paint paint, Offset point, String gender) {
    final indicatorPaint = Paint()
      ..color = gender == 'M' ? Colors.blue : Colors.pink
      ..style = PaintingStyle.fill;
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: gender,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    
    final circleCenter = Offset(point.dx, point.dy - 15);
    canvas.drawCircle(circleCenter, 8, indicatorPaint);
    
    textPainter.paint(
      canvas,
      Offset(circleCenter.dx - textPainter.width / 2, circleCenter.dy - textPainter.height / 2),
    );
  }

  void _drawHeart(Canvas canvas, Paint paint, Offset center) {
    final heartPaint = Paint()
      ..color = Colors.pink.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final size = 6.0;
    
    path.moveTo(center.dx, center.dy + size);
    path.cubicTo(
      center.dx - size, center.dy - size / 2,
      center.dx - size * 2, center.dy - size / 2,
      center.dx - size * 2, center.dy + size / 2,
    );
    path.cubicTo(
      center.dx - size * 2, center.dy + size,
      center.dx - size, center.dy + size * 1.5,
      center.dx, center.dy + size * 2,
    );
    path.cubicTo(
      center.dx + size, center.dy + size * 1.5,
      center.dx + size * 2, center.dy + size,
      center.dx + size * 2, center.dy + size / 2,
    );
    path.cubicTo(
      center.dx + size * 2, center.dy - size / 2,
      center.dx + size, center.dy - size / 2,
      center.dx, center.dy + size,
    );
    
    canvas.drawPath(path, heartPaint);
  }

  Map<FamilyMember, Offset> _calculatePositions() {
    final positions = <FamilyMember, Offset>{};
    final baseX = 500.0; // Position X de base
    final baseY = 250.0; // Position Y de base
    
    // Position de la racine au centre
    positions[root] = Offset(baseX, baseY);
    
    // Calculer les positions des parents (au-dessus)
    final parents = store.parentsOf(root);
    if (parents.isNotEmpty) {
      final parentY = baseY - 120.0;
      final parentSpacing = 180.0;
      final startX = baseX - (parents.length - 1) * parentSpacing / 2;
      
      for (int i = 0; i < parents.length; i++) {
        positions[parents[i]] = Offset(startX + i * parentSpacing, parentY);
      }
    }
    
    // Calculer les positions des partenaires (à côté)
    final partners = store.partnersOf(root);
    if (partners.isNotEmpty) {
      final partnerY = baseY;
      final partnerSpacing = 160.0;
      final startX = baseX + 200.0; // À droite de la racine
      
      for (int i = 0; i < partners.length; i++) {
        positions[partners[i]] = Offset(startX + i * partnerSpacing, partnerY);
      }
    }
    
    // Calculer les positions des enfants (en dessous)
    final children = store.childrenOf(root);
    if (children.isNotEmpty) {
      final childY = baseY + 120.0;
      final childSpacing = 160.0;
      final startX = baseX - (children.length - 1) * childSpacing / 2;
      
      for (int i = 0; i < children.length; i++) {
        positions[children[i]] = Offset(startX + i * childSpacing, childY);
      }
    }
    
    // Ajouter les grands-parents si les parents en ont
    for (final parent in parents) {
      final grandparents = store.parentsOf(parent);
      if (grandparents.isNotEmpty) {
        final grandparentY = baseY - 240.0;
        final grandparentSpacing = 150.0;
        final parentX = positions[parent]!.dx;
        final startX = parentX - (grandparents.length - 1) * grandparentSpacing / 2;
        
        for (int i = 0; i < grandparents.length; i++) {
          positions[grandparents[i]] = Offset(startX + i * grandparentSpacing, grandparentY);
        }
      }
    }
    
    // Ajouter les petits-enfants si les enfants en ont
    for (final child in children) {
      final grandchildren = store.childrenOf(child);
      if (grandchildren.isNotEmpty) {
        final grandchildY = baseY + 240.0;
        final grandchildSpacing = 140.0;
        final childX = positions[child]!.dx;
        final startX = childX - (grandchildren.length - 1) * grandchildSpacing / 2;
        
        for (int i = 0; i < grandchildren.length; i++) {
          positions[grandchildren[i]] = Offset(startX + i * grandchildSpacing, grandchildY);
        }
      }
    }
    
    return positions;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
