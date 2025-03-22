class Fingerprint {
  final int? id;
  final int studentId;
  final String templateData;
  final String? fingerPosition;
  final int? quality;
  final String createdAt;
  final String? updatedAt;
  final bool synced;

  Fingerprint({
    this.id,
    required this.studentId,
    required this.templateData,
    this.fingerPosition = 'right_thumb',
    this.quality,
    required this.createdAt,
    this.updatedAt,
    this.synced = false,
  });

  // Create from Map
  factory Fingerprint.fromMap(Map<String, dynamic> map) {
    return Fingerprint(
      id: map['id'],
      studentId: map['studentId'],
      templateData: map['templateData'],
      fingerPosition: map['fingerPosition'] ?? 'right_thumb',
      quality: map['quality'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      synced: map['synced'] == 1,
    );
  }

  // Convert to Map for database
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'studentId': studentId,
      'templateData': templateData,
      'fingerPosition': fingerPosition,
      'quality': quality,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'synced': synced ? 1 : 0,
    };
  }

  // Convert to Map for API
  Map<String, dynamic> toApiMap() {
    return {
      'studentId': studentId,
      'fingerprint': templateData,
      'fingerprintPosition': fingerPosition,
    };
  }

  // Copy with
  Fingerprint copyWith({
    int? id,
    int? studentId,
    String? templateData,
    String? fingerPosition,
    int? quality,
    String? createdAt,
    String? updatedAt,
    bool? synced,
  }) {
    return Fingerprint(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      templateData: templateData ?? this.templateData,
      fingerPosition: fingerPosition ?? this.fingerPosition,
      quality: quality ?? this.quality,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}