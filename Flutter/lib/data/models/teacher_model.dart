class Teacher {
  final int? id;
  final int? serverId;
  final String employeeId;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? qualification;
  final String? joiningDate;
  final String? fingerprint;
  final String? deviceId;
  final bool active;
  final int instituteId;
  final String? lastLogin;
  final String? lastSync;
  final String createdAt;
  final String? updatedAt;
  final bool synced;

  // Related information
  String? instituteName;
  String? instituteCode;
  List<dynamic>? courses;
  int? studentCount;
  int? courseCount;

  Teacher({
    this.id,
    this.serverId,
    required this.employeeId,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.qualification,
    this.joiningDate,
    this.fingerprint,
    this.deviceId,
    this.active = true,
    required this.instituteId,
    this.lastLogin,
    this.lastSync,
    required this.createdAt,
    this.updatedAt,
    this.synced = false,
    this.instituteName,
    this.instituteCode,
    this.courses,
    this.studentCount,
    this.courseCount,
  });

  // Full name getter
  String get fullName => '$firstName $lastName';

  // Has fingerprint getter
  bool get hasFingerprint => fingerprint != null && fingerprint!.isNotEmpty;

  // Create from Map
  factory Teacher.fromMap(Map<String, dynamic> map) {
    return Teacher(
      id: map['id'],
      serverId: map['serverTeacherId'],
      employeeId: map['employeeId'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      phone: map['phone'],
      qualification: map['qualification'],
      joiningDate: map['joiningDate'],
      fingerprint: map['fingerprint'],
      deviceId: map['deviceId'],
      active: map['active'] == 1,
      instituteId: map['instituteId'],
      lastLogin: map['lastLogin'],
      lastSync: map['lastSync'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      synced: map['synced'] == 1,
      // Related information if available
      instituteName: map['institute']?['name'],
      instituteCode: map['institute']?['code'],
      courses: map['courses'],
      studentCount: map['stats']?['studentCount'],
      courseCount: map['stats']?['courseCount'],
    );
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (serverId != null) 'serverTeacherId': serverId,
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'qualification': qualification,
      'joiningDate': joiningDate,
      'fingerprint': fingerprint,
      'deviceId': deviceId,
      'active': active ? 1 : 0,
      'instituteId': instituteId,
      'lastLogin': lastLogin,
      'lastSync': lastSync,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'synced': synced ? 1 : 0,
    };
  }

  // Convert to Map for API
  Map<String, dynamic> toApiMap() {
    return {
      'employeeId': employeeId,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'qualification': qualification,
      'joiningDate': joiningDate,
      'active': active,
    };
  }

  // Copy with
  Teacher copyWith({
    int? id,
    int? serverId,
    String? employeeId,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? qualification,
    String? joiningDate,
    String? fingerprint,
    String? deviceId,
    bool? active,
    int? instituteId,
    String? lastLogin,
    String? lastSync,
    String? createdAt,
    String? updatedAt,
    bool? synced,
    String? instituteName,
    String? instituteCode,
    List<dynamic>? courses,
    int? studentCount,
    int? courseCount,
  }) {
    return Teacher(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      employeeId: employeeId ?? this.employeeId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      qualification: qualification ?? this.qualification,
      joiningDate: joiningDate ?? this.joiningDate,
      fingerprint: fingerprint ?? this.fingerprint,
      deviceId: deviceId ?? this.deviceId,
      active: active ?? this.active,
      instituteId: instituteId ?? this.instituteId,
      lastLogin: lastLogin ?? this.lastLogin,
      lastSync: lastSync ?? this.lastSync,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      instituteName: instituteName ?? this.instituteName,
      instituteCode: instituteCode ?? this.instituteCode,
      courses: courses ?? this.courses,
      studentCount: studentCount ?? this.studentCount,
      courseCount: courseCount ?? this.courseCount,
    );
  }
}