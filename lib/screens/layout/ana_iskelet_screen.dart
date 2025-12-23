import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// --- EKRANLAR ---
import '../home/anasayfa_screen.dart';
import '../map/harita_screen.dart';
import '../profile/profil_screen.dart';
import '../post/gonderi_ekle_screen.dart';

class AnaIskeletScreen extends StatefulWidget {
  @override
  _AnaIskeletScreenState createState() => _AnaIskeletScreenState();
}

class _AnaIskeletScreenState extends State<AnaIskeletScreen> {
  int _seciliIndex = 0;

  final List<Widget> _sayfalar = [
    AnasayfaScreen(),
    HaritaScreen(),
    GonderiEkleScreen(),
    ProfilScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _seciliIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _sayfalar[_seciliIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, -2)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _seciliIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: false,
          items: [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Ana Sayfa'),
            BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: 'Harita'),
            BottomNavigationBarItem(icon: Icon(Icons.add_box_outlined, size: 28), activeIcon: Icon(Icons.add_box, size: 28), label: 'Ekle'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}