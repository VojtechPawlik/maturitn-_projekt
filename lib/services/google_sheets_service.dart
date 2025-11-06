import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/champions_league_team.dart';
import '../models/premier_league_team.dart';
import '../models/serie_a_team.dart';
import '../models/la_liga_team.dart';
import '../models/bundesliga_team.dart';
import '../models/ligue1_team.dart';
import '../models/europa_league_team.dart';
import '../models/team.dart';

class GoogleSheetsService {
  static const String spreadsheetId = '16wV1v15gxBlR-UP8vUTKfDq9dRPow88FhlLdPljAYAM';
  static const String apiKey = 'AIzaSyC0Ft8dYDodQZm79BET8yA16hJveWQg4Xw'; // Nahraď svým API klíčem
  
  static Future<List<ChampionsLeagueTeam>> getChampionsLeagueData() async {
    try {
      final String range = 'List 1!A2:G100'; // A až G (7 sloupců)
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
      final String range = 'List 2!A2:G100'; // A až G (7 sloupců včetně barev)
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
      final String range = 'List 3!A2:G100'; // A až G (7 sloupců)
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
      final String range = 'List 4!A2:G100'; // A až G (7 sloupců)
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
      final String range = 'List 5!A2:G100'; // A až G (7 sloupců)
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
      final String range = 'List 7!A2:G100'; // List 7 pro Ligue 1
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
      final String range = 'List 6!A2:G100'; // List 6 pro Europa League
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

  static Future<String> getCompetitionLogo(String listName, String cell) async {
    try {
      final String range = '$listName!$cell';
      final String url = 
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range?key=$apiKey';
      
      print('Načítám logo z: $range'); // Debug
      final response = await http.get(Uri.parse(url));
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> values = data['values'] ?? [];
        
        if (values.isNotEmpty && values[0].isNotEmpty) {
          final logo = values[0][0].toString();
          print('Načteno logo: $logo'); // Debug
          return logo;
        }
        print('Prázdná data pro $range'); // Debug
        return '';
      } else {
        print('Chyba HTTP ${response.statusCode} pro $range'); // Debug
        throw Exception('Failed to load logo: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception při načítání loga: $e'); // Debug
      return '';
    }
  }

  static Future<Team> getTeamData(String listName) async {
    try {
      // Načteme všechny potřebné buňky najednou
      final ranges = [
        '$listName!D2', // název
        '$listName!E2', // sezona
        '$listName!G2', // stát
        '$listName!S6', // logo
        '$listName!V6', // stadion
        '$listName!X6', // stát stadionu
        '$listName!Y6', // město
        '$listName!AD6', // liga
      ];
      
      final urls = ranges.map((range) => 
        'https://sheets.googleapis.com/v4/spreadsheets/$spreadsheetId/values/$range?key=$apiKey'
      ).toList();
      
      final responses = await Future.wait(
        urls.map((url) => http.get(Uri.parse(url)))
      );
      
      final values = responses.map((response) {
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final vals = data['values'] as List?;
          if (vals != null && vals.isNotEmpty && vals[0].isNotEmpty) {
            return vals[0][0].toString();
          }
        }
        return '';
      }).toList();
      
      return Team(
        name: values[0],
        season: values[1],
        country: values[2],
        logoUrl: values[3],
        stadium: values[4],
        stadiumCountry: values[5],
        city: values[6],
        league: values[7],
      );
    } catch (e) {
      print('Chyba při načítání týmu: $e');
      throw Exception('Error fetching team data: $e');
    }
  }
}
