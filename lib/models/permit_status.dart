enum PermitStatus {
  none,
  draft,
  pending,
  underReview,
  declined,
  appealReview,
  approved,
  stickerReady,
  active,
  expiringSoon,
  expired,
}

extension PermitStatusLabel on PermitStatus {
  String get label => switch (this) {
        PermitStatus.none => 'No permit',
        PermitStatus.draft => 'Draft',
        PermitStatus.pending => 'Pending',
        PermitStatus.underReview => 'Under review',
        PermitStatus.declined => 'Declined',
        PermitStatus.appealReview => 'Appeal review',
        PermitStatus.approved => 'Approved',
        PermitStatus.stickerReady => 'Sticker ready',
        PermitStatus.active => 'Active',
        PermitStatus.expiringSoon => 'Expiring soon',
        PermitStatus.expired => 'Expired',
      };
}