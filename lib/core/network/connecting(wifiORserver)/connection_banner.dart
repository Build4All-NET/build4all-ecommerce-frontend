// lib/core/network/connecting(wifiORserver)/connection_banner.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connection_cubit.dart';
import 'connection_status.dart';
import 'package:build4front/l10n/app_localizations.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = AppLocalizations.of(context)!;

    return BlocBuilder<ConnectionCubit, ConnectionStateModel>(
      builder: (context, state) {
        if (state.status == ConnectionStatus.online) {
          return const SizedBox.shrink();
        }

        Color bg;
        String text;
        IconData icon;

        switch (state.status) {
          case ConnectionStatus.offline:
            bg = const Color(0xFFD32F2F);
            text = l.connection_offline;
            icon = Icons.wifi_off_rounded;
            break;

          case ConnectionStatus.serverDown:
            bg = const Color(0xFFE68A00);
            text = l.connection_reconnecting;
            icon = Icons.sync_rounded;
            break;

          default:
            bg = const Color(0xFFE68A00);
            text = l.connection_issue;
            icon = Icons.info_outline_rounded;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          color: bg,
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              child:Row(
  children: [
    if (state.status == ConnectionStatus.serverDown)
      const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      )
    else
      Icon(icon, color: Colors.white, size: 18),

    const SizedBox(width: 8),

    Expanded(
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: t.bodyMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  ],
)
            ),
          ),
        );
      },
    );
  }
}