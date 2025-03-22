class Department {
  final int? id;
  final int? serverId;
  final String name;
  final String code;
  final String? description;
  final bool active;
  final int instituteId;
  final String createdAt;
  final String? updatedAt;
  final bool synced;

  // Statistics fields
  int? sectionCount;
  int? teacherCount;
  int? studentCount;
  int? courseCount;

  Department({
    this.id,
    this.serverId,
    required this.name,
    required this.code,
    this.description,
    this.active = true,
    required this.instituteId,
    required this.createdAt,
    this.updatedAt,
    this.synced = false,
    this.sectionCount,
    this.teacherCount,
    this.studentCount,
    this.courseCount,
  });

  // Create from Map
  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'],
      serverId: map['serverDepartmentId'],
      name: map['name'],
      code: map['code'],
      description: map['description'],
      active: map['active'] == 1,
      instituteId: map['instituteId'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      synced: map['synced'] == 1,
      // Stats if available
      sectionCount: map['stats']?['sectionCount'],
      teacherCount: map['stats']?['teacherCount'],
      studentCount: map['stats']?['studentCount'],
      courseCount: map['stats']?['courseCount'],
    );
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (serverId != null) 'serverDepartmentId': serverId,
      'name': name,
      'code': code,
      'description': description,
      'active': active ? 1 : 0,
      'instituteId': instituteId,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'synced': synced ? 1 : 0,
    };
  }

  // Convert to Map for API
  Map<String, dynamic> toApiMap() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'active': active,
    };
  }

  // Copy with
  Department copyWith({
    int? id,
    int? serverId,
    String? name,
    String? code,
    String? description,
    bool? active,
    int? instituteId,
    String? createdAt,
    String? updatedAt,
    bool? synced,
    int? sectionCount,
    int? teacherCount,
    int? studentCount,
    int? courseCount,
  }) {
    return Department(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      active: active ?? this.active,
      instituteId: instituteId ?? this.instituteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      sectionCount: sectionCount ?? this.sectionCount,
      teacherCount: teacherCount ?? this.teacherCount,
      studentCount: studentCount ?? this.studentCount,
      courseCount: courseCount ?? this.courseCount,
    );
  }
}