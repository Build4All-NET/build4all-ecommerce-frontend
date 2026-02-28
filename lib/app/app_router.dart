// lib/app/app_router.dart

import 'package:build4front/features/admin/excel_import/data/repositories/excel_import_repository_impl.dart';
import 'package:build4front/features/admin/excel_import/data/services/excel_import_api_service.dart';
import 'package:build4front/features/admin/excel_import/domain/usecases/import_excel_file.dart';
import 'package:build4front/features/admin/excel_import/domain/usecases/validate_excel_file.dart';
import 'package:build4front/features/admin/excel_import/presentation/bloc/excel_import_bloc.dart';
import 'package:build4front/features/admin/excel_import/presentation/screens/admin_excel_import_screen.dart';
import 'package:build4front/features/auth/data/services/admin_token_store.dart';
import 'package:build4front/features/checkout/domain/usecases/get_last_shipping_address.dart';
import 'package:build4front/features/checkout/domain/usecases/quote_from_cart.dart';
import 'package:build4front/features/forgotpassword/data/repositories/forgot_password_repository_impl.dart';
import 'package:build4front/features/forgotpassword/data/services/forgot_password_api_service.dart';
import 'package:build4front/features/forgotpassword/domain/repositories/forgot_password_repository.dart';
import 'package:build4front/features/forgotpassword/domain/usecases/send_reset_code.dart';
import 'package:build4front/features/forgotpassword/domain/usecases/update_password.dart';
import 'package:build4front/features/forgotpassword/domain/usecases/verify_reset_code.dart';
import 'package:build4front/features/forgotpassword/presentation/bloc/forgot_password_bloc.dart';
import 'package:build4front/features/forgotpassword/presentation/screens/forgot_password_email_screen.dart';
import 'package:build4front/features/forgotpassword/presentation/screens/forgot_password_verify_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:build4front/core/config/app_config.dart';
import 'package:build4front/core/config/env.dart';

import 'package:build4front/features/auth/presentation/gate/auth_gate.dart';
import 'package:build4front/features/auth/presentation/login/screens/user_login_screen.dart';

import 'package:build4front/features/shell/presentation/screens/main_shell.dart';
import 'package:build4front/features/explore/presentation/screens/explore_screen.dart';

// Admin
import 'package:build4front/features/admin/product/presentation/widgets/admin_gate.dart';
import 'package:build4front/features/admin/dashboard/screen/admin_dashboard_screen.dart';
import 'package:build4front/features/admin/product/presentation/screens/admin_products_list_screen.dart';

// ✅ Orders Admin Feature
import 'package:build4front/features/admin/orders_admin/orders_admin_feature.dart';

// Checkout
import 'package:build4front/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:build4front/features/checkout/presentation/bloc/checkout_bloc.dart';

import 'package:build4front/features/checkout/domain/repositories/checkout_repository.dart';
import 'package:build4front/features/checkout/domain/usecases/get_checkout_cart.dart';
import 'package:build4front/features/checkout/domain/usecases/get_payment_methods.dart';
import 'package:build4front/features/checkout/domain/usecases/get_shipping_quotes.dart';
import 'package:build4front/features/checkout/domain/usecases/preview_tax.dart';
import 'package:build4front/features/checkout/domain/usecases/place_order.dart';

// Orders (USER)
import 'package:build4front/features/orders/orders_feature.dart';

// ✅ Notifications (USER)
import 'package:build4front/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:build4front/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:build4front/features/notifications/presentation/bloc/notifications_event.dart';

import 'package:build4front/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:build4front/features/notifications/domain/usecases/get_user_notifications.dart';
import 'package:build4front/features/notifications/domain/usecases/get_unread_count.dart';
import 'package:build4front/features/notifications/domain/usecases/mark_notification_read.dart';
import 'package:build4front/features/notifications/domain/usecases/delete_notification.dart';

class AppRouter {
  static const String initialRoute = '/';

  static const String startup = '/';
  static const String login = '/login';
  static const String main = '/main';

  static const String admin = '/admin';
  static const String adminProducts = '/admin/products';
  static const String adminOrders = '/admin/orders';

  static const String explore = '/explore';
  static const String checkout = '/checkout';

  static const String myOrders = '/my-orders';

  static const String notifications = '/notifications';
  static const forgotEmail = '/forgot/email';
  static const forgotVerify = '/forgot/verify';
  static const forgotUpdate = '/forgot/update';
  static const adminExcelImport = '/admin/excel-import';

  static Route<dynamic> onGenerateRoute(
    RouteSettings settings,
    AppConfig appConfig,
  ) {
    switch (settings.name) {
      // ✅ Startup → AuthGate decides where to go based on token(s)
      case startup:
        return MaterialPageRoute(
          builder: (_) => AuthGate(appConfig: appConfig),
          settings: settings,
        );

      case login:
        return MaterialPageRoute(
          builder: (_) => UserLoginScreen(appConfig: appConfig),
          settings: settings,
        );

      case forgotEmail:
        return MaterialPageRoute(
          builder: (ctx) => _forgotFeature(
            context: ctx,
            child: const ForgotPasswordEmailScreen(),
          ),
        );

      case forgotVerify:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (ctx) => BlocProvider.value(
            value: ctx.read<ForgotPasswordBloc>(),
            child: ForgotPasswordVerifyScreen(
              email: args['email'],
            ),
          ),
        );

      case main:
        return MaterialPageRoute(
          builder: (_) => MainShell(appConfig: appConfig),
          settings: settings,
        );

      case explore:
        {
          final args = settings.arguments as Map<String, dynamic>?;

          final String? initialQuery = args?['query'] as String?;
          final String? initialCategoryLabel = args?['category'] as String?;
          final String? initialSectionId = args?['sectionId'] as String?;
          final int? initialCategoryId = args?['categoryId'] as int?;

          return MaterialPageRoute(
            builder: (_) => ExploreScreen(
              appConfig: appConfig,
              initialQuery: initialQuery,
              initialCategoryLabel: initialCategoryLabel,
              initialSectionId: initialSectionId,
              initialCategoryId: initialCategoryId,
            ),
            settings: settings,
          );
        }

      // ✅ Admin Dashboard
      case admin:
        return MaterialPageRoute(
          builder: (_) =>
              AdminGate(builder: (_) => const AdminDashboardScreen()),
          settings: settings,
        );

      // ✅ Admin Products
      case adminProducts:
        {
          final ownerId = int.tryParse(Env.ownerProjectLinkId) ?? 0;

          return MaterialPageRoute(
            builder: (_) => AdminGate(
              builder: (_) => AdminProductsListScreen(ownerProjectId: ownerId),
            ),
            settings: settings,
          );
        }

      // ✅ OWNER Orders Admin (NO SUPER ADMIN in your app)
      case adminOrders:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AdminGate(
            builder: (ctx) {
              final store = ctx.read<AdminTokenStore>();

              return OrdersAdminFeature(getToken: () => store.getToken());
            },
          ),
        );

      // ✅ USER Orders
      case myOrders:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => OrdersFeature(appConfig: appConfig),
        );

      // ✅ Checkout
      case checkout:
        {
          final args = settings.arguments as Map<String, dynamic>?;

          final ownerProjectId = (args?['ownerProjectId'] as int?) ??
              (int.tryParse(Env.ownerProjectLinkId) ?? 0);

          final currencyId = (args?['currencyId'] as int?) ??
              (int.tryParse(Env.currencyId) ?? 1);

          return MaterialPageRoute(
            settings: settings,
            builder: (context) {
              final repo = context.read<CheckoutRepository>();

              return BlocProvider(
                create: (_) => CheckoutBloc(
                  getCart: GetCheckoutCart(repo),
                  getPaymentMethods: GetPaymentMethods(repo),
                  getShippingQuotes: GetShippingQuotes(repo),
                  previewTax: PreviewTax(repo),
                  placeOrder: PlaceOrder(repo),
                  ownerProjectId: ownerProjectId,
                  currencyId: currencyId,
                  getLastShippingAddress: GetLastShippingAddress(repo),
                  quoteFromCart: QuoteFromCart(repo),
                ),
                child: CheckoutScreen(
                  appConfig: appConfig,
                  ownerProjectId: ownerProjectId,
                ),
              );
            },
          );
        }

      // ✅ Notifications
      case notifications:
        return MaterialPageRoute(
          settings: settings,
          builder: (context) {
            final repo = context.read<NotificationsRepository>();

            return BlocProvider(
              create: (_) => NotificationsBloc(
                getNotifications: GetUserNotifications(repo),
                getUnreadCount: GetUnreadCount(repo),
                markRead: MarkNotificationRead(repo),
                deleteNotif: DeleteNotification(repo),
              )..add(const NotificationsStarted()),
              child: const NotificationsScreen(),
            );
          },
        );

      case adminExcelImport:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AdminGate(
            builder: (ctx) {
              final store = ctx.read<AdminTokenStore>();
              final api =
                  ExcelImportApiService(getToken: () => store.getToken());
              final repo = ExcelImportRepositoryImpl(api: api);

              return BlocProvider(
                create: (_) => ExcelImportBloc(
                  validateUc: ValidateExcelFile(repo),
                  importUc: ImportExcelFile(repo),
                ),
                child: const AdminExcelImportScreen(),
              );
            },
          ),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => UserLoginScreen(appConfig: appConfig),
          settings: settings,
        );
    }
  }
}

Widget _forgotFeature({required BuildContext context, required Widget child}) {
  final repo = context.read<ForgotPasswordRepository>();

  return BlocProvider(
    create: (_) => ForgotPasswordBloc(
      sendResetCode: SendResetCode(repo),
      verifyResetCode: VerifyResetCode(repo),
      updatePassword: UpdatePassword(repo),
    ),
    child: child,
  );
}
