import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final user = FirebaseAuth.instance.currentUser;
  bool _loading = true;

  int totalApplied = 0;
  int totalAccepted = 0;
  int totalRejected = 0;
  List<JobPostTrend> jobTrends = [];
  List<IndustryData> topIndustries = [];

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  /// --- Load Analytics Data ---
  Future<void> _loadAnalytics() async {
    if (user == null) return;

    try {
      // Fetch user's applications
      final applications = await FirebaseFirestore.instance
    .collection('job_applications') 
    .where('userId', isEqualTo: user!.uid)
    .get();

      totalApplied = applications.docs.length;
      totalAccepted = applications.docs
          .where((doc) => doc['status'] == 'Accepted')
          .length;
      totalRejected = applications.docs
          .where((doc) => doc['status'] == 'Rejected')
          .length;

      // Fetch job postings
      final jobPostsSnapshot = await FirebaseFirestore.instance
          .collection('jobs')
          .orderBy('postedAt', descending: false)
          .get();

      Map<String, int> dailyCounts = {};
      Map<String, int> industryCounts = {};

      for (var job in jobPostsSnapshot.docs) {
        final date = (job['postedAt'] as Timestamp).toDate();
        final dayKey =
            "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

        // Count jobs per day
        dailyCounts[dayKey] = (dailyCounts[dayKey] ?? 0) + 1;

        // Fetch company industry using companyId
        final companyId = job['companyId'];
        if (companyId != null) {
          final companyDoc = await FirebaseFirestore.instance
              .collection('companies')
              .doc(companyId)
              .get();
          final industry = companyDoc.data()?['industry'] ?? 'Other';
          industryCounts[industry] = (industryCounts[industry] ?? 0) + 1;
        }
      }

      setState(() {
        jobTrends = dailyCounts.entries
            .map((e) => JobPostTrend(e.key, e.value))
            .toList();

        topIndustries = industryCounts.entries
            .map((e) => IndustryData(e.key, e.value))
            .toList()
          ..sort((a, b) => b.count.compareTo(a.count));

        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error loading analytics: $e")));
    }
  }

  double get successRate {
    if (totalApplied == 0) return 0;
    return (totalAccepted / totalApplied) * 100;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Analytics & Insights'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildSummaryCards(),
                    const SizedBox(height: 20),
                    _buildJobTrendsChart(),
                    const SizedBox(height: 20),
                    _buildTopIndustriesChart(),
                  ],
                ),
              ),
            ),
    );
  }

  /// --- SUMMARY CARDS ---
  Widget _buildSummaryCards() {
    return Wrap(
      alignment: WrapAlignment.spaceEvenly,
      spacing: 12,
      runSpacing: 12,
      children: [
        _summaryCard("Jobs Applied", totalApplied, Colors.blue),
        _summaryCard("Accepted", totalAccepted, Colors.green),
        _summaryCard("Rejected", totalRejected, Colors.red),
        _summaryCard(
            "Success Rate", "${successRate.toStringAsFixed(1)}%", Colors.orange),
      ],
    );
  }

  Widget _summaryCard(String title, dynamic value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 6),
            Text(
              "$value",
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }

  /// --- JOB POST TRENDS BAR CHART ---
  Widget _buildJobTrendsChart() {
    if (jobTrends.isEmpty) {
      return const Center(child: Text("No job trend data available"));
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Jobs Posted Per Day",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < jobTrends.length) {
                            return Text(jobTrends[index].date.split('-').last);
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                  barGroups: jobTrends.asMap().entries.map((entry) {
                    int index = entry.key;
                    final trend = entry.value;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: trend.count.toDouble(),
                          color: Colors.blue,
                          width: 16,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// --- TOP INDUSTRIES PIE CHART ---
  Widget _buildTopIndustriesChart() {
    if (topIndustries.isEmpty) {
      return const Center(child: Text("No industry data available"));
    }

    final displayedIndustries = topIndustries.take(5).toList();
    final total = displayedIndustries.fold<int>(0, (sum, item) => sum + item.count);

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Top Hiring Industries",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  sections: displayedIndustries.map((industryData) {
                    final percentage = (industryData.count / total) * 100;
                    return PieChartSectionData(
                      value: industryData.count.toDouble(),
                      title: "${percentage.toStringAsFixed(1)}%",
                      color: _getColorForIndustry(industryData.industry),
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: displayedIndustries.map((industry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: _getColorForIndustry(industry.industry),
                    ),
                    const SizedBox(width: 6),
                    Text(industry.industry),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForIndustry(String industry) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
      Colors.purple,
      Colors.teal,
    ];
    return colors[topIndustries.indexWhere((i) => i.industry == industry) %
        colors.length];
  }
}

/// --- DATA MODELS ---
class JobPostTrend {
  final String date;
  final int count;

  JobPostTrend(this.date, this.count);
}

class IndustryData {
  final String industry;
  final int count;

  IndustryData(this.industry, this.count);
}
