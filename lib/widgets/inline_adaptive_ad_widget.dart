import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
// import 'package:push100/helpers/ad_helper.dart';

class InlineAdaptiveAdWidget extends StatefulWidget {
  final String adUnitId;

  const InlineAdaptiveAdWidget({super.key, required this.adUnitId});

  @override
  State<InlineAdaptiveAdWidget> createState() => _InlineAdaptiveAdWidgetState();
}

class _InlineAdaptiveAdWidgetState extends State<InlineAdaptiveAdWidget> {
  BannerAd? _ad;
  bool _isLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadAd();
  }

  void _loadAd() async {
    final adSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.truncate(),
    );

    if (adSize == null) return;

    final ad = BannerAd(
      adUnitId: widget.adUnitId,
      size: adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => setState(() => _isLoaded = true),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          debugPrint('광고 로딩 실패: $error');
        },
      ),
    );

    await ad.load();
    setState(() => _ad = ad);
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _ad == null) return const SizedBox();
    return Container(
      alignment: Alignment.center,
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
