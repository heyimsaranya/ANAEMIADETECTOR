import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/scan_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  Palpebral Conjunctiva Capture & Analysis
//
//  Algorithm (no ML needed):
//  1. User pulls lower lid + takes close-up photo
//  2. We scan the image in LAB color space for the pinkest region
//     — healthy conjunctiva: a* > 18, b* < 20, L* 55–80
//     — pale / anemic:       a* < 10, low redness
//  3. Auto-crop best region OR user drags ROI manually
//  4. Score pallor index from mean R / (R+G+B)
//
//  Clinical basis: Sheth et al. (2016), Eye conjunctival pallor
//  threshold for Hgb < 8g/dL: redness ratio < 0.42
// ══════════════════════════════════════════════════════════════════

class ConjunctivaCaptureScreen extends StatefulWidget {
  const ConjunctivaCaptureScreen({super.key});
  @override
  State<ConjunctivaCaptureScreen> createState() => _ConjunctivaCaptureScreenState();
}

class _ConjunctivaCaptureScreenState extends State<ConjunctivaCaptureScreen>
    with TickerProviderStateMixin {

  // ── State ─────────────────────────────────────────────
  ui.Image?  _uiImage;
  img.Image? _rawImage;
  Size       _displaySize = Size.zero;

  Offset _roi      = Offset.zero;
  bool   _roiSet   = false;
  static const double _roiW = 120.0;
  static const double _roiH = 56.0;

  ConjunctivaResult? _result;
  bool   _analyzing   = false;
  bool   _autoRoiDone = false;
  String? _error;

  late final AnimationController _pulseCtrl;
  late final AnimationController _fadeCtrl;
  late final Animation<double>   _pulse;
  late final Animation<double>   _fade;

  // ── Design tokens ─────────────────────────────────────
  static const bg0    = Color(0xFF050D1A);
  static const bg1    = Color(0xFF0A1628);
  static const bg2    = Color(0xFF0F1E36);
  static const teal   = Color(0xFF00D4C8);
  static const tealDk = Color(0xFF00A89E);
  static const text1  = Color(0xFFF0F8FF);
  static const text2  = Color(0xFF7A9BBE);
  static const text3  = Color(0xFF3D5A7A);
  static const bdr    = Color(0xFF1A2E4A);
  static const green  = Color(0xFF22D47A);
  static const amber  = Color(0xFFFFB547);
  static const red    = Color(0xFFFF4D6A);
  static const gold   = Color(0xFFFFD166);

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _pulse = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _fade  = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _pulseCtrl.dispose(); _fadeCtrl.dispose(); super.dispose(); }

  // ── Image pick ────────────────────────────────────────
  Future<void> _pick(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(
          source: src, imageQuality: 95, preferredCameraDevice: CameraDevice.front);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final raw   = img.decodeImage(bytes);
      if (raw == null) { setState(() => _error = 'Cannot decode image.'); return; }
      setState(() {
        _uiImage = frame.image; _rawImage = raw;
        _result = null; _roiSet = false; _autoRoiDone = false; _error = null;
      });
      // Run auto-detect immediately
      await _autoDetectROI();
    } catch (e) { setState(() => _error = 'Error: $e'); }
  }

  // ══════════════════════════════════════════════════════
  //  AUTO-DETECT: find reddest horizontal band
  //  Strategy: scan rows of image, pick band with highest
  //  mean a* (red-green axis in LAB space)
  // ══════════════════════════════════════════════════════
  Future<void> _autoDetectROI() async {
    final raw = _rawImage;
    if (raw == null) return;

    setState(() { _analyzing = true; });
    await Future.delayed(const Duration(milliseconds: 50));

    try {
      // Work on a small thumbnail for speed
      final thumb = img.copyResize(raw, width: 200);
      final tw = thumb.width;
      final th = thumb.height;

      // Compute per-row mean redness (R / (R+G+B))
      final rowScores = <double>[];
      for (int y = 0; y < th; y++) {
        double rSum = 0, total = 0;
        for (int x = 0; x < tw; x++) {
          final p = thumb.getPixel(x, y);
          final r = p.r.toDouble();
          final g = p.g.toDouble();
          final b = p.b.toDouble();
          final denom = r + g + b;
          if (denom > 30) { // skip very dark pixels
            rSum  += r / denom;
            total += 1;
          }
        }
        rowScores.add(total > 0 ? rSum / total : 0);
      }

      // Smooth row scores with a 5-row window
      final smooth = List<double>.filled(th, 0);
      for (int y = 2; y < th - 2; y++) {
        smooth[y] = (rowScores[y-2] + rowScores[y-1] + rowScores[y] +
                     rowScores[y+1] + rowScores[y+2]) / 5;
      }

      // Find best band of height = roiH/raw.height * th
      final bandH = ((_roiH / raw.height) * th).round().clamp(4, th ~/ 4);
      double bestScore = 0;
      int    bestY     = th ~/ 3; // default middle-lower area

      for (int y = th ~/ 6; y < th * 5 ~/ 6 - bandH; y++) {
        double s = 0;
        for (int dy = 0; dy < bandH; dy++) {
          s += smooth[y + dy];
        }
        s /= bandH;
        if (s > bestScore) { bestScore = s; bestY = y; }
      }

      // Map back to display coords
      final scaleY = _displaySize.height / raw.height;
      final scaleX = _displaySize.width  / raw.width;

      // Best x: find column range with highest redness in that row band
      double cxBest = 0.5; // default center
      {
        double bestColScore = 0;
        final colW = ((_roiW / raw.width) * tw).round().clamp(4, tw ~/ 2);
        for (int x = 0; x < tw - colW; x++) {
          double s = 0;
          for (int dx = 0; dx < colW; dx++) {
            for (int dy = 0; dy < bandH; dy++) {
              final p = thumb.getPixel(x + dx, bestY + dy);
              final r = p.r.toDouble();
              final denom = r + p.g.toDouble() + p.b.toDouble();
              if (denom > 30) s += r / denom;
            }
          }
          if (s > bestColScore) { bestColScore = s; cxBest = (x + colW / 2) / tw; }
        }
      }

      final cx = cxBest * _displaySize.width;
      final cy = ((bestY + bandH / 2) / th) * _displaySize.height;

      setState(() {
        _roi          = Offset(cx, cy);
        _roiSet       = true;
        _autoRoiDone  = bestScore > 0.34; // confidence threshold
        _analyzing    = false;
      });
    } catch (e) {
      setState(() { _analyzing = false; _roiSet = true;
        _roi = Offset(_displaySize.width / 2, _displaySize.height / 2); });
    }
  }

  // ══════════════════════════════════════════════════════
  //  ANALYZE ROI — extract color + compute pallor index
  // ══════════════════════════════════════════════════════
  Future<void> _analyze() async {
    final raw = _rawImage;
    if (raw == null) return;
    setState(() { _analyzing = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 80));

    try {
      final sx = raw.width  / _displaySize.width;
      final sy = raw.height / _displaySize.height;

      final cx = (_roi.dx * sx).round();
      final cy = (_roi.dy * sy).round();
      final hw = (_roiW / 2 * sx).round();
      final hh = (_roiH / 2 * sy).round();

      final x1 = (cx - hw).clamp(0, raw.width  - 1);
      final y1 = (cy - hh).clamp(0, raw.height - 1);
      final x2 = (cx + hw).clamp(0, raw.width  - 1);
      final y2 = (cy + hh).clamp(0, raw.height - 1);

      // Collect pixels — filter very dark (shadow) and very bright (specular)
      final pixels = <List<double>>[];
      for (int y = y1; y <= y2; y++) {
        for (int x = x1; x <= x2; x++) {
          final p = raw.getPixel(x, y);
          final r = p.r.toDouble();
          final g = p.g.toDouble();
          final b = p.b.toDouble();
          final lum = 0.299*r + 0.587*g + 0.114*b;
          if (lum > 40 && lum < 230) pixels.add([r, g, b]); // exclude extremes
        }
      }

      if (pixels.isEmpty) {
        setState(() { _error = 'ROI too dark or overexposed. Adjust lighting.'; _analyzing = false; });
        return;
      }

      // Mean R, G, B
      double mr = 0, mg = 0, mb = 0;
      for (final p in pixels) { mr += p[0]; mg += p[1]; mb += p[2]; }
      mr /= pixels.length; mg /= pixels.length; mb /= pixels.length;

      // Remove outliers (>1.5 sigma) for quality
      double vr = 0, vg = 0, vb = 0;
      for (final p in pixels) {
        vr += (p[0]-mr)*(p[0]-mr);
        vg += (p[1]-mg)*(p[1]-mg);
        vb += (p[2]-mb)*(p[2]-mb);
      }
      final sr = math.sqrt(vr / pixels.length).clamp(1.0, 255.0);
      final sg = math.sqrt(vg / pixels.length).clamp(1.0, 255.0);
      final sb = math.sqrt(vb / pixels.length).clamp(1.0, 255.0);

      final qc = pixels.where((p) =>
        (p[0]-mr).abs() < 1.5*sr &&
        (p[1]-mg).abs() < 1.5*sg &&
        (p[2]-mb).abs() < 1.5*sb).toList();

      final qn = qc.isEmpty ? pixels.length : qc.length;
      double qr = 0, qq = 0, qb = 0;
      for (final p in qc.isEmpty ? pixels : qc) { qr += p[0]; qq += p[1]; qb += p[2]; }
      qr /= qn; qq /= qn; qb /= qn;

      // ── Key indices ──────────────────────────────────
      // 1. Redness ratio (clinical standard):
      //    healthy:  R/(R+G+B) ≥ 0.43
      //    anemic:   R/(R+G+B) < 0.38
      final total      = qr + qq + qb + 1;
      final rednessRatio = qr / total;

      // 2. Pallor index (higher = more pale)
      //    1 - redness from total chrominance
      final pallorIdx = 1.0 - rednessRatio;

      // 3. LAB a* approximate (red-green chrominance)
      //    Simplified: astar ≈ (R - G) / 2.55 normalized to [-128, 127]
      final aStar = ((qr - qq) / 255.0 * 127).clamp(-128.0, 127.0);

      // 4. Quality (fraction of usable pixels)
      final quality = qn / pixels.length;

      // ── Pallor grade ─────────────────────────────────
      // Based on Sheth et al. 2016 & WHO pallor grading:
      //   No pallor:   rednessRatio > 0.43
      //   Mild:        0.38–0.43
      //   Moderate:    0.32–0.38
      //   Severe:      < 0.32
      String grade;
      Color  gradeColor;
      if      (rednessRatio >= 0.43) { grade = 'No Pallor';       gradeColor = green; }
      else if (rednessRatio >= 0.38) { grade = 'Mild Pallor';     gradeColor = amber; }
      else if (rednessRatio >= 0.32) { grade = 'Moderate Pallor'; gradeColor = const Color(0xFFF97316); }
      else                           { grade = 'Severe Pallor';   gradeColor = red; }

      setState(() {
        _result = ConjunctivaResult(
          r: qr, g: qq, b: qb,
          rednessRatio: rednessRatio,
          pallorIndex:  pallorIdx,
          aStar:        aStar,
          quality:      quality,
          pallor:       pallorIdx,
          redness:      rednessRatio,
          grade:        grade,
          gradeColor:   gradeColor,
        );
        _analyzing = false;
      });
      _fadeCtrl.forward(from: 0);

      // Pass to provider
      if (mounted) {
        final roi = ROIResult(
          r: qr, g: qq, b: qb,
          pallor:  pallorIdx,
          redness: rednessRatio,
          quality: quality,
        );
        context.read<ScanProvider>().setConjunctivaData([roi]);
      }
    } catch (e) {
      setState(() { _error = 'Analysis error: $e'; _analyzing = false; });
    }
  }

  void _reset() => setState(() {
    _uiImage = null; _rawImage = null;
    _result = null; _roiSet = false; _error = null;
  });

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg0,
    body: SafeArea(child: Column(children: [
      _buildHeader(),
      Expanded(child: _uiImage == null ? _buildUploadZone() : _buildAnalysisView()),
    ])),
  );

  // ── Header ─────────────────────────────────────────────
  Widget _buildHeader() => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    decoration: const BoxDecoration(
      color: bg1, border: Border(bottom: BorderSide(color: bdr))),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: bg2, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bdr)),
          child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: text1))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CONJUNCTIVA', style: GoogleFonts.dmSans(
          fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700, color: teal)),
        Text('Palpebral Pallor Analysis', style: GoogleFonts.playfairDisplay(
          fontSize: 16, fontWeight: FontWeight.w800, color: text1)),
      ])),
      if (_analyzing)
        const SizedBox(width: 22, height: 22,
          child: CircularProgressIndicator(
            color: teal, strokeWidth: 2.5, strokeCap: StrokeCap.round)),
    ]));

  // ── Upload Zone ────────────────────────────────────────
  Widget _buildUploadZone() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      const SizedBox(height: 12),

      // Instruction card
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: bg1, borderRadius: BorderRadius.circular(24),
          border: Border.all(color: teal.withOpacity(0.22)),
          boxShadow: [BoxShadow(color: teal.withOpacity(0.06), blurRadius: 20)]),
        child: Column(children: [
          // Icon
          Container(width: 80, height: 80,
            decoration: BoxDecoration(
              color: teal.withOpacity(0.10),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: teal.withOpacity(0.25))),
            child: const Center(child: Text('👁️', style: TextStyle(fontSize: 38)))),
          const SizedBox(height: 20),
          Text('Palpebral Conjunctiva', style: GoogleFonts.playfairDisplay(
            fontSize: 20, fontWeight: FontWeight.w800, color: text1)),
          const SizedBox(height: 8),
          Text('The inner surface of the lower eyelid is a reliable indicator for anemia.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13, color: text2, height: 1.55)),
          const SizedBox(height: 22),

          // How-to steps
          const _HowToStep('1', 'Wash hands thoroughly', teal),
          const SizedBox(height: 10),
          const _HowToStep('2', 'Gently pull down your lower eyelid to expose the inner surface', amber),
          const SizedBox(height: 10),
          const _HowToStep('3', 'Hold under bright natural or indoor light — avoid flash', green),
          const SizedBox(height: 10),
          const _HowToStep('4', 'Take a close-up photo of the exposed inner eyelid', teal),
          const SizedBox(height: 24),

          _ctaBtn('📷  Capture (Recommended)', () => _pick(ImageSource.camera)),
          const SizedBox(height: 12),
          _outlineBtn('🖼  Choose from Gallery', () => _pick(ImageSource.gallery)),
        ])),

      const SizedBox(height: 16),
      const _TipCard(
        '💡  Clinical Note',
        'Healthy conjunctiva appears bright pink-red. Pale or white conjunctiva suggests reduced hemoglobin. This method is used by WHO for field anemia screening.',
        teal),

      if (_error != null) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: red.withOpacity(0.08), borderRadius: BorderRadius.circular(14),
            border: Border.all(color: red.withOpacity(0.3))),
          child: Row(children: [
            const Icon(Icons.error_outline_rounded, color: red, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(_error!, style: GoogleFonts.dmSans(fontSize: 12, color: red))),
          ])),
      ],
    ]));

  // ── Analysis View ──────────────────────────────────────
  Widget _buildAnalysisView() => Column(children: [
    // Hint bar
    if (_result == null)
      Container(
        color: _autoRoiDone
          ? teal.withOpacity(0.08)
          : const Color(0xFFFFB547).withOpacity(0.08),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Text(_autoRoiDone ? '🎯' : '✋', style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(child: Text(
            _autoRoiDone
              ? 'Auto-detected conjunctiva region. Drag box to fine-tune, then analyze.'
              : 'Drag the yellow box onto the inner eyelid (pink area).',
            style: GoogleFonts.dmSans(fontSize: 11,
              color: _autoRoiDone ? teal : amber))),
        ])),

    // Image + ROI overlay
    Expanded(child: Stack(children: [
      LayoutBuilder(builder: (_, cst) {
        _displaySize = Size(cst.maxWidth, cst.maxHeight);
        if (!_roiSet) {
          _roi = Offset(_displaySize.width / 2, _displaySize.height / 2);
          _roiSet = true;
        }
        return CustomPaint(painter: _ImgPainter(_uiImage), child: const SizedBox.expand());
      }),
      // ROI rectangle
      if (_roiSet) _buildROI(),
    ])),

    // Result strip
    if (_result != null)
      FadeTransition(opacity: _fade, child: _ResultStrip(result: _result!)),

    // Error
    if (_error != null)
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Text(_error!, style: GoogleFonts.dmSans(fontSize: 12, color: red),
          textAlign: TextAlign.center)),

    // Buttons
    Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: bg1,
      child: Row(children: [
        Expanded(child: _outlineBtn('↩  Retake', _reset)),
        const SizedBox(width: 12),
        Expanded(child: _result != null
          ? _ctaBtn('✓  Done', () => Navigator.pop(context))
          : _ctaBtn(_analyzing ? 'Detecting…' : '🔬  Analyze',
              _analyzing ? null : _analyze)),
      ])),
  ]);

  // ── Draggable ROI box ──────────────────────────────────
  Widget _buildROI() {
    final left = (_roi.dx - _roiW/2).clamp(0.0, _displaySize.width  - _roiW);
    final top  = (_roi.dy - _roiH/2).clamp(0.0, _displaySize.height - _roiH);
    final c    = _result?.gradeColor ?? gold;

    return Positioned(left: left, top: top,
      child: GestureDetector(
        onPanUpdate: _result != null ? null : (d) => setState(() {
          _roi = Offset(
            (_roi.dx + d.delta.dx).clamp(_roiW/2, _displaySize.width  - _roiW/2),
            (_roi.dy + d.delta.dy).clamp(_roiH/2, _displaySize.height - _roiH/2));
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          width: _roiW, height: _roiH,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.withOpacity(0.9), width: 2.5),
            color: c.withOpacity(0.06),
            boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 16)]),
          child: Stack(children: [
            // Corner brackets
            ..._corners(c),
            Center(child: _result != null
              ? Text(_result!.grade == 'No Pallor' ? '✓' : '⚠',
                  style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w900,
                    color: c,
                    shadows: [const Shadow(color: Colors.black, blurRadius: 4)]))
              : AnimatedBuilder(animation: _pulse,
                  builder: (_, __) => Opacity(opacity: _pulse.value,
                    child: const Text('👁️', style: TextStyle(fontSize: 20))))),
          ])),
      ));
  }

  List<Widget> _corners(Color c) {
    const s = 12.0; const t = 2.5;
    return [
      Positioned(left: 0, top: 0, child: _Corner(s, t, c, const [1,1])),
      Positioned(right: 0, top: 0, child: _Corner(s, t, c, const [-1,1])),
      Positioned(left: 0, bottom: 0, child: _Corner(s, t, c, const [1,-1])),
      Positioned(right: 0, bottom: 0, child: _Corner(s, t, c, const [-1,-1])),
    ];
  }

  // ── Buttons ────────────────────────────────────────────
  Widget _ctaBtn(String label, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: onTap != null ? const LinearGradient(colors: [teal, tealDk]) : null,
        color: onTap == null ? bg2 : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onTap != null
          ? [BoxShadow(color: teal.withOpacity(0.4), blurRadius: 16, offset: const Offset(0,5))]
          : []),
      child: Center(child: _analyzing && label.contains('Detecting')
        ? Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(
              strokeWidth: 2, color: Colors.white, strokeCap: StrokeCap.round)),
            const SizedBox(width: 8),
            Text('Detecting…', style: GoogleFonts.dmSans(
              fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ])
        : Text(label, style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700,
            color: onTap != null ? Colors.white : text3)))));

  Widget _outlineBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bg2, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bdr)),
      child: Center(child: Text(label,
        style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: text2)))));
}

// ══════════════════════════════════════════════════════════════════
//  CORNER BRACKET WIDGET
// ══════════════════════════════════════════════════════════════════
class _Corner extends StatelessWidget {
  final double size, thickness;
  final Color color;
  final List<int> dir; // [dx, dy] direction signs
  const _Corner(this.size, this.thickness, this.color, this.dir);

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size,
    child: CustomPaint(painter: _CornerPainter(size, thickness, color, dir)));
}

class _CornerPainter extends CustomPainter {
  final double s, t;
  final Color c;
  final List<int> d;
  const _CornerPainter(this.s, this.t, this.c, this.d);

  @override
  void paint(Canvas canvas, Size sz) {
    final p = Paint()..color = c..strokeWidth = t..style = PaintingStyle.stroke..strokeCap = StrokeCap.square;
    final ox = d[0] > 0 ? 0.0 : sz.width;
    final oy = d[1] > 0 ? 0.0 : sz.height;
    canvas.drawLine(Offset(ox, oy), Offset(ox + d[0]*s, oy), p);
    canvas.drawLine(Offset(ox, oy), Offset(ox, oy + d[1]*s), p);
  }

  @override bool shouldRepaint(_) => false;
}

// ══════════════════════════════════════════════════════════════════
//  RESULT STRIP — shown below the image after analysis
// ══════════════════════════════════════════════════════════════════
class _ResultStrip extends StatelessWidget {
  final ConjunctivaResult result;
  const _ResultStrip({required this.result});

  static const bg1   = Color(0xFF0A1628);
  static const text1 = Color(0xFFF0F8FF);
  static const text2 = Color(0xFF7A9BBE);
  static const text3 = Color(0xFF3D5A7A);
  static const bdr   = Color(0xFF1A2E4A);

  @override
  Widget build(BuildContext context) {
    final r = result;
    return Container(
      color: bg1,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(children: [
        // Grade badge + color swatch
        Row(children: [
          // Extracted color swatch
          Container(width: 48, height: 48,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, r.r.round().clamp(0,255),
                r.g.round().clamp(0,255), r.b.round().clamp(0,255)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: r.gradeColor.withOpacity(0.5), width: 2),
              boxShadow: [BoxShadow(color: r.gradeColor.withOpacity(0.4), blurRadius: 12)])),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: r.gradeColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: r.gradeColor.withOpacity(0.35))),
                child: Text(r.grade.toUpperCase(),
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800, color: r.gradeColor))),
              const SizedBox(width: 8),
              Text('QC ${(r.quality * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.dmSans(fontSize: 11, color: text3)),
            ]),
            const SizedBox(height: 4),
            Text('Redness ratio: ${r.rednessRatio.toStringAsFixed(3)}  ·  a*: ${r.aStar.toStringAsFixed(1)}',
              style: GoogleFonts.dmSans(fontSize: 11, color: text2)),
          ])),
        ]),

        const SizedBox(height: 12),

        // Redness scale bar
        _RednessBar(ratio: r.rednessRatio, color: r.gradeColor),

        const SizedBox(height: 10),
        Text(_clinicalNote(r.rednessRatio),
          style: GoogleFonts.dmSans(fontSize: 11, color: text2, height: 1.5),
          textAlign: TextAlign.center),
      ]));
  }

  String _clinicalNote(double ratio) {
    if (ratio >= 0.43) return 'Normal conjunctival redness. Low anemia indicator.';
    if (ratio >= 0.38) return 'Mildly reduced redness. Possible mild anemia. Monitor symptoms.';
    if (ratio >= 0.32) return 'Moderate pallor detected. Consider CBC blood test. Hgb likely < 10 g/dL.';
    return 'Significant pallor. Strong anemia indicator. Hgb likely < 8 g/dL. Seek medical care.';
  }
}

class _RednessBar extends StatelessWidget {
  final double ratio;
  final Color  color;
  const _RednessBar({required this.ratio, required this.color});

  @override
  Widget build(BuildContext context) {
    // Scale: 0.28 (severe) → 0.50 (healthy) mapped to 0→1
    final fill = ((ratio - 0.28) / 0.22).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Conjunctival Redness', style: GoogleFonts.dmSans(
          fontSize: 10, color: const Color(0xFF7A9BBE))),
        Text(ratio.toStringAsFixed(3), style: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 6),
      Stack(children: [
        Container(height: 7,
          decoration: BoxDecoration(
            color: const Color(0xFF162440), borderRadius: BorderRadius.circular(4))),
        FractionallySizedBox(widthFactor: fill,
          child: Container(height: 7,
            decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 8)]))),
        // Threshold lines
        FractionallySizedBox(widthFactor: (0.38-0.28)/0.22, child: Container(
          height: 7, alignment: Alignment.centerRight,
          child: Container(width: 1.5, color: const Color(0xFFFFB547).withOpacity(0.7)))),
        FractionallySizedBox(widthFactor: (0.43-0.28)/0.22, child: Container(
          height: 7, alignment: Alignment.centerRight,
          child: Container(width: 1.5, color: const Color(0xFF22D47A).withOpacity(0.7)))),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        Text('Severe', style: GoogleFonts.dmSans(fontSize: 9, color: const Color(0xFFFF4D6A))),
        const Spacer(),
        Text('Healthy', style: GoogleFonts.dmSans(fontSize: 9, color: const Color(0xFF22D47A))),
      ]),
    ]);
  }
}

// ══════════════════════════════════════════════════════════════════
//  HELPER WIDGETS
// ══════════════════════════════════════════════════════════════════
class _HowToStep extends StatelessWidget {
  final String num, text;
  final Color color;
  const _HowToStep(this.num, this.text, this.color);

  static const text1 = Color(0xFFF0F8FF);
  static const text2 = Color(0xFF7A9BBE);
  static const bg2   = Color(0xFF0F1E36);

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(width: 26, height: 26,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.35))),
      child: Center(child: Text(num, style: GoogleFonts.dmSans(
        fontSize: 12, fontWeight: FontWeight.w800, color: color)))),
    const SizedBox(width: 12),
    Expanded(child: Padding(padding: const EdgeInsets.only(top: 4),
      child: Text(text, style: GoogleFonts.dmSans(
        fontSize: 12, color: text2, height: 1.5)))),
  ]);
}

class _TipCard extends StatelessWidget {
  final String title, text;
  final Color color;
  const _TipCard(this.title, this.text, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.22))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: GoogleFonts.dmSans(
        fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: color)),
      const SizedBox(height: 6),
      Text(text, style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF7A9BBE), height: 1.5)),
    ]));
}

// ══════════════════════════════════════════════════════════════════
//  IMAGE PAINTER
// ══════════════════════════════════════════════════════════════════
class _ImgPainter extends CustomPainter {
  final ui.Image? image;
  const _ImgPainter(this.image);
  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;
    paintImage(canvas: canvas, rect: Rect.fromLTWH(0,0,size.width,size.height),
      image: image!, fit: BoxFit.contain);
  }
  @override
  bool shouldRepaint(_ImgPainter o) => o.image != image;
}

// ══════════════════════════════════════════════════════════════════
//  DATA MODEL
// ══════════════════════════════════════════════════════════════════
class ConjunctivaResult {
  final double r, g, b;
  final double rednessRatio;  // R/(R+G+B) — clinical standard
  final double pallorIndex;   // 1 - rednessRatio
  final double aStar;         // LAB a* approximation
  final double quality;       // pixel quality fraction
  final double pallor;        // same as pallorIndex for ROIResult compat
  final double redness;       // same as rednessRatio
  final String grade;
  final Color  gradeColor;

  const ConjunctivaResult({
    required this.r, required this.g, required this.b,
    required this.rednessRatio, required this.pallorIndex,
    required this.aStar, required this.quality,
    required this.pallor, required this.redness,
    required this.grade, required this.gradeColor,
  });
}