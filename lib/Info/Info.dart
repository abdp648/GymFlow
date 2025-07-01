import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gymflow/Info/Login.dart';

class Info extends StatefulWidget {
  @override
  _InfoState createState() => _InfoState();
}

class _InfoState extends State<Info> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  String gender = 'male';
  String activityLevel = 'Low';
  String goal = 'Maintain';

  void saveDataAndNavigate() async {
    final prefs = await SharedPreferences.getInstance();
    final age = int.tryParse(ageController.text);
    final height = double.tryParse(heightController.text);
    final weight = double.tryParse(weightController.text);

    if (nameController.text.isEmpty ||
        age == null ||
        height == null ||
        weight == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please complete all fields')));
      return;
    }

    await prefs.setString("Name", nameController.text);
    await prefs.setInt("Age", age);
    await prefs.setDouble("Height", height);
    await prefs.setDouble("Weight", weight);
    await prefs.setString("Gender", gender);
    await prefs.setString("ActivityLevel", activityLevel);
    await prefs.setString("Goal", goal);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(360, 740),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Color(0xFF162932),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 30.h),
                  Text(
                    "Welcome, ${nameController.text.isEmpty ? "bro" : nameController.text} 👋",
                    style: TextStyle(
                      fontSize: 24.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    "Let’s get to know you better!",
                    style: TextStyle(fontSize: 16.sp, color: Colors.white70),
                  ),
                  SizedBox(height: 30.h),

                  _buildInfoCard(
                    title: "Name",
                    child: _buildInput(nameController, "Enter your name"),
                  ),
                  _buildInfoCard(
                    title: "Age",
                    child: _buildInput(
                      ageController,
                      "Enter your age",
                      isNumber: true,
                    ),
                  ),
                  _buildInfoCard(
                    title: "Height (cm)",
                    child: _buildInput(
                      heightController,
                      "Enter your height",
                      isNumber: true,
                    ),
                  ),
                  _buildInfoCard(
                    title: "Weight (kg)",
                    child: _buildInput(
                      weightController,
                      "Enter your weight",
                      isNumber: true,
                    ),
                  ),

                  _buildInfoCard(
                    title: "Gender",
                    child: Row(
                      children: [
                        _buildOptionButton(
                          "male",
                          gender == "male",
                              () => setState(() => gender = "male"),
                        ),
                        SizedBox(width: 10.w),
                        _buildOptionButton(
                          "female",
                          gender == "female",
                              () => setState(() => gender = "female"),
                        ),
                      ],
                    ),
                  ),

                  _buildInfoCard(
                    title: "Activity Level",
                    child: Row(
                      children: [
                        _buildOptionButton(
                          "Low",
                          activityLevel == "Low",
                              () => setState(() => activityLevel = "Low"),
                        ),
                        SizedBox(width: 10.w),
                        _buildOptionButton(
                          "Moderate",
                          activityLevel == "Moderate",
                              () => setState(() => activityLevel = "Moderate"),
                        ),
                        SizedBox(width: 10.w),
                        _buildOptionButton(
                          "High",
                          activityLevel == "High",
                              () => setState(() => activityLevel = "High"),
                        ),
                      ],
                    ),
                  ),

                  _buildInfoCard(
                    title: "Goal",
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildOptionButton(
                            "Maintain",
                            goal == "Maintain",
                                () => setState(() => goal = "Maintain"),
                          ),
                          SizedBox(width: 10.w),
                          _buildOptionButton(
                            "Lose Weight",
                            goal == "Lose Weight",
                                () => setState(() => goal = "Lose Weight"),
                          ),
                          SizedBox(width: 10.w),
                          _buildOptionButton(
                            "Gain Weight",
                            goal == "Gain Weight",
                                () => setState(() => goal = "Gain Weight"),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 30.h),
                  ElevatedButton(
                    onPressed: saveDataAndNavigate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.tealAccent[700],
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      minimumSize: Size(double.infinity, 50.h),
                    ),
                    child: Text(
                      "Continue",
                      style: TextStyle(fontSize: 18.sp, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard({required String title, required Widget child}) {
    return Container(
      margin: EdgeInsets.only(bottom: 18.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Color(0xFF22323C),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10.h),
          child,
        ],
      ),
    );
  }

  Widget _buildInput(
      TextEditingController controller,
      String hint, {
        bool isNumber = false,
      }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white38),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Color(0xFF2A3B47),
        contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      ),
    );
  }

  Widget _buildOptionButton(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: selected ? Colors.tealAccent[700] : Color(0xFF2A3B47),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Colors.tealAccent : Colors.white24,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
