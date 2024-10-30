import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/database_helper.dart';
import '../../services/generate_link_rsvp.dart';

class WhatsappScreen extends StatefulWidget {
  final String clientId;
  final String idServer;

  final Map<String, dynamic> guest;

  WhatsappScreen(
      {required this.guest, required this.clientId, required this.idServer});

  @override
  _WhatsappScreenState createState() => _WhatsappScreenState();
}

class _WhatsappScreenState extends State<WhatsappScreen> {
  List<Map<String, dynamic>> templates = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final dbHelper = DatabaseHelper.instance;
    final data = await dbHelper.getTemplatesByClientId(widget.clientId);

    setState(() {
      templates =
          data.map((template) => Map<String, dynamic>.from(template)).toList();
      isLoading = false;
    });
  }

  Future<void> _sendMessageUsingTemplate(int index) async {
    final selectedTemplate = templates[index];

    final phoneNumber = "${widget.guest['phone']}"; // Nomor telepon
    final guestQr = "${widget.guest['guest_qr']}"; // QR tamu
    final guestName = "${widget.guest['name']}"; // Nama tamu

    // Menghasilkan RSVP link
    final rsvpLink = await generateRsvpLink(guestQr, widget.idServer);

    // Membangun pesan
    final message = '''
${selectedTemplate['greeting']} *$guestName*,

${selectedTemplate['opening']}
Please confirm your attendance by clicking the link below:

${selectedTemplate['link']}/?guest_qr=${Uri.encodeComponent(guestQr)}&user_id=${Uri.encodeComponent(widget.idServer)}


${selectedTemplate['closing']}
''';

    // Membangun URI
    final uri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: phoneNumber,
      query: 'text=${Uri.encodeComponent(message)}',
    );

    launchUrl(uri);
  }

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Choose Template'),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: templates.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(templates[index]['key']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(templates[index]['greeting']),
                        SizedBox(
                            height: 4.0), // Spasi antara greeting dan opening
                        Text(templates[index]['opening']),
                        SizedBox(height: 4.0), // Spasi antara opening dan link
                        Text(templates[index]['link']),
                        SizedBox(height: 4.0), // Spasi antara link dan closing
                        Text(templates[index]['closing']),
                      ],
                    ),
                    onTap: () {
                      _sendMessageUsingTemplate(index);
                    },
                    onLongPress: () {
                      _copyTemplateToClipboard(index);
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _copyTemplateToClipboard(int index) async {
    final selectedTemplate = templates[index];

    // Membangun pesan untuk disalin ke clipboard
    final message = '''
${selectedTemplate['greeting']}

${selectedTemplate['opening']}

${selectedTemplate['link']}

${selectedTemplate['closing']}
''';

    // Menyalin ke clipboard
    await Clipboard.setData(ClipboardData(text: message));

    // Menampilkan snackbar untuk memberi tahu pengguna
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Template copied to clipboard!')),
    );
  }
}
