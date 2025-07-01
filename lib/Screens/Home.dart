import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models/Excersize.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with TickerProviderStateMixin {
  List<Program> programs = [];
  List<Exercise> availableExercises = [];
  bool isLoadingExercises = true;
  String searchQuery = '';
  String selectedCategory = 'All';
  late AnimationController _fabAnimationController;

  Future<void> _savePrograms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final programsJson = programs.map((program) => program.toJson()).toList();
      await prefs.setString('workout_programs', jsonEncode(programsJson));
    } catch (e) {
      print('Error saving programs: $e');
    }
  }

  Future<void> _loadPrograms() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final programsString = prefs.getString('workout_programs');
      if (programsString != null) {
        final programsJson = jsonDecode(programsString) as List;
        setState(() {
          programs = programsJson.map((json) => Program.fromJson(json)).toList();
        });
      }
    } catch (e) {
      print('Error loading programs: $e');
      _showErrorSnackBar('Failed to load saved programs');
    }
  }

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _loadExercises();
    _loadPrograms();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final exercises = await ExerciseService.loadExercisesFromJson();
      setState(() {
        availableExercises = exercises;
        isLoadingExercises = false;
      });
    } catch (e) {
      setState(() {
        isLoadingExercises = false;
      });
      _showErrorSnackBar('Failed to load exercises: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: Size(360, 740),
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Color(0xFF0E1C26),
          appBar: _buildAppBar(),
          body: _buildBody(),
        );
      },
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Workout Hub',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 24.sp,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.teal.shade600,
      elevation: 0,
      centerTitle: true,
      actions: [
        PopupMenuButton(
          icon: Icon(Icons.filter_list, color: Colors.white),
          color: Color(0xFF1A2E35),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Text('Reset All Progress', style: TextStyle(color: Colors.white)),
              value: 'reset',
            ),
          ],
          onSelected: (value) {
            if (value == 'reset') _resetAllProgress();
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (isLoadingExercises) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 16.h),
            Text(
              'Loading exercises...',
              style: TextStyle(color: Colors.white70, fontSize: 16.sp),
            ),
          ],
        ),
      );
    }

    return programs.isEmpty ? _buildEmptyState() : _buildProgramsList();
  }

  Widget _buildProgramsList() {
    return Column(
      children: [
        _buildStatsCard(),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(16.r),
            itemCount: programs.length,
            separatorBuilder: (context, index) => SizedBox(height: 16.h),
            itemBuilder: (context, index) => _buildProgramCard(programs[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard() {
    int totalDays = programs.fold(0, (sum, program) => sum + program.days.length);
    int completedDays = programs.fold(0, (sum, program) =>
    sum + program.days.where((day) => day.isCompleted).length);
    double overallProgress = totalDays > 0 ? completedDays / totalDays : 0.0;

    return Container(
      margin: EdgeInsets.all(16.r),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade700, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Programs', programs.length.toString(), Icons.fitness_center),
              _buildStatItem('Total Days', totalDays.toString(), Icons.calendar_today),
              _buildStatItem('Progress', '${(overallProgress * 100).toInt()}%', Icons.trending_up),
            ],
          ),
          SizedBox(height: 8.h,),
          ElevatedButton.icon(
            onPressed: _addProgram,
            icon: Icon(Icons.add, size: 24.sp),
            label: Text(
              'Create Program',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade500,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
              elevation: 5,
            ),
          ),
        ],
      )
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.teal.shade100.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.fitness_center,
              size: 80.sp,
              color: Colors.teal.shade300,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No workout programs yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Create your first program to get started\nand track your fitness journey',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 16.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 32.h),
          ElevatedButton.icon(
            onPressed: _addProgram,
            icon: Icon(Icons.add, size: 24.sp),
            label: Text(
              'Create Program',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade500,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
              elevation: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: _addProgram,
      backgroundColor: Colors.teal.shade500,
      foregroundColor: Colors.white,
      icon: Icon(Icons.add),
      label: Text('New Program'),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
    );
  }

  Widget _buildProgramCard(Program program, int programIndex) {
    double progress = program.days.isEmpty ? 0.0 :
    program.days.where((d) => d.isCompleted).length / program.days.length;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade600, Colors.teal.shade500],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(15.r),
        ),
        child: ExpansionTile(
          collapsedIconColor: Colors.white,
          iconColor: Colors.white,
          title: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18.sp,
                      ),
                    ),
                    if (program.description != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        program.description!,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              _buildProgramMenu(programIndex),
            ],
          ),
          subtitle: _buildProgramSubtitle(program, progress),
          children: [
            Container(
              color: Colors.white.withOpacity(0.1),
              child: Column(
                children: [
                  ...program.days.asMap().entries.map((entry) =>
                      _buildDayCard(entry.value, programIndex, entry.key)),
                  Padding(
                    padding: EdgeInsets.all(16.r),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _addDay(program),
                            icon: Icon(Icons.add, size: 20.sp),
                            label: Text('Add Day'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        ElevatedButton.icon(
                          onPressed: () => _duplicateProgram(program),
                          icon: Icon(Icons.copy, size: 20.sp),
                          label: Text('Duplicate'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramSubtitle(Program program, double progress) {
    return Padding(
      padding: EdgeInsets.only(top: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.white70, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                '${program.days.length} days',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              Spacer(),
              Text(
                '${(progress * 100).toInt()}% complete',
                style: TextStyle(color: Colors.white70, fontSize: 12.sp),
              ),
            ],
          ),
          if (program.days.isNotEmpty) ...[
            SizedBox(height: 8.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.r),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                minHeight: 6.h,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgramMenu(int programIndex) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Colors.white),
      color: Color(0xFF1A2E35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _editProgram(programIndex);
            break;
          case 'reset':
            _resetProgramProgress(programIndex);
            break;
          case 'delete':
            _deleteProgram(programIndex);
            break;
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue),
              SizedBox(width: 8.w),
              Text('Edit', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'reset',
          child: Row(
            children: [
              Icon(Icons.refresh, color: Colors.orange),
              SizedBox(width: 8.w),
              Text('Reset Progress', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete, color: Colors.red),
              SizedBox(width: 8.w),
              Text('Delete', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(Day day, int programIndex, int dayIndex) {
    int completedExercises = day.exercises.where((e) => e.isCompleted).length;
    double dayProgress = day.exercises.isEmpty ? 0.0 : completedExercises / day.exercises.length;

    return Card(
      color: Colors.teal.shade400,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      margin: EdgeInsets.symmetric(vertical: 6.h, horizontal: 12.w),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: day.isCompleted ? Colors.green : Colors.white24,
          child: Icon(
            day.isCompleted ? Icons.check : Icons.fitness_center,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
        title: Text(
          day.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16.sp,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${day.exercises.length} exercises • $completedExercises completed',
              style: TextStyle(color: Colors.white70, fontSize: 12.sp),
            ),
            if (day.exercises.isNotEmpty) ...[
              SizedBox(height: 4.h),
              LinearProgressIndicator(
                value: dayProgress,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.lightGreenAccent),
                minHeight: 3.h,
              ),
            ],
          ],
        ),
        trailing: Checkbox(
          value: day.isCompleted,
          onChanged: (value) {
            setState(() {
              day.isCompleted = value ?? false;
              if (day.isCompleted) {
                // Mark all exercises as completed when day is completed
                for (var exercise in day.exercises) {
                  exercise.isCompleted = true;
                }
              }
            });
            _savePrograms(); // Add this line
          },
          activeColor: Colors.green,
        ),
        children: [
          Container(
            color: Colors.white.withOpacity(0.1),
            child: Column(
              children: [
                ...day.exercises.asMap().entries.map((entry) =>
                    _buildExerciseListTile(entry.value, day, entry.key)),
                Padding(
                  padding: EdgeInsets.all(12.r),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _addExerciseToDay(day),
                          icon: Icon(Icons.add, size: 18.sp),
                          label: Text('Add Exercise'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal.shade600,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 10.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton(
                        onPressed: () => _deleteDayFromProgram(programIndex, dayIndex),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 16.w),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Icon(Icons.delete, size: 18.sp),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseListTile(WorkoutExercise workoutExercise, Day day, int exerciseIndex) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: workoutExercise.isCompleted ? Colors.green : Colors.grey,
        radius: 16.r,
        child: Icon(
          workoutExercise.isCompleted && day.isCompleted ? Icons.check : Icons.fitness_center,
          color: Colors.white,
          size: 16.sp,
        ),
      ),
      title: Text(
        workoutExercise.exercise.name,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
          decoration: workoutExercise.isCompleted && day.isCompleted ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        _buildExerciseSubtitle(workoutExercise),
        style: TextStyle(color: Colors.white70, fontSize: 12.sp),
      ),
      trailing: PopupMenuButton(
        icon: Icon(Icons.more_vert, color: Colors.white70),
        color: Color(0xFF1A2E35),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, color: Colors.blue),
                SizedBox(width: 8.w),
                Text('Edit', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, color: Colors.red),
                SizedBox(width: 8.w),
                Text('Delete', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
        ],
        onSelected: (value) {
          if (value == 'edit') {
            _editExercise(workoutExercise, day);
          } else if (value == 'delete') {
            _deleteExerciseFromDay(day, exerciseIndex);
          }
        },
      ),
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          workoutExercise.isCompleted = !workoutExercise.isCompleted;
        });
        _savePrograms(); // Add this line
        if (workoutExercise.isCompleted) {
          _showSuccessSnackBar('Exercise completed! 💪');
        }
      },
    );
  }

  String _buildExerciseSubtitle(WorkoutExercise workoutExercise) {
    String subtitle = '${workoutExercise.sets} sets × ${workoutExercise.reps} reps';
    if (workoutExercise.weight != null) {
      subtitle += ' | ${workoutExercise.weight}kg';
    }
    if (workoutExercise.duration != null) {
      subtitle += ' • ${workoutExercise.duration}s';
    }
    return subtitle;
  }

  // Dialog and Action Methods
  void _addProgram() {
    TextEditingController nameController = TextEditingController();
    TextEditingController descController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A2E35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text(
          "Create New Program",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(
              controller: nameController,
              hintText: "Program name (e.g., Push Pull Legs)",
              icon: Icons.fitness_center,
            ),
            SizedBox(height: 16.h),
            _buildDialogTextField(
              controller: descController,
              hintText: "Description (optional)",
              icon: Icons.description,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  programs.add(Program(
                    name: nameController.text.trim(),
                    description: descController.text.trim().isEmpty
                        ? null
                        : descController.text.trim(),
                    days: [],
                  ));
                });
                _savePrograms();
                Navigator.pop(context);
                _showSuccessSnackBar('Program created successfully!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text(
              "Create",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildDialogTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.teal.shade300),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.teal.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
      ),
    );
  }

  void _addExerciseToDay(Day day) {
    if (availableExercises.isEmpty) {
      _showErrorSnackBar('No exercises available. Please add exercises.json to assets.');
      return;
    }

    Exercise? selectedExercise;
    int sets = 3;
    int reps = 10;
    double? weight;
    int? duration;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Color(0xFF1A2E35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          title: Text(
            "Add Exercise",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildExerciseDropdown(selectedExercise, (Exercise? exercise) {
                  setDialogState(() {
                    selectedExercise = exercise;
                  });
                }),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(child: _buildNumberField("Sets", sets, (val) => sets = val ?? sets)),
                    SizedBox(width: 8.w),
                    Expanded(child: _buildNumberField("Reps", reps, (val) => reps = val ?? reps)),
                  ],
                ),
                SizedBox(height: 12.h),
                _buildNumberField("Weight (kg)", weight?.toInt(), (val) => weight = val?.toDouble(), optional: true),
                SizedBox(height: 12.h),
                _buildNumberField("Duration (sec)", duration, (val) => duration = val, optional: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: selectedExercise != null ? () {
                setState(() {
                  day.exercises.add(WorkoutExercise(
                    exercise: selectedExercise!,
                    sets: sets,
                    reps: reps,
                    weight: weight,
                    duration: duration,
                  ));
                });
                _savePrograms(); // Add this line
                Navigator.pop(context);
                _showSuccessSnackBar('Exercise added successfully!');
              } : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text(
                "Add",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseDropdown(Exercise? selectedExercise, Function(Exercise?) onChanged) {
    return DropdownButtonFormField<Exercise>(
      value: selectedExercise,
      decoration: InputDecoration(
        labelText: "Select Exercise",
        labelStyle: TextStyle(color: Colors.white70),
        prefixIcon: Icon(Icons.fitness_center, color: Colors.teal.shade300),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.teal.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
      ),
      dropdownColor: Color(0xFF1A2E35),
      items: availableExercises.map((exercise) =>
          DropdownMenuItem(
            value: exercise,
            child: Text(
              exercise.name,
              style: TextStyle(color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildNumberField(String label, int? value, Function(int?) onChanged, {bool optional = false}) {
    TextEditingController controller = TextEditingController(
      text: value?.toString() ?? '',
    );

    return TextField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label + (optional ? " (Optional)" : ""),
        labelStyle: TextStyle(color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.teal.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: Colors.teal, width: 2),
        ),
      ),
      keyboardType: TextInputType.number,
      onChanged: (val) {
        if (val.isEmpty) {
          onChanged(null);
        } else {
          onChanged(int.tryParse(val));
        }
      },
    );
  }
  // Additional Methods
  void _editProgram(int index) {
    final program = programs[index];
    TextEditingController nameController = TextEditingController(text: program.name);
    TextEditingController descController = TextEditingController(text: program.description ?? '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A2E35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text("Edit Program", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogTextField(
              controller: nameController,
              hintText: "Program name",
              icon: Icons.fitness_center,
            ),
            SizedBox(height: 16.h),
            _buildDialogTextField(
              controller: descController,
              hintText: "Description (optional)",
              icon: Icons.description,
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                setState(() {
                  program.name = nameController.text.trim();
                  program.description = descController.text.trim().isEmpty
                      ? null
                      : descController.text.trim();
                });
                _savePrograms(); // Add this line
                Navigator.pop(context);
                _showSuccessSnackBar('Program updated successfully!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _deleteProgram(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A2E35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text("Delete Program", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to delete '${programs[index].name}'? This action cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                programs.removeAt(index);
              });
              _savePrograms(); // Add this line
              Navigator.pop(context);
              _showSuccessSnackBar('Program deleted successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _duplicateProgram(Program program) {
    showDialog(
      context: context,
      builder: (_) {
        TextEditingController nameController = TextEditingController(text: "${program.name} Copy");
        return AlertDialog(
          backgroundColor: Color(0xFF1A2E35),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
          title: Text("Duplicate Program", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: _buildDialogTextField(
            controller: nameController,
            hintText: "New program name",
            icon: Icons.copy,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.white54)),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isNotEmpty) {
                  setState(() {
                    programs.add(Program(
                      name: nameController.text.trim(),
                      description: program.description,
                      days: program.days.map((day) => Day(
                        name: day.name,
                        exercises: day.exercises.map((exercise) => WorkoutExercise(
                          exercise: exercise.exercise,
                          sets: exercise.sets,
                          reps: exercise.reps,
                          weight: exercise.weight,
                          duration: exercise.duration,
                        )).toList(),
                      )).toList(),
                    ));
                  });
                  _savePrograms(); // Add this line
                  Navigator.pop(context);
                  _showSuccessSnackBar('Program duplicated successfully!');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
              ),
              child: Text("Duplicate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );
  }

  void _resetProgramProgress(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A2E35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text("Reset Progress", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to reset all progress for '${programs[index].name}'?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (var day in programs[index].days) {
                  day.isCompleted = false;
                  for (var exercise in day.exercises) {
                    exercise.isCompleted = false;
                  }
                }
              });
              Navigator.pop(context);
              _showSuccessSnackBar('Progress reset successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text("Reset", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }


  void _addDay(Program program) {
    TextEditingController dayNameController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A2E35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text("Add New Day", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: _buildDialogTextField(
          controller: dayNameController,
          hintText: "Day name (e.g., Push Day, Leg Day)",
          icon: Icons.calendar_today,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              if (dayNameController.text.trim().isNotEmpty) {
                setState(() {
                  program.days.add(Day(
                    name: dayNameController.text.trim(),
                    exercises: [],
                  ));
                });
                _savePrograms(); // Add this line
                Navigator.pop(context);
                _showSuccessSnackBar('Day added successfully!');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text("Add", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _deleteDayFromProgram(int programIndex, int dayIndex) {
    final dayName = programs[programIndex].days[dayIndex].name;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A2E35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text("Delete Day", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to delete '$dayName'?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                programs[programIndex].days.removeAt(dayIndex);
              });
              Navigator.pop(context);
              _showSuccessSnackBar('Day deleted successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _editExercise(WorkoutExercise workoutExercise, Day day) {
    int sets = workoutExercise.sets;
    int reps = workoutExercise.reps;
    double? weight = workoutExercise.weight;
    int? duration = workoutExercise.duration;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A2E35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text("Edit Exercise", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                workoutExercise.exercise.name,
                style: TextStyle(color: Colors.teal, fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Expanded(child: _buildNumberField("Sets", sets, (val) => sets = val ?? sets)),
                  SizedBox(width: 8.w),
                  Expanded(child: _buildNumberField("Reps", reps, (val) => reps = val ?? reps)),
                ],
              ),
              SizedBox(height: 12.h),
              _buildNumberField("Weight (kg)", weight?.toInt(), (val) => weight = val?.toDouble(), optional: true),
              SizedBox(height: 12.h),
              _buildNumberField("Duration (sec)", duration, (val) => duration = val, optional: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                workoutExercise.sets = sets;
                workoutExercise.reps = reps;
                workoutExercise.weight = weight;
                workoutExercise.duration = duration;
              });
              Navigator.pop(context);
              _showSuccessSnackBar('Exercise updated successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text("Update", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _deleteExerciseFromDay(Day day, int exerciseIndex) {
    final exerciseName = day.exercises[exerciseIndex].exercise.name;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A2E35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text("Delete Exercise", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to remove '$exerciseName' from this day?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                day.exercises.removeAt(exerciseIndex);
              });
              Navigator.pop(context);
              _showSuccessSnackBar('Exercise removed successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text("Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _resetAllProgress() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1A2E35),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
        title: Text("Reset All Progress", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          "Are you sure you want to reset progress for all programs? This action cannot be undone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (var program in programs) {
                  for (var day in program.days) {
                    day.isCompleted = false;
                    for (var exercise in day.exercises) {
                      exercise.isCompleted = false;
                    }
                  }
                }
              });
              Navigator.pop(context);
              _showSuccessSnackBar('All progress reset successfully!');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
            ),
            child: Text("Reset All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

