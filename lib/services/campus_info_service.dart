import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_config.dart';

/// Same icon keys as the admin website.
const Map<String, IconData> kRuleIcons = {
  'car': Icons.directions_car_outlined,
  'sticker': Icons.confirmation_number_outlined,
  'no_transfer': Icons.do_not_disturb_on_outlined,
  'calendar': Icons.event_available_outlined,
  'parking': Icons.local_parking,
  'edit': Icons.edit_note_outlined,
  'gavel': Icons.gavel_outlined,
  'renew': Icons.autorenew_rounded,
  'lock': Icons.lock_outline,
  'shield': Icons.shield_outlined,
  'time': Icons.schedule_outlined,
  'warning': Icons.warning_amber_outlined,
  'info': Icons.info_outline,
};

class CampusRule {
  const CampusRule(this.icon, this.title, this.body);

  final IconData icon;
  final String title;
  final String body;
}

class CampusZone {
  const CampusZone(this.code, this.name, this.vehicleType, this.description);

  final String code;
  final String name;
  final String vehicleType;
  final String description;
}

/// Parking rules and zones set by the Security Office in the admin website.
/// Returns null when they cannot be loaded, so the screen shows its built-in text.
class CampusInfoService {
  CampusInfoService._();

  static Future<List<CampusRule>?> rules() async {
    if (!kSupabaseReady) return null;
    try {
      final rows = await Supabase.instance.client
          .from('policy_rules')
          .select('title, body, icon')
          .eq('active', true)
          .order('sort_order');
      final list = [
        for (final r in List<Map<String, dynamic>>.from(rows))
          CampusRule(
            kRuleIcons[(r['icon'] ?? '').toString()] ?? Icons.info_outline,
            (r['title'] ?? '').toString(),
            (r['body'] ?? '').toString(),
          ),
      ];
      return list.isEmpty ? null : list;
    } catch (_) {
      return null;
    }
  }

  static Future<List<CampusZone>?> zones() async {
    if (!kSupabaseReady) return null;
    try {
      final rows = await Supabase.instance.client
          .from('parking_zones')
          .select('code, name, vehicle_type, description')
          .eq('active', true)
          .order('sort_order')
          .order('code');
      final list = [
        for (final r in List<Map<String, dynamic>>.from(rows))
          CampusZone(
            (r['code'] ?? '').toString(),
            (r['name'] ?? '').toString(),
            (r['vehicle_type'] ?? '').toString(),
            (r['description'] ?? '').toString(),
          ),
      ];
      return list.isEmpty ? null : list;
    } catch (_) {
      return null;
    }
  }
}