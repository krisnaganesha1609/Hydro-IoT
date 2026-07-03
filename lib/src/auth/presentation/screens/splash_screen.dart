import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

import '../../../../pkg.dart';
import 'landing_screen.dart';

// ─── Brand tokens (sesuaikan kalau ada perubahan warna) ───────────────────────
const _kBg = Color(0xFFFFFFFF);
const _kGreen900 = Color(0xFF1B4332); // gelap untuk teks utama
const _kGreen500 = Color(0xFF40916C); // brand utama
const _kGreen300 = Color(0xFF74C69D); // accent soft
const _kTextSub = Color(0xFF4A5568);
const _kTextVer = Color(0xFF94A3B8);
const _kRing1 = Color(0x2640916C); // green500 @ ~15%
const _kRing2 = Color(0x1A1B4332); // green900 @ ~10%

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  static const String path = 'splash';

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  // 1. Logo bounce in
  late final AnimationController _enterCtrl;
  late final Animation<double> _logoEnterScale;

  // 2. Orbit rings
  late final AnimationController _ringCtrl;
  late final Animation<double> _ring1Scale, _ring1Opacity;
  late final Animation<double> _ring2Scale, _ring2Opacity;

  // 3. Shadow pulse (continuous)
  late final AnimationController _shadowCtrl;

  // 4. Text + progress bar enter
  late final AnimationController _textEnterCtrl;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  // 5. Loading bar
  late final AnimationController _progressCtrl;

  // 6. Exit env (fade out rings / bg decoration)
  late final AnimationController _exitEnvCtrl;
  late final Animation<double> _exitEnvOpacity;

  // 7. Logo exit (scale up + fade)
  late final AnimationController _logoExitCtrl;
  late final Animation<double> _logoExitScale, _logoExitOpacity;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(statusBarColor: Colors.transparent, statusBarIconBrightness: Brightness.dark));

    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 560));
    _logoEnterScale = Tween<double>(begin: 0.76, end: 1.0).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutBack));

    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _ring1Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
      ),
    );
    _ring1Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _ring2Scale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.22, 0.88, curve: Curves.easeOutCubic),
      ),
    );
    _ring2Opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ringCtrl,
        curve: const Interval(0.22, 0.55, curve: Curves.easeOut),
      ),
    );

    _shadowCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 3000))..repeat(reverse: true);

    _textEnterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 480));
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _textEnterCtrl, curve: Curves.easeOut));
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.28),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textEnterCtrl, curve: Curves.easeOutCubic));

    _progressCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2100));

    _exitEnvCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _exitEnvOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(parent: _exitEnvCtrl, curve: Curves.easeIn));

    _logoExitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 460));
    _logoExitScale = Tween<double>(begin: 1.0, end: 1.88).animate(CurvedAnimation(parent: _logoExitCtrl, curve: Curves.easeIn));
    _logoExitOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _logoExitCtrl,
        curve: const Interval(0.08, 0.92, curve: Curves.easeIn),
      ),
    );

    _runSequence();
  }

  Future<void> _runSequence() async {
    _enterCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    _ringCtrl.forward();

    await Future.delayed(const Duration(milliseconds: 680));
    if (!mounted) return;
    _textEnterCtrl.forward();
    _progressCtrl.forward();

    // Sambil animasi jalan, cek session di background
    final destination = await _resolveDestination();

    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    _exitEnvCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    await _logoExitCtrl.forward();
    if (!mounted) return;

    // GoRouter — context.go menggantikan pushReplacement.
    // Curtain transition (white slide up) didefinisikan via CustomTransitionPage
    // di routes.dart. Lihat snippet di bawah file ini.
    context.go(destination);
  }

  /// Cek token + login state, return path tujuan
  String _resolveDestination() {
    return '/${LandingScreen.path}';
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _ringCtrl.dispose();
    _shadowCtrl.dispose();
    _textEnterCtrl.dispose();
    _progressCtrl.dispose();
    _exitEnvCtrl.dispose();
    _logoExitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // ── 1. Dot pattern background ─────────────────────────────────
          const _DotGrid(),

          // ── 2. Accent arc kanan bawah ─────────────────────────────────
          Positioned(
            right: -size.width * 0.22,
            bottom: -size.width * 0.22,
            child: AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, __) => Opacity(
                opacity: (_ring2Opacity.value * _exitEnvOpacity.value) * 0.55,
                child: Transform.scale(
                  scale: _ring2Scale.value,
                  child: Container(
                    width: size.width * 0.82,
                    height: size.width * 0.82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _kGreen300.withOpacity(0.28), width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 3. Accent arc kiri atas ───────────────────────────────────
          Positioned(
            left: -size.width * 0.28,
            top: -size.width * 0.28,
            child: AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, __) => Opacity(
                opacity: (_ring1Opacity.value * _exitEnvOpacity.value) * 0.4,
                child: Transform.scale(
                  scale: _ring1Scale.value,
                  child: Container(
                    width: size.width * 0.82,
                    height: size.width * 0.82,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _kGreen900.withOpacity(0.18), width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── 4. Orbit ring 1 (inner) ───────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_ringCtrl, _exitEnvCtrl]),
            builder: (_, __) => Center(
              child: Opacity(
                opacity: _ring1Opacity.value * _exitEnvOpacity.value,
                child: Transform.scale(
                  scale: _ring1Scale.value,
                  child: _OrbitRing(diameter: size.width * 0.60, color: _kRing1, strokeWidth: 1.2),
                ),
              ),
            ),
          ),

          // ── 5. Orbit ring 2 (outer) ───────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_ringCtrl, _exitEnvCtrl]),
            builder: (_, __) => Center(
              child: Opacity(
                opacity: _ring2Opacity.value * _exitEnvOpacity.value,
                child: Transform.scale(
                  scale: _ring2Scale.value,
                  child: _OrbitRing(diameter: size.width * 0.84, color: _kRing2, strokeWidth: 1.0),
                ),
              ),
            ),
          ),

          // ── 6. Logo ───────────────────────────────────────────────────
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_enterCtrl, _logoExitCtrl, _shadowCtrl]),
              builder: (_, __) => Transform.scale(
                scale: _logoEnterScale.value * _logoExitScale.value,
                child: Opacity(
                  opacity: _logoExitOpacity.value,
                  child: Container(
                    width: 138,
                    height: 138,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Shadow pulse menggunakan _shadowCtrl
                      boxShadow: [
                        BoxShadow(
                          color: _kGreen500.withOpacity(0.10 + _shadowCtrl.value * 0.14),
                          blurRadius: 24 + _shadowCtrl.value * 16,
                          spreadRadius: 2 + _shadowCtrl.value * 4,
                        ),
                      ],
                    ),
                    child: ClipOval(child: Image.asset('assets/img/splash.png', width: 138, height: 138, fit: BoxFit.contain)),
                  ),
                ),
              ),
            ),
          ),

          // ── 7. Text block + progress bar ──────────────────────────────
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedBuilder(
              animation: Listenable.merge([_textEnterCtrl, _exitEnvCtrl]),
              builder: (_, child) => FadeTransition(
                opacity: _textOpacity,
                child: SlideTransition(
                  position: _textSlide,
                  child: Opacity(opacity: _exitEnvOpacity.value, child: child),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 58),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // App name
                    Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: _kGreen900, letterSpacing: 1.6, height: 1.3),
                    ),
                    const SizedBox(height: 10),

                    // Divider accent (green gradient)
                    Container(
                      width: 48,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        gradient: LinearGradient(colors: [Colors.transparent, _kGreen500.withOpacity(0.75), Colors.transparent]),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tagline
                    Text(
                      AppStrings.appDescription,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w400, color: _kTextSub, letterSpacing: 0.2, height: 1.7),
                    ),
                    const SizedBox(height: 26),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: SizedBox(
                        width: 56,
                        height: 2.5,
                        child: AnimatedBuilder(
                          animation: _progressCtrl,
                          builder: (_, __) => LinearProgressIndicator(
                            value: _progressCtrl.value,
                            backgroundColor: _kGreen500.withOpacity(0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(_kGreen500.withOpacity(0.65)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Version
                    Text(
                      'Versi ${AppStrings.appVersion}',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w300, color: _kTextVer, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  ORBIT RING
// ═══════════════════════════════════════════════════════════════════════════════
class _OrbitRing extends StatelessWidget {
  final double diameter;
  final Color color;
  final double strokeWidth;

  const _OrbitRing({required this.diameter, required this.color, this.strokeWidth = 1.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: strokeWidth),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  DOT GRID
// ═══════════════════════════════════════════════════════════════════════════════
class _DotGrid extends StatelessWidget {
  const _DotGrid();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: _DotGridPainter(), child: const SizedBox.expand()),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF40916C).withOpacity(0.05)
      ..style = PaintingStyle.fill;

    const spacing = 28.0;
    const radius = 1.6;

    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
