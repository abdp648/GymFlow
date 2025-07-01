import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:gymflow/Info/Info.dart';
import 'package:gymflow/Onbording/onbording.dart';
import 'package:gymflow/Screens/Viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());
  final prefs = await SharedPreferences.getInstance();
  final onbording = await prefs.getBool('OnBordingDone') ?? false;
  final loggedIn = await prefs.getBool('LoggedIn') ?? false;
  FlutterNativeSplash.remove();

  runApp(ScreenUtilInit(
    designSize: Size(360, 740),
    minTextAdapt: true,
    splitScreenMode: true,
    builder: (context, child) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: onbording ? (loggedIn ? MyApp() : Info()) : Onbording(),
      );
    },
  ));
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Viewer(),
    );
  }
}
