import 'package:flutter/material.dart';

class EventSearch extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> events;

  EventSearch(this.events);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, {});
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Implement buildResults to display search results
    List<Map<String, dynamic>> filteredList = events.where((event) {
      String eventName = event['event_name'].toString().toLowerCase();
      return eventName.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        var event = filteredList[index];
        return ListTile(
          title: Text(event['event_name']),
          subtitle: Text('Date: ${event['date']}'),
          onTap: () {
            close(context, event);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Implement buildSuggestions to display suggestions
    List<Map<String, dynamic>> suggestionList = events.where((event) {
      String eventName = event['event_name'].toString().toLowerCase();
      return eventName.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        var event = suggestionList[index];
        return ListTile(
          title: Text(event['event_name']),
          subtitle: Text('Date: ${event['date']}'),
          onTap: () {
            query = event['event_name'].toString();
            showResults(context);
          },
        );
      },
    );
  }
}
