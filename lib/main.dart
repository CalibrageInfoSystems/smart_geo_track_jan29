import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smartgetrack/splash_screen.dart';
import 'package:workmanager/workmanager.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'Database/DataAccessHandler.dart';
import 'Database/Palm3FoilDatabase.dart';
import 'Database/SyncServiceB.dart';
import 'HomeScreen.dart';
import 'location_service/logic/location_controller/location_controller_cubit.dart';
import 'location_service/notification/notification.dart';
import 'location_service/repository/location_service_repository.dart';


final notificationService = NotificationService(FlutterLocalNotificationsPlugin());

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize WorkManager
  Workmanager().initialize(
    callbackDispatcher, // The function that defines background tasks
    isInDebugMode: true, // Set to false for production
  );

  runApp(
    ChangeNotifierProvider(
      create: (context) => DataAccessHandler(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // App resumed from background, you can show splash screen if needed
      // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SplashScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: notificationService,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => LocationControllerCubit(
              locationServiceRepository: LocationServiceRepository(),
            ),
          ),
        ],
        child: MaterialApp(

        builder: (context, child) {
      final originalTextScaleFactor = MediaQuery.of(context).textScaleFactor;
      final boldText = MediaQuery.boldTextOf(context);

      final newMediaQueryData = MediaQuery.of(context).copyWith(
      textScaleFactor: originalTextScaleFactor.clamp(0.8, 1.0),
      boldText: boldText,
      );

      return MediaQuery(
      data: newMediaQueryData,
      child: child!,
      );
      },
          title: 'Track Your Location',
          debugShowCheckedModeBanner: false,
          home: SplashScreen(), // This is the initial screen
        ),
      ),
    );
  }
}

/// WorkManager callback dispatcher function
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    appendLog("callbackDispatcher");

    if (task == "syncLocationData") {
      appendLog("syncLocationData");

      final palm3FoilDatabase = await Palm3FoilDatabase.getInstance();
      final syncService = SyncServiceB(DataAccessHandler());

      // Perform the sync
      try {
        await syncService.performRefreshTransactionsSync();
        appendLog("Location data synced successfully in background.");
        print("Location data synced successfully in background.");
      } catch (e) {
        print("Error syncing location data in background: $e");
        appendLog("Error syncing location data in background: $e");

        // Retry sync if it fails
        Workmanager().registerOneOffTask(
          "sync-task-retry",
          "syncLocationData",
          initialDelay: Duration(minutes: 5),
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresCharging: true, // Ensure device is charging
          ),
        );
      }
    }
    return Future.value(true);
  });
}

// void callbackDispatcher() {
//   Workmanager().executeTask((task, inputData) async {
//     appendLog("callbackDispatcher");
//
//     if (task == "syncLocationData") {
//       appendLog("syncLocationData");
//
//       final palm3FoilDatabase = await Palm3FoilDatabase.getInstance();
//       final syncService = SyncServiceB(DataAccessHandler());
//
//       // Perform the sync
//       try {
//         await syncService.performRefreshTransactionsSync();
//         appendLog("Location data synced successfully in background.");
//
//         print("Location data synced successfully in background.");
//       } catch (e) {
//         print("Error syncing location data in background: $e");
//         appendLog("Error syncing location data in background: $e");
//         // Retry sync if it fails
//         Workmanager().registerOneOffTask(
//           "sync-task-retry",
//           "syncLocationData",
//           initialDelay: Duration(minutes: 5),
//           constraints: Constraints(
//             networkType: NetworkType.connected,
//             requiresCharging: true, // Ensure device is charging
//           ),
//         );
//       }
//     }
//     return Future.value(true);
//   });
// }
