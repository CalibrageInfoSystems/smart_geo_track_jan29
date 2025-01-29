class UserWeekOffXref {

  String? code;
  int? userId;
  String? date;
  String? remarks;
  bool? isLeave;
  bool? isActive;
  bool? serverUpdatedStatus;
  int? createdByUserId;
  String? createdDate;
  int? updatedByUserId;
  String? updatedDate;

  UserWeekOffXref({

    this.code,
    this.userId,
    this.date,
    this.remarks,
    this.isLeave,
    this.isActive,
    this.serverUpdatedStatus,
    this.createdByUserId,
    this.createdDate,
    this.updatedByUserId,
    this.updatedDate,
  });

  // Convert a UserWeekOffXref object into a Map object
// Convert a UserWeekOffXref object into a Map object
  Map<String, dynamic> toMap() {
    return {

      'Code': code,
      'UserId': userId,
      'Date': date,
      'Remarks': remarks,
      'IsLeave': isLeave ?? false, // Ensure false if null
      'IsActive': isActive ?? false, // Ensure false if null
      'ServerUpdatedStatus': serverUpdatedStatus ?? false, // Ensure false if null
      'CreatedByUserId': createdByUserId,
      'CreatedDate': createdDate,
      'UpdatedByUserId': updatedByUserId,
      'UpdatedDate': updatedDate,
    };
  }



// Extract a UserWeekOffXref object from a Map object
  factory UserWeekOffXref.fromMap(Map<String, dynamic> map) {
    return UserWeekOffXref(

      code: map['Code'],
      userId: map['UserId'],
      date: map['Date'],
      remarks: map['Remarks'],
      isLeave: map['IsLeave'] == 1, // Convert 1/0 to true/false
      isActive: map['IsActive'] == 1, // Convert 1/0 to true/false
      serverUpdatedStatus: map['ServerUpdatedStatus'] == 1, // Convert 1/0 to true/false
      createdByUserId: map['CreatedByUserId'],
      createdDate: map['CreatedDate'],
      updatedByUserId: map['UpdatedByUserId'],
      updatedDate: map['UpdatedDate'],
    );
  }

}
