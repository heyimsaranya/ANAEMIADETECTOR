import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/scan_provider.dart';
import 'nail_capture_screen.dart';
import 'palm_capture_screen.dart';
import 'conjunctiva_capture_screen.dart';
import 'questionnaire_screen.dart';
import 'result_screen.dart';
import 'esp32_screen.dart';

// ══════════════════════════════════════════════════════════════════
//  DESIGN TOKENS — Clinical Dark (Strictly No Emojis)
// ══════════════════════════════════════════════════════════════════
class D {
  static const bg0    = Color(0xFF050D1A);
  static const bg1    = Color(0xFF0A1628);
  static const bg2    = Color(0xFF0F1E36);
  static const bg3    = Color(0xFF162440);
  static const teal   = Color(0xFF00D4C8);
  static const tealDk = Color(0xFF00A89E);
  static const green  = Color(0xFF22D47A);
  static const amber  = Color(0xFFFFB547);
  static const red    = Color(0xFFFF4D6A);
  static const blue   = Color(0xFF4D9EFF);
  static const purp   = Color(0xFFB47FFF);
  static const text1  = Color(0xFFF0F8FF);
  static const text2  = Color(0xFF7A9BBE);
  static const text3  = Color(0xFF3D5A7A);
  static const bdr    = Color(0xFF1A2E4A);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _tab = 0;
  late final AnimationController _ecgCtrl;
  late final AnimationController _dotCtrl;

  @override
  void initState() {
    super.initState();
    _ecgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
    _dotCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  }

  @override
  void dispose() { 
    _ecgCtrl.dispose(); 
    _dotCtrl.dispose(); 
    super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<ScanProvider>();
    return Scaffold(
      backgroundColor: D.bg0,
      body: IndexedStack(index: _tab, children: [
        _DashPage(ecgCtrl: _ecgCtrl, dotCtrl: _dotCtrl, onTab: (i) => setState(() => _tab = i)),
        _ScanPage(onTab: (i) => setState(() => _tab = i)),
        scan.result == null
          ? _EmptyReports(onScan: () => setState(() => _tab = 1))
          : ResultScreen(result: scan.result!, onNewScan: () { scan.reset(); setState(() => _tab = 1); }),
        const ESP32Screen(),
      ]),
      bottomNavigationBar: _NavBar(tab: _tab, onTap: (i) => setState(() => _tab = i)),
    );
  }
}

class _DashPage extends StatelessWidget {
  final AnimationController ecgCtrl, dotCtrl;
  final ValueChanged<int> onTab;
  const _DashPage({required this.ecgCtrl, required this.dotCtrl, required this.onTab});

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<ScanProvider>();
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.split(' ').first ?? 'Doctor';

    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Clinical Dashboard, $name', style: GoogleFonts.dmSans(fontSize: 13, color: D.text2)),
            const SizedBox(height: 2),
            Text('HemoScan AI', style: GoogleFonts.playfairDisplay(
              fontSize: 26, fontWeight: FontWeight.w900, color: D.text1)),
          ])),
          _Avatar(user: user),
        ]),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: _HrCard(ecgCtrl: ecgCtrl, dotCtrl: dotCtrl, scan: scan)),
          const SizedBox(width: 12),
          Expanded(child: _Spo2Card(scan: scan)),
        ]),
        const SizedBox(height: 24),
        
        // REQUESTED CHANGE: Hero Banner
        _HeroBanner(),
        
        const SizedBox(height: 24),
        _SectionLabel('ANALYSIS MODULES'),
        const SizedBox(height: 14),
        _ModuleGrid(onTab: onTab, context: context),
        const SizedBox(height: 24),
        _SectionLabel('SESSION STATUS'),
        const SizedBox(height: 12),
        _SessionStatus(scan: scan),
      ]),
    ));
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        color: D.bg1,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: D.bdr),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // RIGHT CENTER: Doctor/Patient Image
            Positioned(
              right: 0, top: 0, bottom: 0,
              width: MediaQuery.of(context).size.width * 0.5,
              child: Image.network(
                'https://images.unsplash.com/photo-1579684385127-1ef15d508118?auto=format&fit=crop&q=80&w=500',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(color: D.bg3),
              ),
            ),
            // Gradient to blend the image into the background
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft, end: Alignment.centerRight,
                    colors: [D.bg1, D.bg1.withOpacity(0.8), Colors.transparent],
                    stops: const [0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // LEFT CENTER: Wordings and Google Logo
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('HEMOSCAN PROJECT', 
                    style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w800, color: D.teal, letterSpacing: 1.2)),
                  const SizedBox(height: 4),
                  Text('Precision AI\nDiagnostics', 
                    style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.w900, color: D.text1, height: 1.1)),
                  const SizedBox(height: 16),
                  // Google Sign
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.network('https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/1200px-Google_%22G%22_logo.svg.png', height: 12),
                        const SizedBox(width: 6),
                        Text('Google Cloud AI', style: GoogleFonts.dmSans(fontSize: 9, fontWeight: FontWeight.bold, color: D.text2)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleGrid extends StatelessWidget {
  final ValueChanged<int> onTab;
  final BuildContext context;
  const _ModuleGrid({required this.onTab, required this.context});

  @override
  Widget build(BuildContext ctx) {
    final items = [
      _Mod(Icons.remove_red_eye, 'Conjunctiva', const Color(0xFFB47FFF), 
        () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const ConjunctivaCaptureScreen()))),
      _Mod(Icons.back_hand, 'Nail Bed', D.green, 
        () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const NailCaptureScreen()))),
      _Mod(Icons.front_hand, 'Palm Color', D.amber, 
        () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const PalmCaptureScreen()))),
      _Mod(Icons.settings_input_component, 'Sensor Data', D.teal, 
        () => onTab(3)),
      
      // NEW MODULE ADDED HERE
      _Mod(Icons.assignment_outlined, 'Questionnaire', D.blue, 
        () => Navigator.push(ctx, MaterialPageRoute(builder: (_) => const QuestionnaireScreen()))),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        final m = items[index];
        return GestureDetector(
          onTap: m.action,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: D.bg1, 
              borderRadius: BorderRadius.circular(18), 
              border: Border.all(color: D.bdr),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(m.icon, color: m.color, size: 24),
                Text(m.label, 
                  style: GoogleFonts.dmSans(
                    fontSize: 13, 
                    fontWeight: FontWeight.bold, 
                    color: D.text1,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Mod {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback action;
  const _Mod(this.icon, this.label, this.color, this.action);
}

class _SessionStatus extends StatelessWidget {
  final ScanProvider scan;
  const _SessionStatus({required this.scan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: D.bg1, borderRadius: BorderRadius.circular(20), border: Border.all(color: D.bdr)),
      child: Column(children: [
        _row(Icons.wifi, 'Hardware Link', scan.wsStatus == 'connected' ? 'Connected' : 'Disconnected', scan.wsStatus == 'connected' ? D.green : D.text3),
        const Divider(color: D.bdr, height: 24),
        _row(Icons.remove_red_eye_outlined, 'Palpebral Conjunctiva Pallor Analysis',
          scan.conjunctivaData != null ? 'Captured' : 'Pending',
          scan.conjunctivaData != null ? D.green : D.text3),
        const Divider(color: D.bdr, height: 24),
        _row(Icons.cloud_done, 'Database', 'Cloud Ready', D.blue),
      ]));
  }

  Widget _row(IconData ic, String label, String status, Color c) => Row(children: [
    Icon(ic, size: 18, color: D.text2),
    const SizedBox(width: 12),
    Expanded(child: Text(label, style: GoogleFonts.dmSans(fontSize: 13, color: D.text2))),
    Text(status, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w800, color: c)),
  ]);
}

class _HrCard extends StatelessWidget {
  final AnimationController ecgCtrl, dotCtrl;
  final ScanProvider scan;
  const _HrCard({required this.ecgCtrl, required this.dotCtrl, required this.scan});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: D.bg1, borderRadius: BorderRadius.circular(20), border: Border.all(color: D.bdr)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('HEART RATE', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: D.text2)),
        AnimatedBuilder(animation: dotCtrl, builder: (_, __) => Icon(Icons.favorite, size: 14, color: scan.sensorLive ? D.red.withOpacity(dotCtrl.value) : D.text3)),
      ]),
      const SizedBox(height: 8),
      Text(scan.hr != null ? '${scan.hr!.toInt()} BPM' : '--', style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w900, color: D.text1)),
    ]));
}

class _Spo2Card extends StatelessWidget {
  final ScanProvider scan;
  const _Spo2Card({required this.scan});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: D.bg1, borderRadius: BorderRadius.circular(20), border: Border.all(color: D.bdr)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('SPO2 LEVEL', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w700, color: D.text2)),
      const SizedBox(height: 8),
      Text(scan.spo2 != null ? '${scan.spo2!.toInt()}%' : '--', style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w900, color: D.text1)),
    ]));
}

class _Avatar extends StatelessWidget {
  final User? user;
  const _Avatar({required this.user});
  @override
  Widget build(BuildContext context) => Container(
    width: 44, height: 44,
    decoration: BoxDecoration(color: D.bg3, borderRadius: BorderRadius.circular(12), border: Border.all(color: D.teal.withOpacity(0.3))),
    child: const Icon(Icons.person, color: D.teal, size: 20),
  );
}

class _NavBar extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTap;
  const _NavBar({required this.tab, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: tab, onTap: onTap,
      backgroundColor: D.bg1, selectedItemColor: D.teal, unselectedItemColor: D.text3,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.camera_rounded), label: 'Scan'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment_rounded), label: 'Reports'),
        BottomNavigationBarItem(icon: Icon(Icons.sensors_rounded), label: 'Sensor'),
      ],
    );
  }
}

class _EmptyReports extends StatelessWidget {
  final VoidCallback onScan;
  const _EmptyReports({required this.onScan});
  @override
  Widget build(BuildContext context) => const Center(child: Text('No Reports Yet', style: TextStyle(color: D.text2)));
}

// ══════════════════════════════════════════════════════════════════
//  SCAN PAGE
// ══════════════════════════════════════════════════════════════════
class _ScanPage extends StatelessWidget {
  final ValueChanged<int>? onTab;
  const _ScanPage({required this.onTab});

  @override
  Widget build(BuildContext context) {
    final scan = context.watch<ScanProvider>();
    return SafeArea(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('New Scan', style: GoogleFonts.playfairDisplay(
          fontSize: 24, fontWeight: FontWeight.w900, color: D.text1)),
        const SizedBox(height: 4),
        Text('Complete all modules for maximum diagnostic accuracy.',
          style: GoogleFonts.dmSans(fontSize: 12, color: D.text2)),
        const SizedBox(height: 24),

        _StepCard(
          num: '01',
          title: 'Hardware System',
          subtitle: 'Connect ESP32 + MAX30105 optical sensor for live heart rate and arterial oxygen saturation.',
          icon: Icons.settings_input_component_outlined,
          color: D.teal,
          done: scan.sensorLive,
          onTap: () => onTab?.call(3),
          trailing: scan.hr != null ? Row(children: [
            _Tag('HR  ${scan.hr!.toInt()} BPM', D.red),
            const SizedBox(width: 8),
            _Tag('SpO₂  ${scan.spo2?.toInt() ?? '--'} %', D.blue),
          ]) : null),
        const SizedBox(height: 12),

        _StepCard(
          num: '02',
          title: 'Palpebral Conjunctiva Pallor Analysis',
          subtitle: 'Photograph the inner lower eyelid. Redness ratio is the most clinically reliable non-invasive anemia indicator.',
          icon: Icons.remove_red_eye_outlined,
          color: D.purp,
          done: scan.conjunctivaData != null,
          badge: 'HIGHEST ACCURACY · 35 pts',
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const ConjunctivaCaptureScreen())),
          trailing: scan.conjunctivaData != null
            ? _ConjunctivaInline(scan.conjunctivaData!) : null),
        const SizedBox(height: 12),

        _StepCard(
          num: '03',
          title: 'Nail Bed Pallor Detection',
          subtitle: 'Position ROI markers on each fingernail bed to extract mean chrominance for pallor index scoring.',
          icon: Icons.back_hand_outlined,
          color: D.green,
          done: scan.nailData != null,
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const NailCaptureScreen())),
          trailing: scan.nailData != null ? _RoiColorRow(scan.nailData!, 4) : null),
        const SizedBox(height: 12),

        _StepCard(
          num: '04',
          title: 'Palmar Pallor Analysis',
          subtitle: 'Sample thenar and hypothenar eminence regions for palmar crease redness ratio analysis.',
          icon: Icons.front_hand_outlined,
          color: D.amber,
          done: scan.palmData != null,
          onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => const PalmCaptureScreen())),
          trailing: scan.palmData != null ? _RoiColorRow(scan.palmData!, 3) : null),
        const SizedBox(height: 12),

        // Inside _ScanPage Column...

_StepCard(
  num: '05',
  title: 'Clinical Symptom Questionnaire',
  subtitle: '10 validated questions covering fatigue, dyspnoea, pallor, palpitations, and dietary risk factors.',
  icon: Icons.assignment_outlined,
  color: D.blue,
  done: scan.questionnaireOk, // This checks if the scan is completed
  badge: '20 pts · Self-reported',
  onTap: () {
    // Debug print to ensure the tap is registered
    print("Navigating to Questionnaire..."); 
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => const QuestionnaireScreen())
    );
  },
  trailing: scan.questionnaireOk
    ? _SymptomScoreTag(scan.symptomScore!, scan.symptomMax!)
    : null,
),

const SizedBox(height: 32),

// 2. The Final Analysis Button (The "Submit" Button)
// This button only becomes "Accessible" once the modules are done.
GestureDetector(
  onTap: scan.canAnalyze 
    ? () { 
        scan.analyze(); 
        onTab?.call(2); // Moves to the Reports Tab
      } 
    : () {
        // Optional: Show a snackbar if they try to click it while disabled
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please complete the Questionnaire to finish.'))
        );
      },
  child: AnimatedContainer(
    duration: const Duration(milliseconds: 220),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 18),
    decoration: BoxDecoration(
      gradient: scan.canAnalyze
        ? const LinearGradient(colors: [D.teal, D.tealDk]) 
        : null,
      color: scan.canAnalyze ? null : D.bg2,
      borderRadius: BorderRadius.circular(18),
      boxShadow: scan.canAnalyze
        ? [BoxShadow(color: D.teal.withOpacity(0.40), blurRadius: 24, offset: const Offset(0, 8))] 
        : [],
    ),
    child: Center(
      child: Text(
        scan.canAnalyze
          ? 'Compute Anemia Risk Score'
          : 'Complete Questionnaire to Analyze',
        style: GoogleFonts.dmSans(
          fontSize: 14, 
          fontWeight: FontWeight.w800,
          color: scan.canAnalyze ? Colors.white : D.text3,
          letterSpacing: 0.2,
        ),
      ),
    ),
  ),
),

        // Analyze CTA
        GestureDetector(
          onTap: scan.canAnalyze ? () { scan.analyze(); onTab?.call(2); } : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              gradient: scan.canAnalyze
                ? const LinearGradient(colors: [D.teal, D.tealDk]) : null,
              color: scan.canAnalyze ? null : D.bg2,
              borderRadius: BorderRadius.circular(18),
              boxShadow: scan.canAnalyze
                ? [BoxShadow(color: D.teal.withOpacity(0.40),
                    blurRadius: 24, offset: const Offset(0, 8))] : []),
            child: Center(child: Text(
              scan.canAnalyze
                ? 'Compute Anemia Risk Score'
                : 'Complete at least one module to proceed',
              style: GoogleFonts.dmSans(
                fontSize: 14, fontWeight: FontWeight.w800,
                color: scan.canAnalyze ? Colors.white : D.text3,
                letterSpacing: 0.2))))),
      ]),
    ));
  }
}

// ── Step Card ──────────────────────────────────────────────
class _StepCard extends StatelessWidget {
  final String num, title, subtitle;
  final IconData icon;
  final Color color;
  final bool done;
  final String? badge;
  final Widget? trailing;
  final VoidCallback onTap;
  const _StepCard({required this.num, required this.title, required this.subtitle,
    required this.icon, required this.color, required this.done,
    required this.onTap, this.badge, this.trailing});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: D.bg1, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: done ? color.withOpacity(0.28) : D.bdr),
        boxShadow: [BoxShadow(
          color: done ? color.withOpacity(0.05) : Colors.black38,
          blurRadius: 14, offset: const Offset(0, 4))]),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 46, height: 46,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.20))),
          child: Icon(icon, color: color, size: 20)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('$num.  ', style: GoogleFonts.dmSans(
              fontSize: 11, color: D.text3, fontWeight: FontWeight.w600)),
            Expanded(child: Text(title, style: GoogleFonts.dmSans(
              fontSize: 12, fontWeight: FontWeight.w800, color: D.text1))),
            _DoneChip(done, color),
          ]),
          if (badge != null && !done) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(5)),
              child: Text(badge!, style: GoogleFonts.dmSans(
                fontSize: 8, fontWeight: FontWeight.w800,
                color: color, letterSpacing: 0.8))),
          ],
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.dmSans(
            fontSize: 10, color: D.text2, height: 1.5)),
          if (trailing != null) ...[const SizedBox(height: 8), trailing!],
        ])),
      ])));
}

Widget _DoneChip(bool done, Color c) => done
  ? Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: D.green.withOpacity(0.10), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: D.green.withOpacity(0.30))),
      child: Text('Done', style: GoogleFonts.dmSans(
        fontSize: 9, fontWeight: FontWeight.w800, color: D.green)))
  : Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08), borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.25))),
      child: Text('Tap to begin', style: GoogleFonts.dmSans(
        fontSize: 9, fontWeight: FontWeight.w600, color: c)));

Widget _Tag(String t, Color c) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  decoration: BoxDecoration(
    color: c.withOpacity(0.10), borderRadius: BorderRadius.circular(20),
    border: Border.all(color: c.withOpacity(0.28))),
  child: Text(t, style: GoogleFonts.dmSans(
    fontSize: 10, fontWeight: FontWeight.w700, color: c)));

class _RoiColorRow extends StatelessWidget {
  final List<ROIResult> data;
  final int max;
  const _RoiColorRow(this.data, this.max);
  @override
  Widget build(BuildContext context) => Row(children: [
    for (int i = 0; i < data.length && i < max; i++)
      Container(width: 18, height: 18, margin: const EdgeInsets.only(right: 5),
        decoration: BoxDecoration(
          color: data[i].color, shape: BoxShape.circle,
          border: Border.all(color: D.bdr),
          boxShadow: [BoxShadow(color: data[i].color.withOpacity(0.5), blurRadius: 5)])),
    const SizedBox(width: 6),
    Text('chrominance extracted',
      style: GoogleFonts.dmSans(fontSize: 9, color: D.text3)),
  ]);
}

class _ConjunctivaInline extends StatelessWidget {
  final List<ROIResult> data;
  const _ConjunctivaInline(this.data);
  @override
  Widget build(BuildContext context) {
    final ratio = data.map((r) => r.redness).reduce((a,b) => a+b) / data.length;
    final grade = ratio >= 0.43 ? 'No Pallor'
                : ratio >= 0.38 ? 'Mild Pallor'
                : ratio >= 0.32 ? 'Moderate Pallor' : 'Severe Pallor';
    final c = ratio >= 0.43 ? D.green : ratio >= 0.38 ? D.amber
            : ratio >= 0.32 ? const Color(0xFFF97316) : D.red;
    return Row(children: [
      Container(width: 16, height: 16,
        decoration: BoxDecoration(color: data.first.color, shape: BoxShape.circle,
          border: Border.all(color: D.bdr),
          boxShadow: [BoxShadow(color: data.first.color.withOpacity(0.5), blurRadius: 5)])),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: c.withOpacity(0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.28))),
        child: Text(grade, style: GoogleFonts.dmSans(
          fontSize: 10, fontWeight: FontWeight.w800, color: c))),
      const SizedBox(width: 8),
      Text('ratio ${ratio.toStringAsFixed(3)}',
        style: GoogleFonts.dmSans(fontSize: 9, color: D.text3)),
    ]);
  }
}

// ── Symptom score tag shown after questionnaire done ──────
class _SymptomScoreTag extends StatelessWidget {
  final int score, max;
  const _SymptomScoreTag(this.score, this.max);
  @override
  Widget build(BuildContext context) {
    final pct = score / max;
    final c   = pct >= 0.65 ? D.red
              : pct >= 0.40 ? const Color(0xFFF97316)
              : pct >= 0.20 ? D.amber
              : D.green;
    final label = pct >= 0.65 ? 'High Burden'
                : pct >= 0.40 ? 'Moderate'
                : pct >= 0.20 ? 'Mild'
                : 'Low Burden';
    return Row(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: c.withOpacity(0.10), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withOpacity(0.28))),
        child: Text(label, style: GoogleFonts.dmSans(
          fontSize: 10, fontWeight: FontWeight.w800, color: c))),
      const SizedBox(width: 8),
      Text('$score / $max pts',
        style: GoogleFonts.dmSans(fontSize: 9, color: D.text3)),
    ]);
  }
}

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage(this.title);
  @override
  Widget build(BuildContext context) => Center(
    child: Text(title, style: const TextStyle(color: D.text2)));
}

Widget _SectionLabel(String t) => Text(t, style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w800, color: D.teal, letterSpacing: 1.5));