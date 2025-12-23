import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class HaritaScreen extends StatefulWidget {
  @override
  _HaritaScreenState createState() => _HaritaScreenState();
}

class _HaritaScreenState extends State<HaritaScreen> {
  // Harita Kontrolcüsü
  final Completer<GoogleMapController> _controller = Completer();

  // Seçili bildirim (Kartta göstermek için)
  DocumentSnapshot? _seciliBildirim;

  // Harita üzerindeki işaretçiler (Pinler)
  Set<Marker> _markers = {};

  // Başlangıç Konumu (Atatürk Üniversitesi)
  static const CameraPosition _baslangicKonumu = CameraPosition(
    target: LatLng(39.8996, 41.2825),
    zoom: 14.5,
  );

  @override
  void initState() {
    super.initState();
    _konumIzniniAlVeGit();
  }

  // --- 1. KONUM İZİNLERİ ---
  Future<void> _konumIzniniAlVeGit() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      Position position = await Geolocator.getCurrentPosition();
      // Harita hazır olduğunda kamerayı oraya taşı (Hata almamak için try-catch eklenebilir veya controller kontrolü)
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(LatLng(position.latitude, position.longitude), 15));
    }
  }

  // --- 2. PİN RENGİNİ BELİRLEME ---
  double _getPinColor(String tur) {
    switch (tur.toLowerCase()) {
      case 'sağlık': return BitmapDescriptor.hueRed;
      case 'güvenlik': return BitmapDescriptor.hueOrange;
      case 'teknik': return BitmapDescriptor.hueBlue;
      case 'çevre': return BitmapDescriptor.hueGreen;
      default: return BitmapDescriptor.hueViolet;
    }
  }

  // --- 3. HARİTAYI OLUŞTURMA ---
  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
  }

  // --- ZAMAN HESAPLAYICI ---
  String _zamanGecenSure(Timestamp? timestamp) {
    if (timestamp == null) return "Bilinmiyor";
    DateTime olusturmaZamani = timestamp.toDate();
    Duration fark = DateTime.now().difference(olusturmaZamani);

    if (fark.inMinutes < 60) return "${fark.inMinutes} dk önce";
    if (fark.inHours < 24) return "${fark.inHours} sa önce";
    return "${fark.inDays} gün önce";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // --- KATMAN 1: HARİTA ---
          StreamBuilder<QuerySnapshot>(
            // Koleksiyon isminin veritabanınla aynı olduğundan emin ol ('bildirimler' veya 'reports')
            stream: FirebaseFirestore.instance.collection('bildirimler').snapshots(),
            builder: (context, snapshot) {

              if (snapshot.hasData) {
                _markers.clear();

                for (var doc in snapshot.data!.docs) {
                  var data = doc.data() as Map<String, dynamic>;

                  if (data['konum'] == null) continue;

                  GeoPoint nokta = data['konum'];

                  _markers.add(
                    Marker(
                      markerId: MarkerId(doc.id),
                      position: LatLng(nokta.latitude, nokta.longitude),
                      icon: BitmapDescriptor.defaultMarkerWithHue(_getPinColor(data['tur'] ?? '')),
                      onTap: () {
                        setState(() {
                          _seciliBildirim = doc;
                        });
                      },
                    ),
                  );
                }
              }

              return GoogleMap(
                initialCameraPosition: _baslangicKonumu,
                mapType: MapType.normal,
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                onMapCreated: _onMapCreated,
                onTap: (LatLng yeri) {
                  setState(() {
                    _seciliBildirim = null;
                  });
                },
              );
            },
          ),

          // --- KATMAN 2: KONUM BUTONU ---
          Positioned(
            top: 50,
            right: 15,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              child: Icon(Icons.my_location, color: Colors.blue),
              onPressed: _konumIzniniAlVeGit,
            ),
          ),

          // --- KATMAN 3: BİLGİ KARTI (ALT PANEL) ---
          if (_seciliBildirim != null)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: EdgeInsets.all(20),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, spreadRadius: 2)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Üst Satır
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            (_seciliBildirim!['tur'] ?? 'Genel').toString().toUpperCase(),
                            style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        Text(
                          _zamanGecenSure(_seciliBildirim!['createdAt']),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    // Başlık
                    Text(
                      _seciliBildirim!['baslik'] ?? 'Başlıksız Bildirim',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Detayları görmek için butona tıklayın.",
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                    ),
                    SizedBox(height: 15),

                    // --- İŞTE TAMİR EDİLEN BUTON BURASI 👇 ---
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Artık 'print' yerine 'Navigator' kullanıyoruz
                          Navigator.pushNamed(
                              context,
                              '/bildirim-detay',
                              arguments: _seciliBildirim // Seçili dökümanı detay sayfasına paketleyip gönderiyoruz
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text("Detayı Gör", style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}