import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EmergencySlider extends StatelessWidget {//acil duyuru kısmı (slider)
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('acil_duyurular')
          .orderBy('tarih', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty)//veri yoksa boş ise
          return SizedBox.shrink();

        var docs = snapshot.data!.docs; //veri değerleri tutma
        return Container(
          height: 160,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              return _buildEmergencyCard(context, docs[index], index);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmergencyCard(BuildContext context, DocumentSnapshot doc, int index) {//card yapısında veriyi gösterme
    var data = doc.data() as Map<String, dynamic>;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/bildirim-detay', arguments: doc),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 15),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: index == 0
                ? [Color(0xFFFF416C), Color(0xFFFF4B2B)]
                : [Color(0xFFF2994A), Color(0xFFF2C94C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
                color: (index == 0 ? Color(0xFFFF416C) : Color(0xFFF2994A))
                    .withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 8))
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(Icons.campaign_rounded, color: Colors.white, size: 30),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("ACİL DURUM ${index + 1}",
                      style: TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1)),
                  Text(data['baslik'] ?? '',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                      maxLines: 1),
                  Text(data['aciklama'] ?? data['mesaj'] ?? '',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85), fontSize: 13),
                      maxLines: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}