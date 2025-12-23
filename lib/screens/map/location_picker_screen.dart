import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationPickerScreen extends StatefulWidget {
  @override
  _LocationPickerScreenState createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  LatLng _pickedLocation = LatLng(39.9035, 41.2658); // Erzurum Merkez

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Konumu İşaretle", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: Colors.green),
            onPressed: () {
              Navigator.pop(context, _pickedLocation);
            },
          )
        ],
      ),
      body: GoogleMap(
        initialCameraPosition:
        CameraPosition(target: _pickedLocation, zoom: 14),
        onTap: (LatLng pos) {
          setState(() {
            _pickedLocation = pos;
          });
        },
        markers: {
          Marker(
            markerId: MarkerId('secilen'),
            position: _pickedLocation,
          ),
        },
      ),
    );
  }
}