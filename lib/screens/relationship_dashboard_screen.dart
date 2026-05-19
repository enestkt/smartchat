import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

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
  State<RelationshipDashboardScreen> createState() =>
      _RelationshipDashboardScreenState();
}

class _RelationshipDashboardScreenState
    extends State<RelationshipDashboardScreen> {
  bool _isLoading = true;
  String _error = "";

  int _closeness = 50;
  int _politeness = 50;
  String _currentStyle = "Formal (Resmi)";
  List<FlSpot> _spots = [];
  List<String> _dates = [];

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _analytics = {};
  Map<String, dynamic> _mood = {};

  static const Color _teal   = Color(0xFF008F9C);
  static const Color _indigo = Color(0xFF6366F1);
  static const Color _amber  = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = ""; });
    try {
      final results = await Future.wait([
        ApiService().getRelationshipHistory(
            user1Id: widget.senderId, user2Id: widget.receiverId),
        ApiService().getConversationStats(
            user1Id: widget.senderId, user2Id: widget.receiverId),
        ApiService().getSuggestionAnalytics(widget.senderId),
        ApiService().getMoodForecast(
            senderId: widget.senderId, receiverId: widget.receiverId),
      ]);

      final rel = results[0];
      if (rel["success"] == true) {
        final history = rel["history"] as List;
        List<FlSpot> spots = [];
        List<String> dates = [];
        for (int i = 0; i < history.length; i++) {
          spots.add(FlSpot(i.toDouble(),
              double.parse(history[i]["closeness_score"].toString())));
          try {
            final dt = DateTime.parse(history[i]["timestamp"].toString());
            dates.add("${dt.day}/${dt.month}");
          } catch (_) {
            dates.add("");
          }
        }
        _closeness  = (rel["current_score"]      as num? ?? 50).toInt();
        _politeness = (rel["current_politeness"] as num? ?? 50).toInt();
        _currentStyle = rel["current_style"]?.toString() ?? "Formal (Resmi)";
        _spots = spots;
        _dates = dates;
      }

      _stats     = results[1];
      _analytics = results[2];
      _mood      = results[3];

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEAE2),
      appBar: AppBar(
        title: Text("${widget.receiverName} - Analitik",
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: _teal,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadAll,
            tooltip: "Yenile",
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _teal))
          : _error.isNotEmpty
              ? _buildError()
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Column(
                    children: [
                      _buildHeaderCard(),
                      _buildMoodCard(),
                      _buildChartCard(),
                      _buildStatsCard(),
                      _buildAnalyticsCard(),
                    ],
                  ),
                ),
    );
  }

  // ----------------------------------------------------------------
  // ERROR
  // ----------------------------------------------------------------
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text("Veriler yuklenemedi",
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(_error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAll,
              icon: const Icon(Icons.refresh),
              label: const Text("Tekrar Dene"),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _teal, foregroundColor: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // HEADER CARD — Closeness + Politeness + 2D Matris
  // ----------------------------------------------------------------
  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006D7A), _teal, Color(0xFF00B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: _teal.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6))
        ],
      ),
      child: Column(
        children: [
          // Stil etiketi
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _currentStyle,
              style: GoogleFonts.poppins(
                  color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 20),

          // Iki skor yan yana
          Row(
            children: [
              Expanded(child: _scoreGauge(
                label: "Yakinlik",
                value: _closeness,
                icon: Icons.favorite_rounded,
                color: Colors.pinkAccent.shade100,
              )),
              Container(
                width: 1,
                height: 80,
                color: Colors.white.withValues(alpha: 0.25),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(child: _scoreGauge(
                label: "Nezaket",
                value: _politeness,
                icon: Icons.handshake_rounded,
                color: Colors.amber.shade200,
              )),
            ],
          ),
          const SizedBox(height: 20),

          // 2D matris
          _buildMatrixIndicator(),
        ],
      ),
    );
  }

  Widget _scoreGauge({
    required String label,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          "$value%",
          style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.1),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100,
            minHeight: 5,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: GoogleFonts.inter(
                color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildMatrixIndicator() {
    final bool highClose = _closeness > 50;
    final bool highPol   = _politeness > 50;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Iliski Matrisi",
            style: GoogleFonts.inter(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Row(
          children: [
            RotatedBox(
              quarterTurns: 3,
              child: Text("Yakinlik ->",
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      _quadrantCell("Samimi\nYakin",  highClose && highPol),
                      const SizedBox(width: 4),
                      _quadrantCell("Resmi\nYakin",   !highClose && highPol),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _quadrantCell("Serbest\nUzak",  highClose && !highPol),
                      const SizedBox(width: 4),
                      _quadrantCell("Resmi\nUzak",    !highClose && !highPol),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("<- Dusuk Nezaket",
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
                      Text("Yuksek Nezaket ->",
                          style: GoogleFonts.inter(color: Colors.white38, fontSize: 9)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _quadrantCell(String label, bool active) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        height: 46,
        decoration: BoxDecoration(
          color: active
              ? Colors.white.withValues(alpha: 0.28)
              : Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? Colors.white.withValues(alpha: 0.70)
                : Colors.white.withValues(alpha: 0.15),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: active ? Colors.white : Colors.white38,
              fontSize: 10,
              fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------------
  // MOOD FORECAST CARD
  // ----------------------------------------------------------------
  Widget _buildMoodCard() {
    if (_mood.isEmpty) return const SizedBox();

    final mood     = _mood["mood"]    as String? ?? "neutral";
    final score    = (_mood["score"]  as num?)?.toDouble() ?? 0.0;
    final trend    = _mood["trend"]   as String? ?? "stable";
    final warning  = _mood["warning"] as String? ?? "";
    final tip      = _mood["tip"]     as String? ?? "";
    final points   = (_mood["data_points"] as num?)?.toInt() ?? 0;
    final freqDrop = _mood["freq_drop"] as bool? ?? false;

    final cfg = _moodConfig(mood);

    return _card(
      title: "Su An Nasil Hissediyor?",
      icon: Icons.psychology_alt_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: cfg.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                    child: Text(cfg.emoji, style: const TextStyle(fontSize: 28))),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(cfg.label,
                            style: GoogleFonts.poppins(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: cfg.color)),
                        const SizedBox(width: 8),
                        _trendChip(trend),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: (score + 1) / 2,
                        minHeight: 7,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(cfg.color),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text("$points mesaj analiz edildi",
                        style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          if (warning.isNotEmpty) ...[
            const SizedBox(height: 12),
            _infoRow(Icons.warning_amber_rounded, warning, cfg.color),
          ],
          if (tip.isNotEmpty) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.lightbulb_outline_rounded, tip, Colors.grey.shade500),
          ],
          if (freqDrop) ...[
            const SizedBox(height: 6),
            _infoRow(Icons.notifications_paused_outlined,
                "Normalden az mesaj atiyor - belki yogun veya yorgun.", _amber),
          ],
        ],
      ),
    );
  }

  Widget _trendChip(String trend) {
    final (IconData icon, Color color, String label) = switch (trend) {
      "rising"  => (Icons.trending_up_rounded,   Colors.green.shade600, "Yukseliyor"),
      "falling" => (Icons.trending_down_rounded,  Colors.red.shade400,   "Dusuyor"),
      _         => (Icons.trending_flat_rounded,  Colors.grey,           "Sabit"),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 10, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: GoogleFonts.inter(
                  fontSize: 12, color: Colors.grey.shade700, height: 1.4)),
        ),
      ],
    );
  }

  ({String emoji, String label, Color color}) _moodConfig(String mood) {
    return switch (mood) {
      "positive" => (emoji: "😊", label: "Iyi Hissediyor",   color: Colors.green.shade600),
      "negative" => (emoji: "😟", label: "Gergin / Mutsuz",  color: Colors.red.shade400),
      "mixed"    => (emoji: "😐", label: "Karisik Duygular",  color: _amber),
      _          => (emoji: "🙂", label: "Notr",              color: Colors.blueGrey),
    };
  }

  // ----------------------------------------------------------------
  // CHART CARD
  // ----------------------------------------------------------------
  Widget _buildChartCard() {
    return _card(
      title: "Yakinlik Gecmisi",
      icon: Icons.show_chart_rounded,
      child: SizedBox(
        height: 240,
        child: _spots.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.timeline_rounded, size: 40, color: Colors.grey.shade300),
                    const SizedBox(height: 8),
                    Text("Henuz veri yok",
                        style: GoogleFonts.inter(color: Colors.grey)),
                  ],
                ),
              )
            : _buildLineChart(),
      ),
    );
  }

  Widget _buildLineChart() {
    return LineChart(LineChartData(
      minY: 0,
      maxY: 100,
      minX: 0,
      maxX: (_spots.length > 1 ? (_spots.length - 1).toDouble() : 1.0),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 25,
        getDrawingHorizontalLine: (_) =>
            FlLine(color: Colors.grey.shade100, strokeWidth: 1),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles:   const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: (_spots.length > 6
                ? (_spots.length / 4).ceilToDouble()
                : 1),
            getTitlesWidget: (v, _) {
              final i = v.toInt();
              if (i >= 0 && i < _dates.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_dates[i],
                      style: const TextStyle(color: Colors.grey, fontSize: 10)),
                );
              }
              return const SizedBox();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            interval: 25,
            getTitlesWidget: (v, _) => Text(v.toInt().toString(),
                style: const TextStyle(color: Colors.grey, fontSize: 10)),
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: _spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: _teal,
          barWidth: 2.5,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, _, __, ___) => FlDotCirclePainter(
              radius: 3.5,
              color: Colors.white,
              strokeWidth: 2,
              strokeColor: _teal,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                _teal.withValues(alpha: 0.20),
                _teal.withValues(alpha: 0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    ));
  }

  // ----------------------------------------------------------------
  // CONVERSATION STATS CARD
  // ----------------------------------------------------------------
  Widget _buildStatsCard() {
    if (_stats.isEmpty) return const SizedBox();

    final total    = _stats["total_messages"] ?? 0;
    final u1       = _stats["user1_count"] ?? 0;
    final u2       = _stats["user2_count"] ?? 0;
    final hour     = _stats["most_active_hour"];
    final avgDay   = _stats["avg_per_day"];
    final first    = _stats["first_message"] ?? "-";
    final last     = _stats["last_message"]  ?? "-";
    final sentiment= _stats["sentiment"] as Map? ?? {};
    final topWords = (_stats["top_words"] as List?) ?? [];

    final pos = (sentiment["positive"] as num?)?.toDouble() ?? 0;
    final neg = (sentiment["negative"] as num?)?.toDouble() ?? 0;
    final neu = (sentiment["neutral"]  as num?)?.toDouble() ?? 0;

    return _card(
      title: "Konusma Istatistikleri",
      icon: Icons.bar_chart_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statBox("Toplam",      "$total",
                  Icons.chat_bubble_outline_rounded, _teal),
              const SizedBox(width: 10),
              _statBox("Gunluk",      avgDay != null ? "$avgDay" : "-",
                  Icons.today_rounded, _indigo),
              const SizedBox(width: 10),
              _statBox("Aktif Saat",  hour != null ? "$hour:00" : "-",
                  Icons.access_time_rounded, _amber),
            ],
          ),
          const SizedBox(height: 16),

          _sectionLabel("Kim Daha Cok Yazıyor?"),
          const SizedBox(height: 8),
          _twoColorBar(u1, u2, _teal, _indigo),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _barLegend("Sen", "$u1 mesaj", _teal),
              _barLegend(widget.receiverName, "$u2 mesaj", _indigo),
            ],
          ),
          const SizedBox(height: 16),

          _sectionLabel("Duygu Dagilimi (son 60 mesaj)"),
          const SizedBox(height: 8),
          _sentimentBar(pos, neg, neu),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _sentimentLegend("Pozitif", pos, Colors.green.shade600),
              _sentimentLegend("Notr",    neu, Colors.blueGrey),
              _sentimentLegend("Negatif", neg, Colors.red.shade400),
            ],
          ),

          if (topWords.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionLabel("Sik Kullanilan Kelimeler"),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: topWords.take(10).map<Widget>((w) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _teal.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _teal.withValues(alpha: 0.20)),
                  ),
                  child: Text(
                    "${w["word"]}  ${w["count"]}",
                    style: GoogleFonts.inter(
                        fontSize: 12, fontWeight: FontWeight.w600, color: _teal),
                  ),
                );
              }).toList(),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
              const SizedBox(width: 4),
              Text("$first  -  $last",
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // SUGGESTION ANALYTICS CARD
  // ----------------------------------------------------------------
  Widget _buildAnalyticsCard() {
    if (_analytics.isEmpty) return const SizedBox();

    final total    = _analytics["total"] ?? 0;
    final accepted = _analytics["accepted"] ?? 0;
    final rejected = _analytics["rejected"] ?? 0;
    final pending  = _analytics["pending"] ?? 0;
    final rate     = _analytics["acceptance_rate"];
    final best     = _analytics["best_style"];
    final worst    = _analytics["worst_style"];
    final byStyle  = (_analytics["by_style"] as List?) ?? [];

    return _card(
      title: "AI Oneri Analizi",
      icon: Icons.auto_awesome_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _statBox("Toplam",  "$total",
                  Icons.lightbulb_outline_rounded, _indigo),
              const SizedBox(width: 10),
              _statBox("Kabul",   "$accepted",
                  Icons.check_circle_outline_rounded, Colors.green.shade600),
              const SizedBox(width: 10),
              _statBox("Red",     "$rejected",
                  Icons.cancel_outlined, Colors.red.shade400),
            ],
          ),

          if (rate != null) ...[
            const SizedBox(height: 16),
            _sectionLabel("Genel Kabul Orani"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (rate as num) / 100,
                      minHeight: 10,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          rate >= 60
                              ? Colors.green.shade500
                              : Colors.orange.shade500),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text("$rate%",
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: rate >= 60
                            ? Colors.green.shade600
                            : Colors.orange.shade600)),
              ],
            ),
          ],

          if (best != null || worst != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                if (best != null)
                  Expanded(
                    child: _insightChip(
                      "En Cok Kabul",
                      _normalizeStyle(best.toString()),
                      Icons.thumb_up_alt_rounded,
                      Colors.green.shade600,
                    ),
                  ),
                if (best != null && worst != null) const SizedBox(width: 8),
                if (worst != null)
                  Expanded(
                    child: _insightChip(
                      "En Az Kabul",
                      _normalizeStyle(worst.toString()),
                      Icons.thumb_down_alt_rounded,
                      Colors.red.shade400,
                    ),
                  ),
              ],
            ),
          ],

          if (byStyle.isNotEmpty) ...[
            const SizedBox(height: 16),
            _sectionLabel("Stil Bazli Kabul Oranlari"),
            const SizedBox(height: 8),
            ...byStyle.map((s) => _styleRow(s)),
          ],

          if (pending > 0) ...[
            const SizedBox(height: 8),
            Text("$pending oneri henuz degerlendirilmedi.",
                style: GoogleFonts.inter(fontSize: 12, color: Colors.grey)),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------------------
  // SHARED WIDGETS
  // ----------------------------------------------------------------
  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _teal.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _teal, size: 18),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.textColor(context))),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(value,
                style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700, fontSize: 15, color: color)),
            Text(label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                    fontSize: 10, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.4));
  }

  Widget _twoColorBar(int a, int b, Color ca, Color cb) {
    final total = (a + b) == 0 ? 1 : a + b;
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Flexible(
              flex: (a / total * 100).round().clamp(1, 99),
              child: Container(color: ca),
            ),
            Flexible(
              flex: (b / total * 100).round().clamp(1, 99),
              child: Container(color: cb),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barLegend(String name, String sub, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name,
                style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(sub,
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _sentimentBar(double pos, double neg, double neu) {
    final total = (pos + neg + neu).clamp(1.0, double.infinity);
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            Flexible(
              flex: (pos / total * 100).round().clamp(0, 100),
              child: Container(color: Colors.green.shade500),
            ),
            Flexible(
              flex: (neu / total * 100).round().clamp(0, 100),
              child: Container(color: Colors.blueGrey.shade300),
            ),
            Flexible(
              flex: (neg / total * 100).round().clamp(0, 100),
              child: Container(color: Colors.red.shade400),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sentimentLegend(String label, double value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text("$label ${value.toStringAsFixed(1)}%",
            style:
                GoogleFonts.inter(fontSize: 11, color: Colors.grey.shade700)),
      ],
    );
  }

  Widget _styleRow(Map s) {
    final rate = (s["acceptance_rate"] as num).toDouble();
    final color =
        rate >= 60 ? Colors.green.shade500 : Colors.orange.shade500;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(_normalizeStyle(s["style"].toString()),
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: rate / 100,
                minHeight: 7,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text("${rate.toStringAsFixed(0)}%",
              style: GoogleFonts.inter(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _insightChip(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.inter(
                        fontSize: 10, color: Colors.grey.shade600)),
                Text(value,
                    style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _normalizeStyle(String raw) {
    const map = {
      "neutral":                            "Notr / Belirsiz",
      "formal":                             "Formal (Resmi)",
      "informal":                           "Informal (Samimi)",
      "formal (resmi)":                     "Formal (Resmi)",
      "informal (samimi/kanka)":            "Informal (Samimi)",
      "respectful-close (candan/saygili)":  "Candan / Saygili",
      "cold (soguk/mesafeli)":              "Soguk / Mesafeli",
      "very formal":                        "Cok Resmi",
      "semi-formal":                        "Yari Resmi",
    };
    return map[raw.toLowerCase()] ?? raw;
  }
}
