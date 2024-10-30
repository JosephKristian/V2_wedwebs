import 'package:flutter/material.dart';
import '../../services/database_helper.dart';

class TemplatesScreen extends StatefulWidget {
  final String clientId;
  final String idServer;

  TemplatesScreen({required this.clientId, required this.idServer});

  @override
  _TemplatesScreenState createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  List<Map<String, dynamic>> templates = [];
  bool isLoading = true;
  List<TextEditingController> greetingControllers = [];
  List<TextEditingController> openingControllers = [];
  List<TextEditingController> linkControllers = [];
  List<TextEditingController> closingControllers = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final dbHelper = DatabaseHelper.instance;
    final data = await dbHelper.getTemplatesByClientId(widget.clientId);
    // Gunakan Map.from untuk membuat salinan modifiable
    setState(() {
      templates =
          data.map((template) => Map<String, dynamic>.from(template)).toList();
    });

    // Inisialisasi TextEditingController untuk masing-masing template
    greetingControllers = templates
        .map((template) => TextEditingController(text: template['greeting']))
        .toList();
    openingControllers = templates
        .map((template) => TextEditingController(text: template['opening']))
        .toList();
    linkControllers = templates
        .map((template) => TextEditingController(text: template['link']))
        .toList();
    closingControllers = templates
        .map((template) => TextEditingController(text: template['closing']))
        .toList();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveTemplate(int index) async {
    final dbHelper = DatabaseHelper.instance;

    // Update nilai template berdasarkan input pengguna
    templates[index]['greeting'] = greetingControllers[index].text;
    templates[index]['opening'] = openingControllers[index].text;
    templates[index]['link'] = linkControllers[index].text;
    templates[index]['closing'] = closingControllers[index].text;

    // Simpan ke database
    await dbHelper.updateTemplateClientKey(widget.clientId, templates[index]);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Template saved!')));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: templates.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Edit Message Templates'),
          bottom: isLoading
              ? null
              : TabBar(
                  isScrollable: true,
                  tabs: templates
                      .map((template) => Tab(text: template['key']))
                      .toList(),
                ),
        ),
        body: isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                children: templates.asMap().entries.map((entry) {
                  int index = entry.key;
                  Map<String, dynamic> template = entry.value;
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: greetingControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Greeting',
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(fontSize: 16.0),
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: openingControllers[index],
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Opening',
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(fontSize: 16.0),
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: linkControllers[index],
                          decoration: InputDecoration(
                            labelText: 'Link',
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(fontSize: 16.0),
                        ),
                        SizedBox(height: 16.0),
                        TextFormField(
                          controller: closingControllers[index],
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Closing',
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(fontSize: 16.0),
                        ),
                        SizedBox(height: 20.0),
                        ElevatedButton(
                          onPressed: () {
                            _saveTemplate(index); // Simpan template
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Changes saved successfully!'),
                              ),
                            );
                          },
                          child: Text('Save Changes'),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 15.0),
                            textStyle: TextStyle(fontSize: 16.0),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
      ),
    );
  }
}
