import 'package:equatable/equatable.dart';

class AdmissionNoteAuthor extends Equatable {
  const AdmissionNoteAuthor({
    required this.id,
    required this.name,
    required this.role,
  });

  final int id;
  final String name;
  final String role;

  factory AdmissionNoteAuthor.fromJson(dynamic raw) {
    if (raw is Map<String, dynamic>) {
      return AdmissionNoteAuthor(
        id: (raw['id'] as num?)?.toInt() ?? 0,
        name: raw['name']?.toString() ?? '',
        role: raw['role']?.toString() ?? '',
      );
    }
    return const AdmissionNoteAuthor(id: 0, name: '', role: '');
  }

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      final s = parts.first;
      return s.substring(0, s.length >= 2 ? 2 : 1).toUpperCase();
    }
    return ('${parts.first[0]}${parts.last[0]}').toUpperCase();
  }

  @override
  List<Object?> get props => [id, name, role];
}

class AdmissionTimelineNote extends Equatable {
  const AdmissionTimelineNote({
    required this.id,
    required this.admissionId,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    this.author,
  });

  final int id;
  final int admissionId;
  final String content;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;
  final AdmissionNoteAuthor? author;

  factory AdmissionTimelineNote.fromJson(Map<String, dynamic> json) =>
      AdmissionTimelineNote(
        id: (json['id'] as num).toInt(),
        admissionId: (json['admission_id'] as num?)?.toInt() ?? 0,
        content: json['content']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
        updatedAt: json['updated_at']?.toString() ?? '',
        deletedAt: json['deleted_at']?.toString(),
        author: json['added_by'] == null
            ? null
            : AdmissionNoteAuthor.fromJson(json['added_by']),
      );

  @override
  List<Object?> get props =>
      [id, admissionId, content, createdAt, updatedAt, deletedAt, author];
}
