class Section {
  final int? id;
  final int? serverId;
  final String name;
  final String code;
  final int capacity;
  final String? description;
  final bool active;
  final int departmentId;
  final int instituteId;
  final String createdAt;
  final String? updatedAt;
  final bool synced;

  // Related information
  String? departmentName;
  String? departmentCode;
  int? studentCount;
  int? courseCount;

  Section({
    this.id,
    this.serverId,
    required this.name,
    required this.code,
    this.capacity = 50,
    this.description,
    this.active = true,
    required this.departmentId,
    required this.instituteId,
    required this.createdAt,
    this.updatedAt,
    this.synced = false,
    this.departmentName,
    this.departmentCode,
    this.studentCount,
    this.courseCount,
  });

  // Create from Map
  factory Section.fromMap(Map<String, dynamic> map) {
    return Section(
      id: map['id'],
      serverId: map['serverSectionId'],
      name: map['name'],
      code: map['code'],
      capacity: map['capacity'] ?? 50,
      description: map['description'],
      active: map['active'] == 1,
      departmentId: map['departmentId'],
      instituteId: map['instituteId'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      synced: map['synced'] == 1,
      // Related information if available
      departmentName: map['department']?['name'],
      departmentCode: map['department']?['code'],
      studentCount: map['stats']?['studentCount'],
      courseCount: map['stats']?['courseCount'],
    );
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (serverId != null) 'serverSectionId': serverId,
      'name': name,
      'code': code,
      'capacity': capacity,
      'description': description,
      'active': active ? 1 : 0,
      'departmentId': departmentId,
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
      'capacity': capacity,
      'description': description,
      'departmentId': departmentId,
      'active': active,
    };
  }

  // Copy with
  Section copyWith({
    int? id,
    int? serverId,
    String? name,
    String? code,
    int? capacity,
    String? description,
    bool? active,
    int? departmentId,
    int? instituteId,
    String? createdAt,
    String? updatedAt,
    bool? synced,
    String? departmentName,
    String? departmentCode,
    int? studentCount,
    int? courseCount,
  }) {
    return Section(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      code: code ?? this.code,
      capacity: capacity ?? this.capacity,
      description: description ?? this.description,
      active: active ?? this.active,
      departmentId: departmentId ?? this.departmentId,
      instituteId: instituteId ?? this.instituteId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      departmentName: departmentName ?? this.departmentName,
      departmentCode: departmentCode ?? this.departmentCode,
      studentCount: studentCount ?? this.studentCount,
      courseCount: courseCount ?? this.courseCount,
    );
  }
}