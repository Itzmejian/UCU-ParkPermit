class FlaggedDocument {
  const FlaggedDocument({
    required this.title,
    required this.remark,
    this.kind,
  });

  final String title;
  final String remark;

  /// drivers_license, orcr or ucu_id (set when the data comes from the server).
  final String? kind;
}