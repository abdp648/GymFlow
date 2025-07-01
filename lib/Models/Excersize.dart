import 'dart:convert';
import 'package:flutter/services.dart';

class Exercise {
  final String name;
  final String force;
  final String level;
  final String? mechanic;
  final String equipment;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final List<String> instructions;
  final String category;
  final List<String> images;
  final String id;

  Exercise({
    required this.name,
    required this.force,
    required this.level,
    this.mechanic,
    required this.equipment,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.instructions,
    required this.category,
    required this.images,
    required this.id,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      name: json['name'] ?? '',
      force: json['force'] ?? '',
      level: json['level'] ?? '',
      mechanic: json['mechanic'],
      equipment: json['equipment'] ?? '',
      primaryMuscles: List<String>.from(json['primaryMuscles'] ?? []),
      secondaryMuscles: List<String>.from(json['secondaryMuscles'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      category: json['category'] ?? '',
      images: List<String>.from(json['images'] ?? []),
      id: json['id'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'force': force,
      'level': level,
      'mechanic': mechanic,
      'equipment': equipment,
      'primaryMuscles': primaryMuscles,
      'secondaryMuscles': secondaryMuscles,
      'instructions': instructions,
      'category': category,
      'images': images,
      'id': id,
    };
  }
}

class WorkoutExercise {
  final Exercise exercise;
  int sets;
  int reps;
  double? weight;
  int? duration;
  bool isCompleted;

  WorkoutExercise({
    required this.exercise,
    this.sets = 3,
    this.reps = 10,
    this.weight,
    this.duration,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'exercise': exercise.toJson(),
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'duration': duration,
      'isCompleted': isCompleted,
    };
  }

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) {
    return WorkoutExercise(
      exercise: Exercise.fromJson(json['exercise']),
      sets: json['sets'] ?? 3,
      reps: json['reps'] ?? 10,
      weight: (json['weight'] != null) ? json['weight'].toDouble() : null,
      duration: json['duration'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class Day {
  String name;
  List<WorkoutExercise> exercises;
  bool isCompleted;

  Day({
    required this.name,
    required this.exercises,
    this.isCompleted = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'exercises': exercises.map((e) => e.toJson()).toList(),
      'isCompleted': isCompleted,
    };
  }

  factory Day.fromJson(Map<String, dynamic> json) {
    return Day(
      name: json['name'],
      exercises: (json['exercises'] as List)
          .map((e) => WorkoutExercise.fromJson(e))
          .toList(),
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}

class Program {
  String name;
  List<Day> days;
  DateTime createdAt;
  String? description;

  Program({
    required this.name,
    required this.days,
    DateTime? createdAt,
    this.description,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'days': days.map((d) => d.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'description': description,
    };
  }

  factory Program.fromJson(Map<String, dynamic> json) {
    return Program(
      name: json['name'],
      days: (json['days'] as List)
          .map((d) => Day.fromJson(d))
          .toList(),
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      description: json['description'],
    );
  }
}

class ExerciseService {
  static List<Exercise>? _cachedExercises;

  static Future<List<Exercise>> loadExercisesFromJson() async {
    if (_cachedExercises != null) return _cachedExercises!;
    try {
      final String jsonString = await rootBundle.loadString('assets/exercises.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _cachedExercises = jsonList.map((json) => Exercise.fromJson(json)).toList();
      return _cachedExercises!;
    } catch (e) {
      return [];
    }
  }

  static List<Exercise> filterExercises(
      List<Exercise> exercises, {
        String? category,
        String? level,
        String? equipment,
        String? primaryMuscle,
      }) {
    return exercises.where((exercise) {
      if (category != null && exercise.category != category) return false;
      if (level != null && exercise.level != level) return false;
      if (equipment != null && exercise.equipment != equipment) return false;
      if (primaryMuscle != null && !exercise.primaryMuscles.contains(primaryMuscle)) return false;
      return true;
    }).toList();
  }
}
