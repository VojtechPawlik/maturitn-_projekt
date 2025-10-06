// import 'dart:convert';
// import 'package:http/http.dart' as http;

class Fixture {
  Fixture({required this.home, required this.away, required this.kickoff});

  final String home;
  final String away;
  final DateTime kickoff;
}

class FixturesService {
  FixturesService._();
  static final FixturesService instance = FixturesService._();

  Future<List<Fixture>> loadCzechFixtures(DateTime day) async {
    // Placeholder endpoint – replace with your real API later
    // For now, return mocked data aligned to requested date
    final DateTime date = DateTime(day.year, day.month, day.day);
    return <Fixture>[
      Fixture(home: 'Sparta Praha', away: 'Slavia Praha', kickoff: date.add(const Duration(hours: 18))),
      Fixture(home: 'Viktoria Plzeň', away: 'Baník Ostrava', kickoff: date.add(const Duration(hours: 16, minutes: 30))),
      Fixture(home: 'Sigma Olomouc', away: 'Slovan Liberec', kickoff: date.add(const Duration(hours: 15))),
    ];
  }
}


