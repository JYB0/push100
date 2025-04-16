import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:push100/main.dart';
// import 'package:push100/screens/community_category_screen.dart';
import 'package:push100/screens/home_screen.dart';
import 'package:push100/screens/workout_history_screen.dart';
import 'package:push100/screens/setting_screen.dart';

class BottomNavigation extends StatefulWidget {
  final int initialWeek;
  final String initialLevel;
  final bool isTestMode;

  const BottomNavigation({
    super.key,
    required this.initialWeek,
    required this.initialLevel,
    this.isTestMode = false,
  });

  @override
  BottomNavigationState createState() => BottomNavigationState();
}

class BottomNavigationState extends State<BottomNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _screens.addAll([
      HomeScreen(
        week: widget.initialWeek,
        level: widget.initialLevel,
        isTestMode: widget.isTestMode,
      ),
      const WorkoutHistoryScreen(),
      // const CommunityCategoryScreen(),
      const SettingScreen(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;
    double iconSize = isTablet ? 28 : 24;

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (child, animation) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: const AlwaysStoppedAnimation(0),
            transitionType: SharedAxisTransitionType.horizontal,
            child: child,
          );
        },
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(
            () {
              _currentIndex = index;
            },
          );
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: iconSize),
            label: "홈",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, size: iconSize),
            label: "운동 기록",
          ),
          // BottomNavigationBarItem(
          //   icon: Icon(Icons.groups, size: iconSize),
          //   label: "커뮤니티", // 🔥 추가
          // ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: iconSize),
            label: "설정",
          ),
        ],
        selectedItemColor: AppColors.redPrimary,
        unselectedItemColor: Colors.grey,
        selectedFontSize: isTablet ? 14 : 12,
        unselectedFontSize: isTablet ? 12 : 10,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.greyPrimary,
      ),
    );
  }
}
