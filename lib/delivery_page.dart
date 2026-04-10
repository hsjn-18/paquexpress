// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class DeliveryPage extends StatefulWidget {
  final Map<String, dynamic> package;
  const DeliveryPage({super.key, required this.package});

  @override
  _DeliveryPageState createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  File? _photo;
  Position? _position;
  bool _loading = false;
  bool _loadingLocation = false;

  Future<void> _takePhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (picked != null) setState(() => _photo = File(picked.path));
  }

  Future<void> _getLocation() async {
    setState(() => _loadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Activa el GPS en tu dispositivo'), backgroundColor: Colors.red),
        );
        setState(() => _loadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Permiso de ubicación denegado'), backgroundColor: Colors.red),
          );
          setState(() => _loadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Permiso de ubicación denegado permanentemente'), backgroundColor: Colors.red),
        );
        setState(() => _loadingLocation = false);
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      ).timeout(Duration(seconds: 15), onTimeout: () {
        throw Exception('Tiempo de espera agotado');
      });

      setState(() {
        _position = position;
        _loadingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ubicación obtenida'), backgroundColor: Colors.green),
      );
    } catch (e) {
      setState(() => _loadingLocation = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo obtener la ubicación: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _registerDelivery() async {
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Toma una foto primero'), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Obtén la ubicación primero'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://10.0.2.2:8000/api/deliveries'),
      );
      request.fields['package_id'] = widget.package['id'].toString();
      request.fields['latitude'] = _position!.latitude.toString();
      request.fields['longitude'] = _position!.longitude.toString();
      request.fields['token'] = token;
      request.files.add(await http.MultipartFile.fromPath('file', _photo!.path));

      final response = await request.send();
      setState(() => _loading = false);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Entrega registrada correctamente!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar entrega'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de conexión: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Entrega', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1565C0),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info paquete
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: Color(0xFFE3F2FD),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.inventory, color: Color(0xFF1565C0)),
                        SizedBox(width: 8),
                        Text('${widget.package['unique_id']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1565C0))),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text('Destinatario: ${widget.package['recipient_name']}', style: TextStyle(fontSize: 15)),
                    SizedBox(height: 4),
                    Text('Dirección: ${widget.package['destination_address']}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Foto
            Text('Evidencia fotográfica', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            _photo != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(_photo!, height: 200, width: double.infinity, fit: BoxFit.cover),
                  )
                : Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                        Text('Sin foto', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: Icon(Icons.camera_alt),
                label: Text('Tomar Foto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(height: 20),

            // GPS
            Text('Ubicación GPS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            _position != null
                ? Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lat: ${_position!.latitude.toStringAsFixed(6)}\nLng: ${_position!.longitude.toStringAsFixed(6)}',
                            style: TextStyle(color: Colors.green[800]),
                          ),
                        ),
                        Icon(Icons.check_circle, color: Colors.green),
                      ],
                    ),
                  )
                : Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.location_off, color: Colors.grey),
                        SizedBox(width: 8),
                        Text('Ubicación no obtenida', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
            SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadingLocation ? null : _getLocation,
                icon: _loadingLocation
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Icon(Icons.my_location),
                label: Text(_loadingLocation ? 'Obteniendo...' : 'Obtener Ubicación GPS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF42A5F5),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(height: 24),

            // Botón entregar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _registerDelivery,
                icon: _loading
                    ? SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                    : Icon(Icons.check_circle),
                label: Text('Paquete Entregado', style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}