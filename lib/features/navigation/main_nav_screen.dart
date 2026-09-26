import 'package:flutter/material.dart';
import '../home/home_screen.dart';
import '../reports/reports_screen.dart';
import '../profile/profile_screen.dart';
import '../training/training_hub_page.dart';
import '../gait_analysis/walking_dashboard_screen.dart';
import '../../core/ml_widgets.dart';

class MainNavScreen extends StatefulWidget {
  const MainNavScreen({super.key});

  @override
  State<MainNavScreen> createState() => _MainNavScreenState();
}

class _MainNavScreenState extends State<MainNavScreen> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),
    const TrainingHubScreen(),
    const WalkingDashboardScreen(),
    const ReportsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      // 숨은 탭은 TickerMode 를 꺼 둔다. IndexedStack 은 모든 탭을 한꺼번에 만들기 때문에,
      // 그대로 두면 탭의 첫 진입 모션(StaggeredColumn)이 앱 시작 때 보이지 않는 곳에서
      // 재생되고 끝나 버린다. 꺼 두면 처음 그 탭을 여는 순간 한 번 재생된다.
      // 보이지 않는 탭의 애니메이션 프레임도 아낀다.
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          for (var i = 0; i < _widgetOptions.length; i++)
            TickerMode(enabled: i == _selectedIndex, child: _widgetOptions[i]),
        ],
      ),
      bottomNavigationBar: FloatingPillNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
