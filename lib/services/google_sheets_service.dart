import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/champions_league_team.dart';

class GoogleSheetsService {
  static const String spreadsheetId = '16wV1v15gxBlR-UP8vUTKfDq9dRPow88FhlLdPljAYAM';
  static const String apiKey = 'AIzaSyC0Ft8dYDodQZm79BET8yA16hJveWQg4Xw'; // Nahraď svým API klíčem
  
  static Future<List<ChampionsLeagueTeam>> getChampionsLeagueData() async {
    try {
      final String range = 'List 1!A2:J100'; // A až J (10 sloupců včetně loga)
      final String url = 
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range?key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> values = data['values'] ?? [];
        
        return values
            .map((row) => ChampionsLeagueTeam.fromList(row))
            .toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }
}
