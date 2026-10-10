import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/core/payments/stripe_payment_sheet.dart';
import 'package:build4front/features/admin/licensing/data/models/available_payment_method_model.dart';
import 'package:build4front/features/admin/licensing/data/models/upgrade_payment_intent_model.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/ai_api.dart';
import '../../data/models/ai_token_pack.dart';
import '../../data/models/ai_usage_line.dart';
import '../../data/models/ai_wallet.dart';

/// Owner "AI add-on": token balance, buy packs (reusing the existing payment
/// flow with kind=AI_TOKENS), and usage. Shop end-users use AI for free; only
/// the owner is billed. Labels are literal pending l10n.
class AiTokensScreen extends StatefulWidget {
  const AiTokensScreen({super.key});

  @override
  State<AiTokensScreen> createState() => _AiTokensScreenState();
}

class _AiTokensScreenState extends State<AiTokensScreen> {
  final AiApi _api = AiApi();

  bool _loading = true;
  String? _error;
  AiWallet? _wallet;
  List<AiTokenPack> _packs = const [];
  List<AiUsageLine> _usage = const [];
  String? _buyingCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _api.getWallet(),
        _api.getPacks(),
        _api.getUsage(),
      ]);
      if (!mounted) return;
      setState(() {
        _wallet = results[0] as AiWallet;
        _packs = results[1] as List<AiTokenPack>;
        _usage = results[2] as List<AiUsageLine>;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  // ---------------- buy flow ----------------

  Future<void> _buy(AiTokenPack pack) async {
    if (_buyingCode != null) return;
    List<AvailablePaymentMethodModel> methods;
    try {
      methods = await _api.paymentMethods();
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
      return;
    }
    if (!mounted) return;
    if (methods.isEmpty) {
      AppToast.error(context, 'No payment methods are configured.');
      return;
    }

    final method = await showModalBottomSheet<AvailablePaymentMethodModel>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Choose a payment method',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
            for (final m in methods)
              ListTile(
                leading: const Icon(Icons.payments_outlined),
                title: Text(m.displayName.isEmpty ? m.code : m.displayName),
                onTap: () => Navigator.of(ctx).pop(m),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (method == null || !mounted) return;

    setState(() => _buyingCode = pack.code);
    try {
      final intent = await _api.initiatePurchase(
        planCode: pack.code,
        billingCycle: pack.billingCycle,
        paymentMethodCode: method.code,
      );
      final ok = await _completePayment(intent);
      if (!mounted) return;
      if (ok) {
        AppToast.success(context, 'AI tokens added.');
      }
      await _load();
    } catch (e) {
      if (mounted) AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _buyingCode = null);
    }
  }

  /// Dispatches on the provider the backend chose — identical to the license
  /// upgrade flow (Stripe native sheet; PayPal/MPGS external URL; cash pending).
  Future<bool> _completePayment(UpgradePaymentIntentModel intent) async {
    final provider = (intent.provider).toLowerCase();

    if (provider == 'stripe') {
      final pk = (intent.publishableKey ?? '').trim();
      final cs = (intent.clientSecret ?? '').trim();
      if (pk.isEmpty || cs.isEmpty) {
        throw Exception('Stripe configuration is missing.');
      }
      final result = await StripePaymentSheet.pay(
        publishableKey: pk,
        clientSecret: cs,
        merchantName: 'Build4All',
      );
      if (result != StripePayStatus.paid) return false;
      await _api.confirm(intent.paymentIntentId);
      return true;
    }

    if (provider == 'paypal' || provider == 'mpgs') {
      final url = (intent.checkoutUrl ?? '').trim();
      if (url.isEmpty) throw Exception('Checkout URL is missing.');
      final uri = Uri.tryParse(url);
      if (uri != null) {
        try {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } catch (_) {/* fall through to confirm dialog */}
      }
      if (!mounted) return false;
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Complete your payment'),
          content: const Text(
              'Finish the payment in the opened page, then tap "I\'ve paid".'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text("I've paid")),
          ],
        ),
      );
      if (confirmed != true) return false;
      await _api.confirm(intent.paymentIntentId);
      return true;
    }

    // cash / manual: activates when the super-admin marks it paid.
    if (mounted) {
      AppToast.info(context,
          'Request submitted — your AI tokens activate once the payment is confirmed.');
    }
    return false;
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI add-on'),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      _balanceCard(),
                      const SizedBox(height: 18),
                      _sectionTitle('TOKEN PACKS'),
                      ..._packs.map(_packCard),
                      if (_usage.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _sectionTitle('USED THIS PERIOD'),
                        _usageCard(),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 8, top: 4),
        child: Text(t,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
                letterSpacing: .5)),
      );

  Widget _balanceCard() {
    final cs = Theme.of(context).colorScheme;
    final w = _wallet;
    final enabled = w?.aiEnabled ?? false;
    final allowance = (w?.tokensAllowance ?? 0);
    final remaining = (w?.tokensRemaining ?? 0);
    final frac = allowance > 0 ? (remaining / allowance).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        if (!enabled)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.error.withOpacity(.07),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: cs.error.withOpacity(.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, color: cs.error, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'AI is off — buy a pack to turn it on for your shop. Your users use AI for free; only you are billed.',
                    style: TextStyle(color: cs.error, fontWeight: FontWeight.w600, fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: enabled
                  ? [cs.primary, cs.primary.withOpacity(.75)]
                  : [cs.outline, cs.outlineVariant],
            ),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('AI tokens balance',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                '${_fmt(remaining)} / ${_fmt(allowance)}',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 28),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: frac,
                  minHeight: 7,
                  backgroundColor: Colors.white.withOpacity(.3),
                  valueColor: const AlwaysStoppedAnimation(Colors.white),
                ),
              ),
              if ((w?.periodEnd ?? '').isNotEmpty) ...[
                const SizedBox(height: 7),
                Text('Resets ${w!.periodEnd}',
                    style: TextStyle(color: Colors.white.withOpacity(.9), fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _packCard(AiTokenPack p) {
    final cs = Theme.of(context).colorScheme;
    final busy = _buyingCode == p.code;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(p.name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                      if (p.popular) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: cs.primary.withOpacity(.12), borderRadius: BorderRadius.circular(999)),
                          child: Text('POPULAR', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w800, fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text('${_fmt(p.tokensPerPeriod)} tokens / ${p.billingCycle.toLowerCase()}',
                      style: TextStyle(color: cs.primary, fontWeight: FontWeight.w700, fontSize: 12.5)),
                  const SizedBox(height: 3),
                  Text('\$${p.price.toStringAsFixed(2)} ${p.currency}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
                ],
              ),
            ),
            FilledButton(
              onPressed: busy || _buyingCode != null ? null : () => _buy(p),
              child: busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Buy'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _usageCard() {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            for (final u in _usage)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(u.feature, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(_fmt(u.tokens), style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _fmt(int n) {
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}
