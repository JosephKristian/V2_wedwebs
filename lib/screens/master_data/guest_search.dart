import 'package:flutter/material.dart';
import 'guest_detail_screen.dart';

class GuestSearch extends SearchDelegate<Map<String, dynamic>> {
  final List<Map<String, dynamic>> guests;
  final Function(Map<String, dynamic>) onGuestSelected;
  final Function(Map<String, dynamic>) onEditGuest;
  final Function(String) onDeleteGuest;
  final String idServer;

  GuestSearch(this.guests, this.onGuestSelected, this.onEditGuest,
      this.onDeleteGuest, this.idServer);

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
        close(context, {}); // Mengembalikan map kosong
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    // Filter tamu berdasarkan query pencarian
    List<Map<String, dynamic>> filteredList = guests.where((guest) {
      String guestName = guest['name'].toString().toLowerCase();
      return guestName.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        var guest = filteredList[index];
        return Dismissible(
          key: Key(guest['guest_id'].toString()),
          background: Container(
            color: Colors.blue,
            child: Icon(Icons.edit, color: Colors.white),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            child: Icon(Icons.delete, color: Colors.white),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
          ),
          onDismissed: (direction) async {
            bool confirmDelete = false;

            if (direction == DismissDirection.startToEnd) {
              onEditGuest(guest);
            } else if (direction == DismissDirection.endToStart) {
              confirmDelete = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Konfirmasi'),
                      content:
                          Text('Apakah Anda yakin ingin menghapus tamu ini?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Hapus'),
                        ),
                      ],
                    ),
                  ) ??
                  false; // Menangani kasus null

              if (confirmDelete) {
                onDeleteGuest(guest['guest_id']);
              } else {
                // Jika di-cancel, tampilkan snack bar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Penghapusan dibatalkan')),
                );
              }
            }
          },
          child: Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(guest['name']),
              subtitle: Text('Email: ${guest['email']}'),
              onTap: () {
                onGuestSelected(guest);
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => GuestDetailScreen(guest: guest, idServer: idServer ,),
                //   ),
                // );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Filter saran tamu berdasarkan query pencarian
    List<Map<String, dynamic>> suggestionList = guests.where((guest) {
      String guestName = guest['name'].toString().toLowerCase();
      return guestName.contains(query.toLowerCase());
    }).toList();

    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (context, index) {
        var guest = suggestionList[index];
        return Dismissible(
          key: Key(guest['guest_id'].toString()),
          background: Container(
            color: Colors.blue,
            child: Icon(Icons.edit, color: Colors.white),
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
          ),
          secondaryBackground: Container(
            color: Colors.red,
            child: Icon(Icons.delete, color: Colors.white),
            alignment: Alignment.centerRight,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
          ),
          onDismissed: (direction) async {
            bool confirmDelete = false;

            if (direction == DismissDirection.startToEnd) {
              onEditGuest(guest);
            } else if (direction == DismissDirection.endToStart) {
              confirmDelete = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Konfirmasi'),
                      content:
                          Text('Apakah Anda yakin ingin menghapus tamu ini?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('Batal'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Hapus'),
                        ),
                      ],
                    ),
                  ) ??
                  false; // Menangani kasus null

              if (confirmDelete) {
                onDeleteGuest(guest['guest_id']);
              } else {
                // Jika di-cancel, tampilkan snack bar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Penghapusan dibatalkan')),
                );
              }
            }
          },
          child: Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text(guest['name']),
              subtitle: Text('Email: ${guest['email']}'),
              onTap: () {
                onGuestSelected(guest);
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) => GuestDetailScreen(
                //       guest: guest,
                //       idServer: idServer,
                //     ),
                //   ),
                // );
              },
            ),
          ),
        );
      },
    );
  }
}
