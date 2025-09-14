import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/family_member.dart';

class FamilyTreeStore extends ChangeNotifier {
  FamilyTreeStore();

  final _uuid = const Uuid();
  static const String _membersKey = 'family_members';
  static const String _selectedRootKey = 'selected_root_id';

  final List<FamilyMember> _members = <FamilyMember>[];
  String? _selectedRootId;
  bool _initialized = false;

  bool get initialized => _initialized;
  List<FamilyMember> get members => List.unmodifiable(_members);
  FamilyMember? get selectedRoot {
    final found = byId(_selectedRootId);
    if (found != null) return found;
    return _members.isNotEmpty ? _members.first : null;
  }

  set selectedRoot(FamilyMember? value) {
    _selectedRootId = value?.id;
    notifyListeners();
    _save(); // Auto-save when root changes
  }

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load members from storage
      final membersJson = prefs.getString(_membersKey);
      if (membersJson != null) {
        final List<dynamic> membersList = json.decode(membersJson);
        _members.clear();
        _members.addAll(
          membersList.map((json) => FamilyMember.fromJson(json as Map<String, dynamic>))
        );
      }
      
      // Load selected root
      _selectedRootId = prefs.getString(_selectedRootKey);
      if (_selectedRootId != null && byId(_selectedRootId) == null) {
        _selectedRootId = null; // Reset if root doesn't exist
      }
      _selectedRootId ??= _members.isNotEmpty ? _members.first.id : null;
      
      _initialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading family tree data: $e');
      _initialized = true;
      notifyListeners();
    }
  }

  FamilyMember createEmpty({String name = ''}) {
    return FamilyMember(id: _uuid.v4(), displayName: name);
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save members
      final membersJson = json.encode(_members.map((m) => m.toJson()).toList());
      await prefs.setString(_membersKey, membersJson);
      
      // Save selected root
      if (_selectedRootId != null) {
        await prefs.setString(_selectedRootKey, _selectedRootId!);
      } else {
        await prefs.remove(_selectedRootKey);
      }
    } catch (e) {
      debugPrint('Error saving family tree data: $e');
    }
  }

  void upsert(FamilyMember member) {
    final index = _members.indexWhere((m) => m.id == member.id);
    if (index == -1) {
      _members.add(member);
      _selectedRootId ??= member.id;
    } else {
      _members[index] = member..updatedAt = DateTime.now();
    }
    notifyListeners();
    _save(); // Auto-save when members change
  }

  void deleteById(String id) {
    _members.removeWhere((m) => m.id == id);
    for (final m in _members) {
      m.partnerIds.remove(id);
      m.childrenIds.remove(id);
      if (m.motherId == id) m.motherId = null;
      if (m.fatherId == id) m.fatherId = null;
    }
    if (_selectedRootId == id) {
      _selectedRootId = _members.isNotEmpty ? _members.first.id : null;
    }
    notifyListeners();
    _save(); // Auto-save when members are deleted
  }

  FamilyMember? byId(String? id) {
    if (id == null) return null;
    for (final m in _members) {
      if (m.id == id) return m;
    }
    return null;
  }

  List<FamilyMember> childrenOf(FamilyMember person) {
    return _members.where((m) => m.motherId == person.id || m.fatherId == person.id).toList();
  }

  List<FamilyMember> parentsOf(FamilyMember person) {
    final list = <FamilyMember>[];
    final mom = byId(person.motherId);
    final dad = byId(person.fatherId);
    if (mom != null) list.add(mom);
    if (dad != null) list.add(dad);
    return list;
  }

  List<FamilyMember> partnersOf(FamilyMember person) {
    return _members.where((m) => person.partnerIds.contains(m.id)).toList();
  }

  void linkPartners(String aId, String bId) {
    final a = byId(aId);
    final b = byId(bId);
    if (a == null || b == null) return;
    if (!a.partnerIds.contains(bId)) a.partnerIds.add(bId);
    if (!b.partnerIds.contains(aId)) b.partnerIds.add(aId);
    notifyListeners();
    _save(); // Auto-save when relationships change
  }

  void unlinkPartners(String aId, String bId) {
    final a = byId(aId);
    final b = byId(bId);
    if (a == null || b == null) return;
    a.partnerIds.remove(bId);
    b.partnerIds.remove(aId);
    notifyListeners();
    _save(); // Auto-save when relationships change
  }

  // Export data as JSON string
  String exportData() {
    return json.encode({
      'members': _members.map((m) => m.toJson()).toList(),
      'selectedRootId': _selectedRootId,
      'exportDate': DateTime.now().toIso8601String(),
    });
  }

  // Import data from JSON string
  Future<bool> importData(String jsonData) async {
    try {
      final Map<String, dynamic> data = json.decode(jsonData);
      final List<dynamic> membersList = data['members'] as List<dynamic>;
      
      _members.clear();
      _members.addAll(
        membersList.map((json) => FamilyMember.fromJson(json as Map<String, dynamic>))
      );
      
      _selectedRootId = data['selectedRootId'] as String?;
      if (_selectedRootId != null && byId(_selectedRootId) == null) {
        _selectedRootId = _members.isNotEmpty ? _members.first.id : null;
      }
      
      notifyListeners();
      await _save();
      return true;
    } catch (e) {
      debugPrint('Error importing data: $e');
      return false;
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    _members.clear();
    _selectedRootId = null;
    notifyListeners();
    await _save();
  }
}
