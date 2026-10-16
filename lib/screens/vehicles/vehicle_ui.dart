import '../../core/app_routes.dart';
import '../../models/application_store.dart';
import '../../models/mock_application.dart';
import '../../models/permit_status.dart';
import '../../widgets/status_badge.dart';

class VehicleBadge {
  const VehicleBadge(this.text, this.tone);

  final String text;
  final BadgeTone tone;
}

VehicleBadge badgeFor(VehicleRecord v) {
  if (v.pendingVerification) {
    return const VehicleBadge('PENDING VERIFICATION', BadgeTone.gold);
  }
  return switch (v.status) {
    PermitStatus.none || PermitStatus.draft => const VehicleBadge('DRAFT', BadgeTone.gray),
    PermitStatus.pending => const VehicleBadge('PENDING', BadgeTone.gold),
    PermitStatus.underReview => const VehicleBadge('UNDER REVIEW', BadgeTone.gold),
    PermitStatus.declined => const VehicleBadge('DECLINED', BadgeTone.red),
    PermitStatus.appealReview => const VehicleBadge('UNDER RE-EVALUATION', BadgeTone.gold),
    PermitStatus.approved => const VehicleBadge('APPROVED', BadgeTone.green),
    PermitStatus.stickerReady => const VehicleBadge('STICKER READY', BadgeTone.gold),
    PermitStatus.active => const VehicleBadge('ACTIVE PERMIT', BadgeTone.green),
    PermitStatus.expiringSoon => const VehicleBadge('EXPIRING SOON', BadgeTone.gold),
    PermitStatus.expired => const VehicleBadge('EXPIRED', BadgeTone.red),
  };
}

bool hasPermitNumber(PermitStatus s) {
  return s == PermitStatus.approved ||
      s == PermitStatus.stickerReady ||
      s == PermitStatus.active ||
      s == PermitStatus.expiringSoon ||
      s == PermitStatus.expired;
}

bool canRequestUpdate(PermitStatus s) {
  return s == PermitStatus.approved ||
      s == PermitStatus.stickerReady ||
      s == PermitStatus.active ||
      s == PermitStatus.expiringSoon;
}

/// The main shortcut button for a vehicle, as (label, route). Null if none.
(String, String)? vehiclePrimaryAction(PermitStatus s) {
  return switch (s) {
    PermitStatus.pending ||
    PermitStatus.underReview ||
    PermitStatus.appealReview =>
      ('View Review Status', AppRoutes.applicationStatus),
    PermitStatus.declined => ('View Notice', AppRoutes.applicationDeclined),
    PermitStatus.approved || PermitStatus.active => ('View Permit', AppRoutes.permitDetails),
    PermitStatus.stickerReady => ('Pickup Details', AppRoutes.stickerPickup),
    PermitStatus.expiringSoon => ('Renew', AppRoutes.renewal),
    PermitStatus.expired => ('Renew', AppRoutes.permitExpired),
    PermitStatus.none || PermitStatus.draft => null,
  };
}

String vehicleInfoText(VehicleRecord v) {
  if (v.pendingVerification) {
    return 'Your update is waiting for verification (about 24 hours).';
  }
  final app = MockApplication.forStatus(v.status);
  final permit = app.permitNo;
  final until = app.validUntil;
  return switch (v.status) {
    PermitStatus.none || PermitStatus.draft => 'Not submitted yet.',
    PermitStatus.pending => 'Reference ${v.referenceNo}. Waiting in the review queue.',
    PermitStatus.underReview => 'Reference ${v.referenceNo}. Review takes 24 to 48 hours.',
    PermitStatus.declined => 'Your application was declined. You can file an appeal.',
    PermitStatus.appealReview => 'Your appeal is being reviewed.',
    PermitStatus.approved => 'Permit $permit. Your sticker is being prepared.',
    PermitStatus.stickerReady => 'Permit $permit. Your sticker is ready for pickup.',
    PermitStatus.active => 'Permit $permit. Valid until $until.',
    PermitStatus.expiringSoon => 'Permit $permit. Expires on $until.',
    PermitStatus.expired => 'Permit $permit. Expired on $until.',
  };
}