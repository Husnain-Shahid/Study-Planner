// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import '../core/services/firestore_service.dart';
// import '../core/theme/app_theme.dart';
//
// class AnalyticsScreen extends StatefulWidget {
//   const AnalyticsScreen({super.key});
//
//   @override
//   State<AnalyticsScreen> createState() => _AnalyticsScreenState();
// }
//
// class _AnalyticsScreenState extends State<AnalyticsScreen> {
//   Map<int, double> _dailyHours = {};
//   Map<String, double> _subjectHours = {};
//   List<Map<String, dynamic>> _quizResults = [];
//   bool _loading = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _load();
//   }
//
//   Future<void> _load() async {
//     final daily = await FirestoreService.getDailyHoursLast7Days();
//     final subjects = await FirestoreService.getHoursPerSubjectLast7Days();
//     final quizzes = await FirestoreService.getQuizResults();
//     setState(() {
//       _dailyHours = daily;
//       _subjectHours = subjects;
//       _quizResults = quizzes;
//       _loading = false;
//     });
//   }
//
//   double get _totalHours => _dailyHours.values.fold(0, (a, b) => a + b);
//   double get _avgHours => _dailyHours.isEmpty ? 0 : _totalHours / 7;
//   int get _avgQuizScore {
//     if (_quizResults.isEmpty) return 0;
//     final avg = _quizResults.map((r) => (r['score'] as int) / (r['total'] as int) * 100).reduce((a, b) => a + b) / _quizResults.length;
//     return avg.round();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Analytics'),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh_rounded),
//             onPressed: () {
//               setState(() => _loading = true);
//               _load();
//             },
//           ),
//         ],
//       ),
//       body: _loading
//           ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
//           : RefreshIndicator(
//               onRefresh: _load,
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     _buildSummaryCards(),
//                     const SizedBox(height: 28),
//                     _buildDailyChart(),
//                     const SizedBox(height: 28),
//                     _buildSubjectPieChart(),
//                     const SizedBox(height: 28),
//                     _buildQuizHistory(),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
//
//   Widget _buildSummaryCards() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const SizedBox(height: 16),
//         Text('This Week', style: Theme.of(context).textTheme.titleLarge),
//         const SizedBox(height: 12),
//         Row(
//           children: [
//             _SummaryCard(label: 'Total Hours', value: _totalHours.toStringAsFixed(1), unit: 'hrs', color: AppColors.primary),
//             const SizedBox(width: 12),
//             _SummaryCard(label: 'Daily Avg', value: _avgHours.toStringAsFixed(1), unit: 'hrs/day', color: AppColors.accent),
//             const SizedBox(width: 12),
//             _SummaryCard(label: 'Quiz Avg', value: '$_avgQuizScore', unit: '%', color: AppColors.warning),
//           ],
//         ),
//       ],
//     );
//   }
//
//   Widget _buildDailyChart() {
//     final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
//     final now = DateTime.now();
//     final dayLabels = List.generate(7, (i) {
//       final d = now.subtract(Duration(days: 6 - i));
//       return days[d.weekday - 1];
//     });
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Daily Study Hours', style: Theme.of(context).textTheme.titleLarge),
//         const SizedBox(height: 4),
//         Text('Last 7 days', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
//         const SizedBox(height: 16),
//         Container(
//           height: 200,
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
//           ),
//           child: BarChart(
//             BarChartData(
//               alignment: BarChartAlignment.spaceAround,
//               maxY: ((_dailyHours.values.isEmpty ? 4.0 : _dailyHours.values.reduce((a, b) => a > b ? a : b) + 1).clamp(2.0, double.infinity)).toDouble(),
//               barTouchData: BarTouchData(
//                 touchTooltipData: BarTouchTooltipData(
//                   getTooltipColor: (_) => AppColors.primary.withValues(alpha: 0.9),
//                   getTooltipItem: (group, groupIdx, rod, rodIdx) => BarTooltipItem(
//                     '${rod.toY.toStringAsFixed(1)}h',
//                     const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
//                   ),
//                 ),
//               ),
//               titlesData: FlTitlesData(
//                 show: true,
//                 bottomTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     getTitlesWidget: (v, _) => Text(
//                       dayLabels[v.toInt()],
//                       style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey),
//                     ),
//                   ),
//                 ),
//                 leftTitles: AxisTitles(
//                   sideTitles: SideTitles(
//                     showTitles: true,
//                     reservedSize: 30,
//                     getTitlesWidget: (v, _) => Text(
//                       v.toInt().toString(),
//                       style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey),
//                     ),
//                   ),
//                 ),
//                 topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//                 rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
//               ),
//               gridData: FlGridData(
//                 show: true,
//                 drawVerticalLine: false,
//                 getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
//               ),
//               borderData: FlBorderData(show: false),
//               barGroups: List.generate(7, (i) => BarChartGroupData(
//                 x: i,
//                 barRods: [
//                   BarChartRodData(
//                     toY: _dailyHours[i] ?? 0,
//                     color: AppColors.primary,
//                     width: 24,
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(6),
//                       topRight: Radius.circular(6),
//                     ),
//                     backDrawRodData: BackgroundBarChartRodData(
//                       show: true,
//                       toY: ((_dailyHours.values.isEmpty ? 4.0 : _dailyHours.values.reduce((a, b) => a > b ? a : b) + 1).clamp(2.0, double.infinity)).toDouble(),
//                       color: AppColors.primary.withValues(alpha: 0.06),
//                     ),
//                   ),
//                 ],
//               )),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildSubjectPieChart() {
//     if (_subjectHours.isEmpty) {
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Time by Subject', style: Theme.of(context).textTheme.titleLarge),
//           const SizedBox(height: 12),
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.grey.shade50,
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Column(
//               children: [
//                 const Text('📊', style: TextStyle(fontSize: 40)),
//                 const SizedBox(height: 8),
//                 Text('No data yet', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500)),
//                 Text('Complete study sessions to see breakdown', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade400)),
//               ],
//             ),
//           ),
//         ],
//       );
//     }
//
//     final colors = AppColors.subjectColors;
//     final entries = _subjectHours.entries.toList();
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Time by Subject', style: Theme.of(context).textTheme.titleLarge),
//         const SizedBox(height: 16),
//         Container(
//           padding: const EdgeInsets.all(16),
//           decoration: BoxDecoration(
//             color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
//             borderRadius: BorderRadius.circular(16),
//             border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
//           ),
//           child: Row(
//             children: [
//               SizedBox(
//                 width: 160,
//                 height: 160,
//                 child: PieChart(
//                   PieChartData(
//                     sectionsSpace: 2,
//                     centerSpaceRadius: 36,
//                     sections: entries.asMap().entries.map((e) {
//                       final total = _subjectHours.values.fold(0.0, (a, b) => a + b);
//                       return PieChartSectionData(
//                         color: colors[e.key % colors.length],
//                         value: e.value.value,
//                         title: '${(e.value.value / total * 100).round()}%',
//                         radius: 48,
//                         titleStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
//                       );
//                     }).toList(),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 20),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: entries.asMap().entries.map((e) => Padding(
//                     padding: const EdgeInsets.only(bottom: 8),
//                     child: Row(
//                       children: [
//                         Container(
//                           width: 10,
//                           height: 10,
//                           decoration: BoxDecoration(
//                             color: colors[e.key % colors.length],
//                             shape: BoxShape.circle,
//                           ),
//                         ),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             e.value.key,
//                             style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         Text(
//                           '${e.value.value.toStringAsFixed(1)}h',
//                           style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
//                         ),
//                       ],
//                     ),
//                   )).toList(),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _buildQuizHistory() {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text('Quiz History', style: Theme.of(context).textTheme.titleLarge),
//         const SizedBox(height: 12),
//         if (_quizResults.isEmpty)
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(24),
//             decoration: BoxDecoration(
//               color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.grey.shade50,
//               borderRadius: BorderRadius.circular(16),
//             ),
//             child: Column(
//               children: [
//                 const Text('🧠', style: TextStyle(fontSize: 40)),
//                 const SizedBox(height: 8),
//                 Text('No quizzes taken yet', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500)),
//               ],
//             ),
//           )
//         else
//           ..._quizResults.take(5).map((r) {
//             final score = r['score'] as int;
//             final total = r['total'] as int;
//             final pct = (score / total * 100).round();
//             final isPassing = pct >= 60;
//             return Container(
//               margin: const EdgeInsets.only(bottom: 10),
//               padding: const EdgeInsets.all(14),
//               decoration: BoxDecoration(
//                 color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
//               ),
//               child: Row(
//                 children: [
//                   Container(
//                     width: 44,
//                     height: 44,
//                     decoration: BoxDecoration(
//                       color: (isPassing ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
//                       shape: BoxShape.circle,
//                     ),
//                     child: Center(
//                       child: Text(
//                         '$pct%',
//                         style: TextStyle(
//                           fontFamily: 'Poppins',
//                           fontWeight: FontWeight.w700,
//                           fontSize: 12,
//                           color: isPassing ? AppColors.success : AppColors.warning,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(r['topic'] ?? 'Quiz', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
//                         Text('$score/$total correct', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
//                       ],
//                     ),
//                   ),
//                   Icon(
//                     isPassing ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
//                     color: isPassing ? AppColors.success : AppColors.warning,
//                     size: 20,
//                   ),
//                 ],
//               ),
//             );
//           }),
//       ],
//     );
//   }
// }
//
// class _SummaryCard extends StatelessWidget {
//   final String label;
//   final String value;
//   final String unit;
//   final Color color;
//
//   const _SummaryCard({required this.label, required this.value, required this.unit, required this.color});
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     return Expanded(
//       child: Container(
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: isDark ? AppColors.darkCard : Colors.white,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: color.withValues(alpha: 0.15)),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade500)),
//             const SizedBox(height: 4),
//             Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: color)),
//             Text(unit, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey.shade400)),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/services/firestore_service.dart';
import '../../core/theme/app_theme.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<int, double> _dailyHours = {};
  Map<String, double> _subjectHours = {};
  List<Map<String, dynamic>> _quizResults = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final daily = await FirestoreService.getDailyHoursLast7Days();
    final subjects = await FirestoreService.getHoursPerSubjectLast7Days();
    final quizzes = await FirestoreService.getQuizResults();
    setState(() {
      _dailyHours = daily;
      _subjectHours = subjects;
      _quizResults = quizzes;
      _loading = false;
    });
  }

  double get _totalHours => _dailyHours.values.fold(0, (a, b) => a + b);
  double get _avgHours => _dailyHours.isEmpty ? 0 : _totalHours / 7;
  int get _avgQuizScore {
    if (_quizResults.isEmpty) return 0;
    final avg = _quizResults.map((r) => (r['score'] as int) / (r['total'] as int) * 100).reduce((a, b) => a + b) / _quizResults.length;
    return avg.round();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () { setState(() => _loading = true); _load(); }),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(),
              const SizedBox(height: 28),
              _buildDailyChart(),
              const SizedBox(height: 28),
              _buildSubjectPieChart(),
              const SizedBox(height: 28),
              _buildQuizHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('This Week', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          children: [
            _SummaryCard(label: 'Total Hours', value: _totalHours.toStringAsFixed(1), unit: 'hrs', color: AppColors.primary),
            const SizedBox(width: 12),
            _SummaryCard(label: 'Daily Avg', value: _avgHours.toStringAsFixed(1), unit: 'hrs/day', color: AppColors.accent),
            const SizedBox(width: 12),
            _SummaryCard(label: 'Quiz Avg', value: '$_avgQuizScore', unit: '%', color: AppColors.warning),
          ],
        ),
      ],
    );
  }

  Widget _buildDailyChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final dayLabels = List.generate(7, (i) {
      final d = now.subtract(Duration(days: 6 - i));
      return days[d.weekday - 1];
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Study Hours', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Last 7 days', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 16),
        Container(
          height: 200,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: ((_dailyHours.values.isEmpty ? 4.0 : _dailyHours.values.reduce((a, b) => a > b ? a : b) + 1).clamp(2.0, double.infinity)).toDouble(),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.primary.withValues(alpha: 0.9),
                  getTooltipItem: (group, groupIdx, rod, rodIdx) => BarTooltipItem(
                    '${rod.toY.toStringAsFixed(1)}h',
                    const TextStyle(color: Colors.white, fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (v, _) => Text(
                      dayLabels[v.toInt()],
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey),
                    ),
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => FlLine(color: Colors.grey.withValues(alpha: 0.1), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(7, (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: _dailyHours[i] ?? 0,
                    color: AppColors.primary,
                    width: 24,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      topRight: Radius.circular(6),
                    ),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: ((_dailyHours.values.isEmpty ? 4.0 : _dailyHours.values.reduce((a, b) => a > b ? a : b) + 1).clamp(2.0, double.infinity)).toDouble(),
                      color: AppColors.primary.withValues(alpha: 0.06),
                    ),
                  ),
                ],
              )),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectPieChart() {
    if (_subjectHours.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Time by Subject', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('📊', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text('No data yet', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500)),
                Text('Complete study sessions to see breakdown', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade400)),
              ],
            ),
          ),
        ],
      );
    }

    final colors = AppColors.subjectColors;
    final entries = _subjectHours.entries.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Time by Subject', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 36,
                    sections: entries.asMap().entries.map((e) {
                      final total = _subjectHours.values.fold(0.0, (a, b) => a + b);
                      return PieChartSectionData(
                        color: colors[e.key % colors.length],
                        value: e.value.value,
                        title: '${(e.value.value / total * 100).round()}%',
                        radius: 48,
                        titleStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: colors[e.key % colors.length],
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            e.value.key,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${e.value.value.toStringAsFixed(1)}h',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizHistory() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quiz History', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_quizResults.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('🧠', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text('No quizzes taken yet', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey.shade500)),
              ],
            ),
          )
        else
          ..._quizResults.take(5).map((r) {
            final score = r['score'] as int;
            final total = r['total'] as int;
            final pct = (score / total * 100).round();
            final isPassing = pct >= 60;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: (isPassing ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$pct%',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: isPassing ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(r['topic'] ?? 'Quiz', style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                        Text('$score/$total correct', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                  Icon(
                    isPassing ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                    color: isPassing ? AppColors.success : AppColors.warning,
                    size: 20,
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _SummaryCard({required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontFamily: 'Poppins', fontSize: 22, fontWeight: FontWeight.w700, color: color)),
            Text(unit, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, color: Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }
}

