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
      bool isLeave = events[0]['isLeave'];
      return Positioned(
        right: 1,
        bottom: 1,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isLeave ? Colors.red : Colors.green, // Change marker color based on event type
            shape: BoxShape.circle,
          ),
        ),
      );
    }
    return SizedBox();
  }

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
                : ListView.builder(
              itemCount: _selectedEvents.length,
              itemBuilder: (context, index) {
                final event = _selectedEvents[index];
                final eventDescription = event['remarks'];
                final isLeave = event['isLeave'];
                print("eventDate========155${event['Date']}");
                print("eventDate========155${isLeave}");
                if(isLeave == true){
                  leaveCount = 2;
                }
                else{
                  leaveCount = 5 ;
                }
                // Extract only the date part by constructing a DateTime with year, month, and day only.
                final eventDate = DateTime.parse(event['Date']); // Ensure 'Date' format is 'YYYY-MM-DD'

// Get the current date without time
                final currentDate = DateTime.now();
                final today = DateTime(currentDate.year, currentDate.month, currentDate.day);

// Remove time from eventDate for a date-only comparison
                final eventDateOnly = DateTime(eventDate.year, eventDate.month, eventDate.day);
                final isPastEvent = eventDateOnly.isBefore(today);

                print("eventDateOnly: $eventDateOnly, today: $today");
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: isLeave ? Colors.red : Colors.green,
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
                          // IconButton(
                          //   icon: Icon(
                          //     Icons.delete_outline_sharp,
                          //     color: isPastEvent ? Colors.grey : Colors.red, // Grey color for disabled state
                          //   ),
                          //   onPressed: isPastEvent ? null : () => _deleteEvent(index), // Disable if past event
                          //   tooltip: isPastEvent ? 'Cannot delete past events' : 'Delete this event', // Optional tooltip
                          // ),

                          IconButton(
                            icon: Icon(
                              Icons.delete_outline_sharp,
                              color: isPastEvent ? Colors.grey : Colors.red, // Grey color for disabled state
                            ),
                            onPressed: isPastEvent
                                ? null
                                : () async {
                              // Show confirmation dialog
                              bool? confirmed = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    // title: Text('Confirmation'),
                                      titlePadding:
                                      const EdgeInsets.all(0),
                                      title: Container(
                                        alignment: Alignment.center,
                                        padding: const EdgeInsets.all(
                                            16.0),
                                        decoration:
                                        const BoxDecoration(
                                          borderRadius:
                                          BorderRadius.only(
                                            topLeft:
                                            Radius.circular(10),
                                            topRight:
                                            Radius.circular(10),
                                          ),
                                          color:
                                          CommonStyles.btnBlueBgColor,
                                        ),
                                        child: Text(
                                          'Confirmation',
                                          style: TextStyle(
                                            color: Colors
                                                .white, // Text color
                                            fontSize: 18,
                                            fontWeight:
                                            FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      content: Text(
                                          'Are You Sure You Want to Delete This Leave / Work from Office?'),
                                      actions: [
                                      TextButton(
                                      onPressed: () {
                                    Navigator.of(context).pop(
                                        false); // Return false
                                  },
                                  style: TextButton.styleFrom(
                                  backgroundColor:
                                  Colors.grey.shade100
                                  ,
                                  ),
                                  child: Text('Cancel'),
                                  ),
                                  TextButton(
                                  onPressed: () {
                                  Navigator.of(context).pop(
                                  true); // Return true
                                  },
                                  style: TextButton.styleFrom(
                                  backgroundColor:
                                  Colors.grey.shade100
                                  ),
                                  child: Text('Ok', ),
                                  ),
                                  ],  );
                                },
                              );

                              // If confirmed, proceed with deletion
                              if (confirmed == true) {
                                _deleteEvent(index,leaveCount);
                              }
                            },
                            tooltip: isPastEvent ? 'Cannot delete past events' : 'Delete this event', // Optional tooltip
                          ),

                          // IconButton(
                          //   icon: const Icon(Icons.delete_outline_sharp, color: Colors.red),
                          //   onPressed: isPastEvent ? null : () => _deleteEvent(index), // Disable if past event
                          // ),
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
 // String query = "SELECT Code, Date, IsLeave, Remarks FROM UserWeekOffXref WHERE IsActive = '1' AND UserId = $userID";
 String query ="SELECT Code, MAX(Date) AS LatestDate, IsLeave, Remarks FROM UserWeekOffXref WHERE IsActive = '1' AND UserId = $userID GROUP BY Code, Date, IsLeave, Remarks";
    print('query======>$query');
    List<Map<String, dynamic>> result = await dataAccessHandler.getDataFromQuery(query);

    Map<DateTime, List<Map<String, dynamic>>> eventsMap = {};

    for (var row in result) {
      String code = row['Code'];
      String dateString = row['LatestDate'];
      bool isLeave = row['IsLeave'] == 1;
      String? remarks = row['Remarks'];

      DateTime eventDate = DateTime.parse(dateString);
      DateTime normalizedDate = _normalizeDate(eventDate);

      // Store each event as a map containing Code, remarks, and isLeave
      Map<String, dynamic> event = {
        'Code': code,
        'Date':dateString,
        'remarks': remarks,
        'isLeave': isLeave,
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
      // If no internet, show a toast message and navigate
      CommonStyles.showCustomToastMessageLong('Please Check Your Internet Connection.', context, 1, 5);
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
