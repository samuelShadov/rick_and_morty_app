import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rick and Morty Characters',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CharacterListScreen(),
    );
  }
}

class Character {
  final String name;
  final String imageUrl;
  final String gender;

  Character({required this.name, required this.imageUrl, required this.gender});

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: json['name'],
      imageUrl: json['image'],
      gender: json['gender'],
    );
  }
}

class CharacterListScreen extends StatefulWidget {
  @override
  _CharacterListScreenState createState() => _CharacterListScreenState();
}

class _CharacterListScreenState extends State<CharacterListScreen> {
  late Future<List<Character>> characters;
  bool isGridView = false;

  // Mapa para guardar el rating de cada personaje (key: id, value: rating)
  Map<int, double> characterRatings = {};

  Future<List<Character>> fetchCharacters() async {
    final response = await http.get(Uri.parse('https://rickandmortyapi.com/api/character'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body)['results'];
      return data.map((item) => Character.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load characters');
    }
  }

  @override
  void initState() {
    super.initState();
    characters = fetchCharacters();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rick and Morty Characters'),
        backgroundColor: Colors.green,
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: FutureBuilder<List<Character>>(
          future: characters,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No characters found.'));
            } else {
              final data = snapshot.data!;
              return isGridView ? _buildGridView(data) : _buildListView(data);
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            isGridView = !isGridView;
          });
        },
        child: Icon(isGridView ? Icons.list : Icons.grid_view),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildListView(List<Character> characters) {
    return ListView.builder(
      itemCount: characters.length,
      itemBuilder: (context, index) {
        final character = characters[index];
        double rating = characterRatings[character.hashCode] ?? 3.5;

        return Card(
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: ListTile(
            contentPadding: EdgeInsets.all(15),
            leading: GestureDetector(
              onTap: () => _showCharacterDetails(context, character),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(character.imageUrl, width: 80, height: 80, fit: BoxFit.cover),
              ),
            ),
            title: Text(
              character.name,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Gender: ${character.gender}'),
                SizedBox(height: 5),
                Text(
                  'Rating: ${rating.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<Character> characters) {
  return GridView.builder(
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      childAspectRatio: 0.8,
    ),
    itemCount: characters.length,
    itemBuilder: (context, index) {
      final character = characters[index];
      double rating = characterRatings[character.hashCode] ?? 3.5;

      return Card(
        margin: EdgeInsets.all(10),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: GridTile(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => _showCharacterDetails(context, character),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(character.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Rating: ${rating.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 16, color: Colors.green),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

  void _showCharacterDetails(BuildContext context, Character character) {
    double userRating = characterRatings[character.hashCode] ?? 5.0; // Valor inicial del rating

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.black.withOpacity(0.9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(character.imageUrl, height: 200, width: 200, fit: BoxFit.cover),
                    ),
                    SizedBox(height: 20),
                    Text(
                      character.name,
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    SizedBox(height: 10),
                    Text('Gender: ${character.gender}', style: TextStyle(fontSize: 18, color: Colors.white70)),
                    SizedBox(height: 20),
                    Text(
                      'Rate this Character:',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    Slider(
                      value: userRating,
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      label: userRating.toStringAsFixed(1),
                      onChanged: (value) {
                        setState(() {
                          userRating = value;
                        });
                      },
                      activeColor: Colors.green,
                      inactiveColor: Colors.white38,
                    ),
                    Text(
                      '${userRating.toStringAsFixed(1)} / 10',
                      style: TextStyle(color: Colors.green, fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          characterRatings[character.hashCode] = userRating;
                        });
                        Navigator.of(context).pop();
                      },
                      child: Text('Save Rating'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
