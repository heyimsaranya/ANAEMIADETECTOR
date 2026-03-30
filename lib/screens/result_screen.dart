import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/scan_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  Result Screen — Clinical Dark
// ══════════════════════════════════════════════════════════════════
class ResultScreen extends StatefulWidget {
  final ScanResult result;
  final VoidCallback onNewScan;
  const ResultScreen({super.key, required this.result, required this.onNewScan});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> with TickerProviderStateMixin {
  late final AnimationController _entryCtrl;
  late final AnimationController _gaugeCtrl;
  late final Animation<double>   _entry;
  late final Animation<Offset>   _slide;
  late final Animation<double>   _gauge;

  // Tokens
  static const bg0    = Color(0xFF050D1A);
  static const bg1    = Color(0xFF0A1628);
  static const bg2    = Color(0xFF0F1E36);
  static const teal   = Color(0xFF00D4C8);
  static const tealDk = Color(0xFF00A89E);
  static const text1  = Color(0xFFF0F8FF);
  static const text2  = Color(0xFF7A9BBE);
  static const bdr    = Color(0xFF1A2E4A);

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _gaugeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _entry     = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slide     = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _gauge     = CurvedAnimation(parent: _gaugeCtrl, curve: Curves.easeOutCubic);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) { _entryCtrl.forward(); _gaugeCtrl.forward(); }
    });
  }

  @override
  void dispose() { _entryCtrl.dispose(); _gaugeCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Scaffold(
      backgroundColor: bg0,
      body: SafeArea(
        child: FadeTransition(
          opacity: _entry,
          child: SlideTransition(
            position: _slide,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Header ──────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('ASSESSMENT', style: GoogleFonts.dmSans(
                      fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700,
                      color: teal)),
                    Text('Clinical Report', style: GoogleFonts.playfairDisplay(
                      fontSize: 24, fontWeight: FontWeight.w900, color: text1)),
                  ]),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: bg2, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: bdr)),
                    child: Text(
                      DateTime.now().toString().substring(0, 10),
                      style: GoogleFonts.dmSans(fontSize: 11, color: text2))),
                ]),
                const SizedBox(height: 24),

                // ── Gauge Hero ───────────────────────
                _GaugeHero(result: r, gauge: _gauge),
                const SizedBox(height: 16),

                // ── Stat chips row ───────────────────
                _StatChips(result: r),
                const SizedBox(height: 24),

                // ── Breakdown label ──────────────────
                _SLabel('SIGNAL BREAKDOWN'),
                const SizedBox(height: 12),
                ...r.breakdown.entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BreakdownCard(entry: e, gauge: _gauge))),

                const SizedBox(height: 8),
                _InterpCard(result: r),
                const SizedBox(height: 12),
                _DisclaimerCard(),
                const SizedBox(height: 24),

                // ── New scan CTA ─────────────────────
                GestureDetector(
                  onTap: widget.onNewScan,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 17),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [teal, tealDk]),
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(
                        color: teal.withOpacity(0.4), blurRadius: 24, offset: const Offset(0,8))]),
                    child: Center(child: Text('↩  New Scan',
                      style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white))))),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────
Widget _SLabel(String t) => Text(t,
  style: GoogleFonts.dmSans(
    fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700,
    color: const Color(0xFF00D4C8)));

// ══════════════════════════════════════════════════════════════════
//  GAUGE HERO CARD
// ══════════════════════════════════════════════════════════════════
class _GaugeHero extends StatelessWidget {
  final ScanResult result;
  final Animation<double> gauge;
  const _GaugeHero({required this.result, required this.gauge});

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: r.riskColor.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(color: r.riskColor.withOpacity(0.12), blurRadius: 30, offset: const Offset(0,8)),
          BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20)]),
      child: Column(children: [
        Text('RISK SCORE', style: GoogleFonts.dmSans(
          fontSize: 10, letterSpacing: 2, color: r.riskColor, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: gauge,
          builder: (_, __) => CustomPaint(
            size: const Size(230, 125),
            painter: _GaugePainter(r.riskPct * gauge.value / 100, r.riskColor))),
        const SizedBox(height: 14),
        Text(r.riskLevel, style: GoogleFonts.playfairDisplay(
          fontSize: 28, fontWeight: FontWeight.w900, color: r.riskColor,
          shadows: [Shadow(color: r.riskColor.withOpacity(0.5), blurRadius: 20)])),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Estimated Hgb  ', style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF7A9BBE))),
          Text('${r.estHgb.toStringAsFixed(1)} g/dL',
            style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w900,
              color: const Color(0xFFF0F8FF))),
        ]),
        const SizedBox(height: 20),
        _HgbScale(result: r),
      ]),
    );
  }
}

class _HgbScale extends StatelessWidget {
  final ScanResult result;
  const _HgbScale({required this.result});

  @override
  Widget build(BuildContext context) {
    final marker = ((result.estHgb - 5) / 12).clamp(0.0, 1.0);
    return Column(children: [
      ClipRRect(borderRadius: BorderRadius.circular(6),
        child: Container(height: 8,
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [
            Color(0xFFFF4D6A), Color(0xFFFFB547), Color(0xFFFFE066), Color(0xFF22D47A)])))),
      const SizedBox(height: 6),
      LayoutBuilder(builder: (ctx, cst) => Stack(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: ['5','8','10','12','17'].map((v) => Text(v,
            style: GoogleFonts.dmSans(fontSize: 10, color: const Color(0xFF3D5A7A)))).toList()),
        Positioned(left: marker * cst.maxWidth - 8, top: -22,
          child: Container(width: 16, height: 16,
            decoration: BoxDecoration(
              color: result.riskColor, shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF050D1A), width: 2),
              boxShadow: [BoxShadow(color: result.riskColor, blurRadius: 10)]))),
      ])),
      const SizedBox(height: 6),
      Text('Reference hemoglobin scale (g/dL)',
        style: GoogleFonts.dmSans(fontSize: 9, color: const Color(0xFF3D5A7A), letterSpacing: 0.5)),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════
//  STAT CHIPS
// ══════════════════════════════════════════════════════════════════
class _StatChips extends StatelessWidget {
  final ScanResult result;
  const _StatChips({required this.result});

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Row(children: [
      Expanded(child: _Chip('🩸', 'Risk Score', '${r.riskPct.toStringAsFixed(0)}%',
        const Color(0xFFFF4D6A))),
      const SizedBox(width: 12),
      Expanded(child: _Chip('💉', 'Est. Hgb', '${r.estHgb.toStringAsFixed(1)} g/dL',
        const Color(0xFF22D47A))),
    ]);
  }
}

class _Chip extends StatelessWidget {
  final String icon, label, value;
  final Color color;
  const _Chip(this.icon, this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withOpacity(0.22))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const Icon(Icons.more_horiz, size: 16, color: Color(0xFF3D5A7A)),
      ]),
      const SizedBox(height: 8),
      Text(label, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF7A9BBE))),
      const SizedBox(height: 2),
      Text(value, style: GoogleFonts.dmSans(
        fontSize: 18, fontWeight: FontWeight.w900, color: const Color(0xFFF0F8FF))),
    ]));
}

// ══════════════════════════════════════════════════════════════════
//  BREAKDOWN CARD
// ══════════════════════════════════════════════════════════════════
class _BreakdownCard extends StatelessWidget {
  final MapEntry<String, SignalBreakdown> entry;
  final Animation<double> gauge;
  const _BreakdownCard({required this.entry, required this.gauge});

  @override
  Widget build(BuildContext context) {
    final bd  = entry.value;
    final pct = bd.pct;
    final c   = pct > 0.66 ? const Color(0xFFFF4D6A)
              : pct > 0.33 ? const Color(0xFFFFB547)
              :               const Color(0xFF22D47A);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A1628),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A2E4A)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0,3))]),
      child: Row(children: [
        Container(width: 46, height: 46,
          decoration: BoxDecoration(
            color: c.withOpacity(0.10), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.withOpacity(0.22))),
          child: Center(child: Text(bd.icon, style: const TextStyle(fontSize: 22)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(bd.label, style: GoogleFonts.dmSans(
              fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFFF0F8FF)))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: c.withOpacity(0.12), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: c.withOpacity(0.3))),
              child: Text('${bd.points}/${bd.max}',
                style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: c))),
          ]),
          const SizedBox(height: 8),
          AnimatedBuilder(animation: gauge,
            builder: (_, __) => Stack(children: [
              Container(height: 4, decoration: BoxDecoration(
                color: const Color(0xFF162440), borderRadius: BorderRadius.circular(4))),
              FractionallySizedBox(
                widthFactor: (pct * gauge.value).clamp(0, 1),
                child: Container(height: 4,
                  decoration: BoxDecoration(
                    color: c, borderRadius: BorderRadius.circular(4),
                    boxShadow: [BoxShadow(color: c.withOpacity(0.5), blurRadius: 8)]))),
            ])),
        ])),
        const SizedBox(width: 10),
        const Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF3D5A7A)),
      ]));
  }
}

// ══════════════════════════════════════════════════════════════════
//  INTERPRETATION CARD
// ══════════════════════════════════════════════════════════════════
class _InterpCard extends StatelessWidget {
  final ScanResult result;
  const _InterpCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final r = result;
    String msg;
    if (r.riskPct >= 65) {
      msg = 'High likelihood of anemia. Estimated Hgb is critically low. Immediate medical evaluation and CBC blood test is strongly recommended.';
    } else if (r.riskPct >= 40)
      msg = 'Moderate anemia indicators present. Hgb may be 10–12 g/dL. A CBC blood test is recommended to confirm.';
    else if (r.riskPct >= 20)
      msg = 'Mild risk signals detected. Borderline Hgb possible. Monitor fatigue, pallor symptoms and consider a follow-up test.';
    else
      msg = 'Signals within normal range. Low anemia risk based on current data. Continue routine health monitoring.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: r.riskColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: r.riskColor.withOpacity(0.22))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(r.riskPct >= 65 ? '🔴' : r.riskPct >= 40 ? '🟠' : r.riskPct >= 20 ? '🟡' : '🟢',
          style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Clinical Interpretation', style: GoogleFonts.dmSans(
            fontSize: 12, fontWeight: FontWeight.w800, color: r.riskColor, letterSpacing: 0.3)),
          const SizedBox(height: 6),
          Text(msg, style: GoogleFonts.dmSans(
            fontSize: 13, color: const Color(0xFF7A9BBE), height: 1.55)),
        ])),
      ]));
  }
}

// ══════════════════════════════════════════════════════════════════
//  DISCLAIMER
// ══════════════════════════════════════════════════════════════════
class _DisclaimerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFB547).withOpacity(0.06),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFFFB547).withOpacity(0.25))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('⚠️', style: TextStyle(fontSize: 15)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('MEDICAL DISCLAIMER', style: GoogleFonts.dmSans(
          fontSize: 9, fontWeight: FontWeight.w800,
          color: const Color(0xFFFFB547), letterSpacing: 1)),
        const SizedBox(height: 4),
        Text('Screening tool only. Results do not replace a CBC blood test or physician evaluation.',
          style: GoogleFonts.dmSans(fontSize: 11,
            color: const Color(0xFF7A9BBE), height: 1.5)),
      ])),
    ]));
}

// ══════════════════════════════════════════════════════════════════
//  GAUGE PAINTER
// ══════════════════════════════════════════════════════════════════
class _GaugePainter extends CustomPainter {
  final double pct;
  final Color  color;
  const _GaugePainter(this.pct, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height * 0.88;
    final r  = size.width * 0.38;
    const start = -math.pi * 1.25;
    const sweep = math.pi * 1.50;

    // Track glow
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
      start, sweep, false,
      Paint()..color = const Color(0xFF162440)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round);

    // Colored arc
    if (pct > 0) {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start, sweep * pct.clamp(0, 1), false,
        Paint()..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6));
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r),
        start, sweep * pct.clamp(0, 1), false,
        Paint()..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round);
    }

    // Needle
    final angle = start + sweep * pct.clamp(0, 1);
    final nx = cx + (r - 14) * math.cos(angle);
    final ny = cy + (r - 14) * math.sin(angle);
    canvas.drawLine(Offset(cx, cy), Offset(nx, ny),
      Paint()..color = color..strokeWidth = 3..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3));
    canvas.drawCircle(Offset(cx, cy), 7,
      Paint()..color = color
        ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 6));
    canvas.drawCircle(Offset(cx, cy), 5,
      Paint()..color = const Color(0xFF0A1628));
    canvas.drawCircle(Offset(cx, cy), 3, Paint()..color = color);

    // Pct label
    final tp = TextPainter(
      text: TextSpan(text: '${(pct * 100).toStringAsFixed(0)}%',
        style: const TextStyle(fontFamily: 'sans-serif', fontSize: 26,
          fontWeight: FontWeight.w900, color: Color(0xFFF0F8FF))),
      textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(cx - tp.width/2, cy + 6));

    final lp = TextPainter(
      text: const TextSpan(text: 'RISK',
        style: TextStyle(fontFamily: 'sans-serif', fontSize: 9,
          color: Color(0xFF3D5A7A), letterSpacing: 2)),
      textDirection: TextDirection.ltr)..layout();
    lp.paint(canvas, Offset(cx - lp.width/2, cy + 36));
  }

  @override
  bool shouldRepaint(_GaugePainter o) => o.pct != pct || o.color != color;
}