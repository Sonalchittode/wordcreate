import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiClient {
  // Fetch word meaning from Free Dictionary API
  Future<Map<String, dynamic>?> fetchWordDefinition(String word) async {
    try {
      final response = await http.get(Uri.parse('https://api.dictionaryapi.dev/api/v2/entries/en/$word'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.isNotEmpty ? data[0] : null;
      }
      return null;
    } catch (e) {
      print("Error fetching definition: $e");
      return null;
    }
  }

  // Fetch synonyms & antonyms from Datamuse API
  Future<List<String>> fetchRelatedWords(String word, {bool isAntonym = false}) async {
    try {
      final endpoint = isAntonym ? 'rel_ant' : 'rel_syn';
      final response = await http.get(Uri.parse('https://api.datamuse.com/words?$endpoint=$word&max=4'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((e) => e['word'].toString()).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching related words: $e");
      return [];
    }
  }
}