import 'package:flutter_bloc/flutter_bloc.dart';

// Define events
abstract class SearchEvent {}

class SearchProducts extends SearchEvent {
  final String product;
  SearchProducts(this.product);
}

// Define states
abstract class SearchState {}

class SearchLoading extends SearchState {}

class SearchLoaded extends SearchState {
  final List<Map<String, dynamic>> searchResults;
  SearchLoaded(this.searchResults);
}

class SearchError extends SearchState {}

// Define bloc
class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc() : super(SearchLoading());

  @override
  Stream<SearchState> mapEventToState(SearchEvent event) async* {
    if (event is SearchProducts) {
      yield SearchLoading();
      try {
        // Fetch search results
        final searchResults = await _fetchSearchResults(event.product);
        yield SearchLoaded(searchResults);
      } catch (_) {
        yield SearchError();
      }
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSearchResults(String product) async {
    // Your existing fetch search results logic goes here
    // Replace this with your actual API call
    await Future.delayed(Duration(seconds: 2));
    return List.generate(5, (index) => {'placeName': 'Place $index', 'category': 'Category $index'});
  }
}
