import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_theme.dart';

class StaffAccountsScreen extends StatefulWidget {
  const StaffAccountsScreen({super.key});
  @override
  State<StaffAccountsScreen> createState() => _StaffAccountsScreenState();
}

class _StaffAccountsScreenState extends State<StaffAccountsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _staff = [];
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient.instance.get('/api/v1/pharmacy/staff');
      final data = Map<String, dynamic>.from(response.data as Map);
      if (mounted) {
        setState(() => _staff = (data['staff'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList());
      }
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _invite() async {
    final name = TextEditingController(), email = TextEditingController();
    String role = 'staff';
    final ok = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
            builder: (context, setLocal) => AlertDialog(
                    title: const Text('Invite staff member'),
                    content: Column(mainAxisSize: MainAxisSize.min, children: [
                      TextField(
                          controller: name,
                          decoration:
                              const InputDecoration(labelText: 'Full name')),
                      TextField(
                          controller: email,
                          keyboardType: TextInputType.emailAddress,
                          decoration:
                              const InputDecoration(labelText: 'Email')),
                      DropdownButtonFormField<String>(
                          initialValue: role,
                          items: const [
                            DropdownMenuItem(
                                value: 'pharmacist', child: Text('Pharmacist')),
                            DropdownMenuItem(
                                value: 'staff', child: Text('Staff'))
                          ],
                          onChanged: (v) => setLocal(() => role = v!),
                          decoration:
                              const InputDecoration(labelText: 'Access role'))
                    ]),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Send invite'))
                    ])));
    if (ok == true) {
      try {
        await ApiClient.instance.post('/api/v1/pharmacy/staff', body: {
          'fullName': name.text.trim(),
          'email': email.text.trim().toLowerCase(),
          'staffRole': role
        });
        await _load();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('$e')));
        }
      }
    }
    name.dispose();
    email.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
            leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go('/pharmacy/more')),
            title: const Text('Staff accounts')),
        floatingActionButton: FloatingActionButton.extended(
            onPressed: _invite,
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Invite staff')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(_error!),
                    TextButton(onPressed: _load, child: const Text('Retry'))
                  ]))
                : _staff.isEmpty
                    ? Center(
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                                'No staff accounts have been added. Invite a pharmacist or staff member when you are ready.',
                                textAlign: TextAlign.center,
                                style: AppTextStyles.body)))
                    : ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _staff.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final member = _staff[index];
                          return Card(
                              child: ListTile(
                                  leading: const CircleAvatar(
                                      child: Icon(Icons.person_outline)),
                                  title: Text(member['fullName'] as String? ??
                                      member['email'] as String? ??
                                      'Staff member'),
                                  subtitle: Text(
                                      '${member['staffRole'] ?? 'staff'} • ${member['email'] ?? ''}')));
                        }),
      );
}
