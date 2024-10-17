// screens/cards_screen.dart
import 'package:flutter/material.dart';
import '../database_helper.dart';

class CardsScreen extends StatefulWidget {
  final int folderId;
  final String folderName;

  CardsScreen({required this.folderId, required this.folderName});

  @override
  _CardsScreenState createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> cardsInFolder = [];
  List<Map<String, dynamic>> availableCards = [];

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final folderCards = await dbHelper.getCardsInFolder(widget.folderId);
    final unassignedCards = await dbHelper.getUnassignedCards(widget.folderName);

    setState(() {
      cardsInFolder = folderCards;
      availableCards = unassignedCards;
    });
  }

  Future<void> _addCard() async {
    if (!await dbHelper.canAddCardToFolder(widget.folderId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This folder can only hold 6 cards')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Card'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableCards.length,
            itemBuilder: (context, index) {
              final card = availableCards[index];
              return ListTile(
                title: Text(card['name']),
                onTap: () async {
                  await dbHelper.assignCardToFolder(card['id'], widget.folderId);
                  Navigator.pop(context);
                  _loadCards();
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.folderName}'),
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: cardsInFolder.length,
        itemBuilder: (context, index) {
          final card = cardsInFolder[index];
          return Card(
            elevation: 4,
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_card, size: 48),
                      SizedBox(height: 8),
                      Text(card['name']),
                    ],
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(Icons.close),
                    onPressed: () async {
                      await dbHelper.removeCardFromFolder(card['id']);
                      _loadCards();
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: Icon(Icons.add),
      ),
    );
  }
}