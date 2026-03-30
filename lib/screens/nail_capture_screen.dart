import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/scan_provider.dart';

class NailCaptureScreen extends StatefulWidget {
  const NailCaptureScreen({super.key});
  @override
  State<NailCaptureScreen> createState() => _NailCaptureScreenState();
}

class _NailCaptureScreenState extends State<NailCaptureScreen> with TickerProviderStateMixin {
  File?        _imageFile;
  ui.Image?    _uiImage;
  img.Image?   _rawImage;
  Size         _displaySize = Size.zero;
  List<Offset> _rois        = [];
  List<ROIResult> _roiResults = [];
  bool         _analyzed    = false;
  bool         _analyzing   = false;
  String?      _error;

  late AnimationController _fadeCtrl;
  late Animation<double>   _fadeAnim;

  static const _roiSize = 52.0;
  static const _labels  = ['F1', 'F2', 'F3', 'F4'];

  static const bg      = Color(0xFFF0F4F8);
  static const white   = Colors.white;
  static const ink     = Color(0xFF0F172A);
  static const slate   = Color(0xFF64748B);
  static const teal    = Color(0xFF0D9488);
  static const tealDk  = Color(0xFF0F766E);
  static const green   = Color(0xFF22C55E);
  static const greenLt = Color(0xFFDCFCE7);
  static const red     = Color(0xFFEF4444);
  static const gold    = Color(0xFFFFD166);

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() { _fadeCtrl.dispose(); super.dispose(); }

  Future<void> _pick(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(source: src, imageQuality: 90);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final raw   = img.decodeImage(bytes);
      if (raw == null) { setState(() => _error = 'Cannot decode image.'); return; }
      setState(() {
        _imageFile = File(x.path); _uiImage = frame.image; _rawImage = raw;
        _analyzed = false; _roiResults = []; _rois = []; _error = null;
      });
    } catch (e) { setState(() => _error = 'Error: $e'); }
  }

  void _initROIs(Size sz) {
    if (_rois.length != 4) {
      _rois = [
        Offset(sz.width * 0.20, sz.height * 0.45),
        Offset(sz.width * 0.38, sz.height * 0.37),
        Offset(sz.width * 0.57, sz.height * 0.37),
        Offset(sz.width * 0.74, sz.height * 0.45),
      ];
    }
  }

  Future<void> _analyze() async {
    if (_rawImage == null) return;
    setState(() { _analyzing = true; _error = null; });
    await Future.delayed(const Duration(milliseconds: 80));
    try {
      final sx = _rawImage!.width  / _displaySize.width;
      final sy = _rawImage!.height / _displaySize.height;
      final mapped = _rois.map((r) => Offset(r.dx * sx, r.dy * sy)).toList();
      final res = ColorAnalysis.analyze(_rawImage!, mapped, size: (_roiSize * sx).round());
      if (res.isEmpty) { setState(() { _error = 'No valid ROI. Reposition markers.'; _analyzing = false; }); return; }
      setState(() { _roiResults = res; _analyzed = true; _analyzing = false; });
      _fadeCtrl.forward(from: 0);
    } catch (e) { setState(() { _error = 'Error: $e'; _analyzing = false; }); }
  }

  void _saveAndPop() {
    context.read<ScanProvider>().setNailData(_roiResults);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: bg,
    body: SafeArea(child: Column(children: [
      _header(),
      Expanded(child: _imageFile == null ? _uploadZone() : _analysisView()),
    ])),
  );

  Widget _header() => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    color: white,
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0))),
          child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: ink)),
      ),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Nail Bed Analysis', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: ink)),
        Text('Position markers on each fingernail', style: GoogleFonts.poppins(fontSize: 11, color: slate)),
      ])),
    ]),
  );

  Widget _uploadZone() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(children: [
      const SizedBox(height: 20),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0,4))]),
        child: Column(children: [
          Container(width: 80, height: 80,
            decoration: BoxDecoration(color: greenLt, borderRadius: BorderRadius.circular(24)),
            child: const Center(child: Text('💅', style: TextStyle(fontSize: 40)))),
          const SizedBox(height: 20),
          Text('Capture Fingernail Photo',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: ink)),
          const SizedBox(height: 8),
          Text('Take a clear photo of all 4 fingers.\nAvoid nail polish, shadows and flash glare.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 13, color: slate, height: 1.5)),
          const SizedBox(height: 28),
          _ctaBtn('📷  Open Camera', () => _pick(ImageSource.camera)),
          const SizedBox(height: 12),
          _outlineBtn('🖼   Choose from Gallery', () => _pick(ImageSource.gallery)),
        ]),
      ),
      const SizedBox(height: 16),
      _tipCard('Hold your hand flat against a light surface. Use natural or indoor lighting — no flash.'),
      if (_error != null) Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Text(_error!, style: GoogleFonts.poppins(fontSize: 12, color: red))),
    ]),
  );

  Widget _analysisView() => Column(children: [
    if (!_analyzed)
      Container(color: const Color(0xFFFFFBEB),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          const Text('🟡', style: TextStyle(fontSize: 14)), const SizedBox(width: 8),
          Expanded(child: Text('Drag the yellow markers onto each nail bed',
            style: GoogleFonts.poppins(fontSize: 12, color: const Color(0xFF92400E)))),
        ])),

    Expanded(child: Stack(children: [
      LayoutBuilder(builder: (_, cst) {
        _displaySize = Size(cst.maxWidth, cst.maxHeight);
        _initROIs(_displaySize);
        return CustomPaint(painter: _ImgPainter(_uiImage), child: const SizedBox.expand());
      }),
      for (int i = 0; i < _rois.length; i++) _marker(i),
    ])),

    if (_analyzed)
      FadeTransition(opacity: _fadeAnim, child: Container(
        color: white, padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: Row(children: [
          for (int i = 0; i < _roiResults.length && i < 4; i++)
            Padding(padding: const EdgeInsets.only(right: 10),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 34, height: 34,
                  decoration: BoxDecoration(color: _roiResults[i].color,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: _roiResults[i].color.withOpacity(0.5), blurRadius: 8)])),
                const SizedBox(height: 3),
                Text(_labels[i], style: GoogleFonts.poppins(fontSize: 9, color: slate)),
                Text(_roiResults[i].isPale ? 'pale' : '✓',
                  style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700,
                    color: _roiResults[i].isPale ? const Color(0xFFF97316) : green)),
              ])),
          const Spacer(),
          if (_roiResults.isNotEmpty)
            Text('QC ${(_roiResults.map((r)=>r.quality).reduce((a,b)=>a+b)/_roiResults.length*100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(fontSize: 11, color: slate)),
        ]),
      )),

    if (_error != null) Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(_error!, style: GoogleFonts.poppins(fontSize: 12, color: red), textAlign: TextAlign.center)),

    Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16), color: white,
      child: Row(children: [
        Expanded(child: _outlineBtn('↩  Retake',
          () => setState(() { _imageFile = null; _analyzed = false; _roiResults = []; _rois = []; }))),
        const SizedBox(width: 12),
        Expanded(child: _analyzed
          ? _ctaBtn('✓  Use Results', _saveAndPop)
          : _ctaBtn(_analyzing ? 'Analyzing…' : '🔬  Analyze', _analyzing ? null : _analyze)),
      ]),
    ),
  ]);

  Widget _marker(int i) {
    final roi    = _rois[i];
    final result = _analyzed && i < _roiResults.length ? _roiResults[i] : null;
    return Positioned(
      left: roi.dx - _roiSize/2, top: roi.dy - _roiSize/2,
      child: GestureDetector(
        onPanUpdate: _analyzed ? null : (d) => setState(() {
          _rois[i] = Offset(
            (roi.dx + d.delta.dx).clamp(_roiSize/2, _displaySize.width  - _roiSize/2),
            (roi.dy + d.delta.dy).clamp(_roiSize/2, _displaySize.height - _roiSize/2));
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _roiSize, height: _roiSize,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: result != null ? result.color.withOpacity(0.9) : gold.withOpacity(0.85), width: 2.5),
            color: result != null ? result.color.withOpacity(0.2) : gold.withOpacity(0.08),
            boxShadow: result != null ? [BoxShadow(color: result.color.withOpacity(0.5), blurRadius: 14)] : [],
          ),
          child: Center(child: Text(
            result != null ? (result.isPale ? '⚠' : '✓') : _labels[i],
            style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w800,
              color: result != null ? Colors.white : gold,
              shadows: [const Shadow(color: Colors.black45, blurRadius: 4)]))),
        ),
      ),
    );
  }

  Widget _ctaBtn(String label, VoidCallback? onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        gradient: onTap != null ? const LinearGradient(colors: [teal, tealDk]) : null,
        color: onTap == null ? const Color(0xFFE2E8F0) : null,
        borderRadius: BorderRadius.circular(14),
        boxShadow: onTap != null ? [BoxShadow(color: teal.withOpacity(0.4), blurRadius: 14, offset: const Offset(0,5))] : [],
      ),
      child: Center(child: _analyzing && label.contains('Analyzing')
        ? Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            const SizedBox(width: 8),
            Text('Analyzing…', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          ])
        : Text(label, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700,
            color: onTap != null ? Colors.white : slate))),
    ),
  );

  Widget _outlineBtn(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Center(child: Text(label,
        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600, color: slate))),
    ),
  );

  Widget _tipCard(String text) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFA7F3D0))),
    child: Row(children: [
      const Text('💡', style: TextStyle(fontSize: 18)), const SizedBox(width: 10),
      Expanded(child: Text(text, style: GoogleFonts.poppins(fontSize: 11, color: const Color(0xFF065F46), height: 1.4))),
    ]),
  );
}

class _ImgPainter extends CustomPainter {
  final ui.Image? image;
  const _ImgPainter(this.image);
  @override
  void paint(Canvas canvas, Size size) {
    if (image == null) return;
    paintImage(canvas: canvas, rect: Rect.fromLTWH(0,0,size.width,size.height), image: image!, fit: BoxFit.contain);
  }
  @override
  bool shouldRepaint(_ImgPainter o) => o.image != image;
}