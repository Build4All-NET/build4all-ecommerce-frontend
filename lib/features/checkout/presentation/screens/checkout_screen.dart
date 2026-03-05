// lib/features/checkout/presentation/screens/checkout_screen.dart

import 'package:build4front/features/catalog/cubit/money.dart';
import 'package:build4front/features/checkout/presentation/screens/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/config/app_config.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/common/widgets/primary_button.dart';

import 'package:build4front/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:build4front/features/cart/presentation/bloc/cart_event.dart';

import '../bloc/checkout_bloc.dart';
import '../bloc/checkout_event.dart';
import '../bloc/checkout_state.dart';

import '../widgets/checkout_section_card.dart';
import '../widgets/checkout_address_form.dart';
import '../widgets/checkout_coupon_field.dart';
import '../widgets/checkout_shipping_methods.dart';
import '../widgets/checkout_payment_methods.dart';
import '../widgets/checkout_items_preview.dart';
import '../widgets/checkout_order_summary.dart';
import '../widgets/checkout_bottom_bar.dart';

class CheckoutScreen extends StatefulWidget {
  final AppConfig appConfig;
  final int? ownerProjectId;

  const CheckoutScreen({
    super.key,
    required this.appConfig,
    this.ownerProjectId,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _started = false;

  final _addressFormKey = GlobalKey<FormState>();
  final _addressFormController = CheckoutAddressFormController();
  bool _showAddressPickerErrors = false;

  // ✅ scroll anchors
  final _itemsSectionKey = GlobalKey();
  final _addressSectionKey = GlobalKey();
  final _shippingSectionKey = GlobalKey();
  final _paymentSectionKey = GlobalKey();

  Future<void> _scrollTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
      alignment: 0.08,
    );
  }

  Future<bool> _confirmCartWillBeCleared(int itemCount) async {
    final l10n = AppLocalizations.of(context)!;

    final res = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.checkoutConfirmDialogTitle),
          content: Text(l10n.checkoutConfirmCartCleared(itemCount)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.commonNo),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.commonYes),
            ),
          ],
        );
      },
    );

    return res == true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckoutBloc>().add(const CheckoutStarted());
    });
  }

  // ✅ Localize any error string BEFORE showing it to user
  String _localizeCheckoutError(AppLocalizations l10n, String raw) {
    final s = raw.trim().toLowerCase();

    // Known bloc validation strings (avoid showing English)
    if (s.contains('cart is empty')) return l10n.checkoutCartEmptyError;
    if (s.contains('select a payment method')) return l10n.checkoutSelectPayment;
    if (s.contains('payment method code is missing')) return l10n.checkoutPaymentMissingCode;

    if (s.contains('select a country')) return l10n.checkoutCountryRequiredError;
    if (s.contains('select a region')) return l10n.checkoutRegionRequiredError;
    if (s.contains('enter city')) return l10n.checkoutCityRequiredError;
    if (s.contains('enter address')) return l10n.checkoutAddressRequiredError;
    if (s.contains('enter phone')) return l10n.checkoutPhoneRequiredError;

    if (s.contains('select a shipping method')) return l10n.checkoutSelectShipping;
    if (s.contains('shipping method is missing')) return l10n.checkoutShippingMissingError;

    // Stripe errors
    if (s.contains('stripe payment canceled')) return l10n.checkoutStripeCanceled;
    if (s.contains('did not return stripe clientsecret')) return l10n.checkoutStripeClientSecretMissing;
    if (s.contains('did not return stripe publishablekey')) return l10n.checkoutStripePublishableKeyMissing;

    // Fallback
    return l10n.commonSomethingWentWrong;
  }

  // ✅ Coupon errors: never show raw backend English
  String _localizeCouponError(AppLocalizations l10n, String raw) {
    final s = raw.trim().toLowerCase();
    if (s.isEmpty) return '';
    if (s.contains('invalid') || s.contains('not valid') || s.contains('coupon')) {
      return l10n.checkoutCouponInvalid;
    }
    return l10n.checkoutCouponFailed;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final spacing = tokens.spacing;
    final colors = tokens.colors;

    return BlocListener<CheckoutBloc, CheckoutState>(
      listenWhen: (prev, curr) =>
          prev.error != curr.error || prev.orderSummary != curr.orderSummary,
      listener: (context, state) {
        final rawErr = (state.error ?? '').trim();
        if (rawErr.isNotEmpty) {
          AppToast.error(context, _localizeCheckoutError(l10n, rawErr));
        }

        final summary = state.orderSummary;
        if (summary != null) {
          final code = (summary.orderCode ?? '').trim();

          AppToast.error(
            context,
            code.isNotEmpty
                ? l10n.checkoutOrderPlacedWithCode(code)
                : l10n.checkoutOrderPlacedToast(summary.orderId),
          );

          context.read<CartBloc>().add(const CartRefreshed());

          // ✅ BEST fallback: from quote lines first (they include itemName)
          final map = <int, String>{};

          final q = state.quote;
          if (q != null) {
            for (final l in q.lines) {
              final n = (l.itemName ?? '').trim();
              if (n.isNotEmpty) map[l.itemId] = n;
            }
          }

          // ✅ fallback #2: from cart itemName
          final cart = state.cart;
          if (map.isEmpty && cart != null) {
            for (final it in cart.items) {
              final n = (it.itemName ?? '').trim();
              if (n.isNotEmpty) map[it.itemId] = n;
            }
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(
                summary: summary,
                address: state.address,
                shipping: state.selectedQuote,
                itemNameById: map.isEmpty ? null : map,
              ),
            ),
          );
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        appBar: AppBar(title: Text(l10n.checkoutTitle)),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => FocusScope.of(context).unfocus(),
          child: BlocBuilder<CheckoutBloc, CheckoutState>(
            builder: (context, state) {
              if (state.loading) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        SizedBox(height: spacing.md),
                        Text(
                          l10n.checkoutLoading,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(color: colors.body),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final cart = state.cart;
              if (cart == null || cart.items.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(spacing.lg),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shopping_cart_outlined,
                            size: 44, color: colors.muted),
                        SizedBox(height: spacing.sm),
                        Text(
                          l10n.checkoutEmptyCart,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: colors.label),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: spacing.lg),
                        PrimaryButton(
                          label: l10n.checkoutGoBack,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // ✅ Coupon inline status (localized)
              final applied = state.coupon.trim();
              final quote = state.quote;

              final rawCouponErr = (state.couponError ?? '').trim();
              final couponErrMsg =
                  rawCouponErr.isEmpty ? '' : _localizeCouponError(l10n, rawCouponErr);

              bool? couponValid;
              String? couponMsg;

              if (applied.isNotEmpty) {
                if (state.quoting) {
                  couponValid = null;
                  couponMsg = l10n.checkoutCouponChecking;
                } else if (couponErrMsg.isNotEmpty) {
                  couponValid = false;
                  couponMsg = couponErrMsg;
                } else if (quote != null) {
                  final qCode = (quote.couponCode ?? '').trim();
                  final same = qCode.isNotEmpty &&
                      qCode.toUpperCase() == applied.toUpperCase();

                  if (same) {
                    couponValid = true;
                    final disc = quote.couponDiscount ?? 0.0;
                    couponMsg = disc > 0
                        ? l10n.checkoutCouponAppliedDiscount(money(context, disc))
                        : l10n.checkoutCouponApplied;
                  } else {
                    couponValid = false;
                    couponMsg = l10n.checkoutCouponInvalid;
                  }
                }
              }

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<CheckoutBloc>().add(const CheckoutRefreshRequested());
                },
                child: ListView(
                  key: const PageStorageKey('checkout_list'),
                  cacheExtent: MediaQuery.of(context).size.height * 3,
                  addAutomaticKeepAlives: true,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(spacing.md),
                  children: [
                    // ✅ Items
                    KeyedSubtree(
                      key: _itemsSectionKey,
                      child: CheckoutSectionCard(
                        title: l10n.checkoutItemsTitle,
                        child: CheckoutItemsPreview(cart: cart),
                      ),
                    ),
                    SizedBox(height: spacing.md),

                    // ✅ Address
                    KeyedSubtree(
                      key: _addressSectionKey,
                      child: CheckoutSectionCard(
                        title: l10n.checkoutAddressTitle,
                        child: CheckoutAddressForm(
                          key: const PageStorageKey('checkout_address_form'),
                          formKey: _addressFormKey,
                          controller: _addressFormController,
                          showPickerErrors: _showAddressPickerErrors,
                          initial: state.address,
                          onApply: (addr) {
                            context.read<CheckoutBloc>().add(CheckoutAddressChanged(addr));
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.md),

                    // ✅ Coupon (draft typing does NOT call backend)
                    CheckoutSectionCard(
                      title: l10n.checkoutCouponTitle,
                      child: CheckoutCouponField(
                        draft: state.couponDraft,
                        applied: state.coupon,
                        isValid: couponValid,
                        message: couponMsg,
                        onDraftChanged: (v) {
                          context.read<CheckoutBloc>().add(CheckoutCouponDraftChanged(v));
                        },
                        onApply: (code) {
                          context.read<CheckoutBloc>().add(CheckoutCouponApplied(code));
                        },
                      ),
                    ),
                    SizedBox(height: spacing.md),

                    // ✅ Shipping
                    KeyedSubtree(
                      key: _shippingSectionKey,
                      child: CheckoutSectionCard(
                        title: l10n.checkoutShippingTitle,
                        child: CheckoutShippingMethods(
                          quotes: state.shippingQuotes,
                          selectedMethodId: state.selectedShippingMethodId,
                          onSelect: (id) =>
                              context.read<CheckoutBloc>().add(CheckoutShippingSelected(id)),
                          onRefresh: () =>
                              context.read<CheckoutBloc>().add(const CheckoutRefreshRequested()),
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.md),

                    // ✅ Payment
                    KeyedSubtree(
                      key: _paymentSectionKey,
                      child: CheckoutSectionCard(
                        title: l10n.checkoutPaymentTitle,
                        child: CheckoutPaymentMethods(
                          methods: state.paymentMethods,
                          selectedIndex: state.selectedPaymentIndex,
                          onSelectIndex: (i) =>
                              context.read<CheckoutBloc>().add(CheckoutPaymentSelected(i)),
                        ),
                      ),
                    ),
                    SizedBox(height: spacing.md),

                    // ✅ Summary
                    CheckoutSectionCard(
                      title: l10n.checkoutSummaryTitle,
                      child: CheckoutOrderSummary(
                        cart: cart,
                        selectedShipping: state.selectedQuote,
                        tax: state.tax,
                        quote: state.quote,
                      ),
                    ),
                    SizedBox(height: spacing.xl),
                  ],
                ),
              );
            },
          ),
        ),
        bottomNavigationBar: BlocBuilder<CheckoutBloc, CheckoutState>(
          builder: (context, state) {
            final cart = state.cart;
            if (cart == null || cart.items.isEmpty) {
              return const SizedBox.shrink();
            }

            return SafeArea(
              top: false,
              child: CheckoutBottomBar(
                cart: cart,
                selectedShipping: state.selectedQuote,
                tax: state.tax,
                quote: state.quote,
                isPlacing: state.placing,
                onPlaceOrder: () async {
                  FocusScope.of(context).unfocus();
                  if (!mounted) return;

                  final bloc = context.read<CheckoutBloc>();
                  if (bloc.state.placing) return;

                  if (!_showAddressPickerErrors) {
                    setState(() => _showAddressPickerErrors = true);
                  }

                  _addressFormController.flush();
                  await Future<void>.delayed(const Duration(milliseconds: 25));
                  if (!mounted) return;

                  final formState = _addressFormKey.currentState;
                  final formOk = formState?.validate() ?? false;
                  formState?.save();

                  final firstErr = _addressFormController.firstError(l10n);

                  if (!formOk || firstErr != null) {
                    await _scrollTo(_addressSectionKey);
                    AppToast.error(
                      context,
                      firstErr ?? '${l10n.checkoutAddressTitle}: ${l10n.fieldRequired}',
                    );
                    return;
                  }

                  final s = bloc.state;

                  if (s.selectedPaymentIndex == null) {
                    await _scrollTo(_paymentSectionKey);
                    AppToast.error(context, l10n.checkoutSelectPayment);
                    return;
                  }

                  if (s.shippingQuotes.isNotEmpty && s.selectedShippingMethodId == null) {
                    await _scrollTo(_shippingSectionKey);
                    AppToast.error(context, l10n.checkoutSelectShipping);
                    return;
                  }

                  final itemCount = s.cart?.items.length ?? 0;
                  final ok = await _confirmCartWillBeCleared(itemCount);
                  if (!ok || !mounted) return;

                  if (bloc.state.placing) return;
                  bloc.add(const CheckoutPlaceOrderPressed());
                },
              ),
            );
          },
        ),
      ),
    );
  }
}