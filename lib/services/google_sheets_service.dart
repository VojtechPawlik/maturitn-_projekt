import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/champions_league_team.dart';
import '../models/premier_league_team.dart';
import '../models/serie_a_team.dart';
import '../models/la_liga_team.dart';
import '../models/bundesliga_team.dart';
import '../models/ligue1_team.dart';
import '../models/europa_league_team.dart';

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

  static Future<List<PremierLeagueTeam>> getPremierLeagueData() async {
    try {
      final String range = 'List 2!A2:J100'; // List 2 pro Premier League
      final String url = 
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range?key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> values = data['values'] ?? [];
        
        return values
            .map((row) => PremierLeagueTeam.fromList(row))
            .toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  static Future<List<SerieATeam>> getSerieAData() async {
    try {
      final String range = 'List 3!A2:J100'; // List 3 pro Serie A
      final String url = 
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range?key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> values = data['values'] ?? [];
        
        return values
            .map((row) => SerieATeam.fromList(row))
            .toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  static Future<List<LaLigaTeam>> getLaLigaData() async {
    try {
      final String range = 'List 4!A2:J100'; // List 4 pro La Liga
      final String url = 
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range?key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> values = data['values'] ?? [];
        
        return values
            .map((row) => LaLigaTeam.fromList(row))
            .toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  static Future<List<BundesligaTeam>> getBundesligaData() async {
    try {
      final String range = 'List 5!A2:J100'; // List 5 pro Bundesliga
      final String url = 
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range?key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> values = data['values'] ?? [];
        
        return values
            .map((row) => BundesligaTeam.fromList(row))
            .toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  static Future<List<Ligue1Team>> getLigue1Data() async {
    try {
      final String range = 'List 7!A2:J100'; // List 7 pro Ligue 1
      final String url = 
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range?key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> values = data['values'] ?? [];
        
        return values
            .map((row) => Ligue1Team.fromList(row))
            .toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

  static Future<List<EuropaLeagueTeam>> getEuropaLeagueData() async {
    try {
      final String range = 'List 6!A2:J100'; // List 6 pro Europa League
      final String url = 
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range?key=$apiKey';
      
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> values = data['values'] ?? [];
        
        return values
            .map((row) => EuropaLeagueTeam.fromList(row))
            .toList();
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }
}
