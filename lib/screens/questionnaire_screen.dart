import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/scan_provider.dart';

// ══════════════════════════════════════════════════════════════════
//  Clinical Anemia Screening Questionnaire  — 10 Questions
//
//  Scoring:
//    Each YES = weighted points based on clinical significance
//    Total max = 30 pts → added as a signal in ScanProvider
//
//  Weight rationale (WHO / clinical symptom hierarchy):
//    Q1  Fatigue/weakness         3 pts  — most common anemia symptom
//    Q2  Dyspnoea on exertion     3 pts  — cardiopulmonary compensation
//    Q3  Dizziness/lightheadness  3 pts  — cerebral hypoxia
//    Q4  Visible pallor           4 pts  — direct clinical sign
//    Q5  Palpitations             3 pts  — compensatory tachycardia
//    Q6  Frequent headaches       2 pts  — hypoxic headache
//    Q7  Cold intolerance         2 pts  — poor peripheral perfusion
//    Q8  Hair loss / brittle nails 2 pts — iron-deficiency marker
//    Q9  Blood loss (gender-specific) 4 pts — primary cause indicator
//    Q10 Iron-poor diet           4 pts  — dietary deficiency risk
//
//  Total: 30 pts
// ══════════════════════════════════════════════════════════════════

// ── Question model ────────────────────────────────────────
class _Question {
  final int    id;
  final String text;
  final String? subtext;   // optional clarification
  final int    weight;     // pts if answered YES

  const _Question({
    required this.id,
    required this.text,
    this.subtext,
    required this.weight,
  });
}

const List<_Question> _questions = [
  _Question(
    id: 1,
    text: 'Do you often feel tired or weak without a clear reason?',
    weight: 3,
  ),
  _Question(
    id: 2,
    text: 'Do you experience shortness of breath during normal activities?',
    weight: 3,
  ),
  _Question(
    id: 3,
    text: 'Do you feel dizzy or lightheaded frequently?',
    weight: 3,
  ),
  _Question(
    id: 4,
    text: 'Have you noticed pale skin, lips, or nail beds?',
    weight: 4,
  ),
  _Question(
    id: 5,
    text: 'Do you feel your heart racing or pounding even at rest or with minimal activity?',
    weight: 3,
  ),
  _Question(
    id: 6,
    text: 'Do you experience frequent headaches?',
    weight: 2,
  ),
  _Question(
    id: 7,
    text: 'Do you feel cold more often than others around you?',
    weight: 2,
  ),
  _Question(
    id: 8,
    text: 'Have you experienced unusual hair loss or brittle nails recently?',
    weight: 2,
  ),
  _Question(
    id: 9,
    text: 'Do you have significant blood loss history?',
    subtext:
      'Women: heavy or prolonged menstrual bleeding.\n'
      'Men: history of piles, peptic ulcers, or recurrent bleeding.',
    weight: 4,
  ),
  _Question(
    id: 10,
    text: 'Do you follow a diet low in iron-rich foods?',
    subtext: 'E.g., limited intake of green leafy vegetables, red meat, legumes, or fortified cereals.',
    weight: 4,
  ),
];

// ══════════════════════════════════════════════════════════════════
//  SCREEN
// ══════════════════════════════════════════════════════════════════
class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({super.key});
  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen>
    with TickerProviderStateMixin {

  // answers: null = not answered, true = YES, false = NO
  final Map<int, bool> _answers = {};
  bool _submitted = false;

  late final AnimationController _entryCtrl;
  late final Animation<double>   _fadeIn;

  // ── Palette ───────────────────────────────────────────
  static const bg0   = Color(0xFF050D1A);
  static const bg1   = Color(0xFF0A1628);
  static const bg2   = Color(0xFF0F1E36);
  static const bg3   = Color(0xFF162440);
  static const teal  = Color(0xFF00D4C8);
  static const tealDk= Color(0xFF00A89E);
  static const green = Color(0xFF22D47A);
  static const amber = Color(0xFFFFB547);
  static const red   = Color(0xFFFF4D6A);
  static const text1 = Color(0xFFF0F8FF);
  static const text2 = Color(0xFF7A9BBE);
  static const text3 = Color(0xFF3D5A7A);
  static const bdr   = Color(0xFF1A2E4A);

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500));
    _fadeIn = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entryCtrl.forward();
  }

  @override
  void dispose() { _entryCtrl.dispose(); super.dispose(); }

  // ── Compute score from answers ────────────────────────
  int get _score => _questions
      .where((q) => _answers[q.id] == true)
      .fold(0, (sum, q) => sum + q.weight);

  int get _maxScore => _questions.fold(0, (s, q) => s + q.weight); // 30

  bool get _allAnswered => _answers.length == _questions.length;

  double get _riskPct => _score / _maxScore;

  Color get _riskColor {
    if (_riskPct >= 0.65) return red;
    if (_riskPct >= 0.40) return const Color(0xFFF97316);
    if (_riskPct >= 0.20) return amber;
    return green;
  }

  String get _riskLabel {
    if (_riskPct >= 0.65) return 'High Symptom Burden';
    if (_riskPct >= 0.40) return 'Moderate Symptom Burden';
    if (_riskPct >= 0.20) return 'Mild Symptom Burden';
    return 'Low Symptom Burden';
  }

  void _submit() {
    if (!_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: bg2,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: amber.withOpacity(0.4))),
        content: Text(
          'Please answer all ${_questions.length} questions before submitting.',
          style: GoogleFonts.dmSans(fontSize: 12, color: text1))));
      return;
    }
    // Save to provider
    context.read<ScanProvider>().setSymptomScore(_score, _maxScore);
    setState(() => _submitted = true);
  }

  void _saveAndPop() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg0,
      body: SafeArea(child: FadeTransition(
        opacity: _fadeIn,
        child: Column(children: [

          // ── Header ──────────────────────────────────
          _buildHeader(),

          // ── Body ────────────────────────────────────
          Expanded(child: _submitted ? _buildResult() : _buildQuestions()),

          // ── Footer button ────────────────────────────
          _buildFooter(),
        ]),
      )),
    );
  }

  // ── HEADER ────────────────────────────────────────────
  Widget _buildHeader() => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
    decoration: const BoxDecoration(
      color: bg1,
      border: Border(bottom: BorderSide(color: bdr))),
    child: Row(children: [
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: bg2, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: bdr)),
          child: const Icon(Icons.arrow_back_ios_rounded, size: 16, color: text1))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('CLINICAL SCREENING',
          style: GoogleFonts.dmSans(
            fontSize: 9, fontWeight: FontWeight.w800,
            color: teal, letterSpacing: 1.8)),
        Text('Symptom Questionnaire',
          style: GoogleFonts.playfairDisplay(
            fontSize: 16, fontWeight: FontWeight.w800, color: text1)),
      ])),
      // Progress indicator
      if (!_submitted) _ProgressRing(
        answered: _answers.length,
        total:    _questions.length,
        color:    teal),
    ]));

  // ── QUESTIONS LIST ────────────────────────────────────
  Widget _buildQuestions() => ListView.separated(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
    itemCount: _questions.length + 1, // +1 for top info card
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (ctx, i) {
      if (i == 0) return _InfoCard();
      final q = _questions[i - 1];
      return _QuestionCard(
        question:  q,
        answer:    _answers[q.id],
        onAnswer:  (val) => setState(() => _answers[q.id] = val),
      );
    },
  );

  // ── RESULT VIEW ───────────────────────────────────────
  Widget _buildResult() {
    final yesCount = _answers.values.where((v) => v).length;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [

        // Score card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: bg1,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _riskColor.withOpacity(0.30)),
            boxShadow: [
              BoxShadow(color: _riskColor.withOpacity(0.10), blurRadius: 24),
              BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16),
            ]),
          child: Column(children: [
            Text('SYMPTOM SCORE',
              style: GoogleFonts.dmSans(
                fontSize: 10, letterSpacing: 2,
                fontWeight: FontWeight.w700, color: _riskColor)),
            const SizedBox(height: 16),

            // Score display
            RichText(text: TextSpan(children: [
              TextSpan(text: '$_score',
                style: GoogleFonts.dmSans(
                  fontSize: 52, fontWeight: FontWeight.w900,
                  color: text1, height: 1)),
              TextSpan(text: ' / $_maxScore',
                style: GoogleFonts.dmSans(fontSize: 20, color: text2)),
            ])),
            const SizedBox(height: 8),

            // Risk label
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: _riskColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _riskColor.withOpacity(0.35))),
              child: Text(_riskLabel,
                style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w800,
                  color: _riskColor))),
            const SizedBox(height: 20),

            // Progress bar
            _ScoreBar(score: _score, max: _maxScore, color: _riskColor),
            const SizedBox(height: 20),

            // Stats row
            Row(children: [
              Expanded(child: _StatBox(
                label: 'Positive Symptoms',
                value: '$yesCount / ${_questions.length}',
                color: _riskColor)),
              const SizedBox(width: 12),
              Expanded(child: _StatBox(
                label: 'Weighted Score',
                value: '${(_riskPct * 100).toStringAsFixed(0)}%',
                color: _riskColor)),
            ]),
          ])),

        const SizedBox(height: 16),

        // Interpretation
        _InterpretationCard(riskPct: _riskPct, color: _riskColor),
        const SizedBox(height: 16),

        // Answered breakdown
        _AnswerSummary(questions: _questions, answers: _answers),
        const SizedBox(height: 16),

        // Disclaimer
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: amber.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: amber.withOpacity(0.20))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('CLINICAL NOTE',
              style: GoogleFonts.dmSans(
                fontSize: 8, fontWeight: FontWeight.w900,
                color: amber, letterSpacing: 1.5)),
            const SizedBox(height: 5),
            Text(
              'Symptom scores are self-reported and subject to bias. '
              'This questionnaire supplements clinical imaging data and '
              'does not independently diagnose anemia. Always confirm '
              'with a Complete Blood Count (CBC) laboratory test.',
              style: GoogleFonts.dmSans(
                fontSize: 11, color: text2, height: 1.6)),
          ])),
      ]),
    );
  }

  // ── FOOTER ────────────────────────────────────────────
  Widget _buildFooter() => Container(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
    color: bg1,
    child: _submitted
      ? GestureDetector(
          onTap: _saveAndPop,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [teal, tealDk]),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(
                color: teal.withOpacity(0.40),
                blurRadius: 20, offset: const Offset(0, 7))]),
            child: Center(child: Text('Save & Return',
              style: GoogleFonts.dmSans(
                fontSize: 15, fontWeight: FontWeight.w800,
                color: Colors.white)))))
      : Column(mainAxisSize: MainAxisSize.min, children: [
          // Answered count hint
          Text(
            '${_answers.length} of ${_questions.length} answered',
            style: GoogleFonts.dmSans(fontSize: 11, color: text3)),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _submit,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: _allAnswered
                  ? const LinearGradient(colors: [teal, tealDk])
                  : null,
                color: _allAnswered ? null : bg2,
                borderRadius: BorderRadius.circular(16),
                boxShadow: _allAnswered
                  ? [BoxShadow(
                      color: teal.withOpacity(0.40),
                      blurRadius: 20, offset: const Offset(0, 7))]
                  : []),
              child: Center(child: Text(
                _allAnswered
                  ? 'Submit Questionnaire'
                  : 'Answer all questions to submit',
                style: GoogleFonts.dmSans(
                  fontSize: 14, fontWeight: FontWeight.w800,
                  color: _allAnswered ? Colors.white : text3))))),
        ]));
}

// ══════════════════════════════════════════════════════════════════
//  INFO CARD — top of question list
// ══════════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  static const teal  = Color(0xFF00D4C8);
  static const bg2   = Color(0xFF0F1E36);
  static const text2 = Color(0xFF7A9BBE);
  static const bdr   = Color(0xFF1A2E4A);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: teal.withOpacity(0.05),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: teal.withOpacity(0.20))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('ANEMIA SYMPTOM SCREENING',
        style: GoogleFonts.dmSans(
          fontSize: 9, fontWeight: FontWeight.w800,
          color: teal, letterSpacing: 1.5)),
      const SizedBox(height: 6),
      Text(
        '10 clinically validated questions. Answer based on your experience '
        'over the past 4 weeks. Select YES or NO for each question.',
        style: GoogleFonts.dmSans(fontSize: 11, color: text2, height: 1.55)),
    ]));
}

// ══════════════════════════════════════════════════════════════════
//  QUESTION CARD
// ══════════════════════════════════════════════════════════════════
class _QuestionCard extends StatefulWidget {
  final _Question  question;
  final bool?      answer;
  final ValueChanged<bool> onAnswer;
  const _QuestionCard({
    required this.question,
    required this.answer,
    required this.onAnswer,
  });
  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>   _scale;

  static const bg1   = Color(0xFF0A1628);
  static const bg2   = Color(0xFF0F1E36);
  static const teal  = Color(0xFF00D4C8);
  static const green = Color(0xFF22D47A);
  static const red   = Color(0xFFFF4D6A);
  static const text1 = Color(0xFFF0F8FF);
  static const text2 = Color(0xFF7A9BBE);
  static const text3 = Color(0xFF3D5A7A);
  static const bdr   = Color(0xFF1A2E4A);

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween<double>(begin: 1.0, end: 0.98)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _borderColor {
    if (widget.answer == true)  return green.withOpacity(0.40);
    if (widget.answer == false) return red.withOpacity(0.25);
    return bdr;
  }

  @override
  Widget build(BuildContext context) {
    final q      = widget.question;
    final ans    = widget.answer;
    final isYes  = ans == true;
    final isNo   = ans == false;

    return AnimatedBuilder(
      animation: _scale,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg1,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: ans != null
                  ? (isYes ? green : red).withOpacity(0.06)
                  : Colors.black.withOpacity(0.25),
                blurRadius: 12, offset: const Offset(0, 3))]),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Question number + weight badge
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: ans != null
                    ? (isYes ? green : red).withOpacity(0.12)
                    : teal.withOpacity(0.08),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ans != null
                      ? (isYes ? green : red).withOpacity(0.35)
                      : teal.withOpacity(0.20))),
                child: Center(child: Text(
                  '${q.id < 10 ? '0' : ''}${q.id}',
                  style: GoogleFonts.dmSans(
                    fontSize: 10, fontWeight: FontWeight.w800,
                    color: ans != null
                      ? (isYes ? green : red)
                      : teal)))),
              const SizedBox(width: 10),
              Expanded(child: Text(q.text,
                style: GoogleFonts.dmSans(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: text1, height: 1.45))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: teal.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6)),
                child: Text('+${q.weight} pts',
                  style: GoogleFonts.dmSans(
                    fontSize: 8, fontWeight: FontWeight.w700,
                    color: teal.withOpacity(0.70)))),
            ]),

            // Sub-text (gender-specific / clarification)
            if (q.subtext != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: bg2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: bdr)),
                child: Text(q.subtext!,
                  style: GoogleFonts.dmSans(
                    fontSize: 10, color: text2, height: 1.55))),
            ],

            const SizedBox(height: 14),

            // YES / NO buttons
            Row(children: [
              Expanded(child: _AnswerBtn(
                label:   'Yes',
                active:  isYes,
                color:   green,
                onTap:   () {
                  _ctrl.forward().then((_) => _ctrl.reverse());
                  widget.onAnswer(true);
                })),
              const SizedBox(width: 10),
              Expanded(child: _AnswerBtn(
                label:   'No',
                active:  isNo,
                color:   const Color(0xFF7A9BBE),
                onTap:   () {
                  _ctrl.forward().then((_) => _ctrl.reverse());
                  widget.onAnswer(false);
                })),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ── YES/NO button ─────────────────────────────────────────
class _AnswerBtn extends StatelessWidget {
  final String   label;
  final bool     active;
  final Color    color;
  final VoidCallback onTap;
  const _AnswerBtn({
    required this.label, required this.active,
    required this.color, required this.onTap,
  });

  static const bg2 = Color(0xFF0F1E36);
  static const bdr = Color(0xFF1A2E4A);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: active ? color.withOpacity(0.14) : bg2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: active ? color.withOpacity(0.50) : bdr,
          width: active ? 1.5 : 1)),
      child: Center(child: Text(label,
        style: GoogleFonts.dmSans(
          fontSize: 13, fontWeight: FontWeight.w800,
          color: active ? color : const Color(0xFF3D5A7A))))));
}

// ══════════════════════════════════════════════════════════════════
//  RESULT SUB-WIDGETS
// ══════════════════════════════════════════════════════════════════

class _ScoreBar extends StatelessWidget {
  final int score, max;
  final Color color;
  const _ScoreBar({required this.score, required this.max, required this.color});

  @override
  Widget build(BuildContext context) {
    final fill = (score / max).clamp(0.0, 1.0);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Symptom burden',
          style: GoogleFonts.dmSans(fontSize: 10, color: const Color(0xFF7A9BBE))),
        Text('$score / $max pts',
          style: GoogleFonts.dmSans(
            fontSize: 10, fontWeight: FontWeight.w700, color: color)),
      ]),
      const SizedBox(height: 8),
      Stack(children: [
        Container(height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFF162440),
            borderRadius: BorderRadius.circular(4))),
        FractionallySizedBox(
          widthFactor: fill,
          child: Container(height: 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.7), color]),
              borderRadius: BorderRadius.circular(4),
              boxShadow: [BoxShadow(
                color: color.withOpacity(0.5), blurRadius: 8)]))),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        Text('None', style: GoogleFonts.dmSans(fontSize: 9, color: const Color(0xFF22D47A))),
        const Spacer(),
        Text('Severe', style: GoogleFonts.dmSans(fontSize: 9, color: const Color(0xFFFF4D6A))),
      ]),
    ]);
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _StatBox({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: color.withOpacity(0.22))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
        style: GoogleFonts.dmSans(fontSize: 9, color: const Color(0xFF7A9BBE))),
      const SizedBox(height: 6),
      Text(value,
        style: GoogleFonts.dmSans(
          fontSize: 18, fontWeight: FontWeight.w900,
          color: const Color(0xFFF0F8FF))),
    ]));
}

class _InterpretationCard extends StatelessWidget {
  final double riskPct;
  final Color  color;
  const _InterpretationCard({required this.riskPct, required this.color});

  String get _text {
    if (riskPct >= 0.65) {
      return 'Your symptom profile strongly suggests a significant anemia burden. '
             'Multiple high-weight indicators are present. '
             'A Complete Blood Count (CBC) test is strongly recommended.';
    } else if (riskPct >= 0.40) {
      return 'Moderate symptom burden detected. Several indicators consistent '
             'with anemia are reported. Consider dietary assessment and a CBC '
             'blood test to confirm hemoglobin levels.';
    } else if (riskPct >= 0.20) {
      return 'Mild symptom indicators present. May reflect early or borderline '
             'iron-deficiency. Monitor symptoms and consider dietary correction '
             'with iron-rich foods.';
    }
    return 'Low symptom burden. Your responses do not strongly suggest '
           'anemia based on self-reported symptoms. Continue routine '
           'health monitoring.';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color.withOpacity(0.06),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: color.withOpacity(0.25))),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('CLINICAL INTERPRETATION',
        style: GoogleFonts.dmSans(
          fontSize: 9, fontWeight: FontWeight.w800,
          color: color, letterSpacing: 1.5)),
      const SizedBox(height: 8),
      Text(_text,
        style: GoogleFonts.dmSans(
          fontSize: 12, color: const Color(0xFF7A9BBE), height: 1.65)),
    ]));
}

class _AnswerSummary extends StatelessWidget {
  final List<_Question> questions;
  final Map<int, bool>  answers;
  const _AnswerSummary({required this.questions, required this.answers});

  static const bg1   = Color(0xFF0A1628);
  static const bg2   = Color(0xFF0F1E36);
  static const green = Color(0xFF22D47A);
  static const red   = Color(0xFFFF4D6A);
  static const text1 = Color(0xFFF0F8FF);
  static const text2 = Color(0xFF7A9BBE);
  static const text3 = Color(0xFF3D5A7A);
  static const bdr   = Color(0xFF1A2E4A);
  static const teal  = Color(0xFF00D4C8);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: bg1,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: bdr)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('RESPONSE SUMMARY',
        style: GoogleFonts.dmSans(
          fontSize: 9, fontWeight: FontWeight.w800,
          color: teal, letterSpacing: 1.5)),
      const SizedBox(height: 12),
      ...questions.map((q) {
        final ans   = answers[q.id];
        final isYes = ans == true;
        final c     = isYes ? green : red;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: c.withOpacity(0.10),
                shape: BoxShape.circle,
                border: Border.all(color: c.withOpacity(0.30))),
              child: Icon(
                isYes ? Icons.check_rounded : Icons.close_rounded,
                size: 12, color: c)),
            const SizedBox(width: 10),
            Expanded(child: Text(
              '${q.id < 10 ? '0' : ''}${q.id}.  ${q.text}',
              style: GoogleFonts.dmSans(
                fontSize: 11, color: text2, height: 1.4))),
            const SizedBox(width: 6),
            Text(
              isYes ? '+${q.weight}' : '0',
              style: GoogleFonts.dmSans(
                fontSize: 10, fontWeight: FontWeight.w800,
                color: isYes ? green : text3)),
          ]));
      }),
    ]));
}

// ── Progress ring ─────────────────────────────────────────
class _ProgressRing extends StatelessWidget {
  final int   answered, total;
  final Color color;
  const _ProgressRing({
    required this.answered, required this.total, required this.color});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 40, height: 40,
    child: Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(
        value: total > 0 ? answered / total : 0,
        strokeWidth: 3,
        backgroundColor: const Color(0xFF1A2E4A),
        valueColor: AlwaysStoppedAnimation(color),
        strokeCap: StrokeCap.round),
      Text('$answered',
        style: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w800,
          color: const Color(0xFFF0F8FF))),
    ]));
}