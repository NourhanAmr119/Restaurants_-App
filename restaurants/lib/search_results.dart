import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:rxdart/rxdart.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'product_page.dart';

class SearchResultsPage extends StatefulWidget {
  final String product;

  SearchResultsPage({required this.product});

  @override
  _SearchResultsPageState createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> searchResults = [];

  // Define selectedPlace
  Map<String, dynamic>? selectedPlace;

  // Stream controllers for search results and current location
  final BehaviorSubject<List<Map<String, dynamic>>> _searchResultsController =
  BehaviorSubject<List<Map<String, dynamic>>>.seeded([]);
  final BehaviorSubject<Position> _currentLocationController =
  BehaviorSubject<Position>.seeded(
    Position(
      latitude: 0,
      longitude: 0,
      accuracy: 0,
      altitude: 0,
      speed: 0,
      speedAccuracy: 0,
      heading: 0,
      timestamp: DateTime.now(),
      altitudeAccuracy: 0,
      headingAccuracy: 0, // Add a default value for headingAccuracy
    ),
  );

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchSearchResults(widget.product);
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchResultsController.close();
    _currentLocationController.close();
    super.dispose();
  }

  void _fetchSearchResults(String product) async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://www.emaproject.somee.com/api/Product/${Uri.encodeComponent(
              product)}/searchByProduct',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          searchResults = data.map<Map<String, dynamic>>((place) {
            return {
              'placeName': place['placeName'],
              'category': place['category'],
              'placeImage': place['placeImage'],
              'latitude': place['latitude'],
              'longitude': place['longitude'],
            };
          }).toList();
        });
        _searchResultsController.add(searchResults);
      } else {
        print('Failed to fetch search results: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching search results: $e');
    }
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _currentLocationController.add(position);
    } catch (e) {
      print('Error fetching current location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Results'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'List View'),
            Tab(icon: Icon(Icons.map), text: 'Map View'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _searchResultsController.stream,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (BuildContext context, int index) {
                    return _buildCard(
                      context,
                      snapshot.data![index]['placeName'],
                      snapshot.data![index]['category'],
                      snapshot.data![index]['placeImage'],
                      snapshot.data![index]['latitude'],
                      snapshot.data![index]['longitude'],
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return const Center(
                    child: Text('Error loading search results'));
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            },
          ),
          _buildMapView(),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    return FutureBuilder(
      future: _currentLocationController.stream.first,
      builder: (context, AsyncSnapshot<Position> snapshot) {
        if (snapshot.hasData) {
          Position position = snapshot.data!;
          return FlutterMap(
            options: MapOptions(
              initialCenter: searchResults.isNotEmpty
                  ? LatLng(searchResults[0]['latitude'],
                  searchResults[0]['longitude'])
                  : const LatLng(51.5, -0.09),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: searchResults.map((result) {
                  return Marker(
                    width: 80.0,
                    height: 80.0,
                    point: LatLng(result['latitude'], result['longitude']),
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40.0,
                    ),
                  );
                }).toList(),
              ),
            ],
          );
        } else if (snapshot.hasError) {
          return Center(child: Text('Error loading map'));
        } else {
          return Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Widget _buildCard(BuildContext context, String name, String category,
      String? imagePath, double latitude, double longitude) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: ListTile(
        title: Text(name),
        subtitle: Text(category),
        leading: imagePath != null ? Image.network(imagePath) : null,
        trailing: IconButton(
          icon: const Icon(Icons.directions),
          onPressed: () {
            // Set the selectedPlace before calculating the distance
            selectedPlace = {
              'latitude': latitude,
              'longitude': longitude,
            };
            _calculateDistanceAndShowDialog(context, name);
          },
        ),
      ),
    );
  }

  void _calculateDistanceAndShowDialog(
      BuildContext context, String placeName) async {
    // Get the current location
    Position position = await _currentLocationController.first;

    // Calculate the distance between the current location and the place location
    double distanceInMeters = await Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      selectedPlace!['latitude'],
      selectedPlace!['longitude'],
    );

    // Get the directions
    List<Placemark> placemarks = await placemarkFromCoordinates(
      selectedPlace!['latitude'],
      selectedPlace!['longitude'],
    );
    String directions = placemarks.isNotEmpty
        ? placemarks[0].name ?? 'Unnamed place'
        : 'Place';

    // Convert distance to kilometers
    double distanceInKm = distanceInMeters / 1000;

    // Show a dialog with the distance and directions
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Directions to $placeName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Distance: ${distanceInKm.toStringAsFixed(2)} km'),
              const SizedBox(height: 10),
              Text('Directions: $directions'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

}