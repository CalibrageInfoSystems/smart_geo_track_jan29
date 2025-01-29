import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartgetrack/HomeScreen.dart';
import 'package:smartgetrack/LoginScreen.dart';
import 'Common/Constants.dart';
import 'Common/api_config.dart';
import 'Database/DataAccessHandler.dart';
import 'common_styles.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'location_service/logic/location_controller/location_controller_cubit.dart';

class ChangePassword extends StatefulWidget {
  final int? id;
  const ChangePassword({super.key, required this.id});

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword>
    with SingleTickerProviderStateMixin {
  final TextEditingController _currentPasswordController =
  TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isObscure = true;
  bool _isObscurec = true;
  bool _isObscurecurrent = false;
  bool? mobileacess;
  final dataAccessHandler = DataAccessHandler();
  late BackgroundService backgroundService;
  String? currectPassword;

  @override
  void initState() {
    print('initState: ${widget.id}');
    backgroundService = BackgroundService(
        userId: widget.id, dataAccessHandler: dataAccessHandler);
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (Platform.isAndroid) {
          SystemNavigator.pop();
          return Future.value(false);
        } else if (Platform.isIOS) {
          exit(0);
        }
        return Future.value(true);
      },
      child: Scaffold(
        backgroundColor: CommonStyles.whiteColor,
        appBar: appBar(context),
        body: changePasswordTemplate(),
      ),
    );
  }

  AppBar appBar(BuildContext context) {
    return AppBar(
      backgroundColor: CommonStyles.listOddColor,
      leading: IconButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: const Icon(Icons.arrow_back),
      ),
      scrolledUnderElevation: 0,
      title: const Text(
        'Change Password',
        //  style: CommonStyles.txStyF14CbFF5,
      ),
    );
  }

  Form changePasswordTemplate() {
    return Form(
      key: _formKey,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              /*  const Row(
                children: [
                  Icon(
                    Icons.location_pin,
                    color: CommonStyles.loginTextColor,
                    size: 30,
                  ),
                  SizedBox(width: 8),
                  Text(
                    "Change Password",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: CommonStyles.loginTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20), */
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
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
                    //MARK: User Name
                    currentpassword(),
                    const SizedBox(height: 10),
                    //MARK: Password
                    newPassword(),

                    const SizedBox(height: 10),
                    confirmPassword(),

                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: submit,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          backgroundColor: CommonStyles.buttonbg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Change Password",
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
            ],
          ),
        ),
      ),
    );
  }

  TextFormField confirmPassword() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _isObscurec,
      decoration: InputDecoration(
        labelText: "Confirm Password *",
        hintText: "Enter Confirm Password ",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        errorMaxLines: 2,
        suffixIcon: IconButton(
          icon: Icon(
            _isObscurec ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _isObscurec = !_isObscurec;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please Enter Confirm Password';
        }
        if (_newPasswordController.text != _confirmPasswordController.text) {
          return 'Confirm Password Must Be Same As New Password';
        }
        return null;
      },
    );
  }

  TextFormField newPassword() {
    return TextFormField(
      controller: _newPasswordController,
      obscureText: _isObscure, // Toggle between true and false
      decoration: InputDecoration(
        labelText: "New Password *",
        hintText: "Enter New Password ",
        errorMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            _isObscure
                ? Icons.visibility_off
                : Icons.visibility, // Icon changes based on visibility
          ),
          onPressed: () {
            setState(() {
              _isObscure = !_isObscure; // Toggle password visibility
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please Enter Password';
        }
        final regex =
        RegExp(r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$!%*?&])[^\s]{8,}$');
        print(
            'lol: ${_newPasswordController.text} | ${_confirmPasswordController.text} | ${!regex.hasMatch(value)}');
        if (!regex.hasMatch(value)) {
          return 'New Password Must Include One Uppercase Letter, One Lowercase Letter, One Digit, One Special Character, and no Spaces.';
        }
        return null;
      },
    );
  }

  TextFormField currentpassword() {
    return TextFormField(
      controller: _currentPasswordController,
      obscureText: _isObscurecurrent,
      decoration: InputDecoration(
        labelText: "Current Password *",
        hintText: "Enter Current Password",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        errorMaxLines: 2,
        suffixIcon: IconButton(
          icon: Icon(
            _isObscurecurrent ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              _isObscurecurrent = !_isObscurecurrent;
            });
          },
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please Enter Current Password';
        }

        if (currectPassword != value) {
          return 'Entered Password Does not Match the Current Password';
        }
        return null;
      },
    );
  }

  Future<void> submit() async {
    bool isConnected = await CommonStyles.checkInternetConnectivity();
    if (isConnected) {
      if (_formKey.currentState!.validate()) {
        String currentPassword = _currentPasswordController.text.trim();
        String password = _newPasswordController.text.trim();
        String confirmPassword = _confirmPasswordController.text.trim();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        String? currentPasswordPrefs = prefs.getString('currentPassword');
        if (currentPassword != currentPasswordPrefs) {
          CommonStyles.showCustomToastMessageLong(
              'Entered Password Does not Match the Current Password',
              context,
              1,
              3);
          // return _showErrorDialog("Please check your current password");
        }
        String? token = prefs.getString('token');
        String url = '$baseUrl$userChangePassword';
        print('url======$url');
        Map<String, String> body = {
          "id": widget.id.toString(),
          "currentPassword": currentPassword,
          "newPassword": password,
          "confirmPassword": confirmPassword
        };

        try {
          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(body),
          );
          print('submit: $url');
          print('submit: ${jsonEncode(body)}');
          print('submit: ${response.body}');
          if (response.statusCode == 200) {
            final data = json.decode(response.body);

            if (data['isSuccess']) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(data['endUserMessage']),
                ),
              );

              //showErrorDialog(data['endUserMessage']);
              Future.delayed(const Duration(seconds: 2), () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                backgroundService.stopService();
                context.read<LocationControllerCubit>().stopLocationFetch();

                // Show Toast after service stops
                Fluttertoast.showToast(msg: "Service stopped successfully!");
                prefs.setBool(Constants.isLogin, false);
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                        (Route<dynamic> route) => false);
              });
            } else {
              CommonStyles.showCustomToastMessageLong(
                  'Invalid User Name/Email/Mobile Number or Password',
                  context,
                  1,
                  3);
              // Show error message
              // _showErrorDialog("Login failed: Invalid username or password.");
            }
          } else {
            CommonStyles.showCustomToastMessageLong(
                'Error: ${response.statusCode}', context, 1, 3);
            //   _showErrorDialog("Error: ${response.statusCode}");
          }
        } catch (e) {
          CommonStyles.showCustomToastMessageLong(
              'An error occurred: $e', context, 1, 5);
          // _showErrorDialog("An error occurred: $e");
        }
      }
    } else {
      CommonStyles.showCustomToastMessageLong(
          'Please Check Your Internet Connection.', context, 1, 3);
      //   Fluttertoast.showToast(
      //       msg: "Please check your internet connection.",
      //       toastLength: Toast.LENGTH_SHORT,
      //       gravity: ToastGravity.CENTER,
      //       timeInSecForIosWeb: 1,
      //       backgroundColor: Colors.red,
      //       textColor: Colors.white,
      //       fontSize: 16.0);
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        //   title: Text('$title'),
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

  void _showErrorDialog(String message, {String? title = 'Error'}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$title'),
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

  Future<void> initialize() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    currectPassword = prefs.getString('currentPassword');
  }
}
