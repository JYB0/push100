import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static bool isRewardedAdLoaded = false;
  static RewardedAd? _rewardedAd;

  // 보상형 광고 ID
  static String get rewardedAdUnitId {
    bool isTestMode = dotenv.env['USE_TEST_ADS'] == 'true';

    if (Platform.isAndroid) {
      return isTestMode
          ? dotenv.env['ANDROID_TEST_REWARDED_AD_ID'] ?? ''
          : dotenv.env['ANDROID_REWARDED_AD_ID'] ?? '';
    } else if (Platform.isIOS) {
      return isTestMode
          ? dotenv.env['IOS_TEST_REWARDED_AD_ID'] ?? ''
          : dotenv.env['IOS_REWARDED_AD_ID'] ?? '';
    } else {
      return '';
    }
  }

  static void loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          isRewardedAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          isRewardedAdLoaded = false;
        },
      ),
    );
  }

  static void showRewardedAd(Function onRewardEarned) {
    if (_rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) {
          // 광고가 닫혔을 때 실행
          ad.dispose();
          _rewardedAd = null;
          isRewardedAdLoaded = false;
          loadRewardedAd(); // 다음 광고 로드
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) {
          // 광고가 정상적으로 실행되지 못했을 때 실행
          ad.dispose();
          _rewardedAd = null;
          isRewardedAdLoaded = false;
          loadRewardedAd(); // 다시 광고 로드
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          onRewardEarned(); // ✅ 보상을 지급하는 함수 호출
        },
      );
    } else {
      loadRewardedAd(); // 없으면 다시 로드
    }
  }
}
