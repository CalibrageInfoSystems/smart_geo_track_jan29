import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:synchronized/synchronized.dart';

import '../HomeScreen.dart';
import 'DatabaseHelper.dart';

class DataAccessHandler with ChangeNotifier {
  static final Lock _lock = Lock();
  Future<void> deleteRow(String tableName) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.delete(tableName);
      print('Deleted all rows from $tableName');
    } catch (e) {
      print('Error deleting rows from $tableName: $e');
    }
  }

  Future<void> insertData(
      String tableName, List<Map<String, dynamic>> data) async {
    try {
      final db = await DatabaseHelper.instance.database;
      for (var item in data) {
        await db.insert(tableName, item);
      }
      print('Data inserted into $tableName');
    } catch (e) {
      print('Error inserting data into $tableName: $e');
    }
  }
  // Future<void> insertOrUpdateData(
  //     String tableName, List<Map<String, dynamic>> data, String idField) async {
  //   final db = await DatabaseHelper.instance.database;
  //
  //   await db.transaction((txn) async {
  //     for (var item in data) {
  //       // Log the item being processed
  //       print('Processing item: ${item.toString()}');
  //
  //       // Check if a record with the same ID exists
  //       var existingRecord = await txn.query(
  //         tableName,
  //         where: '$idField = ?',
  //         whereArgs: [item[idField]],
  //       );
  //
  //       if (existingRecord.isNotEmpty) {
  //         // If the record exists, update it
  //         await txn.update(
  //           tableName,
  //           item,
  //           where: '$idField = ?',
  //           whereArgs: [item[idField]],
  //         );
  //         print('Updated existing record in $tableName with $idField = ${item[idField]}');
  //       } else {
  //         // If the record does not exist, insert it
  //         await txn.insert(tableName, item);
  //         print('Inserted new record into $tableName with $idField = ${item[idField]}');
  //       }
  //     }
  //   });
  // }
  Future<void> insertLocationValues({
    required double latitude,
    required double longitude,
    required int? createdByUserId,
    required bool serverUpdatedStatus,
    required String? from,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final geoBoundaryValues = {
        'Latitude': latitude,
        'Longitude': longitude,
        'Address': from,
        'CreatedByUserId': createdByUserId,
        'CreatedDate': DateTime.now().toIso8601String(),
        'ServerUpdatedStatus': false, // SQLite stores boolean as 0 or 1
      };

      await db.insert('GeoBoundaries', geoBoundaryValues);
      print('Location values inserted');
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Error inserting GeoBoundaries:",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0);
      print('Failed to insert location values: $e');
      appendLog( 'Failed to insert location values: ${e.toString()}');
    }
  }
  Future<void> insertOrUpdateData(
      String tableName, List<Map<String, dynamic>> data, String idField) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      for (var item in data) {
        print('Processing item: ${item.toString()}');

        // Check if a record with the same ID exists
        var existingRecord = await txn.query(
          tableName,
          where: '$idField = ?',
          whereArgs: [item[idField]],
        );

        if (existingRecord.isNotEmpty) {
          // If the record exists, update it
          await txn.update(
            tableName,
            item,
            where: '$idField = ?',
            whereArgs: [item[idField]],
          );
          print('Updated existing record in $tableName with $idField = ${item[idField]}');
        } else {
          // If the record does not exist, insert it
          await txn.insert(tableName, item);
          print('Inserted new record into $tableName with $idField = ${item[idField]}');
        }
      }
    });
  }
  Future<void> insertOrUpdateweekxrefData(
      String tableName, List<Map<String, dynamic>> data, String idField) async {
    final db = await DatabaseHelper.instance.database;

    await db.transaction((txn) async {
      for (var item in data) {
        print('Processing item: ${item.toString()}');
        print('Processing item: ${item['code']}');
        // Check if a record with the same ID and Code exists
        var existingRecord = await txn.query(
          tableName,
          where: '$idField = ? AND code = ?',
          whereArgs: [item['code']],
        );
        print('Processing item: ${existingRecord.toString()}');
        if (existingRecord.isNotEmpty) {
          // If the record exists, update it
          await txn.update(
            tableName,
            item,
            where: '$idField = ? AND code = ?',
            whereArgs: [item[idField], item['code']],
          );
          print(
              'Updated existing record in $tableName with $idField = ${item[idField]} and code = ${item['code']}');
        } else {
          // If the record does not exist, insert it
          await txn.insert(tableName, item);
          print(
              'Inserted new record into $tableName with $idField = ${item[idField]} and code = ${item['code']}');
        }
      }
    });
  }


  // Future<int> insertLead(Map<String, dynamic> leadData) async {
  //   final db = await database;
  //   return await db.insert(
  //     'Leads',
  //     leadData,
  //     conflictAlgorithm: ConflictAlgorithm.replace,
  //   );
  // }
  Future<int> insertLead(Map<String, dynamic> leadData) async {
    final db = await DatabaseHelper.instance.database;

    // Validate lead data before insertion
    // if (!isValidLeadData(leadData)) {
    //   throw Exception("Invalid lead data");
    // }
    return await _lock.synchronized(() async {
      try {
        return await db.insert(
          'Leads',
          leadData,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } catch (e) {
        // Log or handle the error as needed
        print("Insert failed: $e");
        return -1; // Return an error code or handle it differently
      }
    }) ?? -1; // Fallback value in case of unexpected null.
  }


  Future<int> insertFileRepository(Map<String, dynamic> fileData) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      'FileRepositorys',
      fileData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  Future<int> insertUserWeekOffXref(Map<String, dynamic> fileData) async {
    final db = await DatabaseHelper.instance.database;
    return await db.insert(
      'UserWeekOffXref',
      fileData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  Future<int?> getOnlyOneIntValueFromDb(String query, ) async {
    debugPrint("@@@ query $query");
    try {
      List<Map<String, dynamic>> result =
      await (await DatabaseHelper.instance.database).rawQuery(query);
      if (result.isNotEmpty) {
        return result.first.values.first as int;
      }
      return null;
    } catch (e) {
      debugPrint("Exception: $e");
      return null;
    }
  }
  Future<List<Map<String, dynamic>>> getLocationByLatLong(
      double latitude, double longitude) async {
    // Query to check if the location with the same latitude and longitude exists
    final db = await DatabaseHelper
        .instance.database; // Assuming `database` is your database instance
    final result = await db.query(
      'GeoBoundaries', // Replace with your actual table name
      where: 'latitude = ? AND longitude = ?',
      whereArgs: [latitude, longitude],
    );

    return result;
  }

  Future<String?> getOnlyOneStringValueFromDb(
      String query, List<dynamic> params) async {
    List<Map<String, dynamic>> result;
    try {
      final db = await DatabaseHelper.instance.database;
      result = await db.rawQuery(query, params);

      if (result.isNotEmpty && result.first.isNotEmpty) {
        return result.first.values.first.toString();
      }
      return null;
    } catch (e) {
      debugPrint("Exception: $e");
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> getleads(
      {required int createdByUserId}) async {
    final db = await DatabaseHelper.instance.database;
    String query = 'SELECT * FROM Leads WHERE CreatedByUserId = ?';
    List<Map<String, dynamic>> results =
    await db.rawQuery(query, [createdByUserId]);
    return results;
  }
  Future<List<Map<String, dynamic>>> getTodayLeadsuser(
      String today, int? userID) async {
    final db = await DatabaseHelper.instance.database;

    String query =
        'SELECT * FROM Leads WHERE DATE(CreatedDate) = ? AND CreatedByUserId = ?';
    print('Executing Query: $query with parameters: $today, $userID');

    List<Map<String, dynamic>> results = await db.rawQuery(query, [today, userID]);

    print('Query Results:');
    for (var row in results) {
      print(row);
    }

    return results;
  }

  // Future<List<Map<String, dynamic>>> getTodayLeadsuser(
  //     String today, int? userID) async {
  //   final db = await DatabaseHelper.instance.database;
  //
  //   // Use query parameters to safely pass in the date and userID
  //   String query =
  //       'SELECT * FROM Leads WHERE DATE(CreatedDate) = ? AND CreatedByUserId = ?';
  //   print('Executing Query: $query with parameters: $today, $userID');
  //
  //   // Query the database with the proper filtering
  //   List<Map<String, dynamic>> results =
  //       await db.rawQuery(query, [today, userID]);
  //
  //   print('Query Results:');
  //   for (var row in results) {
  //     print(row);
  //   }
  //
  //   return results;
  // }

  Future<List<Map<String, dynamic>>> getTodayLeads(String today) async {
    final db = await DatabaseHelper.instance.database;
    String query = 'SELECT * FROM Leads WHERE DATE(CreatedDate) = $today';
    List<Map<String, dynamic>> results = await db.query(query);
/*     print('xxx: $query');
    print('xxx: ${jsonEncode(results)}'); */
    return results;
  }

  Future<List<Map<String, dynamic>>> getFilterData(String query) async {
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> results = await db.rawQuery(query);
    return results;
  }

  Future<List<Map<String, dynamic>>> getLeadInfoByCode(String code) async {
    try {
      final db = await DatabaseHelper.instance.database;
      String query = 'SELECT * FROM Leads Where Code = ?';
      List<Map<String, dynamic>> results = await db.rawQuery(
        query,
        [code],
      );

      return results;
    } catch (e) {
      throw Exception('catch: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getLeadImagesByCode(
      String leadsCode, String fileExtension) async {
    try {
      final db = await DatabaseHelper.instance.database;
      String query =
          'SELECT * FROM FileRepositorys WHERE leadsCode = ? AND FileExtension = ?';
      List<Map<String, dynamic>> results = await db.rawQuery(
        query,
        [leadsCode, fileExtension],
      );
      print('xxx getLeadImagesByCode: ${jsonEncode(results)}');
      return results;
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

// SELECT * FROM FileRepositorys WHERE FileExtension in ('.xlsx', '.pdf')
/*   Future<List<Map<String, dynamic>>> getLeadDocsByCode(String code, String fileExtension) async {
    try {
      final db = await database;
      String query =
          'SELECT * FROM FileRepositorys WHERE leadsCode = ? AND FileExtension = ?'; // Define the query
      List<Map<String, dynamic>> results = await db.rawQuery(
        query,
        [code, fileExtension],
      );
      print('Data fetched: ${jsonEncode(results)}');
      return results; // Return the results
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  } */

  Future<List<Map<String, dynamic>>> getLeadDocsByCode(
      String leadsCode, List<String> fileExtensions) async {
    try {
      final db = await DatabaseHelper.instance.database;

      String placeholders = fileExtensions.map((_) => '?').join(', ');
      String query =
          'SELECT * FROM FileRepositorys WHERE leadsCode = ? AND FileExtension IN ($placeholders)';
      print('query: $query');
      List<dynamic> parameters = [leadsCode] + fileExtensions;

      List<Map<String, dynamic>> results = await db.rawQuery(
        query,
        parameters,
      );
      print('getLeadDocsByCode: ${jsonEncode(results)}');
      return results;
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  Future<String?> fetchBase64Image(String leadCode) async {
    // Replace with your actual database path and query
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> result = await db.rawQuery(
      'SELECT FileName FROM FileRepositorys WHERE leadsCode = ?',
      [leadCode],
    );

    if (result.isNotEmpty) {
      return result.first['FileName']
      as String; // Assuming FileName contains Base64
    }
    return null; // Return null if no image found
  }

  bool isValidLeadData(Map<String, dynamic> leadData) {
    // Add your validation logic here
    return leadData.containsKey('requiredField') &&
        leadData['requiredField'] != null;
  }

  String getCurrentDate() {
    DateTime now = DateTime.now();
    String formattedDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    return formattedDate;
  }
  Future<List<Map<String, dynamic>>> getDataFromQuery(String query) async {
    final db = await DatabaseHelper.instance.database;
    return await db.rawQuery(query); // Execute the raw query and return the result
  }
  // Future<List<Map<String, double>>> fetchLatLongsFromDatabase(
  //     String startDate, String endDate) async {
  //   final db = await DatabaseHelper.instance.database;
  //
  //   List<Map<String, dynamic>> queryResult = await db.query(
  //     'GeoBoundaries',
  //     columns: ['Latitude', 'Longitude'],
  //     where: 'DATE(CreatedDate) BETWEEN ? AND ?',
  //     whereArgs: [startDate, endDate], // Arguments for the WHERE clause
  //   );
  //   print('distance query ==  $queryResult');
  //   return queryResult
  //       .map((row) => {
  //             'lat': row['Latitude'] as double,
  //             'lng': row['Longitude'] as double,
  //           })
  //       .toList();
  // }

  Future<List<Map<String, double>>> fetchLatLongsFromDatabase(
      String startDate, String endDate) async {
    final db = await DatabaseHelper.instance.database;

    // Assuming userID is retrieved from SharedPreferences or passed as an argument
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userID = prefs.getInt('userID');

    // Perform the query with both date range and userID
    List<Map<String, dynamic>> queryResult = await db.query(
      'GeoBoundaries',
      columns: ['Latitude', 'Longitude'],
      where: 'DATE(CreatedDate) BETWEEN ? AND ? AND CreatedByUserId = ?',
      whereArgs: [startDate, endDate, userID], // Arguments for the WHERE clause
    );

    print('Distance query result: $queryResult');

    // Convert the query result into a list of latitude/longitude maps
    return queryResult
        .map((row) => {
      'lat': row['Latitude'] as double,
      'lng': row['Longitude'] as double,
    })
        .toList();
  }


// Method to check if GeoBoundary has a point for the current date
  Future<bool> hasPointForToday() async {
    // Get a reference to the database
    final db = await DatabaseHelper.instance.database;

    String currentDate = getCurrentDate();
    // SQL query to be executed
    String query = "SELECT * FROM GeoBoundaries WHERE DATE(CreatedDate) = ?";

    // Print the query and the parameter (formattedDate)
    print("Executing query: $query with parameter: $currentDate");
    appendLog("Executing query hasPointForToday: $query with parameter: $currentDate ");

    // Query the GeoBoundary table for points on the current date
    final List<Map<String, dynamic>> result = await db.rawQuery(query, [currentDate]);

    // If the result is not empty, a point exists for today
    return result.isNotEmpty;
  }
// Method to check if the current date is a holiday (excluded date)
  Future<bool> checkIfExcludedDate() async {
    // Get a reference to the database
    final db = await DatabaseHelper.instance.database;

    // Get the current date in 'YYYY-MM-DD' format
    String currentDate = getCurrentDate();

    // SQL query to check if the current date is a holiday
    String query = 'SELECT * FROM HolidayConfiguration WHERE DATE(Date) = ?';

    // Print the query and the parameter (currentDate)
    print("Executing query: $query with parameter: $currentDate");
    appendLog("Executing query _checkIfExcludedDate: $query with parameter: $currentDate");

    // Query the HolidayConfiguration table for the current date
    final List<Map<String, dynamic>> result = await db.rawQuery(query, [currentDate]);

    // If the result is not empty, the current date is a holiday (excluded)
    return result.isNotEmpty;
  }


// Fetch the ShiftFromTime from the UserInfos table
  Future<String> getShiftFromTime() async {
    final db = await DatabaseHelper.instance.database;
    // Assuming userID is retrieved from SharedPreferences or passed as an argument
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userID = prefs.getInt('userID');
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT TrackFromTime FROM UserInfos WHERE id = ?', [userID]);
    return result.isNotEmpty ? result.first['TrackFromTime'] : '09:00';  // Default to '09:00' if no result
  }

// Fetch the ShiftToTime from the UserInfos table
  Future<String> getShiftToTime() async {
    final db = await DatabaseHelper.instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userID = prefs.getInt('userID');
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT TrackToTime FROM UserInfos WHERE id = ?', [userID]);
    return result.isNotEmpty ? result.first['TrackToTime'] : '19:00';  // Default to '19:00' if no result
  }
  Future<String> getweekoffs() async {
    final db = await DatabaseHelper.instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userID = prefs.getInt('userID');
    final List<Map<String, dynamic>> result = await db.rawQuery('SELECT weekOffs FROM UserInfos WHERE id = ?', [userID]);
    return result.isNotEmpty ? result.first['weekOffs'] : 'sunday';  // Default to 'sunday' if no result
  }
  Future<bool> hasleaveday(String weekOffDate) async {
    // Get a reference to the database
    final db = await DatabaseHelper.instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userID = prefs.getInt('userID');
    // SQL query with additional conditions for IsActive and UserId
    String query = "SELECT * FROM UserWeekOffXref WHERE DATE(Date) = ? AND IsActive = 1 AND UserId = ?";

    // Print the query and parameters
    print("Executing query: $query with parameters: $weekOffDate, $userID");
    appendLog("Executing query hasleaveday: $query with parameters: $weekOffDate, $userID");

    // Query the UserWeekOffXref table for the given weekOffDate, IsActive, and UserId
    final List<Map<String, dynamic>> result = await db.rawQuery(query, [weekOffDate, userID]);

    // If the result is not empty, a leave exists for that date
    return result.isNotEmpty;
  }

  Future<bool> hasleaveForToday() async {
    // Get a reference to the database
    final db = await DatabaseHelper.instance.database;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int? userID = prefs.getInt('userID');
    String currentDate = getCurrentDate();
    // SQL query with additional conditions for IsActive and UserId
    String query = "SELECT * FROM UserWeekOffXref WHERE DATE(Date) = ? AND IsActive = 1 AND UserId = ?";

    // Print the query and parameters
    print("Executing query: $query with parameters: $currentDate, $userID");
    appendLog("Executing query hasleaveForToday: $query with parameters: $currentDate, $userID");

    // Query the GeoBoundaries table for points on the current date, IsActive, and UserId
    final List<Map<String, dynamic>> result = await db.rawQuery(query, [currentDate, userID]);

    // If the result is not empty, a point exists for today
    return result.isNotEmpty;
  }

  // Method to execute update queries
  Future<void> updateData(String query, List<dynamic> arguments) async {
    final db = await DatabaseHelper.instance.database;
    await db.rawUpdate(query, arguments);
  }
}
