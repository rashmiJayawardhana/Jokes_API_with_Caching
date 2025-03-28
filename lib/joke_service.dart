// Import the Dio package for making HTTP requests
import 'package:dio/dio.dart';

class JokeService {
  // Create a private instance of Dio (an HTTP client)
  final Dio _dio = Dio();

  Future<List<Map<String, dynamic>>> fetchJokesRaw() async {
    try {
      final response = await _dio.get('https://v2.jokeapi.dev/joke/Programming?amount=5');

      if (response.statusCode == 200) {
        // Extract the list of jokes from the response data
        final List<dynamic> jokesJsonList = response.data['jokes'];

        // Convert the extracted list into a list of maps and return it
        return jokesJsonList.cast<Map<String, dynamic>>();
      } else {
        throw Exception("Failed to load jokes");
      }
    } catch (e) {
      throw Exception("Error fetching jokes: $e");
    }
  }
}
