import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// バナー広告の共通ウィジェット
/// isSubscriber が true の場合は広告を表示しない
class BannerAdWidget extends StatefulWidget {
  final bool isSubscriber;

  const BannerAdWidget({super.key, required this.isSubscriber});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isSubscriber) {
      _loadAd();
    }
  }

  void _loadAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111',
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('バナー広告のロードに失敗: $error');
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 課金者は広告を表示しない
    if (widget.isSubscriber) {
      return const SizedBox.shrink();
    }

    // 広告がロードされていない場合は空のスペース
    if (!_isAdLoaded || _bannerAd == null) {
      return SizedBox(
        height: AdSize.banner.height.toDouble(),
      );
    }

    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
