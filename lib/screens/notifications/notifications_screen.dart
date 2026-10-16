import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/date_format.dart';
import '../../models/notification_store.dart';
import '../../widgets/icon_badge.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationStore _store = NotificationStore.instance;
  int _filter = 0; // 0 = All, 1 = Permits, 2 = Account

  IconData _icon(NotifKind k) {
    return switch (k) {
      NotifKind.permit => Icons.description_outlined,
      NotifKind.sticker => Icons.inventory_2_outlined,
      NotifKind.expiry => Icons.event_busy_outlined,
      NotifKind.account => Icons.person_outline,
    };
  }

  Widget _chip(String label, int count, int index) {
    final selected = _filter == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: selected ? AppColors.navy : AppColors.inputFill,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? AppColors.navy : AppColors.border),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () => setState(() => _filter = index),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : AppColors.textDark,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: selected ? Colors.white : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppColors.textHint,
        ),
      ),
    );
  }

  Widget _card(NotificationItem n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: n.read ? Colors.white : AppColors.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: n.read ? AppColors.border : AppColors.gold),
        ),
        child: InkWell(
          onTap: () {
            _store.markRead(n.id);
            if (n.route != null) Navigator.pushNamed(context, n.route!);
          },
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 5,
                  color: n.read ? Colors.transparent : AppColors.gold,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: n.read ? AppColors.inputFill : AppColors.goldLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _icon(n.kind),
                            size: 21,
                            color: n.read ? AppColors.navy : AppColors.goldDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: n.read ? FontWeight.w700 : FontWeight.w800,
                                        color: AppColors.textDark,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    formatRelative(n.createdAt),
                                    style: const TextStyle(fontSize: 11.5, color: AppColors.textHint),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                n.body,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                  color: AppColors.textMuted,
                                ),
                              ),
                              if (n.route != null)
                                const Padding(
                                  padding: EdgeInsets.only(top: 6),
                                  child: Text(
                                    'View',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        children: [
          IconBadge(icon: Icons.notifications_off_outlined),
          SizedBox(height: 16),
          Text(
            'No notifications here',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.navy,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Updates about your application, sticker and permit will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _store,
      builder: (context, child) {
        final all = _store.items;
        final permits = all.where((n) => n.kind.isPermit).toList();
        final account = all.where((n) => !n.kind.isPermit).toList();
        final shown = _filter == 0 ? all : (_filter == 1 ? permits : account);
        final fresh = shown.where((n) => !n.read).toList();
        final earlier = shown.where((n) => n.read).toList();
        final unread = _store.unreadCount;

        return Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gold),
                    ),
                    child: Text(
                      '$unread New',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.goldDark,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Mark all as read',
                icon: const Icon(Icons.done_all),
                onPressed: unread == 0 ? null : _store.markAllRead,
              ),
            ],
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _chip('All', all.length, 0),
                      _chip('Permits', permits.length, 1),
                      _chip('Account', account.length, 2),
                    ],
                  ),
                ),
                if (shown.isEmpty) _empty(),
                if (fresh.isNotEmpty) ...[
                  _sectionTitle('NEW'),
                  for (final n in fresh) _card(n),
                ],
                if (earlier.isNotEmpty) ...[
                  _sectionTitle('EARLIER'),
                  for (final n in earlier) _card(n),
                ],
                if (shown.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'Notifications appear inside the app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.textHint),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}