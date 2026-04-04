import 'dart:async';
import 'dart:ui';

import 'package:build4front/debug/debug_config_banner.dart';
import 'package:build4front/features/ai_feature/ai_feature_bootstrap.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:build4front/app/app.dart';
import 'package:build4front/core/config/env.dart';
import 'package:build4front/core/network/globals.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
    debugPrintStack(stackTrace: details.stack);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught platform error: $error');
    debugPrintStack(stackTrace: stack);
    return true;
  };

  await runZonedGuarded(
    () async {
      await _bootstrapApp();
      runApp(const Build4AllFrontApp());

      Future.microtask(() async {
        try {
          await AiFeatureBootstrap().init();
        } catch (e, st) {
          debugPrint('AI bootstrap failed: $e');
          debugPrintStack(stackTrace: st);
        }
      });
    },
    (error, stackTrace) {
      debugPrint('Uncaught zone error: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}

Future<void> _bootstrapApp() async {
  await _initFirebase();
  _initDio();
  await _initStripe();
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized');
  } catch (e, st) {
    debugPrint('Firebase init failed: $e');
    debugPrintStack(stackTrace: st);
  }
}

void _initDio() {
  makeDefaultDio(Env.apiBaseUrl);
}

Future<void> _initStripe() async {
  try {
    if (Env.stripePublishableKey.isNotEmpty) {
      Stripe.publishableKey = Env.stripePublishableKey;
      await Stripe.instance.applySettings();
    } else {
      debugPrint('Stripe publishable key is missing (STRIPE_PUBLISHABLE_KEY).');
    }
  } catch (e, st) {
    debugPrint('Stripe init failed: $e');
    debugPrintStack(stackTrace: st);
  }
}