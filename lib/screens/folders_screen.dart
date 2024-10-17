import 'package:flutter/material.dart';
import '../database_helper.dart';
import 'cards_screen.dart';

class FoldersScreen extends StatefulWidget {
  const FoldersScreen({Key? key}) : super(key: key);

  @override
  _FoldersScreenState createState() => _FoldersScreenState();
}

class _FoldersScreenState extends State<FoldersScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> folders = [];
  Map<int, int> cardCounts = {};
  Map<int, Map<String, dynamic>?> firstCards = {};

  @override
  void initState() {
    super.initState();
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final foldersList = await dbHelper.getFolders();
    final counts = <int, int>{};
    final cards = <int, Map<String, dynamic>?>{};

    for (var folder in foldersList) {
      final id = folder['id'] as int;
      counts[id] = await dbHelper.getCardCount(id);
      cards[id] = await dbHelper.getFirstCardInFolder(id);
    }

    setState(() {
      folders = foldersList;
      cardCounts = counts;
      firstCards = cards;
    });
  }

  String _getSuitIcon(String suitName) {
    switch (suitName.toLowerCase()) {
      case 'hearts':
        return '♥';
      case 'spades':
        return '♠';
      case 'diamonds':
        return '♦';
      case 'clubs':
        return '♣';
      default:
        return '?';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Justin's Card Organizer"),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        itemCount: folders.length,
        itemBuilder: (context, index) {
          final folder = folders[index];
          final folderId = folder['id'] as int;
          final cardCount = cardCounts[folderId] ?? 0;
          final firstCard = firstCards[folderId];

          return Card(
            elevation: 4,
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CardsScreen(
                      folderId: folderId,
                      folderName: folder['name'],
                    ),
                  ),
                ).then((_) => _loadFolders());
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _getSuitIcon(folder['name']),
                        style: TextStyle(
                          fontSize: 48,
                          color: folder['name'].toLowerCase().contains(RegExp(r'hearts|diamonds'))
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    folder['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$cardCount cards',
                    style: TextStyle(
                      color: cardCount < 3 ? Colors.red : Colors.grey[600],
                    ),
                  ),
                  if (cardCount < 3)
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Min 3 cards required',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}