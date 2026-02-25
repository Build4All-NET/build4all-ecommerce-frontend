import 'package:build4front/core/config/app_config.dart';
import 'package:build4front/features/checkout/presentation/screens/order_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/common/widgets/primary_button.dart';

import 'package:build4front/features/cart/presentation/bloc/cart_bloc.dart';
import 'package:build4front/features/cart/presentation/bloc/cart_event.dart';

import 'package:build4front/features/checkout/domain/entities/checkout_entities.dart';

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
  bool _showAddressPickerErrors = false;

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

  // NOTE:
  // Phone format is validated in CheckoutAddressForm (IntlPhoneField validator).
  // Here we only guard "presence" + picker selections.
  String? _addressError(AppLocalizations l10n, ShippingAddress a) {
    if (a.countryId == null) {
      return '${l10n.adminTaxCountryLabel}: ${l10n.fieldRequired}';
    }
    if (a.regionId == null) {
      return '${l10n.adminTaxRegionLabel}: ${l10n.fieldRequired}';
    }
    if ((a.addressLine ?? '').trim().isEmpty) {
      return '${l10n.checkoutAddressLineLabel}: ${l10n.fieldRequired}';
    }
    if ((a.city ?? '').trim().isEmpty) {
      return '${l10n.checkoutCityLabel}: ${l10n.fieldRequired}';
    }

    final ph = (a.phone ?? '').trim();
    if (ph.isEmpty) {
      return '${l10n.checkoutPhoneLabel}: ${l10n.fieldRequired}';
    }

    return null;
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
        if (state.error != null && state.error!.trim().isNotEmpty) {
          AppToast.show(context, state.error!, isError: true);
        }

        if (state.orderSummary != null) {
          final id = state.orderSummary!.orderId;

          AppToast.show(context, l10n.checkoutOrderPlacedToast(id));
          context.read<CartBloc>().add(const CartRefreshed());

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailsScreen(summary: state.orderSummary!),
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
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 44,
                          color: colors.muted,
                        ),
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

              return RefreshIndicator(
                onRefresh: () async {
                  context.read<CheckoutBloc>().add(
                        const CheckoutRefreshRequested(),
                      );
                },
                child: ListView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(spacing.md),
                  children: [
                    CheckoutSectionCard(
                      title: l10n.checkoutItemsTitle,
                      child: CheckoutItemsPreview(cart: cart),
                    ),
                    SizedBox(height: spacing.md),

                    CheckoutSectionCard(
                      title: l10n.checkoutAddressTitle,
                      child: CheckoutAddressForm(
                        formKey: _addressFormKey,
                        showPickerErrors: _showAddressPickerErrors,
                        initial: state.address,
                        onApply: (addr) {
                          context.read<CheckoutBloc>().add(
                                CheckoutAddressChanged(addr),
                              );
                        },
                      ),
                    ),
                    SizedBox(height: spacing.md),

                    CheckoutSectionCard(
                      title: l10n.checkoutCouponTitle,
                      child: CheckoutCouponField(
                        initial: state.coupon,
                        onChanged: (v) {
                          context.read<CheckoutBloc>().add(
                                CheckoutCouponChanged(v),
                              );
                        },
                      ),
                    ),
                    SizedBox(height: spacing.md),

                    CheckoutSectionCard(
                      title: l10n.checkoutShippingTitle,
                      child: CheckoutShippingMethods(
                        quotes: state.shippingQuotes,
                        selectedMethodId: state.selectedShippingMethodId,
                        onSelect: (id) => context.read<CheckoutBloc>().add(
                              CheckoutShippingSelected(id),
                            ),
                        onRefresh: () => context.read<CheckoutBloc>().add(
                              const CheckoutRefreshRequested(),
                            ),
                      ),
                    ),
                    SizedBox(height: spacing.md),

                    CheckoutSectionCard(
                      title: l10n.checkoutPaymentTitle,
                      child: CheckoutPaymentMethods(
                        methods: state.paymentMethods,
                        selectedIndex: state.selectedPaymentIndex,
                        onSelectIndex: (i) => context.read<CheckoutBloc>().add(
                              CheckoutPaymentSelected(i),
                            ),
                      ),
                    ),
                    SizedBox(height: spacing.md),

                    CheckoutSectionCard(
                      title: l10n.checkoutSummaryTitle,
                      child: CheckoutOrderSummary(
                        cart: cart,
                        selectedShipping: state.selectedQuote,
                        tax: state.tax,
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
                isPlacing: state.placing,
                onPlaceOrder: () async {
                  FocusScope.of(context).unfocus();

                  if (!mounted) return;
                  final bloc = context.read<CheckoutBloc>();
                  final current = bloc.state;

                  if (current.placing) return;

                  // ✅ Turn on inline picker errors BEFORE validating
                  if (!_showAddressPickerErrors) {
                    setState(() => _showAddressPickerErrors = true);
                  }

                  // ✅ Let blur/debounce callbacks flush (address/city/phone sync to bloc)
                  // This avoids false "required" when user taps Place Order immediately after typing.
                  await Future<void>.delayed(const Duration(milliseconds: 380));
                  if (!mounted) return;

                  // ✅ Validate form fields
                  final formState = _addressFormKey.currentState;
                  final formOk = formState?.validate() ?? false;
                  formState?.save();

                  // Let CheckoutAddressChanged event process
                  await Future<void>.delayed(const Duration(milliseconds: 10));
                  if (!mounted) return;

                  final s = bloc.state;
                  final addrErr = _addressError(l10n, s.address);

                  if (!formOk || addrErr != null) {
                    AppToast.show(
                      context,
                      addrErr ?? l10n.fieldRequired,
                      isError: true,
                    );
                    return;
                  }

                  // ✅ Payment validation
                  if (s.selectedPaymentIndex == null) {
                    AppToast.show(
                      context,
                      l10n.checkoutSelectPayment,
                      isError: true,
                    );
                    return;
                  }

                  // ✅ Shipping validation (if required)
                  if (s.shippingQuotes.isNotEmpty &&
                      s.selectedShippingMethodId == null) {
                    AppToast.show(
                      context,
                      l10n.checkoutSelectShipping,
                      isError: true,
                    );
                    return;
                  }

                  // ✅ Confirm dialog
                  final itemCount = s.cart?.items.length ?? 0;
                  final ok = await _confirmCartWillBeCleared(itemCount);
                  if (!ok || !mounted) return;

                  final latest = bloc.state;
                  if (latest.placing) return;

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