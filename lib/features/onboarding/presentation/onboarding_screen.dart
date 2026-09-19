import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/marina_theme.dart';
import '../../../shared/widgets/common.dart';

class OnboardingStore {
  static const _storage = FlutterSecureStorage(),
      _key = 'marina_onboarding_complete_v1';
  static Future<bool> isComplete() async =>
      await _storage.read(key: _key) == 'true';
  static Future<void> complete() => _storage.write(key: _key, value: 'true');
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  static const pages = [
    (
      en: 'Welcome to MARINA',
      ar: 'مرحباً بك في مارينا',
      enBody: 'Premium products and a seamless shopping experience.',
      arBody: 'منتجات مختارة بعناية وتجربة تسوق راقية.',
      asset: 'assets/visuals/onboarding-arrival.png',
    ),
    (
      en: 'Premium Quality',
      ar: 'جودة تستحقها',
      enBody: 'Carefully selected products with quality you can trust.',
      arBody: 'منتجات مختارة بعناية لتمنحك الجودة والأناقة في كل اختيار.',
      asset: 'assets/visuals/onboarding-quality.png',
    ),
    (
      en: 'Secure & Fast',
      ar: 'تسوق آمن وسريع',
      enBody: 'Smooth shopping, secure payments, and fast delivery.',
      arBody: 'تجربة شراء سلسة، دفع آمن، وتوصيل سريع.',
      asset: 'assets/visuals/onboarding-secure-delivery.png',
    ),
  ];

  bool get arabic => Localizations.localeOf(context).languageCode == 'ar';

  Future<void> finish() async {
    await OnboardingStore.complete();
    if (mounted) context.go('/welcome');
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
    backgroundColor: MarinaColors.midnight,
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -.7),
          radius: 1.25,
          colors: [Color(0xFF1A2438), MarinaColors.midnight],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 14, 0),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/branding/marina_mark_light.svg',
                    width: 38,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: finish,
                    child: Text(
                      arabic ? 'تخطي' : 'Skip',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: controller,
                itemCount: 3,
                onPageChanged: (v) => setState(() => page = v),
                itemBuilder: (_, i) =>
                    _OnboardingPage(data: pages[i], arabic: arabic),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      3,
                      (i) => AnimatedContainer(
                        duration: MarinaMotion.normal,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == page ? 26 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          gradient:
                              i == page ? MarinaGradients.gold : null,
                          color: i == page ? null : Colors.white24,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (page > 0)
                        TextButton(
                          onPressed: () => controller.previousPage(
                            duration: MarinaMotion.slow,
                            curve: Curves.easeOutCubic,
                          ),
                          child: Text(
                            arabic ? 'السابق' : 'Back',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ),
                      if (page > 0) const SizedBox(width: 10),
                      Expanded(
                        child: MarinaGoldButton(
                          label: page == 2
                              ? (arabic ? 'ابدأ الآن' : 'Get Started')
                              : (arabic ? 'التالي' : 'Next'),
                          icon: page == 2 ? Icons.storefront_rounded : null,
                          onPressed: page == 2
                              ? finish
                              : () => controller.nextPage(
                                  duration: MarinaMotion.slow,
                                  curve: Curves.easeOutCubic,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    ),
  );
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data, required this.arabic});

  final ({String en, String ar, String enBody, String arBody, String asset})
  data;
  final bool arabic;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final visual = (c.maxHeight * .53).clamp(250.0, 440.0);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            SizedBox(
              height: visual,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(data.asset, fit: BoxFit.cover),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x00070B12),
                              Color(0x12070B12),
                              Color(0xB3070B12),
                            ],
                            stops: [0, .66, 1],
                          ),
                        ),
                      ),
                      PositionedDirectional(
                        bottom: 12,
                        end: 12,
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: .12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .25),
                            ),
                          ),
                          child: const Icon(
                            Icons.sailing_rounded,
                            size: 17,
                            color: MarinaColors.goldBright,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Text(
              arabic ? data.ar : data.en,
              textAlign: TextAlign.center,
              style: MarinaType.display(context, size: 28, color: Colors.white),
            ),
            const SizedBox(height: 12),
            const GoldDivider(width: 110),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Text(
                arabic ? data.arBody : data.enBody,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFB9C8D9),
                  fontSize: 15.5,
                  height: 1.55,
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
