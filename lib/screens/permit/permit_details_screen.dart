import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_routes.dart';
import '../../core/date_format.dart';
import '../../models/application_store.dart';
import '../../models/mock_application.dart';
import '../../models/permit_status.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_card.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/tone_colors.dart';

class _StickerInfo {
  const _StickerInfo(this.icon, this.title, this.message, this.tone);

  final IconData icon;
  final String title;
  final String message;
  final BadgeTone tone;
}

class PermitDetailsScreen extends StatelessWidget {
  const PermitDetailsScreen({super.key});

  static bool hasPermit(PermitStatus s) {
    return s == PermitStatus.approved ||
        s == PermitStatus.stickerReady ||
        s == PermitStatus.active ||
        s == PermitStatus.expiringSoon ||
        s == PermitStatus.expired;
  }

  (String, BadgeTone) _badge(PermitStatus s) {
    return switch (s) {
      PermitStatus.approved => ('APPROVED', BadgeTone.green),
      PermitStatus.stickerReady => ('STICKER READY', BadgeTone.gold),
      PermitStatus.active => ('ACTIVE', BadgeTone.green),
      PermitStatus.expiringSoon => ('EXPIRING SOON', BadgeTone.gold),
      _ => ('EXPIRED', BadgeTone.red),
    };
  }

  _StickerInfo _sticker(PermitStatus s) {
    return switch (s) {
      PermitStatus.approved => const _StickerInfo(
          Icons.hourglass_top_rounded,
          'Sticker being prepared',
          'We will notify you when it is ready for pickup.',
          BadgeTone.gold,
        ),
      PermitStatus.stickerReady => const _StickerInfo(
          Icons.inventory_2_outlined,
          'Sticker ready for pickup',
          'Claim it at the Campus Security Office.',
          BadgeTone.gold,
        ),
      PermitStatus.active || PermitStatus.expiringSoon => const _StickerInfo(
          Icons.verified_outlined,
          'Sticker claimed',
          'Keep the sticker on your vehicle where the guard can see it. Stickers are not transferable to another vehicle.',
          BadgeTone.green,
        ),
      _ => const _StickerInfo(
          Icons.event_busy_outlined,
          'Sticker no longer valid',
          'This permit has expired. Renew it to get a valid sticker.',
          BadgeTone.red,
        ),
    };
  }

  String _validFrom(PermitStatus s) {
    return switch (s) {
      PermitStatus.expiringSoon => 'November 8, 2025',
      PermitStatus.expired => 'October 1, 2025',
      _ => 'August 1, 2026',
    };
  }

  String _academicYear(PermitStatus s) {
    return (s == PermitStatus.expiringSoon || s == PermitStatus.expired)
        ? 'A.Y. 2025\u20132026'
        : 'A.Y. 2026\u20132027';
  }

  Widget _row(String label, String value,
      {bool last = false, bool mono = false, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textHint),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: color ?? AppColors.textDark,
                fontFamily: mono ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _empty(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const IconBadge(icon: Icons.confirmation_number_outlined),
            const SizedBox(height: 20),
            const Text(
              'No permit yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your permit details will appear here once your application is approved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'View Application Status',
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, AppRoutes.applicationStatus),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, PermitStatus s, bool replacementRequested) {
    final buttons = <Widget>[];

    if (s == PermitStatus.stickerReady) {
      buttons.add(PrimaryButton(
        label: 'View Pickup Details',
        showArrow: true,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.stickerPickup),
      ));
    }
    if (s == PermitStatus.approved) {
      buttons.add(SecondaryButton(
        label: 'Sticker Pickup Status',
        onPressed: () => Navigator.pushNamed(context, AppRoutes.stickerPickup),
      ));
    }
    if (s == PermitStatus.expiringSoon || s == PermitStatus.expired) {
      buttons.add(PrimaryButton(
        label: 'Renew Permit',
        showArrow: true,
        onPressed: () => Navigator.pushNamed(context, AppRoutes.renewal),
      ));
    }
    if (s == PermitStatus.active || s == PermitStatus.expiringSoon) {
      buttons.add(SecondaryButton(
        label: replacementRequested
            ? 'Replacement Already Requested'
            : 'Request Sticker Replacement',
        onPressed: replacementRequested
            ? null
            : () => Navigator.pushNamed(context, AppRoutes.stickerReplacement),
      ));
    }

    final widgets = <Widget>[];
    for (int i = 0; i < buttons.length; i++) {
      if (i > 0) widgets.add(const SizedBox(height: 10));
      widgets.add(buttons[i]);
    }

    if (s != PermitStatus.expired && s != PermitStatus.stickerReady) {
      widgets.add(const SizedBox(height: 4));
      widgets.add(
        Center(
          child: TextButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('PDF download will be added later.')),
            ),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: const Text(
              'Download Permit Certificate (PDF)',
              style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _content(BuildContext context, ApplicationStore store, PermitStatus status) {
    final app = MockApplication.resolve(status);
    final (badgeText, badgeTone) = _badge(status);
    final sticker = _sticker(status);
    final replacement = store.replacement;
    final expired = status == PermitStatus.expired;
    final expiring = status == PermitStatus.expiringSoon;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PERMIT NUMBER',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Color(0xFFB7C6EC),
                    ),
                  ),
                  StatusBadge(text: badgeText, tone: badgeTone),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                app.permitNo,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Colors.white,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'This number is printed on your permit sticker.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFFB7C6EC)),
              ),
              const Divider(height: 26, color: Color(0x33FFFFFF)),
              Row(
                children: [
                  const Icon(Icons.directions_car, size: 24, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.plate,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text(
                          app.vehicleName,
                          style: const TextStyle(fontSize: 13, color: Color(0xFFB7C6EC)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PERMIT DETAILS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.goldDark,
                ),
              ),
              const SizedBox(height: 4),
              _row('Vehicle type', app.vehicleType),
              _row('Parking zone', app.zone),
              if (app.validFrom == null) _row('Academic year', _academicYear(status)),
              _row('Valid from', app.validFrom ?? _validFrom(status)),
              _row(
                'Valid until',
                app.validUntil,
                color: expired
                    ? AppColors.error
                    : (expiring ? AppColors.goldDark : null),
              ),
              _row('Reference no.', app.referenceNo, mono: true, last: true),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: sticker.tone.tint,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: sticker.tone.accent),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(sticker.icon, size: 24, color: sticker.tone.ink),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sticker.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: sticker.tone.ink,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sticker.message,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (replacement != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.goldLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.gold),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.autorenew_rounded, size: 22, color: AppColors.goldDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Replacement requested on ${formatLongDate(replacement.requestedAt)} (${replacement.reason}). The Security Office will review your request.',
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        ..._actions(context, status, replacement != null),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = ApplicationStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final status = store.status;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Permit Details',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ),
          body: SafeArea(
            child: hasPermit(status)
                ? _content(context, store, status)
                : _empty(context),
          ),
        );
      },
    );
  }
}