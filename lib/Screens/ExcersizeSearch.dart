import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymflow/Models/Excersize.dart';
import 'ExcersizeDetail.dart';

class ExerciseSearch extends StatefulWidget {
  @override
  State<ExerciseSearch> createState() => _ExerciseSearchState();
}

class _ExerciseSearchState extends State<ExerciseSearch>
    with TickerProviderStateMixin {
  List<Exercise> allExercises = [];
  List<Exercise> filteredExercises = [];
  String searchQuery = '';
  String selectedCategory = 'All';
  String selectedLevel = 'All';
  String selectedEquipment = 'All';
  bool isLoading = true;
  bool showFilters = false;

  late TextEditingController _searchController;
  late AnimationController _filterAnimationController;
  late AnimationController _listAnimationController;
  late Animation<double> _filterAnimation;
  late Animation<double> _listAnimation;

  final FocusNode _searchFocusNode = FocusNode();

  // Filter options
  List<String> categories = ['All'];
  List<String> levels = ['All'];
  List<String> equipmentTypes = ['All'];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _filterAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _filterAnimation = CurvedAnimation(
      parent: _filterAnimationController,
      curve: Curves.easeInOut,
    );

    _listAnimation = CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeOutQuart,
    );

    loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _filterAnimationController.dispose();
    _listAnimationController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> loadExercises() async {
    try {
      final exercises = await ExerciseService.loadExercisesFromJson();

      final uniqueCategories = exercises.map((e) => e.category).toSet().toList();
      final uniqueLevels = exercises.map((e) => e.level).toSet().toList();
      final uniqueEquipment = exercises.map((e) => e.equipment).toSet().toList();

      setState(() {
        allExercises = exercises;
        filteredExercises = exercises;
        categories = ['All', ...uniqueCategories]..sort();
        levels = ['All', ...uniqueLevels]..sort();
        equipmentTypes = ['All', ...uniqueEquipment]..sort();
        isLoading = false;
      });

      _listAnimationController.forward();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorSnackBar('Failed to load exercises');
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

  void updateSearch(String query) {
    setState(() {
      searchQuery = query;
      _applyFilters();
    });
  }

  void _applyFilters() {
    List<Exercise> filtered = allExercises.where((exercise) {
      final matchesSearch = exercise.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          exercise.primaryMuscles.any((muscle) => muscle.toLowerCase().contains(searchQuery.toLowerCase()));

      final matchesCategory = selectedCategory == 'All' || exercise.category == selectedCategory;
      final matchesLevel = selectedLevel == 'All' || exercise.level == selectedLevel;
      final matchesEquipment = selectedEquipment == 'All' || exercise.equipment == selectedEquipment;

      return matchesSearch && matchesCategory && matchesLevel && matchesEquipment;
    }).toList();

    setState(() {
      filteredExercises = filtered;
    });
  }

  void clearSearch() {
    setState(() {
      searchQuery = '';
      selectedCategory = 'All';
      selectedLevel = 'All';
      selectedEquipment = 'All';
      filteredExercises = allExercises;
    });
    _searchController.clear();
    _searchFocusNode.unfocus();
  }

  void toggleFilters() {
    setState(() {
      showFilters = !showFilters;
    });

    if (showFilters) {
      _filterAnimationController.forward();
    } else {
      _filterAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E1C26),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildSearchSection()),
          if (showFilters) SliverToBoxAdapter(child: _buildFiltersSection()),
          SliverToBoxAdapter(child: _buildResultsHeader()),
          _buildExercisesList(),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120.h,
      floating: false,
      pinned: true,
      backgroundColor: Colors.teal.shade700,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Exercise Search',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                offset: const Offset(0, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.3),
              ),
            ],
          ),
        ),
        centerTitle: true,
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.teal.shade600,
                Colors.teal.shade700,
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -50,
                top: -50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
              Positioned(
                left: -30,
                bottom: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      elevation: 8,
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          _buildSearchBar(),
          SizedBox(height: 16.h),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.r),
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 12.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: TextStyle(color: Colors.white, fontSize: 16.sp),
        decoration: InputDecoration(
          hintText: 'Search exercises or muscles...',
          hintStyle: TextStyle(color: Colors.white70, fontSize: 16.sp),
          prefixIcon: Icon(Icons.search, color: Colors.white, size: 24.sp),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, color: Colors.white, size: 24.sp),
            onPressed: () {
              _searchController.clear();
              updateSearch('');
              HapticFeedback.lightImpact();
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        ),
        onChanged: updateSearch,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => _searchFocusNode.unfocus(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            icon: Icons.tune,
            label: 'Filters',
            onPressed: () {
              toggleFilters();
              HapticFeedback.lightImpact();
            },
            isActive: showFilters,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildActionButton(
            icon: Icons.clear_all,
            label: 'Clear All',
            onPressed: () {
              clearSearch();
              HapticFeedback.lightImpact();
            },
            isActive: false,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isActive,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isActive ? Colors.teal.shade400 : Colors.teal.shade600.withOpacity(0.5),
          width: 1.5,
        ),
        color: isActive ? Colors.teal.shade600.withOpacity(0.2) : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.teal.shade300 : Colors.teal.shade400,
                  size: 20.sp,
                ),
                SizedBox(width: 8.w),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? Colors.teal.shade300 : Colors.teal.shade400,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersSection() {
    return SizeTransition(
      sizeFactor: _filterAnimation,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: const Color(0xFF172A3A),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: Colors.teal.shade600.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filters',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade300,
              ),
            ),
            SizedBox(height: 16.h),
            _buildFilterDropdown('Category', selectedCategory, categories, (value) {
              setState(() {
                selectedCategory = value!;
                _applyFilters();
              });
            }),
            SizedBox(height: 12.h),
            _buildFilterDropdown('Level', selectedLevel, levels, (value) {
              setState(() {
                selectedLevel = value!;
                _applyFilters();
              });
            }),
            SizedBox(height: 12.h),
            _buildFilterDropdown('Equipment', selectedEquipment, equipmentTypes, (value) {
              setState(() {
                selectedEquipment = value!;
                _applyFilters();
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
      String label,
      String value,
      List<String> options,
      ValueChanged<String?> onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: 6.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1C26),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Colors.teal.shade600.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              onChanged: onChanged,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
              dropdownColor: const Color(0xFF172A3A),
              icon: Icon(Icons.keyboard_arrow_down, color: Colors.teal.shade400),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${filteredExercises.length} Exercise${filteredExercises.length != 1 ? 's' : ''} Found',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade300,
            ),
          ),
          if (filteredExercises.isNotEmpty)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.teal.shade600.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.teal.shade600.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                'Tap to view details',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.teal.shade300,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildExercisesList() {
    if (isLoading) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade400),
              ),
              SizedBox(height: 16.h),
              Text(
                'Loading exercises...',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (filteredExercises.isEmpty) {
      return SliverFillRemaining(
        child: _buildEmptyState(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          return FadeTransition(
            opacity: _listAnimation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.3),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _listAnimationController,
                curve: Interval(
                  (index * 0.1).clamp(0.0, 1.0),
                  ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                  curve: Curves.easeOutQuart,
                ),
              )),
              child: _buildExerciseCard(filteredExercises[index]),
            ),
          );
        },
        childCount: filteredExercises.length,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100.w,
            height: 100.h,
            decoration: BoxDecoration(
              color: Colors.teal.shade600.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.search_off,
              size: 48.sp,
              color: Colors.teal.shade400,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'No exercises found',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: clearSearch,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.r),
              ),
            ),
            child: Text(
              'Clear Filters',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(Exercise exercise) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade600,
            Colors.teal.shade700,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    ExerciseDetailScreen(exercise: exercise),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                _buildExerciseIcon(),
                SizedBox(width: 16.w),
                Expanded(child: _buildExerciseInfo(exercise)),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white70,
                  size: 16.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseIcon() {
    return Container(
      width: 50.w,
      height: 50.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        Icons.fitness_center,
        color: Colors.white,
        size: 24.sp,
      ),
    );
  }

  Widget _buildExerciseInfo(Exercise exercise) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exercise.name,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),
        _buildInfoRow(exercise),
        SizedBox(height: 6.h),
        _buildMuscleChips(exercise.primaryMuscles),
      ],
    );
  }

  Widget _buildInfoRow(Exercise exercise) {
    return Row(
      children: [
        _buildInfoChip(exercise.level, Colors.orange.shade300),
        SizedBox(width: 8.w),
        _buildInfoChip(exercise.equipment, Colors.blue.shade300),
      ],
    );
  }

  Widget _buildInfoChip(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color.withOpacity(0.5), width: 1),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildMuscleChips(List<String> muscles) {
    return Wrap(
      spacing: 4.w,
      runSpacing: 4.h,
      children: muscles.take(3).map((muscle) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            muscle,
            style: TextStyle(
              fontSize: 9.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}