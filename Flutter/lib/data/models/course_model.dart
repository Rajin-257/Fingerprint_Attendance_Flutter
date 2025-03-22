
import 'dart:convert';

class Course {
  final int? id;
  final int? serverId;
  final String name;
  final String code;
  final String? description;
  final double creditHours;
  final Map<String, dynamic>? schedule;
  final bool active;
  final int departmentId;
  final int sectionId;
  final int? teacherId;
  final int instituteId;
  final String createdAt;
  final String? updatedAt;
  final bool synced;

  // Department and section details
  String? departmentName;
  String? departmentCode;
  String? sectionName;
  String? sectionCode;
  String? teacherName;

  Course({
    this.id,
    this.serverId,
    required this.name,
    required this.code,
    this.description,
    this.creditHours = 3.0,
    this.schedule,
    this.active = true,
    required this.departmentId,
    required this.sectionId,
    this.teacherId,
    required this.instituteId,
    required this.createdAt,
    this.updatedAt,
    this.synced = false,
    this.departmentName,
    this.departmentCode,
    this.sectionName,
    this.sectionCode,
    this.teacherName,
  });

  // Convert from Map
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'],
      serverId: map['serverCourseId'],
      name: map['name'],
      code: map['code'],
      description: map['description'],
      creditHours: map['creditHours']?.toDouble() ?? 3.0,
      schedule: map['schedule'] != null
          ? map['schedule'] is String
              ? _parseSchedule(map['schedule'])
              : map['schedule']
          : null,
      active: map['active'] == 1,
      departmentId: map['departmentId'],
      sectionId: map['sectionId'],
      teacherId: map['teacherId'],
      instituteId: map['instituteId'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      synced: map['synced'] == 1,
      // Optional related fields
      departmentName: map['department']?['name'] ?? map['departmentName'],
      departmentCode: map['department']?['code'] ?? map['departmentCode'],
      sectionName: map['section']?['name'] ?? map['sectionName'],
      sectionCode: map['section']?['code'] ?? map['sectionCode'],
      teacherName: map['teacher'] != null
          ? '${map['teacher']['firstName']} ${map['teacher']['lastName']}'
          : map['teacherName'],
    );
  }

  // Parse schedule JSON string
  static Map<String, dynamic>? _parseSchedule(String? scheduleStr) {
    if (scheduleStr == null || scheduleStr.isEmpty) return null;
    
    try {
      return Map<String, dynamic>.from(jsonDecode(scheduleStr));
    } catch (e) {
      return null;
    }
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (serverId != null) 'serverCourseId': serverId,
      'name': name,
      'code': code,
      'description': description,
      'creditHours': creditHours,
      'schedule': schedule != null ? jsonEncode(schedule) : null,
      'active': active ? 1 : 0,
      'departmentId': departmentId,
      'sectionId': sectionId,
      'teacherId': teacherId,
      'instituteId': instituteId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'synced': synced ? 1 : 0,
    };
  }

  // Convert to API Map
  Map<String, dynamic> toApiMap() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'creditHours': creditHours,
      'schedule': schedule,
      'departmentId': departmentId,
      'sectionId': sectionId,
      'teacherId': teacherId,
      'active': active,
    };
  }

  // Copy with
  Course copyWith({
    int? id,
    int? serverId,
    String? name,
    String? code,
    String? description,
    double? creditHours,
    Map<String, dynamic>? schedule,
    bool? active,
    int? departmentId,
    int? sectionId,
    int? teacherId,
    int? instituteId,
    String? createdAt,
    String? updatedAt,
    bool? synced,
    String? departmentName,
    String? departmentCode,
    String? sectionName,
    String? sectionCode,
    String? teacherName,
  }) {
    return Course(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      creditHours: creditHours ?? this.creditHours,
      schedule: schedule ?? this.schedule,
      active: active ?? this.active,
      departmentId: departmentId ?? this.departmentId,
      sectionId: sectionId ?? this.sectionId,
      teacherId: teacherId ?? this.teacherId,
      instituteId: instituteId ?? this.instituteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      departmentName: departmentName ?? this.departmentName,
      departmentCode: departmentCode ?? this.departmentCode,
      sectionName: sectionName ?? this.sectionName,
      sectionCode: sectionCode ?? this.sectionCode,
      teacherName: teacherName ?? this.teacherName,
    );
  }
}

// Missing import at the top