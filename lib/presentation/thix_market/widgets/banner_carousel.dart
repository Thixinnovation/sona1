import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/banner.dart';

class BannerCarousel extends StatefulWidget {
  final List<BannerAd> banners;
  final Duration interval;

  const BannerCarousel({
    super.key,
    required this.banners,
    this.interval = const Duration(seconds: 5),
  });

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    if (widget.banners.length > 1) {
      _timer = Timer.periodic(widget.interval, (timer) {
        if (_currentPage + 1 < widget.banners.length) {
          _pageController.nextPage(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else {
          _pageController.animateToPage(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) {
      return _buildDefaultBanner();
    }

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              final banner = widget.banners[index];
              return _BannerCard(banner: banner);
            },
          ),
        ),
        const SizedBox(height: 8),
        if (widget.banners.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.banners.length, (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index ? const Color(0xFFD4AF37) : Colors.grey.shade300,
              ),
            )),
          ),
      ],
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      height: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0B1B3D), Color(0xFF1A2D56)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'THIX SERVICES',
                  style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Découvrez tous nos services',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Une plateforme complète pour vous accompagner',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward, color: Color(0xFFD4AF37), size: 30),
        ],
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerAd banner;
  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (banner.buttonLink != null && banner.buttonLink!.isNotEmpty) {
          context.push(banner.buttonLink!);
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [banner.backgroundColor, banner.backgroundColor.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            if (banner.imageUrl.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.15,
                  child: Image.network(banner.imageUrl, fit: BoxFit.cover),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          banner.title,
                          style: TextStyle(color: banner.textColor, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          banner.subtitle,
                          style: TextStyle(color: banner.textColor.withOpacity(0.9), fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: banner.textColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            banner.buttonText,
                            style: TextStyle(color: banner.backgroundColor, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward, color: Colors.white, size: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
