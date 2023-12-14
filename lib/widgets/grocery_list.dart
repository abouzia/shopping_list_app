import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    try {
      final url = Uri.https(
        'flutter-prep-21d82-default-rtdb.europe-west1.firebasedatabase.app',
        'shopping-list.json',
      );
      final response = await http.get(url);

      print(response.body);
      if (response.body == 'null') {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final listData = jsonDecode(response.body) as Map<String, dynamic>;
      final List<GroceryItem> _loadedItems = [];

      for (var grocery in listData.entries) {
        final category = categories.entries
            .firstWhere(
                (category) => category.value.title == grocery.value['category'])
            .value;
        _loadedItems.add(
          GroceryItem(
            id: grocery.key,
            name: grocery.value['name'],
            quantity: grocery.value['quantity'],
            category: category,
          ),
        );
      }
      setState(() {
        _groceryItems = _loadedItems;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load data, please try again later.';
      });
    }
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItem(),
      ),
    );

    if (newItem != null) {
      setState(() {
        _groceryItems.add(newItem);
      });
    }
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    try {
      final url = Uri.https(
        'flutter-prep-21d82-default-rtdb.europe-west1.firebasedatabase.app',
        'shopping-list/${item.id}.json',
      );
      await http.delete(url);
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Item removed'),
        ),
      );
    } catch (e) {
      setState(() {
        _groceryItems.insert(index, item);
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to remove item'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('No items added yet.'),
    );

    if (_isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          key: ValueKey(_groceryItems[index].id),
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          child: ListTile(
            title: Text(_groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text('${_groceryItems[index].quantity}x'),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      content = Center(
        child: Text(_errorMessage!),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _addItem();
            },
          )
        ],
      ),
      body: content,
    );
  }
}
