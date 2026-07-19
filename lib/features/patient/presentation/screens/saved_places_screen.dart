import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../../core/storage/local_db_service.dart';
import '../../../../core/theme/app_theme.dart';

class SavedPlacesScreen extends StatefulWidget {
  const SavedPlacesScreen({super.key});
  @override
  State<SavedPlacesScreen> createState() => _SavedPlacesScreenState();
}

class _SavedPlacesScreenState extends State<SavedPlacesScreen> {
  final _label = TextEditingController();
  final _address = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  List<Map<String, dynamic>> _places = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final raw = await LocalDbService().read('saved_places');
    if (raw != null) {
      _places = (jsonDecode(raw) as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _places
        .add({'label': _label.text.trim(), 'address': _address.text.trim()}));
    await LocalDbService().write('saved_places', jsonEncode(_places));
    _label.clear();
    _address.clear();
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Place saved.')));
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _address.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Saved places')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: ListView(padding: const EdgeInsets.all(20), children: [
                  Text('Your places', style: AppTextStyles.heading),
                  Text(
                      'Save multiple addresses for faster medicine searches and directions.',
                      style: AppTextStyles.body),
                  const SizedBox(height: 18),
                  ..._places.asMap().entries.map((entry) => Card(
                          child: ListTile(
                        leading: const Icon(Icons.place_outlined),
                        title: Text(entry.value['label'] as String),
                        subtitle: Text(entry.value['address'] as String),
                        trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              setState(() => _places.removeAt(entry.key));
                              await LocalDbService()
                                  .write('saved_places', jsonEncode(_places));
                            }),
                      ))),
                  if (_places.isNotEmpty) const SizedBox(height: 18),
                  Text('Add a place', style: AppTextStyles.subheading),
                  const SizedBox(height: 10),
                  TextFormField(
                      controller: _label,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                          labelText: 'Label',
                          hintText: 'Home, Work or Mum’s house'),
                      validator: (v) =>
                          (v?.trim().isEmpty ?? true) ? 'Enter a label' : null),
                  const SizedBox(height: 12),
                  TextFormField(
                      controller: _address,
                      textCapitalization: TextCapitalization.words,
                      maxLines: 2,
                      decoration:
                          const InputDecoration(labelText: 'Full address'),
                      validator: (v) => (v?.trim().length ?? 0) < 5
                          ? 'Enter a complete address'
                          : null),
                  const SizedBox(height: 18),
                  FilledButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.add_location_alt_outlined),
                      label: const Text('Save place')),
                ]),
              ),
      );
}
