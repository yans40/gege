import 'package:flutter/material.dart';

/// Gender enumeration for family members.
enum FamilyGender { male, female, other, unknown }

FamilyGender genderFromString(String? value) {
  switch (value) {
    case 'male':
      return FamilyGender.male;
    case 'female':
      return FamilyGender.female;
    case 'other':
      return FamilyGender.other;
    case 'unknown':
    default:
      return FamilyGender.unknown;
  }
}

String genderToString(FamilyGender gender) {
  switch (gender) {
    case FamilyGender.male:
      return 'male';
    case FamilyGender.female:
      return 'female';
    case FamilyGender.other:
      return 'other';
    case FamilyGender.unknown:
      return 'unknown';
  }
}

/// A single person in the family tree. Relationships are stored by IDs.
class FamilyMember {
  FamilyMember({
    required this.id,
    required this.displayName,
    this.photoUrl,
    this.birthDate,
    this.deathDate,
    this.notes,
    this.gender = FamilyGender.unknown,
    this.motherId,
    this.fatherId,
    List<String>? partnerIds,
    List<String>? childrenIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : partnerIds = partnerIds ?? <String>[],
        childrenIds = childrenIds ?? <String>[],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  final String id;
  String displayName;
  String? photoUrl;
  DateTime? birthDate;
  DateTime? deathDate;
  String? notes;
  FamilyGender gender;

  String? motherId;
  String? fatherId;
  final List<String> partnerIds;
  final List<String> childrenIds;

  DateTime createdAt;
  DateTime updatedAt;

  String get initials {
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) return '?';
    final parts = trimmed.split(RegExp(r"\s+"));
    String firstInitial = parts.first.isNotEmpty ? parts.first.substring(0, 1) : '';
    String lastInitial = parts.length > 1 && parts.last.isNotEmpty ? parts.last.substring(0, 1) : '';
    final combined = (firstInitial + lastInitial).toUpperCase();
    return combined.isEmpty ? '?' : combined;
  }

  FamilyMember copyWith({
    String? displayName,
    String? photoUrl,
    DateTime? birthDate,
    DateTime? deathDate,
    String? notes,
    FamilyGender? gender,
    String? motherId,
    String? fatherId,
    List<String>? partnerIds,
    List<String>? childrenIds,
  }) {
    return FamilyMember(
      id: id,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      birthDate: birthDate ?? this.birthDate,
      deathDate: deathDate ?? this.deathDate,
      notes: notes ?? this.notes,
      gender: gender ?? this.gender,
      motherId: motherId ?? this.motherId,
      fatherId: fatherId ?? this.fatherId,
      partnerIds: partnerIds ?? List<String>.from(this.partnerIds),
      childrenIds: childrenIds ?? List<String>.from(this.childrenIds),
      createdAt: this.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'photoUrl': photoUrl,
        'birthDate': birthDate?.toIso8601String(),
        'deathDate': deathDate?.toIso8601String(),
        'notes': notes,
        'gender': genderToString(gender),
        'motherId': motherId,
        'fatherId': fatherId,
        'partnerIds': partnerIds,
        'childrenIds': childrenIds,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  static FamilyMember fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      displayName: json['displayName'] as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      birthDate: (json['birthDate'] as String?) != null ? DateTime.tryParse(json['birthDate'] as String) : null,
      deathDate: (json['deathDate'] as String?) != null ? DateTime.tryParse(json['deathDate'] as String) : null,
      notes: json['notes'] as String?,
      gender: genderFromString(json['gender'] as String?),
      motherId: json['motherId'] as String?,
      fatherId: json['fatherId'] as String?,
      partnerIds: (json['partnerIds'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
      childrenIds: (json['childrenIds'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
      createdAt: (json['createdAt'] as String?) != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      updatedAt: (json['updatedAt'] as String?) != null ? DateTime.tryParse(json['updatedAt'] as String) : null,
    );
  }
}
