import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';

import 'Database/DataAccessHandler.dart';
import 'Database/SyncService.dart';
import 'common_styles.dart';
class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  Map<DateTime, List<Map<String, dynamic>>> _events = {};
  List<Map<String, dynamic>> _selectedEvents = [];

  DateTime? _selectedDay; // Declare as nullable
  DateTime? _focusedDay; // Declare as nullable
  int? userID;
  final dataAccessHandler = DataAccessHandler();
int? leaveCount = 0;
  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now(); // Set default selected day
    _focusedDay = DateTime.now();  // Set default focused day
    fetchEvents(); // Fetch events right away
  }

  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = _normalizeDate(selectedDay);
      _focusedDay = _normalizeDate(focusedDay);
      _selectedEvents = _events[_selectedDay] ?? [];
    });
  }
  Widget _buildEventsMarker(DateTime date, List events) {
    if (events.isNotEmpty) {
      // Check if any event is a holiday
      bool isHoliday = events.any((event) => event['Type'] == 'Holiday');
      bool isLeave = events.any((event) => event['isLeave'] == true);

      return Positioned(
        right: 1,
        bottom: 1,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isHoliday
                ? Colors.blue // Holiday → Blue marker
                : (isLeave ? Colors.red : Colors.green), // Leave → Red, Others → Green
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return SizedBox();
  }

  // Widget _buildEventsMarker(DateTime date, List events) {
  //   if (events.isNotEmpty) {
  //     bool isLeave = events[0]['isLeave'];
  //     return Positioned(
  //       right: 1,
  //       bottom: 1,
  //       child: Container(
  //         width: 8,
  //         height: 8,
  //         decoration: BoxDecoration(
  //           color: isLeave ? Colors.red : Colors.green, // Change marker color based on event type
  //           shape: BoxShape.circle,
  //         ),
  //       ),
  //     );
  //   }
  //   return SizedBox();
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: CommonStyles.listOddColor,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        scrolledUnderElevation: 0,
        title: const Text('View Attendance'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Leave',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Work from Office',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Holiday',
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Container to give background color to TableCalendar
          Container(
            color: Colors.lightBlue.shade50,
            padding: const EdgeInsets.all(8.0),
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay!,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              eventLoader: (day) => _events[_normalizeDate(day)] ?? [],
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, date, events) {
                  return _buildEventsMarker(date, events);
                },
              ),
              onDaySelected: _onDaySelected,
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(color: Colors.blue, fontSize: 20),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.blue),
                rightChevronIcon: Icon(Icons.chevron_right, color: Colors.blue),
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          // Container to give background color to the Expanded widget
          Expanded(
            child: _selectedEvents.isEmpty
                ? Center(child: Text('No Leave / Work From Office For Selected Date'))
                : Column(
              children: [
                // Check if any event is a holiday
                // if (_selectedEvents.any((event) => event['Type'] == 'Holiday'))
                //   Padding(
                //     padding: const EdgeInsets.all(8.0),
                //     child: Text(
                //       'This is a Holiday',
                //       style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                //     ),
                //   ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _selectedEvents.length,
                    itemBuilder: (context, index) {
                      final event = _selectedEvents[index];
                      final isLeave = event['isLeave'];
                      final isHoliday = event['Type'] == 'Holiday'; // Check if the event is a holiday

                      final eventDescription = isHoliday ? event['Name'] : event['remarks'];

                      print("eventDate========${event['Date']}");
                      print("isLeave========${isLeave}");

                      if (isLeave == true) {
                        leaveCount = 2;
                      } else {
                        leaveCount = 5;
                      }

                      final eventDate = DateTime.parse(event['Date']);
                      final currentDate = DateTime.now();
                      final today = DateTime(currentDate.year, currentDate.month, currentDate.day);
                      final eventDateOnly = DateTime(eventDate.year, eventDate.month, eventDate.day);
                      final isPastEvent = eventDateOnly.isBefore(today);

                      print("eventDateOnly: $eventDateOnly, today: $today");

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(
                              color: isHoliday
                                  ? Colors.blue // Set different color for holidays
                                  : (isLeave ? Colors.red : Colors.green),
                              width: 4,
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Card(
                          elevation: 0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    eventDescription ?? '',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                if (!isHoliday) // Hide delete button for holidays
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline_sharp,
                                      color: isPastEvent ? Colors.grey : Colors.red,
                                    ),
                                    onPressed: isPastEvent
                                        ? null
                                        : () async {
                                      bool? confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (BuildContext context) {
                                          return AlertDialog(
                                            titlePadding: const EdgeInsets.all(0),
                                            title: Container(
                                              alignment: Alignment.center,
                                              padding: const EdgeInsets.all(16.0),
                                              decoration: const BoxDecoration(
                                                borderRadius: BorderRadius.only(
                                                  topLeft: Radius.circular(10),
                                                  topRight: Radius.circular(10),
                                                ),
                                                color: CommonStyles.btnBlueBgColor,
                                              ),
                                              child: Text(
                                                'Confirmation',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            content: Text(
                                                'Are you sure you want to delete this Leave / Work from Office?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(false);
                                                },
                                                style: TextButton.styleFrom(
                                                  backgroundColor: Colors.grey.shade100,
                                                ),
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () {
                                                  Navigator.of(context).pop(true);
                                                },
                                                style: TextButton.styleFrom(
                                                  backgroundColor: Colors.grey.shade100,
                                                ),
                                                child: Text('Ok'),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (confirmed == true) {
                                        _deleteEvent(index, leaveCount);
                                      }
                                    },
                                    tooltip: isPastEvent
                                        ? 'Cannot delete past events'
                                        : 'Delete this event',
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },

                  ),
                ),
              ],
            ),
          ),


        ],
      ),

    );
  }
  //
  // Future<void> fetchEvents() async {
  //   String query = "SELECT Date, IsLeave, Remarks FROM UserWeekOffXref where IsActive = '1'";
  //   List<Map<String, dynamic>> result = await dataAccessHandler.getDataFromQuery(query);
  //
  //   Map<DateTime, List<Map<String, dynamic>>> eventsMap = {};
  //
  //   for (var row in result) {
  //     String dateString = row['Date'];
  //     bool isLeave = row['IsLeave'] == 1;
  //     String remarks = row['Remarks'];
  //
  //     DateTime eventDate = DateTime.parse(dateString);
  //     DateTime normalizedDate = _normalizeDate(eventDate);
  //
  //     // Store each event as a map containing both remarks and isLeave
  //     Map<String, dynamic> event = {'remarks': remarks, 'isLeave': isLeave};
  //
  //     if (eventsMap.containsKey(normalizedDate)) {
  //       eventsMap[normalizedDate]?.add(event);
  //     } else {
  //       eventsMap[normalizedDate] = [event];
  //     }
  //   }
  //
  //   setState(() {
  //     _events = eventsMap;
  //     _selectedEvents = _events[_normalizeDate(DateTime.now())] ?? [];
  //   });
  // }
  Future<void> fetchEvents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userID = prefs.getInt('userID');

    // Fetch UserWeekOffXref data
    String weekOffQuery = """
    SELECT Code, MAX(Date) AS LatestDate, IsLeave, Remarks 
    FROM UserWeekOffXref 
    WHERE IsActive = '1' AND UserId = $userID 
    GROUP BY Code, IsLeave, Remarks
  """;
    print('WeekOff Query: $weekOffQuery');

    List<Map<String, dynamic>> weekOffResult = await dataAccessHandler.getDataFromQuery(weekOffQuery);

    // Fetch HolidayConfiguration data
    String holidayQuery = """
    SELECT Name, Date FROM HolidayConfiguration 
    WHERE IsActive = 1
  """;
    print('Holiday Query: $holidayQuery');

    List<Map<String, dynamic>> holidayResult = await dataAccessHandler.getDataFromQuery(holidayQuery);

    Map<DateTime, List<Map<String, dynamic>>> eventsMap = {};

    // Process UserWeekOffXref data
    for (var row in weekOffResult) {
      String code = row['Code'];
      String dateString = row['LatestDate'];
      bool isLeave = row['IsLeave'] == 1;
      String? remarks = row['Remarks'];

      DateTime eventDate = DateTime.parse(dateString);
      DateTime normalizedDate = _normalizeDate(eventDate);

      Map<String, dynamic> event = {
        'Code': code,
        'Date': dateString,
        'remarks': remarks,
        'isLeave': isLeave,
        'Type': 'WeekOff'
      };

      if (eventsMap.containsKey(normalizedDate)) {
        eventsMap[normalizedDate]?.add(event);
      } else {
        eventsMap[normalizedDate] = [event];
      }
    }

    // Process HolidayConfiguration data
    for (var row in holidayResult) {
      String name = row['Name'];
      String dateString = row['Date'];

      DateTime eventDate = DateTime.parse(dateString);
      DateTime normalizedDate = _normalizeDate(eventDate);

      Map<String, dynamic> event = {
        'Name': name,
        'Date': dateString,
        'Type': 'Holiday'
      };

      if (eventsMap.containsKey(normalizedDate)) {
        eventsMap[normalizedDate]?.add(event);
      } else {
        eventsMap[normalizedDate] = [event];
      }
    }

    setState(() {
      _events = eventsMap;
      _selectedEvents = _events[_normalizeDate(DateTime.now())] ?? [];
    });
  }

  //  Future<void> fetchEvents() async {
 //    SharedPreferences prefs = await SharedPreferences.getInstance();
 //    userID = prefs.getInt('userID');
 // // String query = "SELECT Code, Date, IsLeave, Remarks FROM UserWeekOffXref WHERE IsActive = '1' AND UserId = $userID";
 // String query ="SELECT Code, MAX(Date) AS LatestDate, IsLeave, Remarks FROM UserWeekOffXref WHERE IsActive = '1' AND UserId = $userID GROUP BY Code, Date, IsLeave, Remarks";
 //    print('query======>$query');
 //    List<Map<String, dynamic>> result = await dataAccessHandler.getDataFromQuery(query);
 //
 //    Map<DateTime, List<Map<String, dynamic>>> eventsMap = {};
 //
 //    for (var row in result) {
 //      String code = row['Code'];
 //      String dateString = row['LatestDate'];
 //      bool isLeave = row['IsLeave'] == 1;
 //      String? remarks = row['Remarks'];
 //
 //      DateTime eventDate = DateTime.parse(dateString);
 //      DateTime normalizedDate = _normalizeDate(eventDate);
 //
 //      // Store each event as a map containing Code, remarks, and isLeave
 //      Map<String, dynamic> event = {
 //        'Code': code,
 //        'Date':dateString,
 //        'remarks': remarks,
 //        'isLeave': isLeave,
 //      };
 //
 //      if (eventsMap.containsKey(normalizedDate)) {
 //        eventsMap[normalizedDate]?.add(event);
 //      } else {
 //        eventsMap[normalizedDate] = [event];
 //      }
 //    }
 //
 //    setState(() {
 //      _events = eventsMap;
 //      _selectedEvents = _events[_normalizeDate(DateTime.now())] ?? [];
 //    });
 //  }

  void _deleteEvent(int index, int? leaveCount) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    userID = prefs.getInt('userID');
    final event = _selectedEvents[index];
    final weekOffCode = event['Code']; // Ensure 'code' is the key used in your map
print('weekOffCode====$weekOffCode');
    // Corrected query
    String query = '''
    UPDATE UserWeekOffXref
    SET IsActive = false, 
        UpdatedByUserId = ?, 
        UpdatedDate = ?, 
        ServerUpdatedStatus = false
    WHERE Code = ?
  ''';
    print('update query====$query');
    await dataAccessHandler.updateData(query, [
      userID,
      DateTime.now().toIso8601String(),
      weekOffCode
    ]);
    // Checking internet connectivity
    bool isConnected = await CommonStyles.checkInternetConnectivity();
    if (isConnected) {
      // Sync data when connected
      final syncService = SyncService(dataAccessHandler);
      await syncService.performRefreshTransactionsSync(context,leaveCount!).whenComplete(() {
        // Navigator.push(
        //   context,
        //   MaterialPageRoute(builder: (context) =>  CalendarPage()),
        // );
      });
    } else {
      if (leaveCount == 2){
        CommonStyles.showCustomToastMessageLong('Leave Deleted Successfully!', context, 0, 2);

      }
      else if (leaveCount == 5){
        CommonStyles.showCustomToastMessageLong(' Work from Office Deleted Successfully!', context, 0, 2);

      }
      // If no internet, show a toast message and navigate
      // CommonStyles.showCustomToastMessageLong('Please Check Your Internet Connection.', context, 1, 5);
      print("Please check your internet connection.");
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) =>  CalendarPage()),
      );
    }

    setState(() {
      _selectedEvents.removeAt(index);
    });

//    fetchEvents(); // Re-fetch events to refresh the display
  }


  // void _deleteEvent(int index) {
  //   setState(() {
  //     _selectedEvents.removeAt(index);
  //   });
  // }
}
