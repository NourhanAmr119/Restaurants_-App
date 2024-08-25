import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'product_page.dart';
import 'search_results.dart'; // Import the search_results.dart file

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, dynamic>> places = [];
  List<String> products = [];
  String selectedProduct = '';

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
    _fetchProducts();
  }

  void _fetchPlaces() async {
    final response = await http.get(
      Uri.parse('http://www.emaproject.somee.com/api/Place/getAllPlaces'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        places = data.map<Map<String, dynamic>>((place) {
          return {
            'name': place['placeName'],
            'category': place['category'],
            'imagePath': place['placeImage'],
          };
        }).toList();
      });
    } else {
      throw Exception('Failed to fetch places');
    }
  }

  void _fetchProducts() async {
    final response = await http.get(
      Uri.parse('http://www.emaproject.somee.com/GetAllProducts'),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        products = data.cast<String>().toList();
      });
    } else {
      throw Exception('Failed to fetch products');
    }
  }

  void _searchByProduct(String product) async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://www.emaproject.somee.com/api/Product/$product/searchByProduct'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Navigate to SearchResultsPage with the search results
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SearchResultsPage(
                product: product), // Pass the product data here
          ),
        );
      } else {
        throw Exception('Failed to fetch search results');
      }
    } catch (e) {
      print('Error fetching search results: $e');
      // Handle error - Display a snackbar, toast message, or dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to fetch search results. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Places'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate:
                    ProductSearch(products: products), // Pass products here
              ).then((value) {
                if (value != null) {
                  setState(() {
                    selectedProduct = value;
                    _searchByProduct(selectedProduct);
                  });
                }
              });
            },
          ),
        ],
      ),
      body: Container(
        color: Colors.white,
        child: ListView.builder(
          itemCount: places.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildCard(
              context,
              places[index]['name'],
              places[index]['category'],
              places[index]['imagePath'],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCard(
      BuildContext context, String name, String category, String? imagePath) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        title: Text(name),
        subtitle: Text(category),
        leading: imagePath != null ? Image.network(imagePath) : null,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductPage(placeName: name),
            ),
          );
        },
      ),
    );
  }
}

class ProductSearch extends SearchDelegate<String> {
  final List<String> products;

  ProductSearch({required this.products}); // Corrected the constructor

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Not used for this example
    return Container();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? products
        : products.where((product) {
            return product.toLowerCase().contains(query.toLowerCase());
          }).toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(suggestionList[index]),
          onTap: () {
            close(context, suggestionList[index]);
          },
        );
      },
    );
  }
}
