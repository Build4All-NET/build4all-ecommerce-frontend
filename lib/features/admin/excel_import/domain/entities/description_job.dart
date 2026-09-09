import 'package:equatable/equatable.dart';

/// How far the writing of an owner's missing product descriptions has got.
class DescriptionJob extends Equatable {
  /// Whether a model is configured and switched on for this owner. When false
  /// the offer is not made at all rather than made and refused.
  final bool available;

  /// Products with nothing written about them.
  final int missing;

  final bool running;
  final int total;
  final int written;
  final int failed;

  /// Why it stopped, when it stopped for a reason worth telling the owner.
  final String? message;

  const DescriptionJob({
    required this.available,
    required this.missing,
    required this.running,
    required this.total,
    required this.written,
    required this.failed,
    this.message,
  });

  static const DescriptionJob none = DescriptionJob(
    available: false,
    missing: 0,
    running: false,
    total: 0,
    written: 0,
    failed: 0,
  );

  /// Whether there is anything to offer the owner right now.
  bool get worthOffering => available && (missing > 0 || running);

  @override
  List<Object?> get props =>
      [available, missing, running, total, written, failed, message];
}
