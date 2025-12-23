import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';

class BildirimlerScreen extends StatelessWidget {
  final User? currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return Scaffold(body: Center(child: Text("Lütfen giriş yapın.")));

    return Scaffold(
      backgroundColor: Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text("Bildirim Geçmişi", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // 1. Kullanıcının takip listesini al
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return Center(child: CircularProgressIndicator());

          List<dynamic> takipListesi = userSnapshot.data!['takipEdilenler'] ?? [];

          return StreamBuilder<QuerySnapshot>(
            // 2. Bildirim loglarını tarih sırasına göre al
            stream: FirebaseFirestore.instance
                .collection('bildirim_loglari')
                .orderBy('tarih', descending: true)
                .snapshots(),
            builder: (context, logSnapshot) {
              if (logSnapshot.connectionState == ConnectionState.waiting) return Center(child: CircularProgressIndicator());

              if (!logSnapshot.hasData || logSnapshot.data!.docs.isEmpty) {
                return _buildEmptyState();
              }

              // 3. Sadece kullanıcının takip ettiği bildirimlere ait olan logları filtrele
              var logs = logSnapshot.data!.docs.where((log) {
                var logData = log.data() as Map<String, dynamic>;
                return takipListesi.contains(logData['bildirimId']);
              }).toList();

              if (logs.isEmpty) return _buildEmptyState();

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  var logData = logs[index].data() as Map<String, dynamic>;
                  return _buildLogCard(context, logData);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, Map<String, dynamic> log) {
    String durum = log['yeniDurum'] ?? 'Bilinmiyor';
    Color statusColor = durum == 'Çözüldü' ? Colors.green : Colors.orange;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(
            durum == 'Çözüldü' ? Icons.check_circle_rounded : Icons.pending_rounded,
            color: statusColor,
          ),
        ),
        title: Text(
          log['baslik'] ?? 'Bildirim Güncellemesi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text("Durum '${log['eskiDurum']}' -> '$durum' olarak güncellendi."),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: Colors.grey),
                SizedBox(width: 4),
                Text(_formatDate(log['tarih']), style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 70, color: Colors.grey[300]),
          SizedBox(height: 16),
          Text("Henüz bir güncelleme yok", style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600)),
          Text("Takip ettiğin olaylar değişince burada göreceksin", style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Şimdi";
    DateTime date = (timestamp as Timestamp).toDate();
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}