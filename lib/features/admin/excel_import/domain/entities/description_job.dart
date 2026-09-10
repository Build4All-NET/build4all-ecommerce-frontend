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

  /// Whether the card is worth showing at all.
  ///
  /// Shown whenever the assistant could help, even when nothing needs writing:
  /// an owner who sees no card cannot tell a feature that found nothing to do
  /// from one that is broken, and after an import that is exactly the question
  /// they are asking.
  bool get worthOffering => available;

  /// Nothing to write: every product already has something written about it.
  bool get nothingToWrite => !running && missing == 0;

  @override
  List<Object?> get props =>
      [available, missing, running, total, written, failed, message];
}
