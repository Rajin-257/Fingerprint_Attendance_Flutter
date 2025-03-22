class Institute {
  final int? id;
  final String name;
  final String code;
  final String email;
  final String? address;
  final String? contactPerson;
  final String? contactNumber;
  final DateTime? licenseExpiry;
  final bool active;
  final DateTime? lastLogin;
  final int? createdBy;
  final String createdAt;
  final String? updatedAt;

  // Statistics
  int? teacherCount;
  int? departmentCount;
  int? sectionCount;
  int? courseCount;
  int? studentCount;

  Institute({
    this.id,
    required this.name,
    required this.code,
    required this.email,
    this.address,
    this.contactPerson,
    this.contactNumber,
    this.licenseExpiry,
    this.active = true,
    this.lastLogin,
    this.createdBy,
    required this.createdAt,
    this.updatedAt,
    this.teacherCount,
    this.departmentCount,
    this.sectionCount,
    this.courseCount,
    this.studentCount,
  });

  // Check if license is valid
  bool get isLicenseValid {
    if (licenseExpiry == null) return true;
    return licenseExpiry!.isAfter(DateTime.now());
  }

  // Create from Map
  factory Institute.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic date) {
      if (date == null) return null;
      if (date is DateTime) return date;
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return null;
        }
      }
      return null;
    }

    return Institute(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      email: map['email'],
      address: map['address'],
      contactPerson: map['contactPerson'],
      contactNumber: map['contactNumber'],
      licenseExpiry: parseDate(map['licenseExpiry']),
      active: map['active'] == 1 || map['active'] == true,
      lastLogin: parseDate(map['lastLogin']),
      createdBy: map['createdBy'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      // Stats if available
      teacherCount: map['stats']?['teacherCount'],
      departmentCount: map['stats']?['departmentCount'],
      sectionCount: map['stats']?['sectionCount'],
      courseCount: map['stats']?['courseCount'],
      studentCount: map['stats']?['studentCount'],
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'code': code,
      'email': email,
      'address': address,
      'contactPerson': contactPerson,
      'contactNumber': contactNumber,
      'licenseExpiry': licenseExpiry?.toIso8601String(),
      'active': active ? 1 : 0,
      'lastLogin': lastLogin?.toIso8601String(),
      'createdBy': createdBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Copy with
  Institute copyWith({
    int? id,
    String? name,
    String? code,
    String? email,
    String? address,
    String? contactPerson,
    String? contactNumber,
    DateTime? licenseExpiry,
    bool? active,
    DateTime? lastLogin,
    int? createdBy,
    String? createdAt,
    String? updatedAt,
    int? teacherCount,
    int? departmentCount,
    int? sectionCount,
    int? courseCount,
    int? studentCount,
  }) {
    return Institute(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      email: email ?? this.email,
      address: address ?? this.address,
      contactPerson: contactPerson ?? this.contactPerson,
      contactNumber: contactNumber ?? this.contactNumber,
      licenseExpiry: licenseExpiry ?? this.licenseExpiry,
      active: active ?? this.active,
      lastLogin: lastLogin ?? this.lastLogin,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      teacherCount: teacherCount ?? this.teacherCount,
      departmentCount: departmentCount ?? this.departmentCount,
      sectionCount: sectionCount ?? this.sectionCount,
      courseCount: courseCount ?? this.courseCount,
      studentCount: studentCount ?? this.studentCount,
    );
  }
}