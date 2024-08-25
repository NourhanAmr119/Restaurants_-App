import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductPage extends StatefulWidget {
  final String placeName;

  ProductPage({required this.placeName});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  List<Map<String, dynamic>> products = [];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://www.emaproject.somee.com/api/Product/${Uri.encodeComponent(widget.placeName)}/products'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          products = data.map<Map<String, dynamic>>((product) {
            return {
              'name': product['productName'],
              'imagePath': product['productImage'],
            };
          }).toList();
        });
      } else {
        print('Failed to fetch products: ${response.statusCode}');
        throw Exception('Failed to fetch products');
      }
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.placeName} Products'),
      ),
      body: Container(
        color: Colors.white,
        child: ListView.builder(
          itemCount: products.length,
          itemBuilder: (BuildContext context, int index) {
            return _buildProductCard(
              context,
              products[index]['name'],
              products[index]['imagePath'],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProductCard(
      BuildContext context, String name, String? imagePath) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        title: Text(name),
        leading: imagePath != null ? Image.network(imagePath) : null,
        onTap: () {
          // Navigate to ProductDetailsPage when tapped
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsPage(productName: name),
            ),
          );
        },
      ),
    );
  }
}

class ProductDetailsPage extends StatelessWidget {
  final String productName;

  ProductDetailsPage({required this.productName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(productName),
      ),
      body: Center(
        child: Text('Product Details'),
      ),
    );
  }
}
