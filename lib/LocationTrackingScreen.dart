// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:math';
//
// import 'package:background_fetch/background_fetch.dart';
// import 'package:background_location/background_location.dart';
// import 'package:connectivity/connectivity.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:fluttertoast/fluttertoast.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:intl/intl.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:smartgetrack/sync_screen.dart';
// import 'package:smartgetrack/view_leads_info.dart';
// import 'package:workmanager/workmanager.dart';
//
// import 'AddLeads.dart';
// import 'CalendarPage.dart';
// import 'Changepassword.dart';
// import 'Common/Constants.dart';
// import 'Common/api_config.dart';
// import 'Common/custom_lead_template.dart';
// import 'Database/DataAccessHandler.dart';
// import 'Database/DataSyncHelper.dart';
// import 'Database/DatabaseHelper.dart';
// import 'Database/Palm3FoilDatabase.dart';
// import 'Database/SyncService.dart';
// import 'Database/SyncServiceB.dart';
// import 'HomeScreen.dart';
// import 'LoginScreen.dart';
// import 'Model/LeadsModel.dart';
// import 'ViewLeads.dart';
// import 'common_styles.dart';
// import 'package:http/http.dart' as http;
// class LocationTrackingScreen extends StatefulWidget {
//   @override
//   _LocationTrackingScreenState createState() => _LocationTrackingScreenState();
// }
//
// class _LocationTrackingScreenState extends State<LocationTrackingScreen> {
//   double? _latitude, _longitude;
//   Timer? _distanceCheckerTimer;
//   double? _lastLatitude, _lastLongitude;
//   bool isButtonEnabled = true;
//   Palm3FoilDatabase? palm3FoilDatabase;
//   final dataAccessHandler = DataAccessHandler();
//   String? username;
//   String? formattedDate;
//   String? calenderDate;
//   bool isLocationEnabled = false;
//   int? userID;
//   int? totalLeadsCount = 0;
//   int? todayLeadsCount = 0;
//   int? pendingleadscount;
//   int? pendingfilerepocount;
//   int? pendingboundarycount;
//   int? pendingweekoffcount;
//   int? dateRangeLeadsCount = 0;
//   late Future<List<LeadsModel>> futureLeads;
//   bool isLoading = true;
//   double totalDistance = 0.0;
//   DateTime? initialDateOnDatePicker;
//   String? selectedOptionbottom = null; // Default selected option
//   DateTime selectedDatemark = DateTime.now(); // Default current date
//   TextEditingController remarksController = TextEditingController();
//   bool? isLeave ;// Controller for remarks
//   // String selectedOption = 'Leave'; // Default selected option
//   // DateTime selectedDate = DateTime.now(); // Default current date
//   // TextEditingController remarksController = TextEditingController(); // Controller for remarks
//   TextEditingController dateController = TextEditingController(); // Controller for displaying date
//   double POSITION_ACCURACY_THRESHOLD = 15.0; // In meters
//   double MINIMUM_MOVEMENT_SPEED = 0.1;      // In m/s
//
//   int ? toastcount = 0;// Controller for remarks
//   @override
//   void initState() {
//     super.initState();
//     startLocationTracking();
//     getuserdata();
//     fetchLeadCounts();
//     fetchpendingrecordscount();
//     checkLocationEnabled();
//     Future.delayed(Duration.zero, () {
//       setState(() {
//         isLoading = false; // Update loading state
//       });
//     });
//   }
//
//   @override
//   void dispose() {
//     appendLog('S: dispose');
//    // BackgroundLocation.stopLocationService();
//    // _distanceCheckerTimer?.cancel();
//     super.dispose();
//   }
//
//   void startLocationTracking() async {
//     // Start Background Location service
//     await BackgroundLocation.setAndroidNotification(
//       title: "Location Tracking",
//       message: "Your location is being tracked in the background.",
//       icon: "@mipmap/ic_launcher",
//     );
//
//     await BackgroundLocation.startLocationService(distanceFilter: 50);
//
//     // Get location updates
//     BackgroundLocation.getLocationUpdates((location) async {
//       double latitude = location.latitude!;
//       double longitude = location.longitude!;
//       double accuracy = location.accuracy!;
//       double speed = location.speed!;
//
//       // Check for location permission
//       if (await Geolocator.checkPermission() == LocationPermission.always) {
//         DateTime now = DateTime.now();
//
//         // Fetch shift timings and weekoffs
//         final shiftFromTime = await dataAccessHandler.getShiftFromTime();
//         final shiftToTime = await dataAccessHandler.getShiftToTime();
//         final String weekoffsString = await dataAccessHandler.getweekoffs();
//
//         // Parse shift times
//         DateTime shiftStart = DateTime(
//           now.year,
//           now.month,
//           now.day,
//           int.parse(shiftFromTime.split(":")[0]),
//           int.parse(shiftFromTime.split(":")[1]),
//         );
//         DateTime shiftEnd = DateTime(
//           now.year,
//           now.month,
//           now.day,
//           int.parse(shiftToTime.split(":")[0]),
//           int.parse(shiftToTime.split(":")[1]),
//         );
//
//         // Parse weekoffs
//         final Map<String, int> dayToIntMap = {
//           'Monday': 1,
//           'Tuesday': 2,
//           'Wednesday': 3,
//           'Thursday': 4,
//           'Friday': 5,
//           'Saturday': 6,
//           'Sunday': 7,
//         };
//         final List<int> weekoffs = weekoffsString
//             .split(',')
//             .map((day) => day.trim())
//             .where((day) => day.isNotEmpty)
//             .map((day) => dayToIntMap[day])
//             .where((day) => day != null && day >= 1 && day <= 7)
//             .cast<int>()
//             .toList();
//
//         bool isWithinTrackingHours =
//             now.isAfter(shiftStart) && now.isBefore(shiftEnd);
//         bool isWeekOff = weekoffs.contains(now.weekday);
//         bool isExcludedDate = await dataAccessHandler.checkIfExcludedDate();
//
//         if (isWithinTrackingHours && !isExcludedDate && !isWeekOff) {
//           if (_isPositionAccurate(accuracy, speed)) {
//             saveLocationIfNeeded(latitude, longitude);
//           }
//         } else {
//           appendLog(
//               'Tracking not allowed: isWithinTrackingHours: $isWithinTrackingHours, isExcludedDate: $isExcludedDate, isWeekOff: $isWeekOff');
//           print(
//               'Tracking not allowed: isWithinTrackingHours: $isWithinTrackingHours, isExcludedDate: $isExcludedDate, isWeekOff: $isWeekOff');
//         }
//       } else {
//         print('Location permission is not granted.');
//         appendLog('Location permission is not granted.');
//       }
//     });
//
//     BackgroundFetch.configure(BackgroundFetchConfig(
//       minimumFetchInterval: 1,
//       stopOnTerminate: false,
//       startOnBoot: true,
//     ), (taskId) async {
//       // Fetch location and save to DB
//       Location location = await BackgroundLocation.startLocationService();
//       double latitude = location.latitude!;
//       double longitude = location.longitude!;
//       double accuracy = location.accuracy!;
//       double speed = location.speed!;
//
//       if (await Geolocator.checkPermission() == LocationPermission.always) {
//         DateTime now = DateTime.now();
//
//         // Fetch shift timings and weekoffs
//         final shiftFromTime = await dataAccessHandler.getShiftFromTime();
//         final shiftToTime = await dataAccessHandler.getShiftToTime();
//         final String weekoffsString = await dataAccessHandler.getweekoffs();
//
//         // Parse shift times
//         DateTime shiftStart = DateTime(
//           now.year,
//           now.month,
//           now.day,
//           int.parse(shiftFromTime.split(":")[0]),
//           int.parse(shiftFromTime.split(":")[1]),
//         );
//         DateTime shiftEnd = DateTime(
//           now.year,
//           now.month,
//           now.day,
//           int.parse(shiftToTime.split(":")[0]),
//           int.parse(shiftToTime.split(":")[1]),
//         );
//
//         // Parse weekoffs
//         final Map<String, int> dayToIntMap = {
//           'Monday': 1,
//           'Tuesday': 2,
//           'Wednesday': 3,
//           'Thursday': 4,
//           'Friday': 5,
//           'Saturday': 6,
//           'Sunday': 7,
//         };
//         final List<int> weekoffs = weekoffsString
//             .split(',')
//             .map((day) => day.trim())
//             .where((day) => day.isNotEmpty)
//             .map((day) => dayToIntMap[day])
//             .where((day) => day != null && day >= 1 && day <= 7)
//             .cast<int>()
//             .toList();
//
//         bool isWithinTrackingHours =
//             now.isAfter(shiftStart) && now.isBefore(shiftEnd);
//         bool isWeekOff = weekoffs.contains(now.weekday);
//         bool isExcludedDate = await dataAccessHandler.checkIfExcludedDate();
//
//         if (isWithinTrackingHours && !isExcludedDate && !isWeekOff) {
//           if (_isPositionAccurate(accuracy, speed)) {
//             saveLocationIfNeeded(latitude, longitude);
//           }
//         } else {
//           appendLog(
//               'Tracking not allowed: isWithinTrackingHours: $isWithinTrackingHours, isExcludedDate: $isExcludedDate, isWeekOff: $isWeekOff');
//           print(
//               'Tracking not allowed: isWithinTrackingHours: $isWithinTrackingHours, isExcludedDate: $isExcludedDate, isWeekOff: $isWeekOff');
//         }
//       } else {
//         print('Location permission is not granted.');
//         appendLog('Location permission is not granted.');
//       }
//
//       BackgroundFetch.finish(taskId);
//     });
//   }
//
//
// // Updated saveLocationIfNeeded to include additional checks
//   void saveLocationIfNeeded(double latitude, double longitude) async {
//     // Fetch user leave and point status
//     bool hasPointToday = await dataAccessHandler.hasPointForToday();
//     bool hasLeaveToday = await dataAccessHandler.hasleaveForToday();
//
//     if (!hasLeaveToday) {
//       if (_lastLatitude == null || _lastLongitude == null) {
//         saveLocation(latitude, longitude, 0.0);
//         appendLog(
//             '====> Location saved: Latitude=$latitude, Longitude=$longitude');
//       } else {
//         double distance = calculateDistance(
//           _lastLatitude!,
//           _lastLongitude!,
//           latitude,
//           longitude,
//         );
//         if (distance >= 50.0) {
//           saveLocation(latitude, longitude, distance);
//         } else {
//           appendLog('Distance < 50 meters, not saving location.');
//           print("Distance < 50 meters, not saving location.");
//         }
//       }
//     } else {
//       appendLog("Tracking not allowed: User has leave Today");
//       print("Tracking not allowed: User has leave Today");
//     }
//   }
//
//
//
//
//   void SignificantLocationChangeTracking() {
//     BackgroundLocation.startLocationService(distanceFilter: 50); // Fixed for SLC
//   }
//
//
//   bool _isPositionAccurate(double accuracy, double speed) {
//     if (accuracy > POSITION_ACCURACY_THRESHOLD) {
//       print('Position accuracy too low: $accuracy');
//       appendLog('Position accuracy too low: $accuracy');
//       return false;
//     }
//
//     if (speed < MINIMUM_MOVEMENT_SPEED) {
//       print('Speed too low: $speed');
//       appendLog('Speed too low: $speed');
//       return false;
//     }
//
//     return true; // Location is accurate and meets speed requirements
//   }
//
//
//   // void saveLocationIfNeeded(double latitude, double longitude) {
//   //   if (_lastLatitude == null || _lastLongitude == null) {
//   //     // First location, save directly
//   //     saveLocation(latitude, longitude, 0.0);
//   //     appendLog('====> Location saved:150 Latitude=$latitude, Longitude=$longitude');
//   //   } else {
//   //     // Calculate the distance between the last location and the current one
//   //     double distance = calculateDistance(
//   //       _lastLatitude!,
//   //       _lastLongitude!,
//   //       latitude,
//   //       longitude,
//   //     );
//   //     appendLog('====> distance:159=$distance');
//   //     if (distance >= 50.0) {
//   //       saveLocation(latitude, longitude, distance);
//   //     } else {
//   //       appendLog('Distance < 50 meters, not saving location.');
//   //       print("Distance < 50 meters, not saving location.");
//   //     }
//   //   }
//   // }
//
//   Future<void> saveLocation(double latitude, double longitude, double distance) async {
//     final dataAccessHandler = DataAccessHandler();
//     final SyncServiceB syncService = SyncServiceB(dataAccessHandler);
//     Palm3FoilDatabase? palm3FoilDatabase = await Palm3FoilDatabase.getInstance();
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     int? userID = prefs.getInt('userID');
//     if (userID == null) {
//       appendLog('UserID is null. Exiting updateLocation.');
//       return;
//     }
//     // Save location logic (e.g., saving to a database)
//     print(
//         "Saving Location: Latitude=$latitude, Longitude=$longitude Distance= $distance");
//     appendLog(
//         'Last known position: Latitude: $latitude, Longitude: $latitude,Distance= $distance');
//     await insertLocationTinoDatabase(
//         palm3FoilDatabase, latitude, longitude, userID, syncService);
//     // Update last saved location
//     _lastLatitude = latitude;
//     _lastLongitude = longitude;
//   }
//
//   double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
//     const double radius = 6371000; // Earth's radius in meters
//     double dLat = _degreesToRadians(lat2 - lat1);
//     double dLon = _degreesToRadians(lon2 - lon1);
//
//     double a = (sin(dLat / 2) * sin(dLat / 2)) +
//         cos(_degreesToRadians(lat1)) *
//             cos(_degreesToRadians(lat2)) *
//             (sin(dLon / 2) * sin(dLon / 2));
//     double c = 2 * atan2(sqrt(a), sqrt(1 - a));
//     return radius * c; // Distance in meters
//   }
//
//   double _degreesToRadians(double degrees) {
//     return degrees * pi / 180;
//   }
//
//
//
//
//   @override
//   Widget build(BuildContext context) {
//     final size = MediaQuery
//         .of(context)
//         .size;
//
//     return RefreshIndicator(
//       onRefresh: () async {
//         // Re-fetch data and refresh UI
//         fetchpendingrecordscount();
//         setState(() {});
//       },
//       child: WillPopScope(
//         onWillPop: () async {
//           exit(0);
//         },
//         child: Scaffold(
//           backgroundColor: CommonStyles.whiteColor,
//           body: Stack(
//             children: [
//               header(size),
//               Positioned.fill(
//                 top: size.height / 3.5,
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12),
//                   child: SingleChildScrollView(
//                     child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           // Show loading indicator while data is loading
//                           if (isLoading)
//                             const Center(
//                                 child: CircularProgressIndicator()) // Loading indicator
//                           else
//                             ...[
//                               // UI content after loading is complete
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: customBox(
//                                         title: 'Total Client Visits',
//                                         data: totalLeadsCount),
//                                   ),
//                                   const SizedBox(width: 20),
//                                   Expanded(
//                                     child: customBox(
//                                         title: 'Today Client Visits',
//                                         data: todayLeadsCount),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 10),
//                               statisticsSection(),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: dcustomBox(
//                                       title: 'Km\'s Travel',
//                                       data: totalDistance.toStringAsFixed(2),
//                                       // Round to 2 decimal places
//                                       bgImg: 'assets/bg_image2.jpg',
//                                     ),
//                                   ),
//                                   const SizedBox(width: 20),
//                                   Expanded(
//                                     child: customBox(title: 'Client Visits',
//                                         data: dateRangeLeadsCount),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 20),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: customBtn(
//                                       onPressed: () {
//                                         Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder: (
//                                                 context) => const AddLeads(),
//                                           ),
//                                         );
//                                       },
//                                       child: const Row(
//                                         mainAxisAlignment: MainAxisAlignment
//                                             .center,
//                                         children: [
//                                           Icon(
//                                             Icons.add,
//                                             size: 18,
//                                             color: CommonStyles.whiteColor,
//                                           ),
//                                           SizedBox(width: 8),
//                                           Text(
//                                             'Add Client Visit',
//                                             style: CommonStyles.txStyF14CwFF5,
//                                           ),
//                                         ],
//                                       ),
//                                     ),
//                                   ),
//                                   const SizedBox(width: 20),
//                                   Expanded(
//                                     child: customBtn(
//                                       onPressed: () {
//                                         Navigator.push(
//                                           context,
//                                           MaterialPageRoute(
//                                             builder: (
//                                                 context) => const ViewLeads(),
//                                           ),
//                                         );
//                                       },
//                                       child: const Row(
//                                         mainAxisAlignment: MainAxisAlignment
//                                             .center,
//                                         children: [
//                                           Icon(
//                                             Icons.view_list_rounded,
//                                             size: 18,
//                                             color: CommonStyles.whiteColor,
//                                           ),
//                                           SizedBox(width: 8),
//                                           Text(
//                                             'View Client Visits',
//                                             style: CommonStyles.txStyF14CwFF5,
//                                           ),
//                                         ],
//                                       ),
//                                       backgroundColor: CommonStyles
//                                           .btnBlueBgColor,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 20),
//                               Row(
//                                 children: [
//                                   Expanded(
//                                     child: customBtn(
//                                       onPressed: () {
//
//                                         startTransactionSync(context);
//                                       },
//                                       child: const Row(
//                                         mainAxisAlignment: MainAxisAlignment
//                                             .center,
//                                         children: [
//                                           Icon(
//                                             Icons.add,
//                                             size: 18,
//                                             color: CommonStyles.whiteColor,
//                                           ),
//                                           SizedBox(width: 8),
//                                           Text(
//                                             'Get Sync Data',
//                                             style: CommonStyles.txStyF14CwFF5,
//                                           ),
//                                         ],
//                                       ),
//                                       backgroundColor: CommonStyles
//                                           .btnBlueBgColor,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 20),
//                                   Expanded(
//                                     child: customBtn(
//                                       onPressed: () {
//                                         _showBottomSheet(
//                                             context); // Show bottom sheet on button press
//                                       },
//                                       child: const Row(
//                                         mainAxisAlignment: MainAxisAlignment
//                                             .center,
//                                         children: [
//                                           Icon(
//                                             Icons.view_list_rounded,
//                                             size: 18,
//                                             color: CommonStyles.whiteColor,
//                                           ),
//                                           SizedBox(width: 8),
//                                           Text(
//                                             'Mark AS',
//                                             style: CommonStyles.txStyF14CwFF5,
//                                           ),
//                                         ],
//                                       ),
//                                       //backgroundColor: CommonStyles.btnBlueBgColor,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               const SizedBox(height: 20),
//
//                               SizedBox(
//                                 width: double.infinity,
//                                 child: customBtn(
//                                   onPressed: isButtonEnabled
//                                       ? () =>
//                                       Navigator.push(
//                                         context,
//                                         MaterialPageRoute(
//                                             builder: (context) => SyncScreen()),
//                                       )
//                                       : null,
//                                   // Navigate if enabled
//                                   backgroundColor: isButtonEnabled
//                                       ? CommonStyles.btnRedBgColor
//                                       : CommonStyles.hintTextColor,
//                                   // Set background color based on enabled/disabled state
//                                   child: Row(
//                                     mainAxisAlignment: MainAxisAlignment.center,
//                                     children: [
//                                       Icon(
//                                         Icons.sync,
//                                         size: 18,
//                                         color: isButtonEnabled ? CommonStyles
//                                             .whiteColor : CommonStyles
//                                             .disabledTextColor, // Adjust icon color when disabled
//                                       ),
//                                       SizedBox(width: 8),
//                                       Text(
//                                         'Sync Data',
//                                         style: isButtonEnabled ? CommonStyles
//                                             .txStyF14CwFF5 : CommonStyles
//                                             .txStyF14CwFF5.copyWith(
//                                             color: CommonStyles
//                                                 .disabledTextColor), // Adjust text color when disabled
//                                       ),
//                                     ],
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 20),
//                               const Text(
//                                 'Today Client Visits',
//                                 style: CommonStyles.txStyF16CbFF5,
//                               ),
//                               FutureBuilder<List<LeadsModel>>(
//                                 future: futureLeads,
//                                 builder: (context, snapshot) {
//                                   if (snapshot.connectionState ==
//                                       ConnectionState.waiting) {
//                                     return const Center(
//                                         child: CircularProgressIndicator());
//                                   } else if (snapshot.hasError) {
//                                     return Center(child: Text(
//                                         'Error: ${snapshot.error}'));
//                                   } else if (snapshot.hasData &&
//                                       snapshot.data!.isNotEmpty) {
//                                     List<LeadsModel> futureLeads = snapshot
//                                         .data!;
//                                     return ListView.separated(
//                                       itemCount: futureLeads.length,
//                                       physics: const NeverScrollableScrollPhysics(),
//                                       shrinkWrap: true,
//                                       padding: EdgeInsets.zero,
//                                       itemBuilder: (context, index) {
//                                         final lead = futureLeads[index];
//                                         return CustomLeadTemplate(
//                                           index: index,
//                                           lead: lead,
//                                           padding: 0,
//                                           onTap: () {
//                                             Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                 builder: (context) =>
//                                                     ViewLeadsInfo(
//                                                         code: lead.code!),
//                                               ),
//                                             );
//                                           },
//                                         );
//                                       },
//                                       separatorBuilder: (context,
//                                           index) => const SizedBox(height: 10),
//                                     );
//                                   } else {
//                                     return const Center(child: Text(
//                                         'No Client Visits available for today'));
//                                   }
//                                 },
//                               ),
//                               const SizedBox(height: 10),
//
//                             ],
//                         ]),
//                   ),
//                 ),
//               ),
//
//             ],
//           ),
//           floatingActionButton: FloatingActionButton(
//             onPressed: () {
//               String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//               String to_day = DateFormat('dd/MM/yyyy').format(DateTime.now());
//               setState(() {
//                 selectedOption = 'Today'; // Reset the dropdown to "Today"
//                 calenderDate = to_day; // Set calendar to today's date
//                 fetchdatewiseleads(today, today); // Fetch date-wise leads
//                 fetchpendingrecordscount(); // Fetch other counts
//               });
//             },
//             child: const Icon(Icons.refresh), // Refresh icon
//             tooltip: 'Refresh',
//           ),
//
//
//         ),
//       ),
//     );
//   }
//
//
//   Column listCustomText(String text) {
//     return Column(
//       children: [
//         Text(
//           text,
//           style: CommonStyles.txStyF16CbFF5
//               .copyWith(color: CommonStyles.dataTextColor),
//         ),
//         const SizedBox(height: 5),
//       ],
//     );
//   }
//
//   ElevatedButton customBtn({Color? backgroundColor = CommonStyles.btnRedBgColor,
//     required Widget child,
//     void Function()? onPressed}) {
//     return ElevatedButton(
//       onPressed: () {
//         onPressed?.call();
//       },
//       style: ElevatedButton.styleFrom(
//         padding: const EdgeInsets.symmetric(vertical: 15),
//         backgroundColor: backgroundColor,
//       ),
//       child: child,
//     );
//   }
//   Widget statisticsSection() {
//     return Row(
//       children: [
//         const Text(
//           'Statistics',
//           style: CommonStyles.txStyF16CbFF5,
//         ),
//         const Spacer(),
//         datePopupMenu(),
//         Container(
//           height: 30,
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
//           alignment: Alignment.center,
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey),
//           ),
//           child: GestureDetector(
//             onTap: () {
//               final DateTime currentDate = DateTime.now();
//               final DateTime firstDate = DateTime(currentDate.year - 2);
//
//               launchDatePicker(
//                 context,
//                 firstDate: firstDate,
//                 lastDate: DateTime.now(),
//                 initialDate: DateTime.now(),
//               );
//             },
//             child: Row(
//               children: [
//                 Text(
//                   calenderDate ?? DateFormat('dd/MM/yyyy').format(DateTime.now()), // Display current date
//                   style: CommonStyles.txStyF14CbFF5,
//                 ),
//                 const SizedBox(width: 5),
//                 const Icon(
//                   Icons.calendar_today_outlined,
//                   size: 16,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   //
//   // Widget statisticsSection() {
//   //   return Row(children: [
//   //     const Text(
//   //       'Statistics',
//   //       style: CommonStyles.txStyF16CbFF5,
//   //     ),
//   //     const Spacer(),
//   //     datePopupMenu(),
//   //     /*  Row(
//   //       children: [
//   //         Text(
//   //           'Last 7d',
//   //           style: CommonStyles.txStyF14CbFF5
//   //               .copyWith(color: CommonStyles.dataTextColor),
//   //         ),
//   //         const Icon(Icons.keyboard_arrow_down_rounded,
//   //             color: CommonStyles.dataTextColor),
//   //       ],
//   //     ), */
//   //     Container(
//   //       height: 30,
//   //       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
//   //       alignment: Alignment.center,
//   //       decoration: BoxDecoration(
//   //         border: Border.all(color: Colors.grey),
//   //       ),
//   //       child: GestureDetector(
//   //         onTap: () {
//   //           final DateTime currentDate = DateTime.now();
//   //           final DateTime firstDate = DateTime(currentDate.year - 2);
//   //
//   //           launchDatePicker(
//   //             context,
//   //             firstDate: firstDate,
//   //             lastDate: DateTime.now(),
//   //             initialDate: DateTime.now(),
//   //           );
//   //         },
//   //         child: Row(
//   //           children: [
//   //             Text(calenderDate ?? formatDate(DateTime.now()),
//   //                 style: CommonStyles.txStyF14CbFF5),
//   //             SizedBox(width: 5),
//   //             Icon(
//   //               Icons.calendar_today_outlined,
//   //               size: 16,
//   //             ),
//   //           ],
//   //         ),
//   //       ),
//   //     )
//   //   ]);
//   // }
//
//
//   Container dcustomBox({
//     required String title,
//     String? data,
//     String bgImg = 'assets/bg_image1.jpg',
//   }) {
//     return Container(
//       height: 110,
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         image: DecorationImage(
//           image: AssetImage(bgImg),
//           fit: BoxFit.cover,
//         ),
//         border: Border.all(
//           color: CommonStyles.blueTextColor,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(title,
//               style: CommonStyles.txStyF20CbluFF5.copyWith(
//                 fontSize: 16,
//               )
//             /* style: const TextStyle(
//                 color: CommonStyles.blueTextColor, fontSize: 20), */
//           ),
//           Text('$data',
//               style: CommonStyles.txStyF20CbFF5.copyWith(
//                 fontSize: 30,
//               )
//             /* style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold), */
//           ),
//         ],
//       ),
//     );
//   }
//
//   Container customBox({
//     required String title,
//     int? data,
//     String bgImg = 'assets/bg_image1.jpg',
//   }) {
//     return Container(
//       height: 110,
//       padding: const EdgeInsets.symmetric(horizontal: 10),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         image: DecorationImage(
//           image: AssetImage(bgImg),
//           fit: BoxFit.cover,
//         ),
//         border: Border.all(
//           color: CommonStyles.blueTextColor,
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text(title,
//               style: CommonStyles.txStyF20CbluFF5.copyWith(
//                 fontSize: 16,
//               )
//             /* style: const TextStyle(
//                 color: CommonStyles.blueTextColor, fontSize: 20), */
//           ),
//           Text('$data',
//               style: CommonStyles.txStyF20CbFF5.copyWith(
//                 fontSize: 30,
//               )
//             /* style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold), */
//           ),
//         ],
//       ),
//     );
//   }
//
//   Positioned header(Size size) {
//     getuserdata();
//     return Positioned(
//       top: -(size.height / 4.7),
//       left: -10,
//       right: -10,
//       child: Container(
//         width: size.width,
//         height: size.height / 2.1,
//         clipBehavior: Clip.antiAlias,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           image: const DecorationImage(
//             image: AssetImage('assets/header_bg_image.jpg'),
//             fit: BoxFit.cover,
//           ),
//           border: Border.all(
//             color: CommonStyles.blueTextColor,
//             width: 1.0,
//           ),
//         ),
//         child: Column(
//           children: [
//             Expanded(
//               flex: 4,
//               child: Container(
//                 color: Colors.grey,
//               ),
//             ),
//             Expanded(
//               flex: 6,
//               child: SafeArea(
//                 child: Column(
//                   children: [
//                     SizedBox(height: 10,),
//                     customAppBar(),
//                     Expanded(
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         crossAxisAlignment: CrossAxisAlignment.center,
//                         children: [
//                           const Text('Hello,',
//                               style: CommonStyles.txStyF20CpFF5),
//
//                           Text(username ?? '',
//                             // 'string',
//                             style: CommonStyles.txStyF20CpFF5.copyWith(
//                               fontSize: 25,
//                               fontWeight: FontWeight.w900,
//                             ),
//                           ),
//                           Text(formattedDate ?? '',
//                             //  '26th Sep 2024',
//
//                             style: CommonStyles.txStyF14CbFF5,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   List<String> menuItems = [
//     'Change Password',
//     'Logout',
//     'View Attendance '
//   ];
//   List<String> dateItems = [
//     'Today',
//     'This Week',
//     'Month',
//   ];
//
//   String? selectedMenu;
//
//   Widget displayPopupMenu() {
//     return PopupMenuButton<String>(
//       // key: _menuKey,
//       onSelected: (String value) {
//         if (value == 'Logout') {
//           showLogoutDialog();
//         } else if (value == 'Change Password') {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (context) =>
//                   ChangePassword(
//                     id: userID,
//                   ),
//             ),
//           );
//         } else {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//                 builder: (context) =>
//                     CalendarPage()
//               // CalendarPage(
//               //   id: userID,
//               // ),
//             ),
//           );
//         }
//       },
//       itemBuilder: (BuildContext context) {
//         return menuItems.map((String choice) {
//           return PopupMenuItem<String>(
//             value: choice,
//             child: Text(choice),
//           );
//         }).toList();
//       },
//       offset: const Offset(-5, 22),
//     );
//   }
//
//   String selectedOption = 'Today';
//
//   Widget datePopupMenu() {
//     return PopupMenuButton<String>(
//         offset: const Offset(-5, 22),
//         onSelected: (String value) {
//           setState(() {
//             selectedOption = value;
//             totalDistance =
//             0.0; // Reset total distance when a new option is selected
//           });
//           // Handle date selection and print accordingly
//           if (value == 'Today') {
//             String today = DateFormat('yyyy-MM-dd').format(DateTime.now());
//             print("Today: $today");
//             fetchdatewiseleads(today, today);
//           } else if (value == 'This Week') {
//             DateTime now = DateTime.now();
//             int currentWeekDay = now.weekday;
//             DateTime firstDayOfWeek = now.subtract(
//                 Duration(days: currentWeekDay - 1)); // Monday
//             String monday = DateFormat('yyyy-MM-dd').format(firstDayOfWeek);
//             String today = DateFormat('yyyy-MM-dd').format(now);
//             fetchdatewiseleads(monday, today);
//             print("This Week: $monday to $today");
//           } else if (value == 'Month') {
//             DateTime now = DateTime.now();
//             DateTime firstDayOfMonth = DateTime(now.year, now.month, 1);
//             String firstDay = DateFormat('yyyy-MM-dd').format(firstDayOfMonth);
//             String today = DateFormat('yyyy-MM-dd').format(now);
//             print("This Month: $firstDay to $today");
//             fetchdatewiseleads(firstDay, today);
//           }
//         },
//         itemBuilder: (BuildContext context) {
//           return dateItems.map((String choice) {
//             return PopupMenuItem<String>(
//               value: choice,
//               child: Text(choice),
//             );
//           }).toList();
//         },
//         child: Row(
//           children: [
//             Text(
//               selectedOption,
//               style: CommonStyles.txStyF14CbFF5
//                   .copyWith(color: CommonStyles.dataTextColor),
//             ),
//             const Icon(Icons.keyboard_arrow_down_rounded,
//                 color: CommonStyles.dataTextColor),
//           ],
//         ));
//   }
//
//
//   String? selectedDate = 'Today';
//   void launchDatePicker(
//       BuildContext context, {
//         required DateTime firstDate,
//         required DateTime lastDate,
//         required DateTime initialDate,
//       }) {
//     DateTime parsedInitialDate;
//
//     try {
//       parsedInitialDate = calenderDate != null
//           ? DateFormat('dd/MM/yyyy').parse(calenderDate!)
//           : initialDate;
//
//       // Ensure parsedInitialDate is within the allowed range
//       if (parsedInitialDate.isBefore(firstDate) || parsedInitialDate.isAfter(lastDate)) {
//         parsedInitialDate = initialDate; // Reset to initialDate if out of range
//       }
//     } catch (e) {
//       parsedInitialDate = initialDate; // Fallback in case of parsing error
//     }
//
//     showDatePicker(
//       context: context,
//       initialDate: parsedInitialDate,
//       firstDate: firstDate,
//       lastDate: lastDate,
//     ).then((selectedDate) {
//       if (selectedDate != null) {
//         setState(() {
//           calenderDate = DateFormat('dd/MM/yyyy').format(selectedDate);
//           String calender_Date = DateFormat('yyyy-MM-dd').format(selectedDate);
//           print('calenderDate===${calender_Date}'); // Debug print
//           fetchdatewiseleads(calender_Date!, calender_Date!); // Fetch leads
//         });
//       }
//     });
//   }
//
//
//   // Future<void> launchDatePicker(BuildContext context,
//   //     {required DateTime firstDate,
//   //       required DateTime lastDate,
//   //       DateTime? initialDate}) async {
//   //   // final DateTime lastDate = DateTime.now();
//   //   // final DateTime firstDate = DateTime(lastDate.year - 100);
//   //   final DateTime? pickedDay = await showDatePicker(
//   //     context: context,
//   //     initialDate: initialDateOnDatePicker ?? DateTime.now(),
//   //     initialEntryMode: DatePickerEntryMode.calendarOnly,
//   //     firstDate: firstDate,
//   //     lastDate: lastDate,
//   //     initialDatePickerMode: DatePickerMode.day,
//   //   );
//   //   if (pickedDay != null) {
//   //     selectedDate = pickedDay.toString();
//   //     initialDateOnDatePicker = pickedDay;
//   //     String datefromcalender = DateFormat('yyyy-MM-dd').format(pickedDay);
//   //     calenderDate = formatDate(pickedDay);
//   //     fetchdatewiseleads(datefromcalender, datefromcalender);
//   //
//   //     print('pickedDay: $pickedDay');
//   //   }
//   // }
//
//   Widget customAppBar() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       height: 50,
//       decoration: const BoxDecoration(
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           SvgPicture.asset(
//             'assets/sgt_logo.svg',
//             width: 35,
//             height: 35,
//           ),
//           const SizedBox(width: 8),
//           Text(
//             'SGT',
//             style: CommonStyles.txStyF20CpFF5.copyWith(
//                 fontWeight: FontWeight.w900, letterSpacing: 3, fontSize: 22),
//           ),
//           const Spacer(),
//           displayPopupMenu()
//           /* IconButton(
//             icon: const Icon(Icons.more_vert_rounded),
//             onPressed: () {
//               displayPopupMenu();
//             },
//           ), */
//         ],
//       ),
//     );
//   }
//
//
//
//
//   // Ensure you have intl package
//
//   void appendLog(String text) async {
//     const String folderName = 'SmartGeoTrack';
//     const String fileName = 'UsertrackinglogTest.file';
//     //  final appFolderPath = await getApplicationDocumentsDirectory();
//     // Directory appFolderPath = Directory(
//     //     '/storage/emulated/0/Download/$folderName');
//     Directory appFolderPath = Directory('/storage/emulated/0/Download/SmartGeoTrack');
//     if (!appFolderPath.existsSync()) {
//       appFolderPath.createSync(recursive: true);
//     }
//
//     final logFile = File('${appFolderPath.path}/$fileName');
//     if (!logFile.existsSync()) {
//       logFile.createSync();
//     }
//
//     // Get the current date and time in a readable format
//     String currentDateTime = DateFormat('yyyy-MM-dd HH:mm:ss').format(
//         DateTime.now());
//
//     try {
//       final buf = logFile.openWrite(mode: FileMode.append);
//       // Prepend the timestamp to the log message
//       buf.writeln('$currentDateTime: $text');
//       await buf.close();
//     } catch (e) {
//       print("Error appending to log file: $e");
//     }
//   }
//
//   Future<void> getuserdata() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     userID = prefs.getInt('userID');
//     username = prefs.getString('username') ?? '';
//     print(' username==$username');
//     String firstName = prefs.getString('firstName') ?? '';
//     String email = prefs.getString('email') ?? '';
//     String mobileNumber = prefs.getString('mobileNumber') ?? '';
//     String roleName = prefs.getString('roleName') ?? '';
//     DateTime now = DateTime.now();
//     formattedDate = formatDate(now);
//     //  calenderDate = formattedDate;
//     futureLeads = loadleads();
//     print(' formattedDate==$formattedDate'); // Example output: "25th Sep 2024"
//   }
//
//   void showLogoutDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Logout'),
//           content: const Text('Are you sure you wanna logout?'),
//           actions: [
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text('Cancel'),
//             ),
//             TextButton(
//               onPressed: () async {
//                 SharedPreferences prefs = await SharedPreferences.getInstance();
//                 prefs.setBool(Constants.isLogin, false);
//                 Navigator.pushAndRemoveUntil(
//                     context,
//                     MaterialPageRoute(
//                         builder: (context) => const LoginScreen()),
//                         (Route<dynamic> route) => false);
//               },
//               child: const Text('OK'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   String formatDate(DateTime date) {
//     String day = DateFormat('d').format(date);
//     String suffix = getDaySuffix(int.parse(day));
//     String formattedDate =
//         '$day$suffix ${DateFormat('MMM').format(date)} ${DateFormat('y').format(
//         date)}';
//     return formattedDate;
//   }
//
//   String getDaySuffix(int day) {
//     if (day >= 11 && day <= 13) {
//       return 'th';
//     }
//     switch (day % 10) {
//       case 1:
//         return 'st';
//       case 2:
//         return 'nd';
//       case 3:
//         return 'rd';
//       default:
//         return 'th';
//     }
//   }
//
//   Future<void> checkLocationEnabled() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     setState(() {
//       isLocationEnabled = serviceEnabled;
//     });
//     if (!serviceEnabled) {
//       // If location services are disabled, prompt the user to enable them
//       await _promptUserToEnableLocation();
//     }
//   }
//
//   Future<void> _promptUserToEnableLocation() async {
//     bool locationEnabled = await showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text("Location Services Disabled"),
//           content:
//           const Text("Please enable location services to use this app."),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: const Text("Cancel"),
//             ),
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               child: const Text("Enable"),
//             ),
//           ],
//         );
//       },
//     );
//
//     if (locationEnabled) {
//       // Redirect the user to the device settings to enable location services
//       await Geolocator.openLocationSettings();
//     }
//   }
//
//
//   Future<void> fetchLeadCounts() async {
//     setState(() {
//       isLoading = true; // Start loading
//     });
//
//     String currentDate = getCurrentDate(); // Assuming this returns a string in 'YYYY-MM-DD' format
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     userID = prefs.getInt('userID');
//
//     // Fetch total lead counts based on CreatedByUserId
//     totalLeadsCount = await dataAccessHandler.getOnlyOneIntValueFromDb(
//         'SELECT COUNT(*) AS totalLeadsCount FROM Leads WHERE CreatedByUserId = $userID');
//
//     // Fetch today's lead counts for the current date and userID
//     todayLeadsCount = await dataAccessHandler.getOnlyOneIntValueFromDb(
//         "SELECT COUNT(*) AS todayLeadsCount FROM Leads WHERE DATE(CreatedDate) = '$currentDate' AND CreatedByUserId = $userID");
//
//     // Fetch lead counts within a date range for userID (you can modify the date range logic as needed)
//     dateRangeLeadsCount = await dataAccessHandler.getOnlyOneIntValueFromDb(
//         "SELECT COUNT(*) AS dateRangeLeadsCount FROM Leads WHERE DATE(CreatedDate) BETWEEN '$currentDate' AND '$currentDate' AND CreatedByUserId = $userID");
//
//     double calculateDistance(lat1, lon1, lat2, lon2) {
//       var p = 0.017453292519943295; // Pi/180 to convert degrees to radians
//       var c = cos;
//       var a = 0.5 - c((lat2 - lat1) * p) / 2 +
//           c(lat1 * p) * c(lat2 * p) *
//               (1 - c((lon2 - lon1) * p)) / 2;
//       return 12742 * asin(sqrt(a)); // Radius of Earth * arc
//     }
//
//     // Replace this list with dynamically fetched data
//     // Fetch latitude and longitude data for the given date range
//     List<Map<String, double>> data = await dataAccessHandler
//         .fetchLatLongsFromDatabase(currentDate, currentDate);
//
//
//     print('Data: $data km');
//
//
//     for (var i = 0; i < data.length - 1; i++) {
//       totalDistance += calculateDistance(
//           data[i]["lat"], data[i]["lng"], data[i + 1]["lat"],
//           data[i + 1]["lng"]);
//     }
//     print('Total Distance: $totalDistance km');
//
//
//     setState(() {
//       isLoading = false; // Stop loading
//     });
//   }
//
//   Future<List<LeadsModel>> TodayloadLeads(String today) async {
//     try {
//       // final dataAccessHandler = Provider.of<DataAccessHandler>(context, listen: false);
//       List<dynamic> leads = await dataAccessHandler.getTodayLeads(today);
//       return leads.map((item) => LeadsModel.fromMap(item)).toList();
//     } catch (e) {
//       throw Exception('catch: ${e.toString()}');
//     }
//   }
//
//
//   String getCurrentDate() {
//     DateTime now = DateTime.now();
//     String formattedDate = "${now.year}-${now.month.toString().padLeft(
//         2, '0')}-${now.day.toString().padLeft(2, '0')}";
//     return formattedDate;
//   }
//
//
//   Future<List<LeadsModel>> loadleads() async {
//     String currentDate = getCurrentDate();
//     try {
//       final dataAccessHandler =
//       Provider.of<DataAccessHandler>(context, listen: false);
//       List<dynamic> leads = await dataAccessHandler.getTodayLeadsuser(
//           currentDate, userID);
//       return leads.map((item) => LeadsModel.fromMap(item)).toList();
//     } catch (e) {
//       throw Exception('catch: ${e.toString()}');
//     }
//   }
//
//   Future<void> fetchdatewiseleads(String startday, String today) async {
//     setState(() {
//       isLoading = true; // Start loading
//     });
//     dateRangeLeadsCount = await dataAccessHandler.getOnlyOneIntValueFromDb(
//         "SELECT COUNT(*) AS dateRangeLeadsCount FROM Leads WHERE DATE(CreatedDate) BETWEEN '$startday' AND '$today'");
//     print('dateRangeLeadsCount==1240 :  $dateRangeLeadsCount');
//     double calculateDistance(lat1, lon1, lat2, lon2) {
//       var p = 0.017453292519943295; // Pi/180 to convert degrees to radians
//       var c = cos;
//       var a = 0.5 - c((lat2 - lat1) * p) / 2 +
//           c(lat1 * p) * c(lat2 * p) *
//               (1 - c((lon2 - lon1) * p)) / 2;
//       return 12742 * asin(sqrt(a)); // Radius of Earth * arc
//     }
//
//     // Replace this list with dynamically fetched data
//     // Fetch latitude and longitude data for the given date range
//     List<Map<String, double>> data = await dataAccessHandler
//         .fetchLatLongsFromDatabase(startday, today);
//
//
//     print('Data: $data km');
//     totalDistance = 0.0;
//
//     for (var i = 0; i < data.length - 1; i++) {
//       totalDistance += calculateDistance(
//           data[i]["lat"], data[i]["lng"], data[i + 1]["lat"],
//           data[i + 1]["lng"]);
//     }
//     print('Total Distance: $totalDistance km');
//     setState(() {
//       isLoading = false; // Stop loading
//     });
//   }
//
//   void fetchpendingrecordscount() async {
//     setState(() {
//       isLoading = true; // Start loading
//     });
//
//     // Fetch pending counts
//     pendingleadscount = await dataAccessHandler.getOnlyOneIntValueFromDb(
//         'SELECT Count(*) AS pendingLeadsCount FROM Leads WHERE ServerUpdatedStatus = 0');
//     pendingfilerepocount = await dataAccessHandler.getOnlyOneIntValueFromDb(
//         'SELECT Count(*) AS pendingrepoCount FROM FileRepositorys WHERE ServerUpdatedStatus = 0');
//     pendingboundarycount = await dataAccessHandler.getOnlyOneIntValueFromDb(
//         'SELECT Count(*) AS pendingboundaryCount FROM GeoBoundaries WHERE ServerUpdatedStatus = 0');
//     pendingweekoffcount = await dataAccessHandler.getOnlyOneIntValueFromDb(
//         'SELECT Count(*) AS pendingweekoffcount FROM UserWeekOffXref WHERE ServerUpdatedStatus = 0');
//     print('pendingleadscount: $pendingleadscount ');
//     print('pendingfilerepocount: $pendingfilerepocount');
//     print('pendingboundarycount: $pendingboundarycount ');
//
//
//     // Enable button if any of the counts are greater than 0
//     isButtonEnabled = pendingleadscount! > 0 || pendingfilerepocount! > 0 ||
//         pendingboundarycount! > 0 || pendingweekoffcount! > 0 ;
//
//     setState(() {
//       isLoading = false; // Stop loading
//     });
//   }
//
//   void showProgressDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       // Prevents closing the dialog by tapping outside
//       builder: (BuildContext context) {
//         return Dialog(
//           child: Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Row(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(width: 16),
//                 Text("Downloading data..."),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   void hideProgressDialog(BuildContext context) {
//     Navigator.pop(context); // Close the dialog
//   }
//   Future<void> startTransactionSync(BuildContext context) async {
//     // Check internet connection
//     var connectivityResult = await Connectivity().checkConnectivity();
//     if (connectivityResult == ConnectivityResult.none) {
//       CommonStyles.showCustomToastMessageLong('Please Check Your Internet Connection.', context, 1, 5);
//       return; // Exit the function if no internet
//     }
//
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     String? date = prefs.getString('PREVIOUS_SYNC_DATE');
//     print('Previous Sync Date: $date');
//
//     // Show progress dialog
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           content: Row(
//             children: [
//               const CircularProgressIndicator(),
//               const SizedBox(width: 20),
//               const Text("Getting total records count..."),
//             ],
//           ),
//         );
//       },
//     );
//
//     try {
//       // Call getCountOfHits method and await it
//       await getCountOfHits(context,date);
//     } catch (e) {
//       print("Error during sync: $e");
//     } finally {
//       // Dismiss the progress dialog after sync is completed
//       Navigator.of(context, rootNavigator: true).pop();
//     }
//   }
// // Fetch total hits count
//   Future<void> getCountOfHits(BuildContext context, String? date) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//
//     String url = '$baseUrl$Getcount';
//     print('===========>${url}');
//
//     Map<String, dynamic> syncDataMap = {
//       "userId": '$userID',
//       "date": date,
//     };
//
//     print('===========>${jsonEncode(syncDataMap)}');
//
//     final response = await http.post(
//       Uri.parse(url),
//       body: jsonEncode(syncDataMap),
//       headers: {"Content-Type": "application/json"},
//     );
//
//     if (response.statusCode == 200) {
//       final data = jsonDecode(response.body);
//
//       if (data['isSuccess']) {
//         List<dynamic> listResult = data['listResult'];
//
//         bool hasSyncedData = false; // Flag to track if any sync happens
//
//         for (var result in listResult) {
//           var holidayConfig = result['holidayConfiguration'];
//           var shifts = result['shifts'];
//           var userWeekOffs = result['userWeekOffs'];
//
//           if (holidayConfig['count'] > 0) {
//             print("counts: syncHoliday");
//             await syncHoliday(context, date);
//             hasSyncedData = true;
//           }
//
//           if (shifts['count'] > 0) {
//             print("counts: syncShift");
//             await syncShift(date);
//             hasSyncedData = true;
//           }
//
//           if (userWeekOffs['count'] > 0) {
//             print("counts: userWeekOffs");
//             await syncUserWeekOff(date);
//             hasSyncedData = true;
//           }
//         }
//
//         if (hasSyncedData) {
//           DateTime now = DateTime.now();
//           String formattedDate =
//           DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS").format(now);
//           await prefs.setString('PREVIOUS_SYNC_DATE', formattedDate);
//           print('Sync Date Saved: $formattedDate');
//         } else {
//           // Show toast if no data was synced
//           CommonStyles.showCustomToastMessageLong('No data available for sync.', context, 0, 2);
//           // Fluttertoast.showToast(msg: "No data available for sync");
//         }
//       } else {
//         print("Failed to retrieve counts: ${data['endUserMessage']}");
//       }
//     } else {
//       throw Exception('Failed to load data count');
//     }
//   }
//
//
//   // Show toast message (Utility function)
//   static void showToast(BuildContext context, String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }
//
//   Future<void> syncHoliday(BuildContext context, String? date) async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     int? userID = prefs.getInt('userID'); // Ensure userID is retrieved properly
//
//     if (userID == null) {
//       print('Error: userID is null');
//       return; // Exit the function if userID is null
//     }
//
//     // Create sync data map with null-safe `date`
//     Map<String, dynamic> syncDataMap = {
//       "date": date, // This will remain `null` if `date` is null
//       "userId": '$userID',
//       "pageIndex": 1,
//     };
//
//     print('===========>Request Date: $date');
//     print('===========>Request Body: ${jsonEncode(syncDataMap)}');
//
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl$SyncHoliday'),
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//         },
//         body: jsonEncode(syncDataMap), // Pass the syncDataMap here
//       );
//
//       if (response.statusCode == 200) {
//         // Parse the response
//         final data = jsonDecode(response.body);
//
//         // Check if the response is successful
//         if (data['isSuccess']) {
//           print("Insert the list of holidays into the database");
//
//           // Insert or update the list of holidays into the database
//           await dataAccessHandler.insertOrUpdateData(
//             'HolidayConfiguration', // Table name
//             List<Map<String, dynamic>>.from(data['listResult']), // Ensure proper format
//             'id', // Assuming 'id' is the primary key field
//           );
//         } else {
//           print("Failed to retrieve holidays: ${data['endUserMessage']}");
//         }
//       } else {
//         throw Exception('Failed to sync holiday data from server: ${response.statusCode}');
//       }
//     } catch (e) {
//       print('Error during holiday sync: $e');
//       // You can also show a user-friendly message using a dialog or snackbar
//     }
//   }
//
//   Future<void> syncShift(String? date) async {
//     // Prepare the request body
//     Map<String, dynamic> syncDataMap = {
//       "date": date, // `null` if date is null
//       "userId": '$userID',
//       "pageIndex": 1,
//     };
//
//     print('===========>Request Date: $date');
//     print('===========>Request Body: ${jsonEncode(syncDataMap)}');
//
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl$SyncShift'),
//         //  Uri.parse('http://182.18.157.215/SmartGeoTrack/API/Sync/SyncShift'),
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//         },
//         body: jsonEncode(syncDataMap), // Pass the prepared map here
//       );
//
//       if (response.statusCode == 200) {
//         // Parse the response
//         final data = jsonDecode(response.body);
//
//         // Check if the response is successful
//         if (data['isSuccess']) {
//           print("Insert the list of shifts into the database");
//           // Insert the list of shifts into the database
//           await insertShiftData(context, data['listResult']);
//         } else {
//           print("Failed to retrieve shifts: ${data['endUserMessage']}");
//         }
//       } else {
//         throw Exception('Failed to sync shift data from server');
//       }
//     } catch (e) {
//       print('Error during shift sync: $e');
//     }
//   }
//
//
//   // Method to insert holiday data into the database
//   static Future<void> insertHolidayData(BuildContext context,
//       List<dynamic> holidays) async {
//     final dataAccessHandler = Provider.of<DataAccessHandler>(context, listen: false);
//
//     for (var holiday in holidays) {
//       print('Inserting/updating holiday: $holiday');
//       await dataAccessHandler.insertOrUpdateData(
//           'holidayConfiguration', [holiday], 'Id');
//     }
//   }
//
//   // Method to insert shift data into the database
//   static Future<void> insertShiftData(BuildContext context,
//       List<dynamic> shifts) async {
//     final dataAccessHandler = Provider.of<DataAccessHandler>(
//         context, listen: false);
//
//     for (var shift in shifts) {
//       print('Inserting shift: $shift');
//       await dataAccessHandler.insertData('Shift', [shift]);
//     }
//   }
//
// // Function to show bottom sheet
//   Future<void> _showBottomSheet(BuildContext context) async {
//     // Reset previous data before showing the bottom sheet
//     selectedOptionbottom = null; // Clear previous selection
//     // selectedDatemark = DateTime.now(); // Reset to current date
//     remarksController.clear();
//     final holidays = await _fetchHolidays();
//     print('HolidayConfiguration====>$holidays');
//
//     // Initialize selected date as today
//     DateTime potentialDate = DateTime.now();
//
//     // If today is a holiday, find the next non-holiday date
//     while (holidays.contains(DateTime(potentialDate.year, potentialDate.month, potentialDate.day))) {
//       potentialDate = potentialDate.add(const Duration(days: 1)); // Move to the next day
//     }
//
//     // Update the selected date to the next available working date (if today is a holiday)
//     setState(() {
//       selectedDatemark = potentialDate;
//       dateController.text = DateFormat('dd-MM-yyyy').format(selectedDatemark);
//     });
// // Clear the remarks field
//     ///  dateController.text = DateFormat('dd-MM-yyyy').format(selectedDatemark);
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true, // To allow for dynamic height
//       builder: (BuildContext context) {
//         return StatefulBuilder( // Use StatefulBuilder to manage the state inside the bottom sheet
//           builder: (BuildContext context, StateSetter setModalState) {
//             return Padding(
//               padding: MediaQuery.of(context).viewInsets, // To handle keyboard overlay
//               child: Container(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     const Text(
//                       'Add Leave / Work from Office',
//                       style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 16),
//
//                     // Radio buttons for Leave and Work from Office
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Expanded(
//                           flex: 2,
//                           child: Row(
//                             children: [
//                               Radio<String>(
//                                 value: 'Leave',
//                                 groupValue: selectedOptionbottom,
//                                 onChanged: (value) {
//                                   setModalState(() {
//                                     selectedOptionbottom = value!;
//                                     isLeave = true;
//                                   });
//                                 },
//                               ),
//                               const Text('Leave'),
//                             ],
//                           ),
//                         ),
//                         Expanded(
//                           flex: 3,
//                           child: Row(
//                             children: [
//                               Radio<String>(
//                                 value: 'Work from Office',
//                                 groupValue: selectedOptionbottom,
//                                 onChanged: (value) {
//                                   setModalState(() {
//                                     selectedOptionbottom = value!;
//                                     isLeave = false;
//                                   });
//                                 },
//                               ),
//                               const Text('Work from Office'),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//
//                     // Date picker with non-editable text field
//                     TextField(
//                       controller: dateController,
//                       readOnly: true, // Makes the text field non-editable
//                       decoration: InputDecoration(
//                         labelText: 'Select Date *',
//
//                         suffixIcon: IconButton(
//                           icon: const Icon(Icons.calendar_today),
//                           onPressed: () => _selectDate(context, setModalState), // Opens date picker
//                         ),
//                         border: const OutlineInputBorder(),
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//
//                     // Remarks text field
//                     TextField(
//                       controller: remarksController,
//                       decoration: const InputDecoration(
//                         labelText: 'Remarks *',
//                         hintText: "Enter Remarks",
//                         // counterText: "",
//                         border: OutlineInputBorder(),
//                       ),
//                       maxLength: 250,
//                       maxLines: null,
//
//                       keyboardType: TextInputType.multiline,
//                     ),
//
//                     const SizedBox(height: 16),
//
//                     // Close and Submit buttons
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                       children: [
//                         ElevatedButton(
//                           onPressed: () {
//                             Navigator.pop(context); // Close bottom sheet
//                           },
//                           child: Text(
//                             'Close',
//                             style: TextStyle(color: CommonStyles.buttonbg),
//                           ),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: Colors.white,
//                             foregroundColor: Colors.grey,
//                             side: BorderSide(color: CommonStyles.buttonbg),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                         ),
//                         ElevatedButton(
//                           onPressed: () async {
//                             FocusScope.of(context).unfocus();
//                             if (selectedOptionbottom == null) {
//                               CommonStyles.showCustomToastMessageLong('Please Select Leave or Work from Office.', context, 1, 5);
//                               return; // Stop further execution if radio button is not selected
//                             }
//
//                             if (remarksController.text.isEmpty) {
//                               CommonStyles.showCustomToastMessageLong('Please Enter Remarks.', context, 1, 5);
//                               return; // Stop further execution if remarks are empty
//                             }
//
//                             // Handle submit logic here
//                             print('Selected Option: $selectedOptionbottom');
//                             print('Selected Date: $selectedDate');
//                             print('Remarks: ${remarksController.text}');
//
//                             final dataAccessHandler = Provider.of<DataAccessHandler>(context, listen: false);
//                             SharedPreferences prefs = await SharedPreferences.getInstance();
//                             userID = prefs.getInt('userID');
//                             String empCode = prefs.getString('empCode') ?? '';
//
//                             // Assigning the values from the form and default values if null
//                             String formattedDate = getCurrentDateInDDMMYY();
//
//                             String maxNumQuery = '''
//       SELECT MAX(CAST(SUBSTR(code, INSTR(code, '-') + 1) AS INTEGER)) AS MaxNumber
//       FROM UserWeekOffXref WHERE code LIKE 'MW$empCode$formattedDate-%'
//     ''';
//
//                             int? maxSerialNumber = await dataAccessHandler.getOnlyOneIntValueFromDb(maxNumQuery);
//
//                             int serialNumber = (maxSerialNumber != null) ? maxSerialNumber + 1 : 1;
//                             String formattedSerialNumber = serialNumber.toString().padLeft(3, '0');
//
//                             String weekOffCode = 'MW$empCode$formattedDate-$formattedSerialNumber';
//
//                             String weekOffDate = DateFormat('yyy-MM-dd').format(selectedDatemark);
//                             print('weekOffDate======1695>$weekOffDate');
//                             bool hasleaveToday = await dataAccessHandler.hasleaveday(weekOffDate);
//                             String currentDate = getCurrentDate();
//                             print('currentDate======1697>$currentDate weekOffDate======1697>$weekOffDate');
//                             print('weekOffDate======1697>$hasleaveToday');
//                             if(isLeave == true) {
//                               if (currentDate == weekOffDate) {
//                                 CommonStyles.showCustomToastMessageLong(
//                                     'Cannot apply leave for today’s date.',
//                                     context, 1, 5);
//                                 return; // Stop execution if current date matches weekOffDate
//                               }
//                             }
//                             // If leave exists for today, proceed without showing error
//                             if (!hasleaveToday) {
//                               print('weekOffDate======>$weekOffDate');
//                               print('WeekOffCode======>$weekOffCode');
//                               print('hasleaveToday======>$hasleaveToday');
//                               if(isLeave == true) {
//                                 toastcount = 1;
//                               }
//                               else{
//                                 toastcount = 0;
//                               }
//                               // Insert data into the UserWeekOffXref table
//                               final userWeekOff = {
//                                 'Code': weekOffCode,
//                                 'UserId': userID,
//                                 'Date': weekOffDate,
//                                 'empCode':empCode,
//                                 'Remarks': remarksController.text,
//                                 'IsLeave': isLeave,
//                                 'IsActive': true,
//                                 'ServerUpdatedStatus': false,
//                                 'CreatedByUserId': userID,
//                                 'CreatedDate': DateTime.now().toIso8601String(),
//                                 'UpdatedByUserId': userID,
//                                 'UpdatedDate': DateTime.now().toIso8601String(),
//                               };
//
//                               print('userWeekOff======>$userWeekOff');
//
//                               // Inserting data using the data access handler
//                               await dataAccessHandler.insertUserWeekOffXref(userWeekOff);
//
//                               // Checking internet connectivity
//                               bool isConnected = await CommonStyles.checkInternetConnectivity();
//                               if (isConnected) {
//                                 // Sync data when connected
//                                 final syncService = SyncService(dataAccessHandler);
//                                 await syncService.performRefreshTransactionsSync(context,toastcount!).whenComplete(() {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(builder: (context) => const HomeScreen()),
//                                   );
//                                 });
//                               } else {
//                                 if(toastcount == 0){
//                                   CommonStyles.showCustomToastMessageLong('Work from Office Added Successfully!', context, 0, 2);
//
//                                 }else if (toastcount == 1){
//                                   CommonStyles.showCustomToastMessageLong('Leave Added Successfully!', context, 0, 2);
//
//                                 }
//                                 // If no internet, show a toast message and navigate
//                                 Navigator.push(
//                                   context,
//                                   MaterialPageRoute(builder: (context) => const HomeScreen()),
//                                 );
//                               }
//
//                               // Reset form fields after submission
//                               remarksController.clear();  // Clear the remark TextField
//                               setState(() {
//                                 selectedOptionbottom = null; // Reset radio button selection
//                                 selectedDatemark = DateTime.now(); // Reset to current date
//                               });
//
//                               // Close the bottom sheet after submission
//                               Navigator.push(
//                                 context,
//                                 MaterialPageRoute(builder: (context) => const HomeScreen()),
//                               );
//                             }
//
//                             else {
//                               // If leave doesn't exist for today, show error message
//                               CommonStyles.showCustomToastMessageLong('You Have Already Applied for Leave / Work from Office for Selected Date. If You Want to Change, Please Delete the Previous One', context, 1, 5);
//
//                             }
//                           },
//                           child: const Text('Submit'),
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: CommonStyles.buttonbg,
//                             foregroundColor: Colors.white, // Text color
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8), // Rounded corners
//                             ),
//                           ),
//                         )
//
//
//                       ],
//                     )
//
//                   ],
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   // Future<void> _selectDate(BuildContext context, StateSetter setModalState) async {
//   //   // Fetch the list of holiday dates
//   //   final List<DateTime> holidays = await _fetchHolidays();
//   //   print('HolidayConfiguration====>$holidays');
//   //
//   //   // Initialize selected date as today
//   //   DateTime potentialDate = DateTime.now();
//   //
//   //   // Find the next non-holiday date if today is a holiday
//   //   while (holidays.contains(DateTime(potentialDate.year, potentialDate.month, potentialDate.day))) {
//   //     potentialDate = potentialDate.add(const Duration(days: 1)); // Move to the next day
//   //   }
//   //
//   //   // Fetch the week-offs as a comma-separated string, then convert to a list of integers
//   //   final String weekoffsString = await dataAccessHandler.getweekoffs();
//   //   print('weekoffsString==========>${weekoffsString}');
//   //
//   //   // Map weekday names to their corresponding integer values (1 = Monday, ..., 7 = Sunday)
//   //   final Map<String, int> dayToIntMap = {
//   //     'Monday': 1,
//   //     'Tuesday': 2,
//   //     'Wednesday': 3,
//   //     'Thursday': 4,
//   //     'Friday': 5,
//   //     'Saturday': 6,
//   //     'Sunday': 7
//   //   };
//   //
//   //   // Convert the weekoffs string to a list of integers
//   //   final List<int> weekoffs = weekoffsString
//   //       .split(',')
//   //       .map((day) => day.trim())
//   //       .where((day) => day.isNotEmpty)
//   //       .map((day) => dayToIntMap[day]) // Map day names to integers
//   //       .where((day) => day != null && day >= 1 && day <= 7) // Only valid weekdays
//   //       .cast<int>()
//   //       .toList();
//   //   print('weekoffs==========>${weekoffs}');
//   //
//   //   // Update the selected date to the next available working date (if today is a holiday)
//   //   setModalState(() {
//   //     selectedDatemark = potentialDate;
//   //     dateController.text = DateFormat('dd-MM-yyyy').format(selectedDatemark);
//   //   });
//   //
//   //   // Show the date picker
//   //   final DateTime? picked = await showDatePicker(
//   //     context: context,
//   //     initialEntryMode: DatePickerEntryMode.calendarOnly,
//   //     initialDate: selectedDatemark,
//   //     firstDate: DateTime.now(),
//   //     lastDate: DateTime(2101),
//   //     selectableDayPredicate: (DateTime date) {
//   //       // Check if the date is a holiday or a week-off day
//   //       bool isHoliday = holidays.any((holiday) =>
//   //       holiday.year == date.year &&
//   //           holiday.month == date.month &&
//   //           holiday.day == date.day);
//   //       bool isWeekOff = weekoffs.contains(date.weekday);
//   //
//   //       // Disable date if it is a holiday or week-off
//   //       return !(isHoliday || isWeekOff);
//   //     },
//   //   );
//   //
//   //   if (picked != null && picked != selectedDatemark) {
//   //     setModalState(() {
//   //       selectedDatemark = picked;
//   //       dateController.text = DateFormat('dd-MM-yyyy').format(selectedDatemark); // Update text field
//   //     });
//   //   }
//   // }
//
//   Future<void> _selectDate(BuildContext context, StateSetter setModalState) async {
//     // Fetch the list of holiday dates
//     final List<DateTime> holidays = await _fetchHolidays();
//     print('HolidayConfiguration====>$holidays');
//
//     // Fetch the week-offs as a comma-separated string, then convert to a list of integers
//     final String weekoffsString = await dataAccessHandler.getweekoffs();
//     print('weekoffsString==========>${weekoffsString}');
//
//     // Map weekday names to their corresponding integer values (1 = Monday, ..., 7 = Sunday)
//     final Map<String, int> dayToIntMap = {
//       'Monday': 1,
//       'Tuesday': 2,
//       'Wednesday': 3,
//       'Thursday': 4,
//       'Friday': 5,
//       'Saturday': 6,
//       'Sunday': 7
//     };
//
//     // Convert the weekoffs string to a list of integers
//     final List<int> weekoffs = weekoffsString
//         .split(',')
//         .map((day) => day.trim())
//         .where((day) => day.isNotEmpty)
//         .map((day) => dayToIntMap[day]) // Map day names to integers
//         .where((day) => day != null && day >= 1 && day <= 7) // Only valid weekdays
//         .cast<int>()
//         .toList();
//     print('weekoffs==========>${weekoffs}');
//
//     // Initialize selected date as today
//     DateTime potentialDate = DateTime.now();
//
//     // Check if today is a holiday or week-off; if so, find the next working day
//     while (
//     holidays.contains(DateTime(potentialDate.year, potentialDate.month, potentialDate.day)) ||
//         weekoffs.contains(potentialDate.weekday)
//     ) {
//       potentialDate = potentialDate.add(const Duration(days: 1)); // Move to the next day
//     }
//
//     // Update the selected date to the next available working date
//     setModalState(() {
//       selectedDatemark = potentialDate;
//       dateController.text = DateFormat('dd-MM-yyyy').format(selectedDatemark);
//     });
//
//     // Show the date picker
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialEntryMode: DatePickerEntryMode.calendarOnly,
//       initialDate: selectedDatemark,
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2101),
//       selectableDayPredicate: (DateTime date) {
//         // Check if the date is a holiday or a week-off day
//         bool isHoliday = holidays.any((holiday) =>
//         holiday.year == date.year &&
//             holiday.month == date.month &&
//             holiday.day == date.day);
//         bool isWeekOff = weekoffs.contains(date.weekday);
//
//         // Disable date if it is a holiday or week-off
//         return !(isHoliday || isWeekOff);
//       },
//     );
//
//     // Update the selected date if a new date is picked
//     if (picked != null && picked != selectedDatemark) {
//       setModalState(() {
//         selectedDatemark = picked;
//         dateController.text = DateFormat('dd-MM-yyyy').format(selectedDatemark); // Update text field
//       });
//     }
//   }
//
//
//
//   String getCurrentDateInDDMMYY() {
//     final DateTime now = DateTime.now();
//     final String day = now.day.toString().padLeft(2, '0');
//     final String month = now.month.toString().padLeft(2, '0');
//     final String year = (now.year % 100).toString().padLeft(2, '0');
//     return '$day$month$year';
//   }
//
// // Function to fetch holidays from database
//   Future<List<DateTime>> _fetchHolidays() async {
//     final db = await DatabaseHelper.instance.database;
//     final List<Map<String, dynamic>> result = await db.query(
//       'HolidayConfiguration',
//       where: 'IsActive = ?',
//       whereArgs: [1], // Fetch only active holidays
//     );
//
//     // Convert each holiday date to DateTime and return the list
//     return result.map((row) => DateTime.parse(row['Date'])).toList();
//   }
//
//   Future<void> syncUserWeekOff(String? date) async {
//     // Prepare the request body
//     Map<String, dynamic> syncDataMap = {
//       "date": date, // `null` if date is null
//       "userId": '$userID', // Ensure userID is fetched from preferences
//       "pageIndex": 1,
//     };
//
//     print('===========>Request Date: $date');
//     print('===========>Request Body: ${jsonEncode(syncDataMap)}');
//
//     try {
//       final response = await http.post(
//         Uri.parse('$baseUrl${SyncUserWeekOffXref}'), // Replace with the actual endpoint
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//         },
//         body: jsonEncode(syncDataMap), // Pass the prepared map here
//       );
//
//       if (response.statusCode == 200) {
//         // Parse the response
//         final data = jsonDecode(response.body);
//
//         // Check if the response is successful
//         if (data['isSuccess']) {
//           print("Insert the list of user week offs into the database");
//
//           // Insert or update the list of user week offs into the database
//           await insertUserWeekOffData(data['listResult']);
//           CommonStyles.showCustomToastMessageLong('Sync is Successful', context, 0, 3);
//         } else {
//           print("Failed to retrieve user week offs: ${data['endUserMessage']}");
//         }
//       } else {
//         throw Exception('Failed to sync user week off data from server');
//       }
//     } catch (e) {
//       print('Error during user week off sync: $e');
//     }
//   }
//
//   Future<void> insertUserWeekOffData(List<dynamic> listResult) async {
//     final dataAccessHandler =
//     Provider.of<DataAccessHandler>(context, listen: false);
//     await dataAccessHandler.insertOrUpdateweekxrefData(
//       'UserWeekOffXref', // Table name
//       List<Map<String, dynamic>>.from(
//           listResult), // Ensure the data is in the correct format
//       'id',
//       // Assuming 'id' is the primary key field
//     );
//   }
//   Future<void> insertLocationTinoDatabase(Palm3FoilDatabase? database,
//       double latitude, double longitude, int? userID,
//       SyncServiceB syncService) async {
//     if (database == null) {
//       appendLog("Error: Database instance is null.");
//       return;
//     }
//
//     print('Inserting location into database...');
//     appendLog('Inserting location into database...');
//
//     bool locationExists = await checkIfLocationExists(
//         database, latitude, longitude);
//     //
//     if (!locationExists) {
//       try {
//         // Insert the location data into the database
//         await database.insertLocationValues(
//           latitude: latitude,
//           longitude: longitude,
//           createdByUserId: userID,
//           serverUpdatedStatus:
//           false,
//           // Initially false, will be updated after successful sync
//           from: '997', // Replace with appropriate source if needed
//         );
//         print(
//             'Location inserted: Latitude: ${latitude}, Longitude: ${longitude}.');
//         appendLog(
//             'Location inserted: Latitude: ${latitude}, Longitude: ${longitude}.');
//
//         // Check if the network is available and then sync data
//         bool isConnected = await CommonStyles.checkInternetConnectivity();
//         if (isConnected) {
//           appendLog("Network is  available. Sync");
//           try {
//             // Perform the sync operation
//             await syncService.performRefreshTransactionsSync();
//             //   print("Location data synced successfully.");
//             //  appendLog("Location data synced successfully.");
//           } catch (e, stackTrace) {
//             print("Error syncing location data: $e");
//             appendLog("Error syncing location data: $e");
//             print("Error syncing location data stackTrace: $stackTrace");
//             appendLog("Error syncing location data stackTrace: $stackTrace");
//           }
//         } else {
//           // Schedule a background task to retry sync when network is available
//           Workmanager().registerOneOffTask(
//             "sync-task", // Unique task name
//             "syncLocationData", // The function defined in WorkManager
//             initialDelay: Duration(minutes: 10), // Retry after 10 minutes
//             // constraints: Constraints(
//             //     networkType:
//             //     NetworkType.connected), // Only run if network is available
//           );
//
//           Fluttertoast.showToast(
//             msg: "No network. Sync will retry later.",
//             toastLength: Toast.LENGTH_SHORT,
//             gravity: ToastGravity.CENTER,
//             timeInSecForIosWeb: 1,
//             backgroundColor: Colors.red,
//             textColor: Colors.white,
//             fontSize: 16.0,
//           );
//           print("Network is not available. Sync will retry later.");
//           appendLog("Network is not available. Sync will retry later.");
//         }
//       } catch (e) {
//         appendLog('Error inserting location: $e');
//         print("Error inserting location into database: $e");
//       }
//     }
//     else {
//       print("Location already exists in the database.");
//       appendLog("Location already exists in the database.");
//     }
//   }
//
//
//
// }
//
//
//
//
// class DataCountModel {
//   final int count;
//   final String tableName;
//   final String methodName;
//
//   DataCountModel({
//     required this.count,
//     required this.tableName,
//     required this.methodName,
//   });
//
//   factory DataCountModel.fromJson(Map<String, dynamic> json) {
//     return DataCountModel(
//       count: json['count'],
//       tableName: json['tableName'],
//       methodName: json['methodName'],
//     );
//   }
// }
//
//
//
//
//
//
// String getCurrentDate() {
//   DateTime now = DateTime.now();
//   String formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
//   return formattedDate;
//
//
// }
//
//
// // Future<void> insertLocationToDatabase(
// //     Palm3FoilDatabase? database, Position position, int? userID, SyncServiceB syncService) async {
// //
// //   print('Inserting location into database...');
// //   appendLog('Inserting location into database...');
// //   bool locationExists = await checkIfLocationExists(database, position.latitude, position.longitude);
// //
// //   if (!locationExists) {
// //     // Insert the location data into the database
// //     await database!.insertLocationValues(
// //       latitude: position.latitude,
// //       longitude: position.longitude,
// //       createdByUserId: userID,
// //       serverUpdatedStatus: false, // Initially false, will be updated after successful sync
// //       from: '997', // Replace with appropriate source if needed
// //     );
// //
// //     appendLog('Latitude: ${position.latitude}, Longitude: ${position.longitude}.');
// //     print("Location inserted successfully.");
// //     appendLog("Location inserted successfully.");
// //     // Check if the network is available and then sync data
// //     bool isConnected = await CommonStyles.checkInternetConnectivity();
// //     if (isConnected) {
// //       try {
// //         // Perform the sync operation
// //         await syncService.performRefreshTransactionsSync();
// //         print("Location data synced successfully.");
// //         appendLog("Location data synced successfully.");
// //       } catch (e) {
// //         print("Error syncing location data: $e");
// //       }
// //     } else {
// //       Fluttertoast.showToast(
// //           msg: "Please check your internet connection.",
// //           toastLength: Toast.LENGTH_SHORT,
// //           gravity: ToastGravity.CENTER,
// //           timeInSecForIosWeb: 1,
// //           backgroundColor: Colors.red,
// //           textColor: Colors.white,
// //           fontSize: 16.0);
// //       print("Network is not available. Data will be synced later.");
// //     }
// //   } else {
// //     print("Location already exists in the database.");
// //   }
// //
// //
// // }
//
// // Helper method to check network availability (stub example)
// Future<bool> checkNetworkAvailability() async {
//   // Add your logic here to check for network availability
//   // Example: Use Connectivity package or similar
//   return true; // Assume network is available for this example
// }
//
//
// Future<bool> checkIfLocationExists(Palm3FoilDatabase? database, double latitude, double longitude) async {
//   final queryResult = await database!.getLocationByLatLong(latitude, longitude);
//   return queryResult.isNotEmpty;
// }
// const double POSITION_ACCURACY_THRESHOLD = 20.0; // Adjusted threshold for position accuracy
// const double SPEED_ACCURACY_THRESHOLD = 10.0; // Adjusted threshold for speed accuracy
// const double MINIMUM_MOVEMENT_SPEED = 0.1; // Adjusted threshold for minimum speed
//
// // Function to check if the position is accurate
// bool _isPositionAccurate(Position position) {
//   print('Position Accuracy: ${position.accuracy}');
//   print('Speed Accuracy: ${position.speedAccuracy}');
//   print('Speed: ${position.speed}');
//
//   if (position.accuracy > POSITION_ACCURACY_THRESHOLD) {
//     appendLog('Position accuracy too low: ${position.accuracy}');
//   }
//
//   if (position.speed < MINIMUM_MOVEMENT_SPEED) {
//     appendLog('Speed too low: ${position.speed}');
//   }
//
//   // Return true only if all conditions for accuracy and speed are met
//   return position.accuracy <= POSITION_ACCURACY_THRESHOLD &&
//       position.speed >= MINIMUM_MOVEMENT_SPEED; // Check only for speed
// }
//
// // bool _isPositionAccurate(Position position) {
// //   print('Position Accuracy: ${position.accuracy}');
// //   print('Speed Accuracy: ${position.speedAccuracy}');
// //   print('Speed: ${position.speed}');
// //   if (position.accuracy > 15.0) {
// //     appendLog('Position accuracy too low: ${position.accuracy}');
// //   }
// //   // if (position.speedAccuracy > 10.0) {
// //   //   appendLog('Speed accuracy too low: ${position.speedAccuracy}');
// //   // }
// //   if (position.speed < 0.1) {
// //     appendLog('Speed too low: ${position.speed}');
// //   }
// //
// //   return position.accuracy <= 15.0 && // Adjusted threshold for position accuracy
// //    //   position.speedAccuracy <= 10.0 && // Adjusted threshold for speed accuracy
// //       position.speed >= 0.1; // Adjusted threshold for minimum speed
// // }
// // // bool _isPositionAccurate(Position position) {
// //   print('Position Accuracy: ${position.accuracy}');
// //   print('Speed Accuracy: ${position.speedAccuracy}');
// //   print('Speed: ${position.speed}');
// //
// //   if (position.accuracy > POSITION_ACCURACY_THRESHOLD) {
// //     appendLog('Position accuracy too low: ${position.accuracy}');
// //   }
// //
// //   if (position.speed < MINIMUM_MOVEMENT_SPEED) {
// //     appendLog('Speed too low: ${position.speed}');
// //   }
// //
// //   // Return true only if all conditions for accuracy and speed are met
// //   return position.accuracy <= POSITION_ACCURACY_THRESHOLD &&
// //       position.speed >= MINIMUM_MOVEMENT_SPEED; // Check only for speed
// // }
//
// void appendLog(String text) async {
//   const String folderName = 'SmartGeoTrack';
//   const String fileName = 'UsertrackinglogTest.file';
//   // final appFolderPath = await getApplicationDocumentsDirectory();
//   Directory appFolderPath = Directory('/storage/emulated/0/Download/SmartGeoTrack');
//   if (!appFolderPath.existsSync()) {
//     appFolderPath.createSync(recursive: true);
//   }
//
//
//   final logFile = File('${appFolderPath.path}/$fileName');
//   if (!logFile.existsSync()) {
//     logFile.createSync();
//   }
//
//   // Get the current date and time
//   String currentDateTime = DateTime.now().toString();
//
//   try {
//     final buf = logFile.openWrite(mode: FileMode.append);
//     // Prepend the timestamp to the log message
//     buf.writeln('$currentDateTime: $text');
//     await buf.close();
//   } catch (e) {
//     print("Error appending to log file: $e");
//   }
// }
//
//
// class StatCard extends StatelessWidget {
//   final String label;
//   final String value;
//
//   const StatCard({super.key, required this.label, required this.value});
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         color: Colors.pink[50],
//       ),
//       child: Column(
//         children: [
//           Text(value,
//               style:
//               const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
//           const SizedBox(height: 8),
//           Text(label, style: const TextStyle(fontSize: 18)),
//         ],
//       ),
//     );
//   }
// }
//
//
