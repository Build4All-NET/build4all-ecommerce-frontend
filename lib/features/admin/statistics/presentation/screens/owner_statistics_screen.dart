import 'package:build4front/common/widgets/app_toast.dart';
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/owner_statistics_cubit.dart';
import '../widgets/owner_stat_tile.dart';
import '../widgets/owner_user_card.dart';
import '../widgets/owner_user_contact_sheet.dart';

/// The owner's audience at a glance: how many people installed the app, and
/// every one of them with the email/phone needed to reach out.
class OwnerStatisticsScreen extends StatefulWidget {
  const OwnerStatisticsScreen({super.key});

  @override
  State<OwnerStatisticsScreen> createState() => _OwnerStatisticsScreenState();
}

class _OwnerStatisticsScreenState extends State<OwnerStatisticsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<OwnerStatisticsCubit>().load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: Text(
          l10n.adminStatisticsTitle,
          style: tokens.typography.titleMedium.copyWith(
            color: colors.label,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            tooltip: l10n.adminStatisticsRefresh,
            onPressed: () =>
                context.read<OwnerStatisticsCubit>().load(refresh: true),
            icon: Icon(Icons.refresh_rounded, color: colors.body),
          ),
        ],
      ),
      body: BlocConsumer<OwnerStatisticsCubit, OwnerStatisticsState>(
        listenWhen: (prev, next) =>
            next.error != null && next.status == OwnerStatisticsStatus.loaded,
        listener: (context, state) {
          // Only surfaced as a toast when content is still on screen; a failed
          // first load gets the full error state below instead.
          AppToast.error(context, state.error!);
          context.read<OwnerStatisticsCubit>().clearError();
        },
        builder: (context, state) {
          if (state.status == OwnerStatisticsStatus.loading ||
              state.status == OwnerStatisticsStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == OwnerStatisticsStatus.error) {
            return _ErrorView(
              message: state.error ?? l10n.adminStatisticsLoadFailed,
              onRetry: () => context.read<OwnerStatisticsCubit>().load(),
            );
          }

          final stats = state.statistics;
          final users = state.visibleUsers;

          return RefreshIndicator(
            onRefresh: () =>
                context.read<OwnerStatisticsCubit>().load(refresh: true),
            child: CustomScrollView(
              // Keeps pull-to-refresh working on a short list.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    spacing.md,
                    spacing.md,
                    spacing.md,
                    spacing.sm,
                  ),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 220,
                      mainAxisExtent: 126,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    delegate: SliverChildListDelegate([
                      OwnerStatTile(
                        icon: Icons.groups_outlined,
                        label: l10n.adminStatisticsTotalUsers,
                        value: '${stats.totalUsers}',
                        accent: colors.primary,
                      ),
                      OwnerStatTile(
                        icon: Icons.person_outline,
                        label: l10n.adminStatisticsActiveUsers,
                        value: '${stats.activeUsers}',
                      ),
                      OwnerStatTile(
                        icon: Icons.verified_outlined,
                        label: l10n.adminStatisticsVerifiedUsers,
                        value: '${stats.verifiedUsers}',
                      ),
                      OwnerStatTile(
                        icon: Icons.person_add_alt_outlined,
                        label: l10n.adminStatisticsNewLast7Days,
                        value: '${stats.newUsersLast7Days}',
                        accent: colors.success,
                      ),
                      OwnerStatTile(
                        icon: Icons.calendar_month_outlined,
                        label: l10n.adminStatisticsNewLast30Days,
                        value: '${stats.newUsersLast30Days}',
                      ),
                      OwnerStatTile(
                        icon: Icons.login_outlined,
                        label: l10n.adminStatisticsActiveLast30Days,
                        value: '${stats.activeLast30Days}',
                      ),
                    ]),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: spacing.md),
                    child: _ReachabilityCard(
                      reachable: stats.reachableUsers,
                      total: stats.totalUsers,
                      withEmail: stats.withEmail,
                      withPhone: stats.withPhone,
                      rate: stats.reachableRate,
                    ),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.md,
                      spacing.lg,
                      spacing.md,
                      spacing.sm,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            l10n.adminStatisticsUsersSectionTitle,
                            style: tokens.typography.titleMedium.copyWith(
                              color: colors.label,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Text(
                          '${users.length}',
                          style: tokens.typography.bodySmall.copyWith(
                            color: colors.muted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (stats.totalUsers > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: spacing.md),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) =>
                            context.read<OwnerStatisticsCubit>().search(v),
                        style: tokens.typography.bodyMedium
                            .copyWith(color: colors.label),
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: l10n.adminStatisticsSearchHint,
                          hintStyle: tokens.typography.bodySmall
                              .copyWith(color: colors.muted),
                          prefixIcon:
                              Icon(Icons.search_rounded, color: colors.muted),
                          suffixIcon: state.query.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<OwnerStatisticsCubit>()
                                        .search('');
                                  },
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: colors.muted,
                                  ),
                                ),
                          filled: true,
                          fillColor: colors.surface,
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(tokens.search.radius),
                            borderSide: BorderSide(
                              color: colors.border.withOpacity(0.22),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(tokens.search.radius),
                            borderSide: BorderSide(
                              color: colors.border.withOpacity(0.22),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(tokens.search.radius),
                            borderSide: BorderSide(color: colors.primary),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (users.isEmpty)
                  SliverToBoxAdapter(
                    child: _EmptyView(
                      message: stats.isEmpty
                          ? l10n.adminStatisticsEmpty
                          : l10n.adminStatisticsNoSearchResults,
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      spacing.md,
                      spacing.sm,
                      spacing.md,
                      spacing.xl,
                    ),
                    sliver: SliverList.separated(
                      itemCount: users.length,
                      separatorBuilder: (_, __) => SizedBox(height: spacing.sm),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return OwnerUserCard(
                          user: user,
                          onTap: () => showOwnerUserContactSheet(context, user),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// How much of the audience the owner can actually reach — the number that
/// decides whether the list below is useful to them at all.
class _ReachabilityCard extends StatelessWidget {
  final int reachable;
  final int total;
  final int withEmail;
  final int withPhone;
  final double rate;

  const _ReachabilityCard({
    required this.reachable,
    required this.total,
    required this.withEmail,
    required this.withPhone,
    required this.rate,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(tokens.card.radius),
        border: Border.all(color: colors.border.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.adminStatisticsReachableTitle,
                  style: tokens.typography.bodyMedium.copyWith(
                    color: colors.label,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$reachable/$total',
                style: tokens.typography.bodySmall.copyWith(
                  color: colors.muted,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: rate,
              minHeight: 8,
              backgroundColor: colors.border.withOpacity(0.25),
              valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
            ),
          ),
          SizedBox(height: spacing.sm),
          Row(
            children: [
              Icon(Icons.mail_outline_rounded, size: 16, color: colors.muted),
              const SizedBox(width: 6),
              Text(
                l10n.adminStatisticsWithEmail(withEmail),
                style:
                    tokens.typography.bodySmall.copyWith(color: colors.muted),
              ),
              SizedBox(width: spacing.md),
              Icon(Icons.call_outlined, size: 16, color: colors.muted),
              const SizedBox(width: 6),
              Text(
                l10n.adminStatisticsWithPhone(withPhone),
                style:
                    tokens.typography.bodySmall.copyWith(color: colors.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;

  const _EmptyView({required this.message});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;

    return Padding(
      padding: EdgeInsets.all(spacing.xl),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 42, color: colors.muted),
          SizedBox(height: spacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: tokens.typography.bodyMedium.copyWith(color: colors.muted),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final tokens = context.watch<ThemeCubit>().state.tokens;
    final colors = tokens.colors;
    final spacing = tokens.spacing;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 42, color: colors.error),
            SizedBox(height: spacing.md),
            Text(
              message,
              textAlign: TextAlign.center,
              style: tokens.typography.bodyMedium.copyWith(color: colors.body),
            ),
            SizedBox(height: spacing.md),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(l10n.adminStatisticsRetry),
            ),
          ],
        ),
      ),
    );
  }
}
