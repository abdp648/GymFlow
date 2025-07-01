import 'package:flutter/material.dart';
import 'package:gymflow/Info/Info.dart';
import 'package:gymflow/Info/Login.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Onbording extends StatefulWidget {
  @override
  _OnbordingState createState() => _OnbordingState();
}

class _OnbordingState extends State<Onbording> {
  final PageController _controller = PageController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF162932),
      body: PageView(
        controller: _controller,
        children: [
          OnboardingScreen(controller: _controller),
          OnboardingScreen2(),
        ],
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  final PageController controller;

  OnboardingScreen({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              child: Lottie.asset(
                "assets/onbording1.json",
                width: 250.w,
                height: 250.h,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 60.h),
            Text(
              "Welcome to GymFlow",
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              "Track your workouts with a big workout library",
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent[700],
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () {
                controller.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Text(
                "Next",
                style: TextStyle(fontSize: 18.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingScreen2 extends StatelessWidget {
  OnboardingScreen2({super.key});
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(24.r),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              child: Lottie.asset(
                "assets/onbording2.json",
                width: 250.w,
                height: 250.h,
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 40.h),
            Text(
              "Stay Healthy",
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            Text(
              "Stay healthy, and achieve your fitness goals — all in one app!",
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.tealAccent[700],
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              onPressed: () => onBoardingDone(context),
              child: Text(
                "Get Started",
                style: TextStyle(fontSize: 18.sp, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> onBoardingDone(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('OnBordingDone', true);
  Navigator.pushReplacement(
    context,
    MaterialPageRoute(builder: (context) => Info()),
  );
}
