class Attendance {
  final int? id;
  final int? serverId;
  final String offlineId;
  final int studentId;
  final int courseId;
  final int teacherId;
  final int instituteId;
  final DateTime date;
  final String status;
  final String? timeIn;
  final String? remarks;
  final bool fingerprintVerified;
  final bool verified;
  final bool syncedFromOffline;
  final String createdAt;
  final String? updatedAt;
  final bool synced;

  // Optional related information
  String? studentName;
  String? studentRegNumber;
  String? courseName;
  String? courseCode;
  String? teacherName;

  Attendance({
    this.id,
    this.serverId,
    required this.offlineId,
    required this.studentId,
    required this.courseId,
    required this.teacherId,
    required this.instituteId,
    required this.date,
    required this.status,
    this.timeIn,
    this.remarks,
    this.fingerprintVerified = false,
    this.verified = false,
    this.syncedFromOffline = false,
    required this.createdAt,
    this.updatedAt,
    this.synced = false,
    this.studentName,
    this.studentRegNumber,
    this.courseName,
    this.courseCode,
    this.teacherName,
  });

  // Create from Map (database or API)
  factory Attendance.fromMap(Map<String, dynamic> map) {
    DateTime parseDate(dynamic date) {
      if (date is DateTime) return date;
      if (date is String) {
        try {
          return DateTime.parse(date);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    return Attendance(
      id: map['id'],
      serverId: map['serverAttendanceId'],
      offlineId: map['offlineId'] ?? '',
      studentId: map['studentId'],
      courseId: map['courseId'],
      teacherId: map['teacherId'],
      instituteId: map['instituteId'],
      date: parseDate(map['date']),
      status: map['status'],
      timeIn: map['timeIn'],
      remarks: map['remarks'],
      fingerprintVerified: map['fingerprintVerified'] == 1,
      verified: map['verified'] == 1,
      syncedFromOffline: map['syncedFromOffline'] == 1,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      synced: map['synced'] == 1,
      // Optional related data
      studentName: map['student'] != null 
          ? '${map['student']['firstName']} ${map['student']['lastName']}'
          : map['studentName'],
      studentRegNumber: map['student']?['registrationNumber'] ?? map['studentRegNumber'],
      courseName: map['course']?['name'] ?? map['courseName'],
      courseCode: map['course']?['code'] ?? map['courseCode'],
      teacherName: map['teacher'] != null
          ? '${map['teacher']['firstName']} ${map['teacher']['lastName']}'
          : map['teacherName'],
    );
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      if (serverId != null) 'serverAttendanceId': serverId,
      'offlineId': offlineId,
      'studentId': studentId,
      'courseId': courseId,
      'teacherId': teacherId,
      'instituteId': instituteId,
      'date': date.toIso8601String().split('T')[0],
      'status': status,
      'timeIn': timeIn,
      'remarks': remarks,
      'fingerprintVerified': fingerprintVerified ? 1 : 0,
      'verified': verified ? 1 : 0,
      'syncedFromOffline': syncedFromOffline ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'synced': synced ? 1 : 0,
    };
  }

  // Convert to Map for API
  Map<String, dynamic> toApiMap() {
    return {
      'offlineId': offlineId,
      'studentId': studentId,
      'courseId': courseId,
      'date': date.toIso8601String().split('T')[0],
      'status': status,
      'timeIn': timeIn,
      'remarks': remarks,
      'fingerprintVerified': fingerprintVerified,
    };
  }

  // Copy with
  Attendance copyWith({
    int? id,
    int? serverId,
    String? offlineId,
    int? studentId,
    int? courseId,
    int? teacherId,
    int? instituteId,
    DateTime? date,
    String? status,
    String? timeIn,
    String? remarks,
    bool? fingerprintVerified,
    bool? verified,
    bool? syncedFromOffline,
    String? createdAt,
    String? updatedAt,
    bool? synced,
    String? studentName,
    String? studentRegNumber,
    String? courseName,
    String? courseCode,
    String? teacherName,
  }) {
    return Attendance(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      offlineId: offlineId ?? this.offlineId,
      studentId: studentId ?? this.studentId,
      courseId: courseId ?? this.courseId,
      teacherId: teacherId ?? this.teacherId,
      instituteId: instituteId ?? this.instituteId,
      date: date ?? this.date,
      status: status ?? this.status,
      timeIn: timeIn ?? this.timeIn,
      remarks: remarks ?? this.remarks,
      fingerprintVerified: fingerprintVerified ?? this.fingerprintVerified,
      verified: verified ?? this.verified,
      syncedFromOffline: syncedFromOffline ?? this.syncedFromOffline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
      studentName: studentName ?? this.studentName,
      studentRegNumber: studentRegNumber ?? this.studentRegNumber,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      teacherName: teacherName ?? this.teacherName,
    );
  }
}