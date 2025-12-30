import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:mobile_app/screens/auth/giris_screen.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import 'widgets/admin_notification_card.dart';
import 'widgets/emergency_dialog.dart';
import '../post/gonderi_ekle_screen.dart';

class AdminScreen extends StatefulWidget {//admin sayfası
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,//Ekranı kaydırdığında klavyeyi otomatik kapatır. (özel işlem eklendi)
        slivers: [
          //APPBAR
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Text(
              "Yönetim Merkezi",
              style: TextStyle(
                color: Color(0xFF1A1A1A),
                fontWeight: FontWeight.w900,
                fontSize: 22,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                onPressed: () async {
                  await _authService.signOut();

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => GirisScreen()),
                        (route) => false,
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(72),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Bildirimlerde ara...",
                    prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
          ),

          //BİLDİRİM LİSTESİ
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bildirimler')
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("Yönetilecek kayıt yok.")),
                );
              }

              final docs = snapshot.data!.docs.where((doc) {
                final baslik = (doc['baslik'] ?? '').toString().toLowerCase();
                return baslik.contains(_searchController.text.toLowerCase());
              }).toList();

              if (docs.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text("Sonuç bulunamadı.")),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, i) => AdminNotificationCard(doc: docs[i]),
                    childCount: docs.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // FAB
      floatingActionButton: SpeedDial(//admin panelinde bildirim acil durum eklemek için sağ alt köşede bulunan buton
        icon: Icons.add_rounded,
        backgroundColor: AppColors.primary,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.campaign_rounded, color: Colors.white),
            backgroundColor: Colors.redAccent,
            label: 'Acil Duyuru',
            onTap: () => showDialog(
              context: context,
              builder: (_) => EmergencyDialog(),
            ),
          ),
          SpeedDialChild(
            child: const Icon(Icons.add_task_rounded, color: Colors.white),
            backgroundColor: Colors.green,
            label: 'Yeni Bildirim',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GonderiEkleScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
