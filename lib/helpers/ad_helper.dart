import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdHelper {
  static bool isRewardedAdLoaded = false;
  static RewardedAd? _rewardedAd;

  static bool isInterstitialAdLoaded = false;
  static InterstitialAd? _interstitialAd;

  static bool isRewardedInterstitialAdLoaded = false;
  static RewardedInterstitialAd? _rewardedInterstitialAd;

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

  static List<String> get adaptiveBannerAdUnitIds {
    bool isTestMode = dotenv.env['USE_TEST_ADS'] == 'true';

    if (Platform.isAndroid) {
      return isTestMode
          ? [dotenv.env['ANDROID_TEST_ADAPTIVE_BANNER_AD_ID'] ?? '']
          : [
              dotenv.env['ANDROID_ADAPTIVE_BANNER_AD_ID1'] ?? '',
              dotenv.env['ANDROID_ADAPTIVE_BANNER_AD_ID2'] ?? '',
              dotenv.env['ANDROID_ADAPTIVE_BANNER_AD_ID3'] ?? '',
            ];
    } else if (Platform.isIOS) {
      return isTestMode
          ? [dotenv.env['IOS_TEST_ADAPTIVE_BANNER_AD_ID'] ?? '']
          : [
              dotenv.env['IOS_ADAPTIVE_BANNER_AD_ID1'] ?? '',
              dotenv.env['IOS_ADAPTIVE_BANNER_AD_ID2'] ?? '',
              dotenv.env['IOS_ADAPTIVE_BANNER_AD_ID3'] ?? '',
            ];
    } else {
      return [''];
    }
  }

  static String get nativeAdUnitId {
    bool isTestMode = dotenv.env['USE_TEST_ADS'] == 'true';

    if (Platform.isAndroid) {
      return isTestMode
          ? dotenv.env['ANDROID_TEST_NATIVE_AD_ID'] ?? ''
          : dotenv.env['ANDROID_NATIVE_AD_ID'] ?? '';
    } else if (Platform.isIOS) {
      return isTestMode
          ? dotenv.env['IOS_TEST_NATIVE_AD_ID'] ?? ''
          : dotenv.env['IOS_NATIVE_AD_ID'] ?? '';
    } else {
      return '';
    }
  }

  static String get interstitialAdUnitId {
    bool isTestMode = dotenv.env['USE_TEST_ADS'] == 'true';

    if (Platform.isAndroid) {
      return isTestMode
          ? dotenv.env['ANDROID_TEST_INTERSTITIAL_AD_ID'] ?? ''
          : dotenv.env['ANDROID_INTERSTITIAL_AD_ID'] ?? '';
    } else if (Platform.isIOS) {
      return isTestMode
          ? dotenv.env['IOS_TEST_INTERSTITIAL_AD_ID'] ?? ''
          : dotenv.env['IOS_INTERSTITIAL_AD_ID'] ?? '';
    } else {
      return '';
    }
  }

  static String get rewardedInterstitialAdUnitId {
    bool isTestMode = dotenv.env['USE_TEST_ADS'] == 'true';

    if (Platform.isAndroid) {
      return isTestMode
          ? dotenv.env['ANDROID_TEST_REWARDEDINTERSTITIAL_AD_ID'] ?? ''
          : dotenv.env['ANDROID_REWARDEDINTERSTITIAL_AD_ID'] ?? '';
    } else if (Platform.isIOS) {
      return isTestMode
          ? dotenv.env['IOS_TEST_REWARDEDINTERSTITIAL_AD_ID'] ?? ''
          : dotenv.env['IOS_REWARDEDINTERSTITIAL_AD_ID'] ?? '';
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

  static void loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          isInterstitialAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          isInterstitialAdLoaded = false;
        },
      ),
    );
  }

  // ✅ 전면 광고 보여주기
  static void showInterstitialAd({void Function()? onAdDismissed}) {
    if (_interstitialAd != null) {
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _interstitialAd = null;
          isInterstitialAdLoaded = false;
          loadInterstitialAd();
          onAdDismissed?.call();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _interstitialAd = null;
          isInterstitialAdLoaded = false;
          loadInterstitialAd();
        },
      );

      _interstitialAd!.show();
    } else {
      loadInterstitialAd();
    }
  }

  static void loadRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
      adUnitId: rewardedInterstitialAdUnitId,
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedInterstitialAd = ad;
          isRewardedInterstitialAdLoaded = true;
        },
        onAdFailedToLoad: (error) {
          _rewardedInterstitialAd = null;
          isRewardedInterstitialAdLoaded = false;
        },
      ),
    );
  }

  // ✅ 보상형 전면 광고 보여주기
  static void showRewardedInterstitialAd(Function onRewardEarned) {
    if (_rewardedInterstitialAd != null) {
      _rewardedInterstitialAd!.fullScreenContentCallback =
          FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          isRewardedInterstitialAdLoaded = false; // 광고가 시작되었으니 false로 설정
        },
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _rewardedInterstitialAd = null;
          loadRewardedInterstitialAd(); // 광고 닫히면 새로 로드
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _rewardedInterstitialAd = null;
          loadRewardedInterstitialAd();
        },
      );

      _rewardedInterstitialAd!.show(
        onUserEarnedReward: (ad, reward) {
          onRewardEarned();
        },
      );

      _rewardedInterstitialAd = null; // 재사용 방지
      isRewardedInterstitialAdLoaded = false;
    } else {
      loadRewardedInterstitialAd();
    }
  }
}
