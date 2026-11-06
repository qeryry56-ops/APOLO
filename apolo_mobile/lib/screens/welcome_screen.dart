import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../core/state/app_state.dart';
import 'auth_screen.dart';
import 'widgets/app_image.dart';

class WelcomeScreen extends StatelessWidget {
  final VoidCallback? onContinueAsGuest;
  const WelcomeScreen({super.key, this.onContinueAsGuest});

  @override
  Widget build(BuildContext context) {
    final state = AppState();
    final s = state.s;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0F1D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-screen breathtaking background photography
          AppImage(
            url: 'https://images.unsplash.com/photo-1539020140153-e479b8c22e70?auto=format&fit=crop&w=1400&q=85',
            fit: BoxFit.cover,
            fallback: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFE31B23), Color(0xFF090D16)],
                ),
              ),
            ),
          ),

          // 2. Smooth multi-stop dark gradient overlay for crisp text readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.36, 0.66, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.22),
                  Colors.transparent,
                  const Color(0xFF090E17).withValues(alpha: 0.84),
                  const Color(0xFF070B12).withValues(alpha: 0.96),
                ],
              ),
            ),
          ),

          // 3. Top bar: Language switcher & Guest browse button
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => state.toggleLanguage(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(CupertinoIcons.globe, color: Colors.white, size: 15),
                            const SizedBox(width: 6),
                            Text(
                              s.isAr ? 'Français' : 'العربية',
                              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (onContinueAsGuest != null)
                      GestureDetector(
                        onTap: onContinueAsGuest,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            s.tr('تصفح كزائر', 'Explorer'),
                            style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Bottom Content: Official White Apolo Logo + Editorial Headline + Subheadline + Email & Google Pill Buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Official Pure White Apolo Logo
                  Image.asset(
                    'assets/images/apolo_logo_white.png',
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 18),

                  // Headline
                  Text(
                    s.tr('صفقتك القادمة\nتبدأ من هنا', 'Votre prochaine\naffaire commence ici'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Subheadline
                  Text(
                    s.tr(
                      'اكتشف، بيع، وتسوّق آلاف الإعلانات والمتاجر الموثوقة فالمغرب',
                      'Découvrez, vendez et achetez en toute confiance au Maroc',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 14,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button 1: Continue with Email (Apolo Brand Primary Red #E31B23 Pill)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE31B23),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AuthScreen()),
                        ).then((logged) {
                          if (logged == true && onContinueAsGuest != null) {
                            onContinueAsGuest!();
                          }
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.mail, size: 19, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            s.tr('المتابعة بالبريد أو الهاتف', 'Continuer avec Email'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button 2: Continue with Google (Crisp Pure White #FFFFFF Pill)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F1B2D),
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AuthScreen(autoTriggerGoogle: true),
                          ),
                        ).then((logged) {
                          if (logged == true && onContinueAsGuest != null) {
                            onContinueAsGuest!();
                          }
                        });
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(shape: BoxShape.circle),
                            child: const Text(
                              'G',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFEA4335),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            s.tr('المتابعة عبر Google', 'Continuer avec Google'),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F1B2D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Small Terms & Privacy Policy footer
                  Text.rich(
                    TextSpan(
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11.5,
                        height: 1.45,
                      ),
                      children: [
                        TextSpan(
                          text: s.tr('بالمتابعة، فإنك توافق على ', 'En continuant, vous acceptez nos\n'),
                        ),
                        TextSpan(
                          text: s.tr('شروط الاستخدام', 'Conditions d\'utilisation'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: s.tr(' و ', ' et ')),
                        TextSpan(
                          text: s.tr('سياسة الخصوصية', 'Politique de confidentialité'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
