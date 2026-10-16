import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../models/notification_store.dart';
import '../../widgets/ucu_logo.dart';
import '../home/home_tab.dart';
import '../profile/profile_tab.dart';
import '../vehicles/vehicles_tab.dart';

/// Logged-in area: top bar with notification bell and 3 bottom tabs.
class MainShell extends StatefulWidget {
  const MainShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: false,
        titleSpacing: 16,
        title: const Row(
          children: [
            UcuLogo(size: 34),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'UCU ParkPermit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
                Text(
                  'OFFICIAL PORTAL',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: AppColors.goldDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          AnimatedBuilder(
            animation: NotificationStore.instance,
            builder: (context, child) {
              final n = NotificationStore.instance.unreadCount;
              return IconButton(
                tooltip: 'Notifications',
                icon: Badge(
                  isLabelVisible: n > 0,
                  label: Text(n > 9 ? '9+' : '$n'),
                  backgroundColor: AppColors.error,
                  child: const Icon(Icons.notifications_none_rounded),
                ),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.notifications),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: IndexedStack(
        index: _index,
        children: const [HomeTab(), VehiclesTab(), ProfileTab()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        backgroundColor: Colors.white,
        indicatorColor: AppColors.navy,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: Colors.white),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car, color: Colors.white),
            label: 'Vehicles',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Colors.white),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}