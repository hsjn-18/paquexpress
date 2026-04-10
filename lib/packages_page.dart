// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'delivery_page.dart';

class PackagesPage extends StatefulWidget {
  const PackagesPage({super.key});

  @override
  _PackagesPageState createState() => _PackagesPageState();
}

class _PackagesPageState extends State<PackagesPage> {
  List<dynamic> _packages = [];
  bool _loading = true;
  String _agentName = '';

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    _agentName = prefs.getString('agent_name') ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/packages?token=$token'),
      );
      if (response.statusCode == 200) {
        setState(() {
          _packages = jsonDecode(response.body);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    await http.post(Uri.parse('http://10.0.2.2:8000/api/logout?token=$token'));
    await prefs.clear();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Entregas', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1565C0),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            color: Color(0xFFE3F2FD),
            child: Text(
              'Bienvenido, $_agentName',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator())
                : _packages.isEmpty
                ? Center(child: Text('No hay paquetes pendientes'))
                : RefreshIndicator(
                    onRefresh: _loadPackages,
                    child: ListView.builder(
                      padding: EdgeInsets.all(12),
                      itemCount: _packages.length,
                      itemBuilder: (context, index) {
                        final pkg = _packages[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Color(0xFF1565C0),
                              child: Icon(Icons.inventory, color: Colors.white),
                            ),
                            title: Text(
                              pkg['unique_id'],
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Destinatario: ${pkg['recipient_name']}'),
                                Text(
                                  'Dirección: ${pkg['destination_address']}',
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DeliveryPage(package: pkg),
                                  ),
                                );
                                _loadPackages();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF1565C0),
                              ),
                              child: Text(
                                'Entregar',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
