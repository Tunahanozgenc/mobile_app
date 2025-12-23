import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/services/auth_service.dart'; // Auth servisini import et
import '../../core/constants/app_colors.dart'; // Renkler (Varsa)

class BildirimDetayScreen extends StatefulWidget {
  @override
  _BildirimDetayScreenState createState() => _BildirimDetayScreenState();
}

class _BildirimDetayScreenState extends State<BildirimDetayScreen> {
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _currentUserRole; // 'admin' veya 'user'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _roluGetir();
  }

  // Kullanıcının rolünü öğrenelim (Admin ise butonları göster)
  void _roluGetir() async {
    User? user = _auth.currentUser;
    if (user != null) {
      String role = await _authService.getUserRole(user);
      if (mounted) {
        setState(() {
          _currentUserRole = role;
          _isLoading = false;
        });
      }
    }
  }

  // --- DURUM GÜNCELLEME (SADECE ADMIN) ---
  void _durumuGuncelle(String docId, String yeniDurum) async {
    await FirebaseFirestore.instance.collection('bildirimler').doc(docId).update({
      'durum': yeniDurum,
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Durum güncellendi: $yeniDurum")));
    setState(() {}); // Ekranı yenile
  }

  // --- TAKİP ET / BIRAK (SADECE USER) ---
  void _takipIslemi(String bildirimId, bool zatenTakipEdiyor) async {
    User? user = _auth.currentUser;
    if (user == null) return;

    DocumentReference userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);

    if (zatenTakipEdiyor) {
      // Takipten çık
      await userRef.update({
        'takipEdilenler': FieldValue.arrayRemove([bildirimId])
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Takip bırakıldı.")));
    } else {
      // Takip et
      await userRef.update({
        'takipEdilenler': FieldValue.arrayUnion([bildirimId])
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Bildirim takibe alındı!")));
    }
  }

  // Renk Yardımcısı
  Color _getDurumColor(String durum) {
    switch (durum) {
      case 'Açık': return Colors.red;
      case 'İnceleniyor': return Colors.orange;
      case 'Çözüldü': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Önceki sayfadan gönderilen veriyi alıyoruz
    final DocumentSnapshot? bildirim = ModalRoute.of(context)?.settings.arguments as DocumentSnapshot?;

    // Eğer veri gelmediyse hata göster
    if (bildirim == null) {
      return Scaffold(
        appBar: AppBar(title: Text("Hata")),
        body: Center(child: Text("Bildirim verisi bulunamadı.")),
      );
    }

    final Map<String, dynamic> data = bildirim.data() as Map<String, dynamic>;

    // Konum verisi var mı?
    GeoPoint? geoPoint = data['konum'];
    CameraPosition? _kameraKonumu;

    if (geoPoint != null) {
      _kameraKonumu = CameraPosition(
        target: LatLng(geoPoint.latitude, geoPoint.longitude),
        zoom: 15,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Bildirim Detayı"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- MİNİ HARİTA (Varsa Göster) ---
            if (_kameraKonumu != null)
              Container(
                height: 250,
                width: double.infinity,
                child: GoogleMap(
                  initialCameraPosition: _kameraKonumu,
                  mapType: MapType.normal,
                  zoomControlsEnabled: false,
                  liteModeEnabled: true, // Statik resim gibi davranır, hızlıdır
                  markers: {
                    Marker(
                      markerId: MarkerId('konum'),
                      position: _kameraKonumu.target,
                    )
                  },
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off, size: 40, color: Colors.grey),
                      Text("Konum Bilgisi Yok"),
                    ],
                  ),
                ),
              ),

            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ÜST BİLGİLER (Tür ve Durum) ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(data['tur'] ?? 'Genel'),
                        backgroundColor: Colors.blue.shade50,
                        labelStyle: TextStyle(color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getDurumColor(data['durum'] ?? 'Açık').withOpacity(0.1),
                          border: Border.all(color: _getDurumColor(data['durum'] ?? 'Açık')),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          (data['durum'] ?? 'Açık').toString().toUpperCase(),
                          style: TextStyle(
                            color: _getDurumColor(data['durum'] ?? 'Açık'),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // --- BAŞLIK VE TARİH ---
                  Text(data['baslik'] ?? 'Başlık Yok', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text("Oluşturulma: ${(data['createdAt'] as Timestamp?)?.toDate().toString().substring(0, 16) ?? '-'}", style: TextStyle(color: Colors.grey)),
                  SizedBox(height: 16),

                  // --- AÇIKLAMA METNİ ---
                  Text("Açıklama:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 4),
                  Text(data['aciklama'] ?? 'Açıklama girilmemiş.', style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                  SizedBox(height: 30),

                  Divider(),

                  // --- ADMIN İŞLEMLERİ (DURUM DEĞİŞTİRME) ---
                  if (_currentUserRole == 'admin') ...[
                    Text("Yönetici Paneli", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: data['durum'] ?? 'Açık',
                          isExpanded: true,
                          items: ['Açık', 'İnceleniyor', 'Çözüldü'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              _durumuGuncelle(bildirim.id, newValue);
                            }
                          },
                        ),
                      ),
                    ),
                  ],

                  // --- USER İŞLEMLERİ (TAKİP ET) ---
                  if (_currentUserRole == 'user') ...[
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance.collection('users').doc(_auth.currentUser!.uid).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return SizedBox();

                        var userData = snapshot.data!.data() as Map<String, dynamic>?;
                        List takipEdilenler = userData?['takipEdilenler'] ?? [];
                        bool isFollowing = takipEdilenler.contains(bildirim.id);

                        return SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => _takipIslemi(bildirim.id, isFollowing),
                            icon: Icon(isFollowing ? Icons.check : Icons.add_alert),
                            label: Text(isFollowing ? "Takibi Bırak" : "Bildirimi Takip Et"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing ? Colors.grey : (AppColors.primary),
                            ),
                          ),
                        );
                      },
                    ),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}