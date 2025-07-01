import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymflow/Models/Excersize.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({required this.exercise, Key? key}) : super(key: key);

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1C2E),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Padding(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageCarousel(),
                    SizedBox(height: 24.h),
                    _buildQuickStatsRow(),
                    SizedBox(height: 24.h),
                    _buildInfoSection(),
                    SizedBox(height: 24.h),
                    _buildMuscleGroupsSection(),
                    SizedBox(height: 24.h),
                    _buildCategorySection(),
                    SizedBox(height: 32.h),
                    _buildInstructionsSection(),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ),
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
          widget.exercise.name,
          style: TextStyle(
            fontSize: 18.sp,
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
        ),
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
      ),
      elevation: 8,
    );
  }

  Widget _buildImageCarousel() {
    if (widget.exercise.images.isEmpty) {
      return _buildPlaceholderImage();
    }

    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF172A3A),
            const Color(0xFF1E3A4A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12.r,
            spreadRadius: 2.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: PageView.builder(
        itemCount: widget.exercise.images.length,
        onPageChanged: (index) {
          setState(() {
            _currentImageIndex = index;
          });
        },
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: Stack(
              children: [
                Image.network(
                  'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/${widget.exercise.images[index]}',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildErrorImage();
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildLoadingImage(loadingProgress);
                  },
                ),
                Positioned(
                  bottom: 16.h,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.exercise.images.length,
                          (dotIndex) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        width: 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: dotIndex == _currentImageIndex
                              ? Colors.teal.shade300
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: const Color(0xFF172A3A),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fitness_center,
              size: 48.sp,
              color: Colors.teal.shade300,
            ),
            SizedBox(height: 8.h),
            Text(
              'No Image Available',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorImage() {
    return Container(
      color: const Color(0xFF172A3A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48.sp,
              color: Colors.red.shade300,
            ),
            SizedBox(height: 8.h),
            Text(
              'Failed to load image',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingImage(ImageChunkEvent loadingProgress) {
    return Container(
      color: const Color(0xFF172A3A),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
                  : null,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.teal.shade300),
            ),
            SizedBox(height: 16.h),
            Text(
              'Loading image...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatChip(Icons.flash_on, widget.exercise.level)),
        SizedBox(width: 12.w),
        Expanded(child: _buildStatChip(Icons.build, widget.exercise.equipment)),
        SizedBox(width: 12.w),
        Expanded(child: _buildStatChip(Icons.category, widget.exercise.category)),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 8.r,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20.sp),
          SizedBox(height: 4.h),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return _buildCard(
      child: Column(
        children: [
          _buildInfoRow(
            Icons.flash_on,
            'Force',
            widget.exercise.force,
            Icons.bar_chart,
            'Level',
            widget.exercise.level,
          ),
          SizedBox(height: 20.h),
          _buildInfoRow(
            Icons.accessibility,
            'Mechanic',
            widget.exercise.mechanic ?? 'N/A',
            Icons.build,
            'Equipment',
            widget.exercise.equipment,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
      IconData icon1,
      String label1,
      String value1,
      IconData icon2,
      String label2,
      String value2,
      ) {
    return Row(
      children: [
        Expanded(child: _buildInfoTile(icon1, label1, value1)),
        SizedBox(width: 20.w),
        Expanded(child: _buildInfoTile(icon2, label2, value2)),
      ],
    );
  }

  Widget _buildInfoTile(IconData icon, String label, String value) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1C2E),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.teal.shade700.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18.sp, color: Colors.teal.shade300),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleGroupsSection() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Muscle Groups',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade300,
            ),
          ),
          SizedBox(height: 16.h),
          _buildMuscleGroupRow('Primary', widget.exercise.primaryMuscles, true),
          if (widget.exercise.secondaryMuscles.isNotEmpty) ...[
            SizedBox(height: 16.h),
            _buildMuscleGroupRow('Secondary', widget.exercise.secondaryMuscles, false),
          ],
        ],
      ),
    );
  }

  Widget _buildMuscleGroupRow(String label, List<String> muscles, bool isPrimary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: isPrimary ? Colors.teal.shade600 : Colors.teal.shade700.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: muscles.map((muscle) => _buildMuscleChip(muscle)).toList(),
        ),
      ],
    );
  }

  Widget _buildMuscleChip(String muscle) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1C2E),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.teal.shade600.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        muscle,
        style: TextStyle(
          color: Colors.white,
          fontSize: 13.sp,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildCategorySection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.teal.shade600, Colors.teal.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 12.r,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Icons.category, color: Colors.white, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  widget.exercise.category,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade300,
          ),
        ),
        SizedBox(height: 16.h),
        _buildCard(
          child: Column(
            children: widget.exercise.instructions
                .asMap()
                .entries
                .map((entry) => _buildInstructionItem(entry.key + 1, entry.value))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionItem(int stepNumber, String instruction) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28.w,
            height: 28.h,
            decoration: BoxDecoration(
              color: Colors.teal.shade600,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$stepNumber',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 15.sp,
                color: Colors.white,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF172A3A),
            const Color(0xFF1E3A4A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8.r,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.teal.shade700.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: child,
    );
  }
}