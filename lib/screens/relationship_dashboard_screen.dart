import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class RelationshipDashboardScreen extends StatefulWidget {
  final int senderId;
  final int receiverId;
  final String receiverName;

  const RelationshipDashboardScreen({
    super.key,
    required this.senderId,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<RelationshipDashboardScreen> createState() => _RelationshipDashboardScreenState();
}

class _RelationshipDashboardScreenState extends State<RelationshipDashboardScreen> {
  bool _isLoading = true;
  String _error = "";
  int _currentScore = 50;
  List<FlSpot> _spots = [];
  List<String> _dates = []; // X ekseninde göstermek için

  static const Color _turquoise = Color(0xFF008F9C);

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final res = await ApiService().getRelationshipHistory(
        user1Id: widget.senderId,
        user2Id: widget.receiverId,
      );

      if (res["success"] == true) {
        final history = res["history"] as List;
        
        List<FlSpot> loadedSpots = [];
        List<String> loadedDates = [];

        int index = 0;
        for (var item in history) {
          double score = double.parse(item["closeness_score"].toString());
          loadedSpots.add(FlSpot(index.toDouble(), score));
          
          if (item["timestamp"] != null) {
            try {
              DateTime dt = DateTime.parse(item["timestamp"].toString());
              loadedDates.add("${dt.day}/${dt.month}");
            } catch (_) {
              loadedDates.add("");
            }
          } else {
            loadedDates.add("");
          }
          index++;
        }

        setState(() {
         // Gelen veriyi önce 'num' (her iki sayı tipi) olarak kabul et, sonra int'e çevir
          _currentScore = (res["current_score"] as num? ?? 50).toInt();
          _spots = loadedSpots;
          _dates = loadedDates;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Could not load history.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffefeae2),
      appBar: AppBar(
        title: Text("${widget.receiverName} - Analytics"),
        backgroundColor: _turquoise,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _turquoise))
          : _error.isNotEmpty
              ? Center(child: Text("Error: $_error", style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Header Card
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_turquoise, Color(0xFF00B4D8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _turquoise.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Closeness Score",
                              style: TextStyle(color: Colors.white70, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "$_currentScore%",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _getRelationshipLevel(_currentScore),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Chart Card
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "History Timeline",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 30),
                            SizedBox(
                              height: 300,
                              child: _spots.isEmpty
                                  ? const Center(child: Text("No data yet"))
                                  : _buildChart(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  String _getRelationshipLevel(int score) {
    if (score <= 30) return "Formal";
    if (score >= 71) return "Informal (Close)";
    return "Neutral";
  }

  Widget _buildChart() {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 100,
        minX: 0,
        maxX: (_spots.length > 1 ? (_spots.length - 1).toDouble() : 1.0),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200],
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < _dates.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      _dates[value.toInt()],
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  );
                }
                return const Text("");
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              interval: 20,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: _spots.isEmpty ? [const FlSpot(0, 50)] : _spots,
            isCurved: true,
            color: _turquoise,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  _turquoise.withOpacity(0.3),
                  _turquoise.withOpacity(0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
