import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'connection_cubit.dart';
import 'connection_status.dart';

class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context)!;

    return BlocBuilder<ConnectionCubit, ConnectionStateModel>(
      builder: (context, state) {
        if (state.status == ConnectionStatus.online) {
          return const SizedBox.shrink();
        }

        late final Color backgroundColor;
        late final String text;
        late final IconData icon;
        final bool showSpinner = state.status == ConnectionStatus.serverDown;

        switch (state.status) {
          case ConnectionStatus.offline:
            backgroundColor = const Color(0xFFD32F2F);
            text = l10n.connection_offline;
            icon = Icons.wifi_off_rounded;
            break;

          case ConnectionStatus.serverDown:
            backgroundColor = const Color(0xFFE68A00);
            text = l10n.connection_reconnecting;
            icon = Icons.sync_rounded;
            break;

          case ConnectionStatus.online:
            return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: double.infinity,
          color: backgroundColor,
          child: SafeArea(
            bottom: false,
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  if (showSpinner)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
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
                      style: textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}