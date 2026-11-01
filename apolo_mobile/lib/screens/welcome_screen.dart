import 'package:flutter/material.dart';
import '../core/state/app_state.dart';
import 'auth_screen.dart';
import 'main_shell.dart';
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
                  colors: [Color(0xFF1E3A8A), Color(0xFF090D16)],
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
                stops: const [0.0, 0.38, 0.68, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.transparent,
                  const Color(0xFF090E17).withValues(alpha: 0.82),
                  const Color(0xFF070B12).withValues(alpha: 0.96),
                ],
              ),
            ),
          ),

          // 3. Top bar: Language switcher & Skip button
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Language toggle pill
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
                            const Icon(Icons.language_rounded, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              s.isAr ? 'Français' : 'العربية',
                              style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Skip / Guest browse pill
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

          // 4. Bottom Content: Editorial Headline + Subheadline + 3 Pill Buttons + Terms
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Headline (2 lines centered, 32px bold, tight letter-spacing like the mockup)
                  Text(
                    s.tr('صفقتك القادمة\nتبدأ من هنا', 'Votre prochaine\naffaire commence ici'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 33,
                      height: 1.18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subheadline
                  Text(
                    s.tr(
                      'اكتشف، بيع، وتسوّق آلاف الإعلانات والمتاجر الموثوقة فالمغرب',
                      'Découvrez, vendez et achetez en toute confiance au Maroc',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontSize: 14.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Button 1: Continue with Email (Ocean Blue #2563EB Pill)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
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
                          const Icon(Icons.mail_outline_rounded, size: 20, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            s.tr('المتابعة بالبريد أو الهاتف', 'Continuer avec Email'),
                            style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button 2: Continue with Google (Crisp White Pill)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1F1F1F),
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
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Button 3: Continue with Apple (Crisp White Pill)
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1F1F1F),
                        elevation: 0,
                        shape: const StadiumBorder(),
                      ),
                      onPressed: () {
                        if (onContinueAsGuest != null) {
                          onContinueAsGuest!();
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const MainShell()),
                          );
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.apple_rounded, size: 24, color: Color(0xFF1F1F1F)),
                          const SizedBox(width: 8),
                          Text(
                            s.tr('المتابعة عبر Apple', 'Continuer avec Apple'),
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F1F1F),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Small Terms & Privacy Policy footer
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
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
                            color: Color(0xFF60A5FA),
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                        TextSpan(text: s.tr(' و ', ' et ')),
                        TextSpan(
                          text: s.tr('سياسة الخصوصية', 'Politique de confidentialité'),
                          style: const TextStyle(
                            color: Color(0xFF60A5FA),
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
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
