import 'package:build4front/features/admin/licensing/domain/entities/available_payment_method.dart';
import 'package:build4front/features/admin/licensing/domain/entities/billing_cycle.dart';
import 'package:build4front/features/admin/licensing/domain/entities/owner_app_access.dart';
import 'package:build4front/features/admin/licensing/domain/entities/plan_code.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_payment_confirmation.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_payment_intent.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_plan.dart';
import 'package:build4front/features/admin/licensing/domain/entities/upgrade_request.dart';

abstract class ILicensingRepository {
  /// Current owner license/subscription snapshot.
  Future<OwnerAppAccess> getCurrentLicensePlan();

  /// Plans this owner can upgrade to, with dynamic pricing.
  Future<List<UpgradePlan>> getAvailableUpgradePlans();

  /// Payment methods the owner can choose on the Pay Now popup.
  Future<List<AvailablePaymentMethod>> getAvailablePaymentMethods();

  /// Creates a server-side payment intent for the selected upgrade.
  Future<UpgradePaymentIntent> initiateUpgradePayment({
    required PlanCode planCode,
    required BillingCycle billingCycle,
    required String paymentMethodCode,
    int? usersAllowedOverride,
  });

  /// Notifies the backend that the client-side payment step succeeded
  /// and the subscription should be activated. Returns the refreshed
  /// subscription state alongside receipt metadata.
  Future<UpgradePaymentConfirmation> confirmUpgradePayment({
    required String paymentIntentId,
  });

  /// Convenience call to re-fetch license after any state change.
  Future<OwnerAppAccess> refreshOwnerSubscription();

  /// Historical upgrade requests for the current owner.
  Future<List<UpgradeRequest>> listUpgradeRequests();

  /// Legacy "request upgrade" (no payment) — kept for backward compatibility
  /// with the pre-existing SUPER_ADMIN approval flow.
  Future<void> requestUpgrade({
    required PlanCode planCode,
    required BillingCycle billingCycle,
    int? usersAllowedOverride,
  });
}
