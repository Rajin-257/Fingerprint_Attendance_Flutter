class Student {
  final int? id;
  final int? serverId;
  final String registrationNumber;
  final String firstName;
  final String lastName;
  final String? email;
  final String? dateOfBirth;
  final String gender;
  final String? contactNumber;
  final String? address;
  final String? fingerprint;
  final bool active;
  final int instituteId;
  final int departmentId;
  final int sectionId;
  final int addedBy;
  final String createdAt;
  final String? updatedAt;
  final bool synced;

  Student({
    this.id,
    this.serverId,
    required this.registrationNumber,
    required this.firstName,
    required this.lastName,
    this.email,
    this.dateOfBirth,
    required this.gender,
    this.contactNumber,
    this.address,
    this.fingerprint,
    required this.active,
    required this.instituteId,
    required this.departmentId,
    required this.sectionId,
    required this.addedBy,
    required this.createdAt,
    this.updatedAt,
    required this.synced,
  });

  // Full name getter
  String get fullName => '$firstName $lastName';

  // Has fingerprint getter
  bool get hasFingerprint => fingerprint != null && fingerprint!.isNotEmpty;

  // Convert from Map (database or API)
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      serverId: map['serverStudentId'],
      registrationNumber: map['registrationNumber'],
      firstName: map['firstName'],
      lastName: map['lastName'],
      email: map['email'],
      dateOfBirth: map['dateOfBirth'],
      gender: map['gender'] ?? 'Other',
      contactNumber: map['contactNumber'],
      address: map['address'],
      fingerprint: map['fingerprint'],
      active: map['active'] == 1,
      instituteId: map['instituteId'],
      departmentId: map['departmentId'],
      sectionId: map['sectionId'],
      addedBy: map['addedBy'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      synced: map['synced'] == 1,
    );
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (serverId != null) 'serverStudentId': serverId,
      'registrationNumber': registrationNumber,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'contactNumber': contactNumber,
      'address': address,
      'fingerprint': fingerprint,
      'active': active ? 1 : 0,
      'instituteId': instituteId,
      'departmentId': departmentId,
      'sectionId': sectionId,
      'addedBy': addedBy,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'synced': synced ? 1 : 0,
    };
  }

  // Convert to Map for API
  Map<String, dynamic> toApiMap() {
    return {
      'registrationNumber': registrationNumber,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'contactNumber': contactNumber,
      'address': address,
      'fingerprint': fingerprint,
      'departmentId': departmentId,
      'sectionId': sectionId,
    };
  }

  // Copy with
  Student copyWith({
    int? id,
    int? serverId,
    String? registrationNumber,
    String? firstName,
    String? lastName,
    String? email,
    String? dateOfBirth,
    String? gender,
    String? contactNumber,
    String? address,
    String? fingerprint,
    bool? active,
    int? instituteId,
    int? departmentId,
    int? sectionId,
    int? addedBy,
    String? createdAt,
    String? updatedAt,
    bool? synced,
  }) {
    return Student(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      registrationNumber: registrationNumber ?? this.registrationNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      fingerprint: fingerprint ?? this.fingerprint,
      active: active ?? this.active,
      instituteId: instituteId ?? this.instituteId,
      departmentId: departmentId ?? this.departmentId,
      sectionId: sectionId ?? this.sectionId,
      addedBy: addedBy ?? this.addedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}

class StudentEnrollment {
  final int? id;
  final int? serverId;
  final int studentId;
  final int courseId;
  final String enrollmentDate;
  final String status;
  final String createdAt;
  final String? updatedAt;
  final bool synced;

  StudentEnrollment({
    this.id,
    this.serverId,
    required this.studentId,
    required this.courseId,
    required this.enrollmentDate,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.synced,
  });

  // Convert from Map
  factory StudentEnrollment.fromMap(Map<String, dynamic> map) {
    return StudentEnrollment(
      id: map['id'],
      serverId: map['serverEnrollmentId'],
      studentId: map['studentId'],
      courseId: map['courseId'],
      enrollmentDate: map['enrollmentDate'],
      status: map['status'] ?? 'Active',
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      synced: map['synced'] == 1,
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (serverId != null) 'serverEnrollmentId': serverId,
      'studentId': studentId,
      'courseId': courseId,
      'enrollmentDate': enrollmentDate,
      'status': status,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'synced': synced ? 1 : 0,
    };
  }
}