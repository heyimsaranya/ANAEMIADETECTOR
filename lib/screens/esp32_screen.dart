import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/scan_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  ESP32 Screen — Clinical Dark
// ══════════════════════════════════════════════════════════════════
class ESP32Screen extends StatefulWidget {
  const ESP32Screen({super.key});
  @override
  State<ESP32Screen> createState() => _ESP32ScreenState();
}

class _ESP32ScreenState extends State<ESP32Screen> with TickerProviderStateMixin {
  final _ipCtrl = TextEditingController();
  late final AnimationController _signalCtrl;

  static const bg0    = Color(0xFF050D1A);
  static const bg1    = Color(0xFF0A1628);
  static const bg2    = Color(0xFF0F1E36);
  static const bg3    = Color(0xFF162440);
  static const teal   = Color(0xFF00D4C8);
  static const tealDk = Color(0xFF00A89E);
  static const text1  = Color(0xFFF0F8FF);
  static const text2  = Color(0xFF7A9BBE);
  static const text3  = Color(0xFF3D5A7A);
  static const bdr    = Color(0xFF1A2E4A);
  static const green  = Color(0xFF22D47A);
  static const amber  = Color(0xFFFFB547);
  static const red    = Color(0xFFFF4D6A);
  static const blue   = Color(0xFF4D9EFF);

  @override
  void initState() {
    super.initState();
    _signalCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
    final scan = context.read<ScanProvider>();
    _ipCtrl.text = scan.esp32IP;
  }

  @override
  void dispose() { _signalCtrl.dispose(); _ipCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<ScanProvider>();
    final ok   = scan.wsStatus == 'connected';
    final busy = scan.wsStatus == 'connecting';
    final err  = scan.wsStatus == 'error';

    Color statusColor = ok ? green : busy ? amber : err ? red : text3;
    String statusText = ok ? '● Live Connection — ${scan.esp32IP}'
      : busy ? '◌  Connecting to ${_ipCtrl.text}…'
      : err  ? '✕  Connection failed'
      :         '○  Not connected';

    return Scaffold(
      backgroundColor: bg0,
      body: SafeArea(child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // Header
          Text('SENSOR', style: GoogleFonts.dmSans(
            fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700, color: teal)),
          Text('ESP32 Configuration', style: GoogleFonts.playfairDisplay(
            fontSize: 24, fontWeight: FontWeight.w900, color: text1)),
          const SizedBox(height: 22),

          // Connection diagram
          _ConnectionDiagram(connected: ok, signal: _signalCtrl),
          const SizedBox(height: 18),

          // Status bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: statusColor.withOpacity(0.3))),
            child: Text(statusText,
              style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w700, color: statusColor))),
          const SizedBox(height: 18),

          // IP input card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bg1, borderRadius: BorderRadius.circular(22),
              border: Border.all(color: bdr),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0,4))]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('IP ADDRESS', style: GoogleFonts.dmSans(
                fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: teal)),
              const SizedBox(height: 4),
              Text('Same Wi-Fi as phone  ·  WebSocket port 81',
                style: GoogleFonts.dmSans(fontSize: 11, color: text2)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: Container(
                  decoration: BoxDecoration(
                    color: bg3, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: bdr)),
                  child: TextField(
                    controller: _ipCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: GoogleFonts.sourceCodePro(fontSize: 15, color: text1, fontWeight: FontWeight.w600),
                    decoration: InputDecoration(
                      hintText: '192.168.1.100',
                      hintStyle: GoogleFonts.sourceCodePro(fontSize: 15, color: text3),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none)))),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: busy ? null : () => scan.connectESP32(_ipCtrl.text.trim()),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: busy ? null : const LinearGradient(colors: [teal, tealDk]),
                      color: busy ? bg3 : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: busy ? [] : [BoxShadow(color: teal.withOpacity(0.4), blurRadius: 16, offset: const Offset(0,6))]),
                    child: busy
                      ? const SizedBox(width: 20, height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: teal, strokeCap: StrokeCap.round))
                      : Text('Connect', style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)))),
              ]),
            ])),
          const SizedBox(height: 18),

          // Live data cards
          if (ok) ...[
            Text('LIVE DATA', style: GoogleFonts.dmSans(
              fontSize: 10, letterSpacing: 2, fontWeight: FontWeight.w700, color: teal)),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _LiveCard('❤️', 'Heart Rate',
                scan.hr != null ? '${scan.hr!.toStringAsFixed(0)} bpm' : '-- bpm',
                red, scan.hrAbnormal, 'Elevated')),
              const SizedBox(width: 12),
              Expanded(child: _LiveCard('🫁', 'SpO₂',
                scan.spo2 != null ? '${scan.spo2!.toStringAsFixed(0)} %' : '-- %',
                blue, scan.spo2Abnormal, 'Low')),
            ]),
            const SizedBox(height: 18),
          ],

          // Manual entry
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bg1, borderRadius: BorderRadius.circular(22),
              border: Border.all(color: bdr)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: bg3, borderRadius: BorderRadius.circular(8)),
                  child: Text('MANUAL ENTRY', style: GoogleFonts.dmSans(
                    fontSize: 9, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: text3))),
              ]),
              const SizedBox(height: 4),
              Text('Fallback if sensor is unavailable',
                style: GoogleFonts.dmSans(fontSize: 11, color: text2)),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(child: _ManualField('Heart Rate', 'bpm',
                  scan.hr?.toStringAsFixed(0), (v) => scan.setManualHR(double.tryParse(v)))),
                const SizedBox(width: 14),
                Expanded(child: _ManualField('SpO₂', '%',
                  scan.spo2?.toStringAsFixed(0), (v) => scan.setManualSpo2(double.tryParse(v)))),
              ]),
            ])),
          const SizedBox(height: 18),

          // Firmware hint
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: teal.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: teal.withOpacity(0.20))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('💡  FIRMWARE FORMAT', style: GoogleFonts.dmSans(
                fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.w700, color: teal)),
              const SizedBox(height: 8),
              Text('{ "hr": 78, "spo2": 97, "valid": 1 }',
                style: GoogleFonts.sourceCodePro(fontSize: 13, color: text2, height: 1.5)),
              const SizedBox(height: 4),
              Text('Broadcast JSON on WebSocket port 81',
                style: GoogleFonts.dmSans(fontSize: 11, color: text3)),
            ])),
        ]),
      )));
  }
}

// ── Connection Diagram ────────────────────────────────────
class _ConnectionDiagram extends StatelessWidget {
  final bool connected;
  final AnimationController signal;
  const _ConnectionDiagram({required this.connected, required this.signal});

  static const bg1  = Color(0xFF0A1628);
  static const bg3  = Color(0xFF162440);
  static const bdr  = Color(0xFF1A2E4A);
  static const teal = Color(0xFF00D4C8);
  static const text2 = Color(0xFF7A9BBE);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
    decoration: BoxDecoration(
      color: bg1, borderRadius: BorderRadius.circular(22),
      border: Border.all(color: bdr),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 14)]),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      _Node('📱', 'Phone', teal, true),
      const SizedBox(width: 12),
      AnimatedBuilder(animation: signal, builder: (_, __) => Row(
        children: List.generate(5, (i) {
          final lit = connected && ((signal.value * 5 - i).abs() < 1.2);
          return Container(
            width: 10, height: 3, margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: lit ? teal : const Color(0xFF162440),
              borderRadius: BorderRadius.circular(2),
              boxShadow: lit ? [BoxShadow(color: teal.withOpacity(0.6), blurRadius: 6)] : []));
        }))),
      const SizedBox(width: 12),
      _Node('📡', 'ESP32', connected ? teal : const Color(0xFF3D5A7A), connected),
      const SizedBox(width: 12),
      _ConnLine(),
      const SizedBox(width: 12),
      _Node('🩸', 'MAX30105', const Color(0xFFFF4D6A), true),
    ]));

  static Widget _Node(String icon, String label, Color c, bool active) =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 48, height: 48,
        decoration: BoxDecoration(
          color: c.withOpacity(0.10),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: active ? c.withOpacity(0.35) : const Color(0xFF1A2E4A)),
          boxShadow: active ? [BoxShadow(color: c.withOpacity(0.15), blurRadius: 12)] : []),
        child: Center(child: Text(icon, style: const TextStyle(fontSize: 22)))),
      const SizedBox(height: 6),
      Text(label, style: GoogleFonts.dmSans(fontSize: 10, color: text2)),
    ]);

  static Widget _ConnLine() => Container(
    width: 2, height: 36,
    color: const Color(0xFF1A2E4A));
}

// ── Live Card ─────────────────────────────────────────────
class _LiveCard extends StatelessWidget {
  final String icon, label, value, warnText;
  final Color color;
  final bool warn;
  const _LiveCard(this.icon, this.label, this.value, this.color, this.warn, this.warnText);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withOpacity(0.22))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(icon, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Expanded(child: Text(label, style: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w600, color: color))),
      ]),
      const SizedBox(height: 8),
      Text(value, style: GoogleFonts.dmSans(
        fontSize: 22, fontWeight: FontWeight.w900,
        color: const Color(0xFFF0F8FF))),
      if (warn) Padding(padding: const EdgeInsets.only(top: 4),
        child: Text('⚠ $warnText', style: GoogleFonts.dmSans(
          fontSize: 10, fontWeight: FontWeight.w700,
          color: const Color(0xFFFF4D6A)))),
    ]));
}

// ── Manual Field ──────────────────────────────────────────
class _ManualField extends StatefulWidget {
  final String label, unit;
  final String? initial;
  final ValueChanged<String> onChanged;
  const _ManualField(this.label, this.unit, this.initial, this.onChanged);

  @override
  State<_ManualField> createState() => _ManualFieldState();
}

class _ManualFieldState extends State<_ManualField> {
  late final TextEditingController _ctrl;

  static const bg3   = Color(0xFF162440);
  static const bdr   = Color(0xFF1A2E4A);
  static const text1 = Color(0xFFF0F8FF);
  static const text2 = Color(0xFF7A9BBE);
  static const text3 = Color(0xFF3D5A7A);

  @override
  void initState() { super.initState(); _ctrl = TextEditingController(text: widget.initial ?? ''); }
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(widget.label, style: GoogleFonts.dmSans(fontSize: 11, color: text2)),
    const SizedBox(height: 6),
    Container(
      decoration: BoxDecoration(
        color: bg3, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdr)),
      child: Row(children: [
        Expanded(child: TextField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          onChanged: widget.onChanged,
          style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: text1),
          decoration: InputDecoration(
            hintText: '--',
            hintStyle: GoogleFonts.dmSans(fontSize: 20, color: text3),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: InputBorder.none))),
        Padding(padding: const EdgeInsets.only(right: 12),
          child: Text(widget.unit, style: GoogleFonts.dmSans(fontSize: 12, color: text3))),
      ])),
  ]);
}