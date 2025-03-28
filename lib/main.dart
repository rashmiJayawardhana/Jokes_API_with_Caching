import 'package:flutter/material.dart';
import 'joke_service.dart';
import 'package:shared_preferences/shared_preferences.dart'; // For local storage
import 'dart:convert'; // For JSON encoding and decoding
import 'package:connectivity_plus/connectivity_plus.dart'; // For checking internet connection

void main() {
  runApp(MyApp());
}

// Root widget of the app
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jokes App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false, // Removes the debug banner
      home: JokeListPage(),
    );
  }
}

// Stateful widget for displaying jokes
class JokeListPage extends StatefulWidget {
  const JokeListPage({Key? key}) : super(key: key);

  @override
  _JokeListPageState createState() => _JokeListPageState();
}

class _JokeListPageState extends State<JokeListPage> {
  final JokeService _jokeService = JokeService();
  List<Map<String, dynamic>> _jokesRaw = []; // List to store fetched jokes
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCachedJokes(); // Load cached jokes when the app starts
  }

  // Function to fetch jokes from API
  Future<void> _fetchJokes() async {
    if (await _isOffline()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No internet connection. Loading cached jokes.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final jokes = await _jokeService.fetchJokesRaw(); // Fetch jokes from API
      setState(() {
        _jokesRaw = jokes.length >= 5 ? jokes.take(5).toList() : jokes; // Store max 5 jokes
      });
      await _cacheJokes(_jokesRaw); // Cache fetched jokes
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to fetch jokes: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Function to check internet connection
  Future<bool> _isOffline() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.none;
  }

  // Load cached jokes from local storage
  Future<void> _loadCachedJokes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? jokesJson = prefs.getString('cached_jokes');

    if (jokesJson != null) {
      setState(() {
        _jokesRaw = List<Map<String, dynamic>>.from(json.decode(jokesJson));
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loaded jokes from cache.')),
      );
    }
  }

  // Save jokes to local storage
  Future<void> _cacheJokes(List<Map<String, dynamic>> jokes) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jokesJson = json.encode(jokes);
    await prefs.setString('cached_jokes', jokesJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff5fabfb),
        elevation: 10,
        centerTitle: true,
        title: const Text(
          'Joke App',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(16.0, 30.0, 16.0, 16.0),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xff001848),
              Color(0xff003366),
              Color(0xff00509E),
            ],
            stops: [0.3, 0.7, 1.0],
          ),
        ),
        child: Column(
          children: [
            Text(
              'Welcome!',
              style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                color: Colors.orange[50],
                fontWeight: FontWeight.w900,
                fontSize: 40,
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchJokes,
              child: const Text(
                'View Jokes',
                style: TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff004ebf),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
                padding: const EdgeInsets.all(16.0),
                elevation: 10,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _jokesRaw.isEmpty
                  ? const Center(
                child: Text(
                  'No jokes fetched yet.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black45,
                  ),
                ),
              )
                  : ListView.builder(
                itemCount: _jokesRaw.length,
                itemBuilder: (context, index) {
                  final joke = _jokesRaw[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          joke['type'] == 'single' ? 'Single Joke' : joke['category'],
                          style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          joke['type'] == 'single' ? joke['joke'] : '${joke['setup']}\n\n${joke['delivery']}',
                          style: const TextStyle(fontSize: 16.0, color: Colors.black87),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
