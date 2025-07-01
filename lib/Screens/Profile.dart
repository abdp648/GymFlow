import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymflow/Info/Info.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProfileField {
  final String key;
  final String label;
  final IconData icon;
  final String Function() getValue;
  final String Function() getDisplayValue;
  final ProfileFieldType type;
  final List<String>? options;

  const ProfileField({
    required this.key,
    required this.label,
    required this.icon,
    required this.getValue,
    required this.getDisplayValue,
    required this.type,
    this.options,
  });
}

enum ProfileFieldType { text, integer, decimal, selection }

enum BMICategory {
  underweight('Underweight', Colors.blue),
  normal('Normal', Colors.green),
  overweight('Overweight', Colors.orange),
  obese('Obese', Colors.red);

  const BMICategory(this.label, this.color);
  final String label;
  final Color color;

  static BMICategory fromBMI(double bmi) {
    if (bmi < 18.5) return underweight;
    if (bmi < 25.0) return normal;
    if (bmi < 30.0) return overweight;
    return obese;
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // User data
  String _name = '';
  String _email = '';
  int _age = 0;
  double _height = 0.0;
  double _weight = 0.0;
  String _gender = '';
  String _activityLevel = '';
  String _goal = '';
  String _photoPath = '';
  double? _bmi;
  BMICategory? _bmiCategory;

  // Loading and error states
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;

  // Services
  final ImagePicker _imagePicker = ImagePicker();
  SharedPreferences? _prefs;

  late final List<ProfileField> _profileFields;

  @override
  void initState() {
    super.initState();
    _initializeProfileFields();
    _initializeData();
  }

  void _initializeProfileFields() {
    _profileFields = [
      ProfileField(
        key: 'Age',
        label: 'Age',
        icon: Icons.cake_outlined,
        getValue: () => _age.toString(),
        getDisplayValue: () => _age > 0 ? '$_age years' : 'Not set',
        type: ProfileFieldType.integer,
      ),
      ProfileField(
        key: 'Height',
        label: 'Height',
        icon: Icons.height,
        getValue: () => _height.toString(),
        getDisplayValue: () => _height > 0 ? '${_height.toStringAsFixed(1)} cm' : 'Not set',
        type: ProfileFieldType.decimal,
      ),
      ProfileField(
        key: 'Weight',
        label: 'Weight',
        icon: Icons.monitor_weight_outlined,
        getValue: () => _weight.toString(),
        getDisplayValue: () => _weight > 0 ? '${_weight.toStringAsFixed(1)} kg' : 'Not set',
        type: ProfileFieldType.decimal,
      ),
      ProfileField(
        key: 'Gender',
        label: 'Gender',
        icon: Icons.wc_outlined,
        getValue: () => _gender,
        getDisplayValue: () => _gender.isNotEmpty ? _gender.capitalize() : 'Not set',
        type: ProfileFieldType.selection,
        options: ['Male', 'Female', 'Other'],
      ),
      ProfileField(
        key: 'ActivityLevel',
        label: 'Activity Level',
        icon: Icons.fitness_center_outlined,
        getValue: () => _activityLevel,
        getDisplayValue: () => _activityLevel.isNotEmpty ? _activityLevel : 'Not set',
        type: ProfileFieldType.selection,
        options: ['Low', 'Moderate', 'High', 'Very High'],
      ),
      ProfileField(
        key: 'Goal',
        label: 'Goal',
        icon: Icons.flag_outlined,
        getValue: () => _goal,
        getDisplayValue: () => _goal.isNotEmpty ? _goal : 'Not set',
        type: ProfileFieldType.selection,
        options: ['Maintain Weight', 'Lose Weight', 'Gain Weight', 'Build Muscle'],
      ),
    ];
  }

  Future<void> _initializeData() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadUserData();
    } catch (e) {
      _setError('Failed to load profile data: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserData() async {
    if (_prefs == null) return;

    setState(() {
      _name = _prefs!.getString('Name') ?? '';
      _email = _prefs!.getString('Email') ?? '';
      _age = _prefs!.getInt('Age') ?? 0;
      _height = _prefs!.getDouble('Height') ?? 0.0;
      _weight = _prefs!.getDouble('Weight') ?? 0.0;
      _gender = _prefs!.getString('Gender') ?? '';
      _activityLevel = _prefs!.getString('ActivityLevel') ?? '';
      _goal = _prefs!.getString('Goal') ?? '';
      _photoPath = _prefs!.getString('Photo') ?? '';
      _errorMessage = null;
    });

    _calculateBMI();
  }

  void _calculateBMI() {
    if (_height > 0 && _weight > 0) {
      final heightInMeters = _height / 100;
      final calculatedBmi = _weight / (heightInMeters * heightInMeters);
      setState(() {
        _bmi = calculatedBmi;
        _bmiCategory = BMICategory.fromBMI(calculatedBmi);
      });
    } else {
      setState(() {
        _bmi = null;
        _bmiCategory = null;
      });
    }
  }

  void _setError(String message) {
    if (mounted) {
      setState(() => _errorMessage = message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image == null) return;

      setState(() => _isUpdating = true);

      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = '${directory.path}/$fileName';

      await File(image.path).copy(filePath);

      // Delete old profile image if exists
      if (_photoPath.isNotEmpty && File(_photoPath).existsSync()) {
        await File(_photoPath).delete();
      }

      setState(() => _photoPath = filePath);
      await _prefs?.setString('Photo', _photoPath);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile photo updated successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _setError('Failed to update profile photo: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await _showConfirmationDialog(
      'Logout',
      'Are you sure you want to logout?',
    );

    if (shouldLogout && mounted) {
      try {
        await _prefs?.setBool('LoggedIn', false);
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => Info()),
          );
        }
      } catch (e) {
        _setError('Failed to logout: ${e.toString()}');
      }
    }
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2A32),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(content, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _editField(ProfileField field) async {
    if (field.type == ProfileFieldType.selection) {
      await _showSelectionDialog(field);
    } else {
      await _showTextInputDialog(field);
    }
  }

  Future<void> _showSelectionDialog(ProfileField field) async {
    if (field.options == null) return;

    String? selectedValue = await showDialog<String>(
      context: context,
      builder: (context) => _SelectionDialog(
        title: 'Select ${field.label}',
        options: field.options!,
        currentValue: field.getValue(),
      ),
    );

    if (selectedValue != null) {
      await _saveFieldValue(field.key, selectedValue);
    }
  }

  Future<void> _showTextInputDialog(ProfileField field) async {
    final controller = TextEditingController(text: field.getValue());

    final result = await showDialog<String>(
      context: context,
      builder: (context) => _TextInputDialog(
        title: 'Edit ${field.label}',
        controller: controller,
        fieldType: field.type,
        hintText: 'Enter ${field.label.toLowerCase()}',
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _saveFieldValue(field.key, result);
    }
  }

  Future<void> _saveFieldValue(String key, String value) async {
    if (_prefs == null) return;

    setState(() => _isUpdating = true);

    try {
      switch (key) {
        case 'Age':
          final intValue = int.tryParse(value);
          if (intValue != null && intValue > 0 && intValue < 150) {
            await _prefs!.setInt(key, intValue);
          } else {
            throw const FormatException('Invalid age value');
          }
          break;
        case 'Height':
          final doubleValue = double.tryParse(value);
          if (doubleValue != null && doubleValue > 0 && doubleValue < 300) {
            await _prefs!.setDouble(key, doubleValue);
          } else {
            throw const FormatException('Invalid height value');
          }
          break;
        case 'Weight':
          final doubleValue = double.tryParse(value);
          if (doubleValue != null && doubleValue > 0 && doubleValue < 1000) {
            await _prefs!.setDouble(key, doubleValue);
          } else {
            throw const FormatException('Invalid weight value');
          }
          break;
        case 'Name':
          if (value.trim().isNotEmpty) {
            await _prefs!.setString(key, value.trim());
          } else {
            throw const FormatException('Name cannot be empty');
          }
          break;
        default:
          await _prefs!.setString(key, value);
      }

      await _loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${key == 'Name' ? 'Name' : _getFieldLabel(key)} updated successfully'),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _setError('Failed to update ${_getFieldLabel(key)}: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  String _getFieldLabel(String key) {
    return _profileFields.firstWhere((field) => field.key == key).label;
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(360, 740),
      builder: (context, child) => Scaffold(
        backgroundColor: const Color(0xFF0D1117),
        appBar: _buildAppBar(),
        body: _isLoading ? _buildLoadingIndicator() : _buildBody(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text('Profile', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600)),
      backgroundColor: Colors.teal.shade700,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      actions: [
        IconButton(
          onPressed: _isUpdating ? null : _logout,
          icon: Icon(Icons.logout, size: 22.sp),
          tooltip: 'Logout',
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
      ),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        _buildProfileHeader(),
        Expanded(
          child: _buildProfileFields(),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.teal.shade700,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24.r),
          bottomRight: Radius.circular(24.r),
        ),
      ),
      child: Row(
        children: [
          _buildProfileImage(),
          SizedBox(width: 20.w),
          Expanded(child: _buildProfileInfo()),
        ],
      ),
    );
  }

  Widget _buildProfileImage() {
    return GestureDetector(
      onTap: _isUpdating ? null : _pickImage,
      child: Stack(
        children: [
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: _photoPath.isNotEmpty && File(_photoPath).existsSync()
                  ? Image.file(
                File(_photoPath),
                width: 100.w,
                height: 100.w,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(),
              )
                  : _buildDefaultAvatar(),
            ),
          ),
          if (_isUpdating)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black54,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                ),
              ),
            ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: Colors.teal.shade800,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 16.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.teal.shade400,
      child: Icon(
        Icons.person,
        size: 50.sp,
        color: Colors.white,
      ),
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: AutoSizeText(
                _name.isNotEmpty ? _name : 'Your Name',
                style: TextStyle(
                  fontSize: 22.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                minFontSize: 12,
              ),
            ),
            IconButton(
              onPressed: () => _showTextInputDialog(
                ProfileField(
                  key: 'Name',
                  label: 'Name',
                  icon: Icons.person,
                  getValue: () => _name,
                  getDisplayValue: () => _name,
                  type: ProfileFieldType.text,
                ),
              ),
              icon: Icon(Icons.edit_outlined, color: Colors.white, size: 20.sp),
              tooltip: 'Edit name',
            ),
          ],
        ),
        SizedBox(height: 4.h),
        Text(
          _email.isNotEmpty ? _email : 'your.email@example.com',
          style: TextStyle(
            fontSize: 14.sp,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileFields() {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: _profileFields.length + (_bmi != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < _profileFields.length) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildProfileFieldCard(_profileFields[index]),
          );
        } else {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: _buildBMICard(),
          );
        }
      },
    );
  }

  Widget _buildProfileFieldCard(ProfileField field) {
    return Card(
      color: const Color(0xFF1E2A32),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: InkWell(
        onTap: _isUpdating ? null : () => _editField(field),
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: Colors.teal.shade700.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(field.icon, color: Colors.teal.shade300, size: 24.sp),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      field.label,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      field.getDisplayValue(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white30,
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBMICard() {
    if (_bmi == null || _bmiCategory == null) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Card(
          color: const Color(0xFF1E2A32),
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: Container(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: _bmiCategory!.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(
                    Icons.monitor_heart_outlined,
                    color: _bmiCategory!.color,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Body Mass Index',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Text(
                            _bmi!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                            decoration: BoxDecoration(
                              color: _bmiCategory!.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text(
                              _bmiCategory!.label,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: _bmiCategory!.color,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  color: Colors.white30,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h,)
      ],
    );
  }
}

// Selection Dialog Widget
class _SelectionDialog extends StatefulWidget {
  final String title;
  final List<String> options;
  final String currentValue;

  const _SelectionDialog({
    required this.title,
    required this.options,
    required this.currentValue,
  });

  @override
  State<_SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<_SelectionDialog> {
  late String _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.currentValue;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2A32),
      title: Text(widget.title, style: const TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: widget.options.map((option) {
            final isSelected = option.toLowerCase() == _selectedValue.toLowerCase();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: InkWell(
                onTap: () => setState(() => _selectedValue = option),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.teal.shade700 : const Color(0xFF2A3B47),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.teal : Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    option,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(_selectedValue),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

// Text Input Dialog Widget
class _TextInputDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final ProfileFieldType fieldType;
  final String hintText;

  const _TextInputDialog({
    required this.title,
    required this.controller,
    required this.fieldType,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E2A32),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      content: TextField(
        controller: controller,
        keyboardType: _getKeyboardType(),
        inputFormatters: _getInputFormatters(),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.white54),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.teal),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.teal, width: 2),
          ),
        ),
        style: const TextStyle(color: Colors.white),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.teal.shade700),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  TextInputType _getKeyboardType() {
    switch (fieldType) {
      case ProfileFieldType.integer:
        return TextInputType.number;
      case ProfileFieldType.decimal:
        return const TextInputType.numberWithOptions(decimal: true);
      default:
        return TextInputType.text;
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    switch (fieldType) {
      case ProfileFieldType.integer:
        return [FilteringTextInputFormatter.digitsOnly];
      case ProfileFieldType.decimal:
        return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];
      default:
        return [];
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}