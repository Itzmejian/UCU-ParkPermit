import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/application_store.dart';
import 'data_service.dart';

/// Refreshes the data and shows a short report of what the app can read.
/// Used by the refresh button while the server connection is being tested.
Future<void> refreshWithFeedback(BuildContext context) async {
  final c = Supabase.instance.client;
  final uid = c.auth.currentUser?.id;
  final lines = <String>[];

  if (uid == null) {
    lines.add('Not logged in.');
  } else {
    Future<void> check(String label, Future<dynamic> query) async {
      try {
        final r = await query;
        final n = r is List ? r.length : (r == null ? 0 : 1);
        lines.add('$label: $n row(s)');
      } catch (e) {
        lines.add('$label: ERROR $e');
      }
    }

    await check('profiles', c.from('profiles').select().eq('id', uid));
    await check('vehicles', c.from('vehicles').select().eq('owner_id', uid));
    await check('applications', c.from('applications').select().eq('applicant_id', uid));
    await check(
      'permits (with zone)',
      c.from('permits').select('*, parking_zones(code, name)').eq('owner_id', uid),
    );
    await check('documents', c.from('documents').select().eq('owner_id', uid));
    await check('appeals', c.from('appeals').select().eq('applicant_id', uid));
    await check('sticker_replacements', c.from('sticker_replacements').select().eq('owner_id', uid));
    await check('draft', c.from('application_drafts').select().eq('user_id', uid).maybeSingle());
  }

  await DataService.refresh();
  final store = ApplicationStore.instance;
  lines.add('');
  lines.add('App status now: ${store.status.name}');
  lines.add('Vehicles shown in the app: ${store.vehicles.length}');

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Refresh report'),
      content: SingleChildScrollView(child: SelectableText(lines.join('\n'))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
      ],
    ),
  );
}