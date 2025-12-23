import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_app/screens/home/widgets/emergency_slider.dart+.dart';
import 'package:mobile_app/screens/notifications/bildirimler_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/campus_feed_card.dart'; // Yeni Widget


class AnasayfaScreen extends StatefulWidget {
  @override
  _AnasayfaScreenState createState() => _AnasayfaScreenState();
}

class _AnasayfaScreenState extends State<AnasayfaScreen> {
  String _aramaMetni = "";
  String _secilenKategori = "Tümü";
  bool _sadeceAciklar = false;

  final List<String> _kategoriler = [
    "Tümü", "Sağlık", "Güvenlik", "Teknik", "Çevre", "Kayıp-Buluntu"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FD),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // 1. APPBAR
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            surfaceTintColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              titlePadding: EdgeInsetsDirectional.only(start: 20, bottom: 16),
              title: Text(
                "Kampüs Akışı",
                style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    letterSpacing: -0.5),
              ),
            ),
            actions: [
              Container(
                margin: EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                    color: Colors.grey[100], shape: BoxShape.circle),
                child: IconButton(
                  icon: Icon(Icons.notifications_active_outlined,
                      color: Colors.black87),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => BildirimlerScreen()),
                    );
                  },
                ),
              ),
            ],
          ),

          // 2. ACİL DURUM
          SliverToBoxAdapter(child: EmergencySlider()),

          // 3. FİLTRELER
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(30)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                      offset: Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  _buildSearchBar(),
                  _buildCategoryFilter(),
                  _buildStatusSwitch(),
                  SizedBox(height: 15),
                ],
              ),
            ),
          ),

          // 4. LİSTE
          _buildBildirimListesi(),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: TextField(
        onChanged: (v) => setState(() => _aramaMetni = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: "Kampüste neler oluyor?",
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
          filled: true,
          fillColor: Color(0xFFF5F7FA),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none),
          contentPadding: EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 15),
        scrollDirection: Axis.horizontal,
        itemCount: _kategoriler.length,
        itemBuilder: (context, i) {
          final kat = _kategoriler[i];
          final isSelected = _secilenKategori == kat;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 5, vertical: 10),
            child: ChoiceChip(
              label: Text(kat),
              selected: isSelected,
              onSelected: (_) => setState(() => _secilenKategori = kat),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              backgroundColor: Colors.white,
              elevation: isSelected ? 4 : 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              side: BorderSide(
                  color: isSelected ? AppColors.primary : Colors.grey[200]!),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusSwitch() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text("Sadece Aktif Olaylar",
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600])),
          Spacer(),
          Transform.scale(
            scale: 0.8,
            child: Switch(
              value: _sadeceAciklar,
              onChanged: (v) => setState(() => _sadeceAciklar = v),
              activeColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBildirimListesi() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bildirimler')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()));

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
          return SliverFillRemaining(
              child: _bosDurum("Huzurlu bir kampüs, bildirim yok."));

        var filtered = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          bool matchCat =
              _secilenKategori == "Tümü" || data['tur'] == _secilenKategori;
          bool matchSearch =
          data['baslik'].toString().toLowerCase().contains(_aramaMetni);
          bool matchStatus = !_sadeceAciklar || data['durum'] == 'Açık';
          return matchCat && matchSearch && matchStatus;
        }).toList();

        if (filtered.isEmpty)
          return SliverFillRemaining(child: _bosDurum("Sonuç bulunamadı."));

        return SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, i) => CampusFeedCard(doc: filtered[i]), // YENİ WIDGET KULLANIMI
              childCount: filtered.length,
            ),
          ),
        );
      },
    );
  }

  Widget _bosDurum(String mesaj) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 80, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text(mesaj, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
        ],
      ),
    );
  }
}