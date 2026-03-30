import 'package:build4front/debug/debug_config_banner.dart';
import 'package:build4front/features/ai_feature/ai_feature_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:build4front/app/app.dart';
import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/network/globals.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  makeDefaultDio(Env.apiBaseUrl);

  await AiFeatureBootstrap().init();

  try {
    if (Env.stripePublishableKey.isNotEmpty) {
      Stripe.publishableKey = Env.stripePublishableKey;
      await Stripe.instance.applySettings();
    } else {
      debugPrint("Stripe publishable key is missing (STRIPE_PUBLISHABLE_KEY).");
    }
  } catch (e) {
    debugPrint("Stripe init failed: $e");
  }

  runApp(const Build4AllFrontApp());
}