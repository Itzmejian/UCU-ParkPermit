import 'package:flutter/material.dart';
import '../../widgets/tab_placeholder.dart';

class VehiclesTab extends StatelessWidget {
  const VehiclesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabPlaceholder(
      icon: Icons.directions_car_outlined,
      title: 'My Registered Vehicles',
      message: 'Your vehicles and their permits will show here.',
    );
  }
}