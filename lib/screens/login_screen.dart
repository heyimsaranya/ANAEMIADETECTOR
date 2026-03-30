import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

// ══════════════════════════════════════════════════════════════════
//  HemoScan — Login Screen
//  Layout  : Full-screen dark navy
//  Card    : Left half = project title + clinical modules list
//            Right half = asset image (doctor assessing patient)
//                         + animated scan-line + typewriter on hover
//  Footer  : Medical disclaimer
//  Zero emojis — pure clinical text
// ══════════════════════════════════════════════════════════════════

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {

  late final AnimationController _bgCtrl;
  late final AnimationController _ecgCtrl;
  late final AnimationController _entryCtrl;
  late final AnimationController _pulseCtrl;
  late final AnimationController _scanCtrl;
  late final AnimationController _typeCtrl;

  late final Animation<double> _fadeCard;
  late final Animation<Offset> _slideCard;
  late final Animation<double> _fadeLogo;
  late final Animation<double> _fadeText;
  late final Animation<double> _fadeBtn;
  late final Animation<double> _pulse;
  late final Animation<int>    _typeAnim;

  bool    _loading = false;
  bool    _hovered = false;
  String? _error;

  static const _typeText = 'HemoScan Clinical AI';

  // ── Palette ───────────────────────────────────────────
  static const bg0    = Color(0xFF050D1A);
  static const bg1    = Color(0xFF0A1628);
  static const bg2    = Color(0xFF0F1E36);
  static const teal   = Color(0xFF00D4C8);
  static const tealDk = Color(0xFF00A89E);
  static const white  = Color(0xFFF0F8FF);
  static const slate  = Color(0xFF7A9BBE);
  static const slate2 = Color(0xFF3D5A7A);
  static const red    = Color(0xFFFF4D6A);
  static const bdr    = Color(0xFF1A2E4A);

  @override
  void initState() {
    super.initState();

    _bgCtrl    = AnimationController(vsync: this, duration: const Duration(seconds: 16))..repeat();
    _ecgCtrl   = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _scanCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
        ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.93, end: 1.07)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _typeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _typeAnim = IntTween(begin: 0, end: _typeText.length)
        .animate(CurvedAnimation(parent: _typeCtrl, curve: Curves.easeOut));

    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _fadeLogo  = _iv(0.00, 0.35, Curves.easeOut);
    _slideCard = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(_iv(0.20, 0.65, Curves.easeOutCubic));
    _fadeCard  = _iv(0.20, 0.60, Curves.easeOut);
    _fadeText  = _iv(0.40, 0.75, Curves.easeOut);
    _fadeBtn   = _iv(0.60, 1.00, Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  Animation<double> _iv(double b, double e, Curve c) =>
      CurvedAnimation(parent: _entryCtrl, curve: Interval(b, e, curve: c));

  @override
  void dispose() {
    _bgCtrl.dispose();
    _ecgCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _typeCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  void _onHover(bool hovering) {
    setState(() => _hovered = hovering);
    if (hovering) {
      _typeCtrl.forward(from: 0);
    } else {
      _typeCtrl.reverse();
    }
  }

  Future<void> _signIn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final user = await AuthService.signInWithGoogle();
      if (user == null && mounted) {
        setState(() { _loading = false; _error = 'Sign-in cancelled.'; });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _loading = false; _error = 'Authentication failed. Try again.'; });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: bg0,
      body: Stack(children: [

        // ── Cosmos background ─────────────────────────
        _CosmosBackground(bgCtrl: _bgCtrl, size: size),

        // ── ECG sweep line ────────────────────────────
        Positioned(
          bottom: size.height * 0.16,
          left: 0, right: 0,
          child: SizedBox(height: 60,
            child: AnimatedBuilder(
              animation: _ecgCtrl,
              builder: (_, __) => CustomPaint(
                painter: _FullEcgPainter(_ecgCtrl.value, teal.withOpacity(0.14)),
                child: const SizedBox.expand())))),

        // ── Main layout ───────────────────────────────
        SafeArea(child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(children: [

            // Logo row
            FadeTransition(
              opacity: _fadeLogo,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) => Transform.scale(
                  scale: _pulse.value,
                  child: _LogoMark()))),

            const SizedBox(height: 32),

            // ── Main glass card ───────────────────────
            SlideTransition(
              position: _slideCard,
              child: FadeTransition(
                opacity: _fadeCard,
                child: _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── TOP: split row — left text / right image ──
                      MouseRegion(
                        onEnter:  (_) => _onHover(true),
                        onExit:   (_) => _onHover(false),
                        child: GestureDetector(
                          onTapDown:  (_) => _onHover(true),
                          onTapUp:    (_) => _onHover(false),
                          onTapCancel: () => _onHover(false),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: _hovered
                                  ? teal.withOpacity(0.40)
                                  : bdr,
                                width: 1),
                              boxShadow: _hovered
                                ? [BoxShadow(color: teal.withOpacity(0.10), blurRadius: 20)]
                                : [],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(17),
                              child: Row(children: [

                                // ── LEFT: project description ─────────
                                Expanded(child: Container(
                                  color: bg2,
                                  padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [

                                      // Typewriter — visible on hover
                                      AnimatedBuilder(
                                        animation: _typeAnim,
                                        builder: (_, __) {
                                          final displayed = _typeText.substring(0, _typeAnim.value);
                                          return AnimatedOpacity(
                                            opacity: _hovered ? 1.0 : 0.0,
                                            duration: const Duration(milliseconds: 200),
                                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                                              Text(displayed,
                                                style: GoogleFonts.sourceCodePro(
                                                  fontSize: 9, color: teal,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 0.5)),
                                              AnimatedOpacity(
                                                opacity: _hovered ? 1.0 : 0.0,
                                                duration: const Duration(milliseconds: 300),
                                                child: Container(
                                                  width: 1.5, height: 10,
                                                  margin: const EdgeInsets.only(left: 1),
                                                  color: teal)),
                                            ]));
                                        }),

                                      const SizedBox(height: 4),

                                      // Project label
                                      Text('HEMOSCAN PROJECT',
                                        style: GoogleFonts.dmSans(
                                          fontSize: 8, fontWeight: FontWeight.w800,
                                          color: teal, letterSpacing: 1.5)),
                                      const SizedBox(height: 5),

                                      // Title
                                      Text('Non-Invasive\nAnemia Screening',
                                        style: GoogleFonts.playfairDisplay(
                                          fontSize: 15, fontWeight: FontWeight.w900,
                                          color: white, height: 1.2)),
                                      const SizedBox(height: 8),

                                      // Clinical modules list — no emojis, proper names
                                      const _ModuleLine('Palpebral Conjunctiva Pallor Analysis'),
                                      const _ModuleLine('Nail Bed Pallor Detection'),
                                      const _ModuleLine('Palmar Pallor Analysis'),
                                      const _ModuleLine('Hardware System (ESP32 + MAX30105)'),
                                    ],
                                  ),
                                )),

                                // ── RIGHT: asset image + effects ──────
                                SizedBox(
                                  width: 150,
                                  child: Stack(fit: StackFit.expand, children: [

                                    // Asset image
                                    // PATH: assets/images/doctor_patient.jpg
                                    // Create folder: anemia_app/assets/images/
                                    // Add to pubspec.yaml under flutter > assets:
                                    //   - assets/images/doctor_patient.jpg
                                    Image.asset(
                                      'assets/images/doctor_patient.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                        _ImagePlaceholder()),

                                    // Left-fade gradient blending into card
                                    DecoratedBox(decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                        colors: [
                                          bg2,
                                          bg2.withOpacity(0.35),
                                          Colors.transparent],
                                        stops: const [0.0, 0.22, 1.0]))),

                                    // Top + bottom vignette
                                    DecoratedBox(decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          bg2.withOpacity(0.55),
                                          Colors.transparent,
                                          Colors.transparent,
                                          bg2.withOpacity(0.55)]))),

                                    // Animated scan line
                                    AnimatedBuilder(
                                      animation: _scanCtrl,
                                      builder: (_, __) => CustomPaint(
                                        painter: _ScanLinePainter(
                                          _scanCtrl.value, teal),
                                        child: const SizedBox.expand())),

                                    // HUD corner brackets
                                    Positioned(top: 6, right: 6,
                                      child: _HudCorner(teal.withOpacity(0.55))),
                                    Positioned(bottom: 6, left: 6,
                                      child: Transform.rotate(angle: math.pi,
                                        child: _HudCorner(teal.withOpacity(0.35)))),

                                    // "CLINICAL VIEW" badge on hover
                                    if (_hovered)
                                      Positioned(top: 8, left: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: teal.withOpacity(0.14),
                                            borderRadius: BorderRadius.circular(5),
                                            border: Border.all(
                                              color: teal.withOpacity(0.40))),
                                          child: Text('CLINICAL VIEW',
                                            style: GoogleFonts.dmSans(
                                              fontSize: 7,
                                              fontWeight: FontWeight.w800,
                                              color: teal,
                                              letterSpacing: 1.0)))),
                                  ]),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ── Titles below the banner ───────────────
                      FadeTransition(opacity: _fadeText, child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HemoScan',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32, fontWeight: FontWeight.w900,
                              color: white, letterSpacing: -0.5,
                              shadows: [Shadow(
                                color: teal.withOpacity(0.45),
                                blurRadius: 20)])),
                          const SizedBox(height: 4),
                          Text('Clinical Anemia Screening System',
                            style: GoogleFonts.dmSans(
                              fontSize: 12, color: slate,
                              fontWeight: FontWeight.w500, letterSpacing: 0.5)),
                          const SizedBox(height: 16),

                          // Teal gradient divider
                          Container(height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                teal.withOpacity(0.55),
                                teal.withOpacity(0.15),
                                Colors.transparent]))),
                          const SizedBox(height: 14),

                          Text(
                            'Multi-modal pallor assessment via palpebral conjunctiva '
                            'redness ratio, nail bed chrominance index, and palmar '
                            'pallor analysis combined with optical biosensor data.',
                            style: GoogleFonts.dmSans(
                              fontSize: 12, color: slate, height: 1.65)),
                        ])),

                      const SizedBox(height: 22),

                      // ── Error message ─────────────────────────
                      if (_error != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: red.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: red.withOpacity(0.30))),
                          child: Row(children: [
                            const Icon(Icons.error_outline_rounded,
                              color: red, size: 15),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_error!,
                              style: GoogleFonts.dmSans(
                                fontSize: 12, color: red))),
                          ])),

                      // ── Google Sign-In button ─────────────────
                      FadeTransition(
                        opacity: _fadeBtn,
                        child: _GoogleSignInButton(
                          loading: _loading, onTap: _signIn)),

                      const SizedBox(height: 12),

                      // ── Security note ─────────────────────────
                      FadeTransition(opacity: _fadeBtn,
                        child: Center(child: Text(
                          'Secured by Firebase Authentication',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            color: slate.withOpacity(0.50))))),
                    ]),
                ))),

            const SizedBox(height: 28),

            // ── Medical disclaimer (bottom) ───────────
            FadeTransition(opacity: _fadeBtn,
              child: Column(children: [
                Row(children: [
                  Expanded(child: Divider(
                    color: slate2.withOpacity(0.25), height: 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('MEDICAL DISCLAIMER',
                      style: GoogleFonts.dmSans(
                        fontSize: 8, fontWeight: FontWeight.w800,
                        color: slate2.withOpacity(0.55), letterSpacing: 1.5))),
                  Expanded(child: Divider(
                    color: slate2.withOpacity(0.25), height: 1)),
                ]),
                const SizedBox(height: 10),
                Text(
                  'HemoScan is a non-invasive screening tool for academic research only.\n'
                  'Results do not replace a Complete Blood Count (CBC) laboratory test\n'
                  'or evaluation by a qualified physician.\n'
                  'TNWiSE Hackathon 2025',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: slate.withOpacity(0.35),
                    height: 1.7,
                    letterSpacing: 0.2)),
              ])),

            const SizedBox(height: 16),
          ]),
        )),
      ]),
    );
  }
}

// ── Module line (left side of banner) ────────────────────
class _ModuleLine extends StatelessWidget {
  final String text;
  const _ModuleLine(this.text);

  static const teal  = Color(0xFF00D4C8);
  static const slate = Color(0xFF7A9BBE);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 3),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: 3, height: 3,
        margin: const EdgeInsets.only(top: 5, right: 5),
        decoration: BoxDecoration(
          color: teal.withOpacity(0.7),
          shape: BoxShape.circle)),
      Expanded(child: Text(text,
        style: GoogleFonts.dmSans(
          fontSize: 9, color: slate,
          fontWeight: FontWeight.w500, height: 1.4))),
    ]));
}

// ── Image placeholder ─────────────────────────────────────
class _ImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFF0F1E36),
    child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.medical_services_outlined,
        color: const Color(0xFF00D4C8).withOpacity(0.3), size: 28),
      const SizedBox(height: 6),
      Text('assets/images/\ndoctor_patient.jpg',
        textAlign: TextAlign.center,
        style: GoogleFonts.sourceCodePro(
          fontSize: 8,
          color: const Color(0xFF3D5A7A), height: 1.5)),
    ])));
}

// ── Scan-line painter ─────────────────────────────────────
class _ScanLinePainter extends CustomPainter {
  final double t;
  final Color  color;
  const _ScanLinePainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final y = t * size.height;
    canvas.drawRect(
      Rect.fromLTWH(0, y - 1.5, size.width, 3),
      Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.transparent,
            color.withOpacity(0.50),
            Colors.transparent],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    canvas.drawLine(Offset(0, y), Offset(size.width, y),
      Paint()
        ..color = color.withOpacity(0.65)
        ..strokeWidth = 0.7);
  }

  @override
  bool shouldRepaint(_ScanLinePainter o) => o.t != t;
}

// ── HUD corner bracket ────────────────────────────────────
class _HudCorner extends StatelessWidget {
  final Color color;
  const _HudCorner(this.color);
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(12, 12), painter: _HudPainter(color));
}

class _HudPainter extends CustomPainter {
  final Color color;
  const _HudPainter(this.color);
  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = color ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset.zero, Offset(s.width, 0), p);
    canvas.drawLine(Offset.zero, Offset(0, s.height), p);
  }
  @override bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════
//  COSMOS BACKGROUND
// ══════════════════════════════════════════════════════════════════
class _CosmosBackground extends StatelessWidget {
  final AnimationController bgCtrl;
  final Size size;
  const _CosmosBackground({required this.bgCtrl, required this.size});

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: bgCtrl,
    builder: (_, __) {
      final t = bgCtrl.value * 2 * math.pi;
      return Stack(children: [
        Positioned(
          right: -60 + math.cos(t * 0.4) * 30,
          top:   -80 + math.sin(t * 0.3) * 25,
          child: Container(
            width: size.width * 0.85, height: size.width * 0.85,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF00D4C8).withOpacity(0.10),
                Colors.transparent])))),
        Positioned(
          left:   -80 + math.cos(t * 0.5 + 1) * 20,
          bottom: size.height * 0.05 + math.sin(t * 0.4) * 15,
          child: Container(
            width: size.width * 0.70, height: size.width * 0.70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFF0A4FFF).withOpacity(0.08),
                Colors.transparent])))),
        CustomPaint(
          painter: _StarfieldPainter(bgCtrl.value),
          child: const SizedBox.expand()),
      ]);
    });
}

// ══════════════════════════════════════════════════════════════════
//  STARFIELD PAINTER
// ══════════════════════════════════════════════════════════════════
class _StarfieldPainter extends CustomPainter {
  final double t;
  static final _rng   = math.Random(42);
  static final _stars = List.generate(55, (_) =>
      Offset(_rng.nextDouble(), _rng.nextDouble()));
  static final _sizes = List.generate(55, (_) =>
      _rng.nextDouble() * 1.6 + 0.4);

  const _StarfieldPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < _stars.length; i++) {
      final opacity =
          (math.sin(t * 2 * math.pi + i * 0.7) * 0.3 + 0.4).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(_stars[i].dx * size.width, _stars[i].dy * size.height),
        _sizes[i],
        Paint()..color =
            const Color(0xFF7AB8FF).withOpacity(opacity * 0.45));
    }
  }

  @override
  bool shouldRepaint(_StarfieldPainter o) => o.t != t;
}

// ══════════════════════════════════════════════════════════════════
//  FULL-WIDTH ECG PAINTER
// ══════════════════════════════════════════════════════════════════
class _FullEcgPainter extends CustomPainter {
  final double t;
  final Color  color;
  const _FullEcgPainter(this.t, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    const pts  = 200;
    for (int i = 0; i < pts; i++) {
      final x     = (i / pts) * size.width;
      final phase = ((i / pts) * 2.5 + t) % 1.0;
      double y    = size.height / 2;
      if      (phase < 0.06) {
        y = size.height/2 - math.sin(phase/0.06*math.pi)*size.height*0.08;
      } else if (phase < 0.13)  y = size.height/2;
      else if (phase < 0.16)  y = size.height/2 + size.height*0.12;
      else if (phase < 0.20)  y = size.height/2 - size.height*0.48;
      else if (phase < 0.24)  y = size.height/2 + size.height*0.20;
      else if (phase < 0.36)  y = size.height/2 -
          math.sin((phase-0.24)/0.12*math.pi)*size.height*0.14;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path,
      Paint()
        ..color = color ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_FullEcgPainter o) => o.t != t;
}

// ══════════════════════════════════════════════════════════════════
//  LOGO MARK  — teal gradient box, no emoji
// ══════════════════════════════════════════════════════════════════
class _LogoMark extends StatelessWidget {
  static const teal   = Color(0xFF00D4C8);
  static const tealDk = Color(0xFF00A89E);

  @override
  Widget build(BuildContext context) => Stack(alignment: Alignment.center, children: [
    Container(width: 100, height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [
          teal.withOpacity(0.16), Colors.transparent]))),
    Container(width: 72, height: 72,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [teal, tealDk],
          begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: teal.withOpacity(0.50), blurRadius: 28, offset: const Offset(0, 6)),
          BoxShadow(color: teal.withOpacity(0.18), blurRadius: 48, spreadRadius: 2),
        ]),
      child: const Center(
        child: Icon(Icons.monitor_heart_outlined, color: Colors.white, size: 32))),
  ]);
}

// ══════════════════════════════════════════════════════════════════
//  GLASS CARD
// ══════════════════════════════════════════════════════════════════
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFF0A1628).withOpacity(0.93),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(
        color: const Color(0xFF00D4C8).withOpacity(0.16), width: 1),
      boxShadow: [
        BoxShadow(color: const Color(0xFF00D4C8).withOpacity(0.07), blurRadius: 40),
        BoxShadow(color: Colors.black.withOpacity(0.55),
          blurRadius: 32, offset: const Offset(0, 12)),
      ]),
    child: child);
}

// ══════════════════════════════════════════════════════════════════
//  GOOGLE SIGN-IN BUTTON  (preserved exactly)
// ══════════════════════════════════════════════════════════════════
class _GoogleSignInButton extends StatefulWidget {
  final bool loading;
  final VoidCallback onTap;
  const _GoogleSignInButton({required this.loading, required this.onTap});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTapDown:   (_) => _ctrl.forward(),
    onTapUp:     (_) { _ctrl.reverse(); widget.onTap(); },
    onTapCancel: ()  => _ctrl.reverse(),
    child: AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              const Color(0xFF00D4C8).withOpacity(0.14),
              const Color(0xFF00A89E).withOpacity(0.07)]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00D4C8).withOpacity(0.38), width: 1.5),
            boxShadow: [BoxShadow(
              color: const Color(0xFF00D4C8).withOpacity(0.12),
              blurRadius: 18, offset: const Offset(0, 5))]),
          child: widget.loading
            ? const Center(child: SizedBox(width: 22, height: 22,
                child: CircularProgressIndicator(
                  color: Color(0xFF00D4C8),
                  strokeWidth: 2.5, strokeCap: StrokeCap.round)))
            : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                CustomPaint(size: const Size(22, 22), painter: _GoogleGPainter()),
                const SizedBox(width: 12),
                Text('Continue with Google',
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700,
                    color: const Color(0xFFF0F8FF))),
              ])))));
}

// ── Google "G" logo (preserved exactly) ──────────────────
class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final c   = Offset(s.width/2, s.height/2);
    final r   = s.width/2;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width*0.155
      ..strokeCap = StrokeCap.butt;
    final rect = Rect.fromCircle(center: c, radius: r*0.72);
    arc.color = const Color(0xFF4285F4);
    canvas.drawArc(rect, -math.pi/2, math.pi/2, false, arc);
    arc.color = const Color(0xFFEA4335);
    canvas.drawArc(rect, -math.pi*1.5, -math.pi/2, false, arc);
    arc.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect, math.pi, math.pi/2, false, arc);
    arc.color = const Color(0xFF34A853);
    canvas.drawArc(rect, math.pi/2, math.pi/2, false, arc);
    canvas.drawRect(
      Rect.fromLTWH(c.dx-0.5, c.dy-s.height*0.13, r*0.82, s.height*0.265),
      Paint()..color = const Color(0xFF4285F4));
    canvas.drawCircle(c, r*0.44,
      Paint()..color = const Color(0xFF0A1628));
  }
  @override bool shouldRepaint(_) => false;
}