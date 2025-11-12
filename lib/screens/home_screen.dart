import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final DateTime _today;
  late final List<DateTime> _days;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _days = List<DateTime>.generate(15, (int i) => _today.add(Duration(days: i - 7)));
    _tabController = TabController(length: 15, vsync: this, initialIndex: 7);
    
    // Vycentrovat na dnešní datum po vykreslení
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_tabController.index == 7) {
        _tabController.animateTo(7);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatShort(DateTime d) {
    final int day = d.day;
    final int month = d.month;
    return '${day.toString().padLeft(2, '0')}.${month.toString().padLeft(2, '0')}';
  }

  String _weekdayCzShort(DateTime d) {
    switch (d.weekday) {
      case DateTime.monday:
        return 'Po';
      case DateTime.tuesday:
        return 'Út';
      case DateTime.wednesday:
        return 'St';
      case DateTime.thursday:
        return 'Čt';
      case DateTime.friday:
        return 'Pá';
      case DateTime.saturday:
        return 'So';
      case DateTime.sunday:
        return 'Ne';
      default:
        return '';
    }
  }

  Widget _buildDayContent(DateTime date) {
    return Center(
      child: Text(
        'Zápasy pro ${_formatShort(date)}',
        style: const TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Material(
          color: Theme.of(context).colorScheme.surface,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              indicatorColor: Theme.of(context).colorScheme.primary,
              tabs: _days.map<Widget>((DateTime d) {
                final bool isToday = d.year == _today.year && d.month == _today.month && d.day == _today.day;
                final String label = isToday ? 'Dnes ${_formatShort(d)}' : '${_weekdayCzShort(d)} ${_formatShort(d)}';
                return Tab(text: label);
              }).toList(),
              isScrollable: true,
            ),
          ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _days.map<Widget>((DateTime d) => _buildDayContent(d)).toList(),
          ),
        ),
      ],
    );
  }
}


