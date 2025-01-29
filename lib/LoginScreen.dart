import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:smartgetrack/test.dart';
import 'package:sqflite/sqflite.dart';
import 'Common/Constants.dart';
import 'Common/api_config.dart';
import 'Database/DataAccessHandler.dart';
import 'Forgotpassword.dart';
import 'common_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import 'HomeScreen.dart';

import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isObscure = true; // Keeps track of password visibility
  bool? mobileacess;
  bool isRequestProcessing = false;
  @override
  void initState() {
    super.initState();
    // _usernameController.text = 'Durga';
    // _passwordController.text = 'test@123';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (Platform.isAndroid) {
            // Close the app on Android
            SystemNavigator.pop();
            return Future.value(false); // Do not navigate back
          } else if (Platform.isIOS) {
            // Close the app on iOS
            exit(0);
            return Future.value(false); // Do not navigate back
          }
          return Future.value(
              true); // Default behavior (navigate back) if not Android or iOS
        },
        child: Scaffold(
          body: Stack(
            children: [
              // Background with map-like design
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(
                          "assets/Splash_bg.png"), // Map background image
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
              // Top-left circular shape (Red)
              Positioned(
                top: -150,
                left: -200,
                child: Container(
                  width: MediaQuery.of(context).size.width * 1.5,
                  height: 380,
                  decoration: BoxDecoration(
                    color: CommonStyles.whiteColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      // Add border property here
                      color: CommonStyles.primaryTextColor, // Red border color
                      width: 2.0, // Border width
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                        left: 50.0), // Add padding to the left
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment
                          .center, // Align text to start (left)
                      children: [
                        const SizedBox(height: 150),
                        // App Logo
                        SvgPicture.asset(
                          "assets/sgt_v4.svg", // Replace with your actual logo path
                          width: 180, // Adjust the size of the logo
                          height: 180,
                        ),
                        //                 Transform.translate(
                        //                   offset: Offset(0, -25), // Move the text 8 pixels upwards
                        //                   child: Text(
                        // 'SGT',
                        // style: TextStyle(
                        // fontSize: 24,
                        // fontWeight: FontWeight.bold,
                        //   color:CommonStyles.blueheader, // Customize color as needed
                        // ),
                        //                   ),),
                      ],
                    ),
                  ),
                ),
              ),

              // Top-right circular shape (Blue)
              Positioned(
                top: -250,
                right: -150,
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  height: 350,
                  decoration: const BoxDecoration(
                    color: CommonStyles.blueColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Bottom-left circular shape (Blue)
              Positioned(
                bottom: -300,
                left: -230,
                child: Container(
                  width: MediaQuery.of(context).size.width * 2,
                  height: 400,
                  decoration: const BoxDecoration(
                    color: CommonStyles.blueColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // Bottom-right circular shape (Red)
              Positioned(
                bottom: -200,
                right: -210,
                child: Container(
                  width: MediaQuery.of(context).size.width / 1.2,
                  height: 450,
                  decoration: const BoxDecoration(
                    color: CommonStyles.primaryTextColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              Positioned(
                top: MediaQuery.of(context).size.height / 2.5 - 40,
                left: 20,
                child: const Row(
                  children: [
                    Icon(
                      Icons.location_pin,
                      color: CommonStyles.loginTextColor,
                      size: 30,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Login",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w400,
                        color: CommonStyles.loginTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).size.height / 2.5,
                left: 30,
                right: 30,
                child: Form(
                  key: _formKey,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(1),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 15),
                        // Mobile Number / Email TextField
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: "User Name/Email/Mobile Number *",
                            hintText: "Enter User Name/Email/Mobile Number",
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          maxLength: 50,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Enter a User Name/Email/Mobile Number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 10),
                        // Password TextField
                        TextFormField(
                          controller: _passwordController,
                          obscureText:
                          _isObscure, // Toggle between true and false
                          decoration: InputDecoration(
                            labelText: "Password *",
                            hintText: "Enter Password ",
                            counterText: "",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isObscure
                                    ? Icons.visibility_off
                                    : Icons
                                    .visibility, // Icon changes based on visibility
                              ),
                              onPressed: () {
                                setState(() {
                                  _isObscure =
                                  !_isObscure; // Toggle password visibility
                                });
                              },
                            ),
                          ),
                          maxLength: 25,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please Enter a Password';
                            }
                            return null;
                          },
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) =>
                                    const Forgotpassword()),
                              );
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: CommonStyles.blueheader),
                            ),
                          ),
                        ),
                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: isRequestProcessing ? null : _login,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              backgroundColor: isRequestProcessing
                                  ? Colors.grey
                                  : CommonStyles.buttonbg,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.perm_identity,
                                  color: CommonStyles.whiteColor,
                                  size: 20,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ));
  }

  Future<void> _login() async {
    try {
      setState(() {
        isRequestProcessing = true;
      });
      bool isConnected = await CommonStyles.checkInternetConnectivity();
      if (isConnected) {
        if (_formKey.currentState!.validate()) {
          String username = _usernameController.text.trim();
          String password = _passwordController.text.trim();
          String url = '$baseUrl$ValidateUser';
          print('ValidateUser==$url');
          //
          // // API URL
          // String url =
          //     'http://182.18.157.215/SmartGeoTrack/API/User/'ValidateUser'';
          print('url=== $url');
          // Request body
          Map<String, dynamic> body = {
            'username': username,
            'password': password,
            'isFromMobile': true, // Boolean value
          };

          // Send HTTP POST request
          final response = await http.post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: json.encode(body),
          );
          print('object ${json.encode(body)}');
          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            if (data['isSuccess']) {
              // Successful login
              // Navigate to the Home screen
              SharedPreferences prefs = await SharedPreferences.getInstance();

              // Save the user data in SharedPreferences
              prefs.setBool(Constants.isLogin, true);
              prefs.setString('token', data['token']);
              prefs.setInt('userID', data['user']['id']);
              prefs.setString('username', data['user']['username']);
              prefs.setString('firstName', data['user']['firstName']);
              prefs.setString('email', data['user']['email']);
              prefs.setString('mobileNumber', data['user']['mobileNumber']);
              prefs.setInt('roleID', data['user']['roleID']);
              prefs.setString('roleName', data['user']['roleName']);
              prefs.setString('empCode', data['user']['empCode']);
              prefs.setString('currentPassword', data['user']['password']);
              mobileacess = data['user']['isMobileAccess'];

              print(
                  'mobileacess  for ${data['user']['username']} ===$mobileacess');
              if (mobileacess!) {
                startTransactionSync(context, data['user']['id']);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => HomeScreen()),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Mobile access is not allowed for ${data['user']['username']}'),
                  ),
                );
              }
            } else {
              CommonStyles.showCustomToastMessageLong(
                  'Invalid User Name/Email/Mobile Number or Password',
                  context,
                  1,
                  5);
            }
          } else {
            CommonStyles.showCustomToastMessageLong(
                'Error: ${response.statusCode}', context, 1, 3);
          }
        }
      } else {
        CommonStyles.showCustomToastMessageLong(
            'Please Check Your Internet Connection.', context, 1, 5);
      }
    } catch (e) {
      setState(() {
        isRequestProcessing = false;
      });
      CommonStyles.showCustomToastMessageLong(
          'An error occurred: $e', context, 1, 3);
    } finally{
      setState(() {
        isRequestProcessing = false;
      });
    }
  }

  // Future<void> _login() async {
  //   bool isConnected = await CommonStyles.checkInternetConnectivity();
  //   if (isConnected) {
  //     if (_formKey.currentState!.validate()) {
  //       String username = _usernameController.text.trim();
  //       String password = _passwordController.text.trim();
  //       String url = '$baseUrl$ValidateUser';
  //       print('ValidateUser==$url');
  //       //
  //       // // API URL
  //       // String url =
  //       //     'http://182.18.157.215/SmartGeoTrack/API/User/'ValidateUser'';
  //       print('url=== $url');
  //       // Request body
  //       Map<String, dynamic> body = {
  //         'username': username,
  //         'password': password,
  //         'isFromMobile': true, // Boolean value
  //       };

  //       try {
  //         // Send HTTP POST request
  //         final response = await http.post(
  //           Uri.parse(url),
  //           headers: {'Content-Type': 'application/json'},
  //           body: json.encode(body),
  //         );
  //         print('object ${json.encode(body)}');
  //         if (response.statusCode == 200) {
  //           final data = json.decode(response.body);

  //           if (data['isSuccess']) {
  //             // Successful login
  //             // Navigate to the Home screen
  //             SharedPreferences prefs = await SharedPreferences.getInstance();

  //             // Save the user data in SharedPreferences
  //             prefs.setBool(Constants.isLogin, true);
  //             prefs.setString('token', data['token']);
  //             prefs.setInt('userID', data['user']['id']);
  //             prefs.setString('username', data['user']['username']);
  //             prefs.setString('firstName', data['user']['firstName']);
  //             prefs.setString('email', data['user']['email']);
  //             prefs.setString('mobileNumber', data['user']['mobileNumber']);
  //             prefs.setInt('roleID', data['user']['roleID']);
  //             prefs.setString('roleName', data['user']['roleName']);
  //             prefs.setString('empCode', data['user']['empCode']);
  //             prefs.setString('currentPassword', data['user']['password']);
  //             //    prefs.setString('mobileNumber', data['user']['isMobileAccess']);
  //             mobileacess = data['user']['isMobileAccess'];

  //             print('mobileacess  for ${data['user']['username']} ===$mobileacess');
  //             if (mobileacess!) {
  //               startTransactionSync(context,data['user']['id']);
  //               //TODO
  //               // If true, navigate to HomeScreen
  //               // Navigator.push(
  //               //   context,
  //               //   MaterialPageRoute(builder: (context) => const LocationTrackingScreen()),
  //               // );
  //               Navigator.push(
  //                 context,
  //                 MaterialPageRoute(builder: (context) =>  LocationTrackingScreen()),
  //               );
  //               // Navigator.push(
  //               //   context,
  //               //   MaterialPageRoute(builder: (context) => const HomeScreen()),
  //               // );
  //             } else {
  //               // If false, show an error message
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(
  //                   content: Text(
  //                       'Mobile access is not allowed for ${data['user']['username']}'),
  //                 ),
  //               );
  //             }
  //             // if(mobileacess)
  //             // Navigator.push(
  //             //   context,
  //             //   MaterialPageRoute(builder: (context) => const HomeScreen()),
  //             // );

  //             // Navigator.push(
  //             //   context,
  //             //   MaterialPageRoute(builder: (context) => const Test()),
  //             // );
  //           } else {
  //             CommonStyles.showCustomToastMessageLong('Invalid User Name/Email/Mobile Number or Password', context, 1, 5);
  //             // Show error message
  //           //  _showErrorDialog("Login failed: Invalid User Name/Email/Mobile Number or Password");
  //           }
  //         } else {
  //           CommonStyles.showCustomToastMessageLong('Error: ${response.statusCode}', context, 1, 3);
  //         //  _showErrorDialog("Error: ${response.statusCode}");
  //         }
  //       } catch (e) {
  //         CommonStyles.showCustomToastMessageLong('An error occurred: $e', context, 1, 3);
  //       //  _showErrorDialog("An error occurred: $e");
  //       }
  //     }
  //   } else {
  //     CommonStyles.showCustomToastMessageLong('Please Check Your Internet Connection.', context, 1, 5);
  //     // Fluttertoast.showToast(
  //     //     msg: "Please check your internet connection.",
  //     //     toastLength: Toast.LENGTH_SHORT,
  //     //     gravity: ToastGravity.CENTER,
  //     //     timeInSecForIosWeb: 1,
  //     //     backgroundColor: Colors.red,
  //     //     textColor: Colors.white,
  //     //     fontSize: 16.0);
  //   }
  // }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> startTransactionSync(BuildContext context, int userId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Retrieve the previous sync date; use null if not available
    String? date = prefs.getString('PREVIOUS_SYNC_DATE');
    print('Previous Sync Date: $date');

    // Show progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 20),
              const Text("Getting total records count..."),
            ],
          ),
        );
      },
    );

    try {
      // Call getCountAndSync method and await it
      await getCountOfHits(userId, date);
    } catch (e) {
      print("Error during sync: $e");
    } finally {
      // Dismiss the progress dialog after sync is completed
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

// Fetch total hits count
//   Future<void> getCountOfHits(int userId, String date) async {
//     String url = '$baseUrl$Getcount';
//     print('===========>${url}');
//
//     Map<String, String> syncDataMap = {
//       "userId": '$userId',
//       "date": date, // Use the passed date (could be an empty string if null initially)
//     };
//     print('===========>${jsonEncode(syncDataMap)}');
//
//     final response = await http.post(
//       Uri.parse(url),
//       body: jsonEncode(syncDataMap),
//       headers: {"Content-Type": "application/json"},
//     );
//
//     if (response.statusCode == 200) {
//       // Parse the response body
//       final data = jsonDecode(response.body);
//
//       if (data['isSuccess']) {
//         List<dynamic> listResult = data['listResult'];
//
//         // Iterate through each result and call the appropriate sync method if count > 0
//         for (var result in listResult) {
//           var holidayConfig = result['holidayConfiguration'];
//           var shifts = result['shifts'];
//
//           if (holidayConfig['count'] > 0) {
//             print("counts: syncHoliday");
//             await syncHoliday(context, userId); // Sync Holiday
//           }
//
//           if (shifts['count'] > 0) {
//             print("counts: syncShift");
//             await syncShift(); // Sync Shift
//           }
//         }
//       } else {
//         print("Failed to retrieve counts: ${data['endUserMessage']}");
//       }
//     } else {
//       throw Exception('Failed to load data count');
//     }
//   }

  Future<void> getCountOfHits(int userId, String? date) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String url = '$baseUrl$Getcount';
    print('===========>${url}');

    // Use null for the `date` key if date is null, otherwise include its value
    Map<String, dynamic> syncDataMap = {
      "userId": '$userId',
      "date": date, // Will be null if `date` is null
    };

    print('===========>${jsonEncode(syncDataMap)}');

    final response = await http.post(
      Uri.parse(url),
      body: jsonEncode(syncDataMap),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      // Parse the response body
      final data = jsonDecode(response.body);

      if (data['isSuccess']) {
        List<dynamic> listResult = data['listResult'];

        // Iterate through each result and call the appropriate sync method if count > 0
        for (var result in listResult) {
          var holidayConfig = result['holidayConfiguration'];
          var shifts = result['shifts'];
          var userWeekOffs = result['userWeekOffs'];

          if (holidayConfig['count'] > 0) {
            print("counts: syncHoliday");
            await syncHoliday(context, userId, date); // Sync Holiday
          }

          if (shifts['count'] > 0) {
            print("counts: syncShift");
            await syncShift(userId, date); // Sync Shift
          }

          if (userWeekOffs['count'] > 0) {
            print("counts: userWeekOffs");
            await syncUserWeekOff(userId, date); // Sync Shift
          }
          String currentDate =
          getCurrentDate(); // Assume this function returns the current date in the required format
          await prefs.setString('PREVIOUS_SYNC_DATE', currentDate);
          print('Sync Date Saved: $currentDate');
        }
      } else {
        print("Failed to retrieve counts: ${data['endUserMessage']}");
      }
    } else {
      throw Exception('Failed to load data count');
    }
  }

  // Show toast message (Utility function)
  static void showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> syncHoliday(
      BuildContext context, int userid, String? date) async {
    String currentDate = getCurrentDate();
    print('===========>${currentDate}');
    final dataAccessHandler =
    Provider.of<DataAccessHandler>(context, listen: false);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$SyncHoliday'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          "date": date,
          "userId": '$userid',
          "pageIndex": 1,
        }),
      );

      if (response.statusCode == 200) {
        // Parse the response
        final data = jsonDecode(response.body);

        // Check if the response is successful
        if (data['isSuccess']) {
          print("Insert the list of holidays into the database");

          // Insert or update the list of holidays into the database
          await dataAccessHandler.insertOrUpdateData(
            'HolidayConfiguration', // Table name
            List<Map<String, dynamic>>.from(
                data['listResult']), // Ensure proper format
            'id', // Assuming 'id' is the primary key field
          );
        } else {
          print("Failed to retrieve holidays: ${data['endUserMessage']}");
        }
      } else {
        throw Exception(
            'Failed to sync holiday data from server: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during holiday sync: $e');
      // You can also show a user-friendly message using a dialog or snackbar
    }
  }

  // Future<void> syncHoliday(int userid) async {
  //   String currentDate = getCurrentDate();
  //   print('===========>${currentDate}');
  //   final response = await http.post(
  //     Uri.parse('$baseUrl$SyncHoliday'),
  //     headers: <String, String>{
  //       'Content-Type': 'application/json; charset=UTF-8',
  //     },
  //
  //     body: jsonEncode({
  //       "date": currentDate,
  //       "userId": '$userid',
  //       "pageIndex": 1
  //     }),
  //   );
  //
  //   if (response.statusCode == 200) {
  //     // Parse the response
  //     final data = jsonDecode(response.body);
  //
  //     // Check if the response is successful
  //     if (data['isSuccess']) {
  //       print("Insert the list of holidays into the database");
  //
  //       // Insert the list of holidays into the database
  //       await insertHolidayData(context, data['listResult']);  // Call the new insert method
  //     } else {
  //       print("Failed to retrieve holidays: ${data['endUserMessage']}");
  //     }
  //   } else {
  //     throw Exception('Failed to sync holiday data from server');
  //   }
  // }
  Future<void> syncShift(int userId, String? date) async {
    final response = await http.post(
      Uri.parse('$baseUrl$SyncShift'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({"date": date, "userId": userId, "pageIndex": 1}),
    );

    if (response.statusCode == 200) {
      // Parse the response
      final data = jsonDecode(response.body);

      // Check if the response is successful
      if (data['isSuccess']) {
        print("Insert the list of shifts into the database");
        // Insert the list of holidays into the database
        await insertShiftData(context, data['listResult']);
      } else {
        print("Failed to retrieve holidays: ${data['endUserMessage']}");
      }
    } else {
      throw Exception('Failed to sync holiday data from server');
    }
  }

  // Method to insert holiday data into the database
  // Method to insert or update holiday data into the database
  static Future<void> insertHolidayData(
      BuildContext context, List<dynamic> holidays) async {
    final dataAccessHandler =
    Provider.of<DataAccessHandler>(context, listen: false);

    for (var holiday in holidays) {
      print('Inserting/updating holiday: $holiday');
      await dataAccessHandler.insertOrUpdateData(
          'holidayConfiguration', [holiday], 'Id');
    }
  }

  // static Future<void> insertHolidayData(BuildContext context, List<dynamic> holidays) async {
  //   final dataAccessHandler = Provider.of<DataAccessHandler>(context, listen: false);
  //
  //   for (var holiday in holidays) {
  //     print('Inserting holiday: $holiday');
  //     await dataAccessHandler.insertData('holidayConfiguration', [holiday]);
  //   }
  // }

  // Method to insert shift data into the database
  static Future<void> insertShiftData(
      BuildContext context, List<dynamic> shifts) async {
    final dataAccessHandler =
    Provider.of<DataAccessHandler>(context, listen: false);

    for (var shift in shifts) {
      print('Inserting shift: $shift');
    //  await dataAccessHandler.insertData('Shift', [shift]);
    }
  }

  Future<void> syncUserWeekOff(int userId, String? date) async {
    // Prepare the request body
    Map<String, dynamic> syncDataMap = {
      "date": date, // `null` if date is null
      "userId": userId,
      "pageIndex": 1,
    };

    print('===========>Request Date: $date');
    print('===========>Request Body: ${jsonEncode(syncDataMap)}');

    try {
      final response = await http.post(
        Uri.parse(
            '$baseUrl${SyncUserWeekOffXref}'), // Replace with the actual endpoint
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(syncDataMap), // Pass the prepared map here
      );

      if (response.statusCode == 200) {
        // Parse the response
        final data = jsonDecode(response.body);

        // Check if the response is successful
        if (data['isSuccess']) {
          print("Insert the list of user week offs into the database");

          // Insert or update the list of user week offs into the database
          await insertUserWeekOffData(data['listResult']);
        } else {
          print("Failed to retrieve user week offs: ${data['endUserMessage']}");
        }
      } else {
        throw Exception('Failed to sync user week off data from server');
      }
    } catch (e) {
      print('Error during user week off sync: $e');
    }
  }

  Future<void> insertUserWeekOffData(List<dynamic> listResult) async {
    final dataAccessHandler =
    Provider.of<DataAccessHandler>(context, listen: false);
    await dataAccessHandler.insertOrUpdateweekxrefData(
      'UserWeekOffXref', // Table name
      List<Map<String, dynamic>>.from(
          listResult), // Ensure the data is in the correct format
      'id',
      // Assuming 'id' is the primary key field
    );
  }
// Future<void> insertUserWeekOffData(List<dynamic> listResult) async {
//   final dataAccessHandler = Provider.of<DataAccessHandler>(context, listen: false);
// //  final db = await dataAccessHandler.getDatabase();
//
//   Batch batch = dataAccessHandler.batch();
//   for (var record in listResult) {
//     batch.insert(
//       'UserWeekOffXref',
//       record,
//       conflictAlgorithm: ConflictAlgorithm.replace, // Replace duplicates
//     );
//   }
//
//   await batch.commit(noResult: true);
// }
}
