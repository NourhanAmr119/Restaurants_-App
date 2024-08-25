import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

class ProductService {
  final _productsSubject = BehaviorSubject<List<String>>();
  final _searchResultsSubject = BehaviorSubject<List<Map<String, dynamic>>>();

  Stream<List<String>> get productsStream => _productsSubject.stream;
  Stream<List<Map<String, dynamic>>> get searchResultsStream => _searchResultsSubject.stream;

  void fetchProducts() async {
    final response = await http.get(Uri.parse('http://www.emaproject.somee.com/GetAllProducts'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _productsSubject.add(data.cast<String>());
    } else {
      _productsSubject.addError('Failed to fetch products');
    }
  }

  void searchByProduct(String product) async {
    final response = await http.get(Uri.parse('http://www.emaproject.somee.com/api/Product/${Uri.encodeComponent(product)}/searchByProduct'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      _searchResultsSubject.add(data.cast<Map<String, dynamic>>());
    } else {
      _searchResultsSubject.addError('Failed to fetch search results');
    }
  }

  void dispose() {
    _productsSubject.close();
    _searchResultsSubject.close();
  }
}
