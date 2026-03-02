import 'dart:async';

import 'package:build4front/core/network/globals.dart' as net;
import 'package:build4front/core/theme/theme_cubit.dart';
import 'package:build4front/features/home/homebanner/domain/data/services/home_banners_api_service.dart';
import 'package:build4front/features/home/homebanner/domain/entities/home_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class HomeBannerSlider extends StatefulWidget {
  final String token;

  final void Function(HomeBanner banner)? onBannerTap;

  final int cacheBuster;

  const HomeBannerSlider({
    super.key,
    required this.token,
    this.onBannerTap,
    this.cacheBuster = 0,
  });

  @override
  State<HomeBannerSlider> createState() => _HomeBannerSliderState();
}

class _HomeBannerSliderState extends State<HomeBannerSlider> {
  late final HomeBannersApiService _service;
  late final PageController _pageController;

  List<HomeBanner> _banners = [];
  bool _isLoading = true;
  String? _error;
  int _currentIndex = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _service = HomeBannersApiService.create();
    _pageController = PageController();
    _load();
  }

  @override
  void didUpdateWidget(covariant HomeBannerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token ||
        oldWidget.cacheBuster != widget.cacheBuster) {
      _load();
    }
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _service.fetchActiveBanners(token: widget.token);

      if (!mounted) return;

      setState(() {
        _banners = list.map((e) => HomeBanner.fromJson(e)).toList();
        _isLoading = false;
        _currentIndex = 0;
      });

      _setupAutoSlide();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _setupAutoSlide() {
    _autoSlideTimer?.cancel();
    if (_banners.length <= 1) return;

    _autoSlideTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || _banners.isEmpty) return;

      final nextIndex = (_currentIndex + 1) % _banners.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
      );
    });
  }

  String _withCacheBuster(String url) {
    final cb = widget.cacheBuster;
    if (cb == 0) return url;
    return url.contains('?') ? '$url&cb=$cb' : '$url?cb=$cb';
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final spacing = context.read<ThemeCubit>().state.tokens.spacing;

    if (_isLoading) {
      return Container(
        margin: EdgeInsets.only(bottom: spacing.lg),
        height: 170,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Container(
        margin: EdgeInsets.only(bottom: spacing.lg),
        padding: EdgeInsets.all(spacing.md),
        decoration: BoxDecoration(
          color: c.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: c.onErrorContainer),
            SizedBox(width: spacing.sm),
            Expanded(
              child: Text(
                'Failed to load banners',
                style: t.bodyMedium?.copyWith(color: c.onErrorContainer),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh, color: c.onErrorContainer),
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    if (_banners.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.only(bottom: spacing.lg),
      height: 170,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _banners.length,
            onPageChanged: (i) {
              if (!mounted) return;
              setState(() => _currentIndex = i);
            },
            itemBuilder: (_, i) {
              final banner = _banners[i];

              final resolved = net.resolveUrl(banner.imageUrl);
              final imageUrl = _withCacheBuster(resolved);

              return GestureDetector(
                onTap: () => widget.onBannerTap?.call(banner),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: c.surfaceVariant,
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: c.onSurfaceVariant,
                            size: 32,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withOpacity(0.05),
                              Colors.black.withOpacity(0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                      Positioned(
                        left: spacing.lg,
                        right: spacing.lg,
                        bottom: spacing.lg,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((banner.title ?? '').trim().isNotEmpty)
                              Text(
                                banner.title!.trim(),
                                style: t.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            if ((banner.subtitle ?? '').trim().isNotEmpty) ...[
                              SizedBox(height: spacing.xs),
                              Text(
                                banner.subtitle!.trim(),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: t.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: spacing.sm,
            right: spacing.lg,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_banners.length, (i) {
                final active = i == _currentIndex;
                return Container(
                  margin: EdgeInsets.only(left: i == 0 ? 0 : 4),
                  width: active ? 10 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(999),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}