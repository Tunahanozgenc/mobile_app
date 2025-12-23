import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_colors.dart';

class CampusFeedCard extends StatelessWidget {
  final DocumentSnapshot doc;

  const CampusFeedCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final String tur = data['tur'] ?? 'Genel';
    final String durum = data['durum'] ?? 'Açık';
    final Color color = _getCategoryColor(tur);
    final IconData icon = _getCategoryIcon(tur);

    return Container(
      margin: EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: Offset(0, 8))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, '/bildirim-detay', arguments: doc),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(15)),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tur.toUpperCase(),
                                style: TextStyle(
                                    color: color,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                    letterSpacing: 0.5)),
                            Text(data['baslik'] ?? 'Başlık Yok',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2D3142))),
                          ],
                        ),
                      ),
                      _buildStatusBadge(durum),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    data['aciklama'] ?? '',
                    style: TextStyle(
                        color: Colors.grey[600], fontSize: 14, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 15),
                  Row(
                    children: [
                      Icon(Icons.access_time_filled_rounded,
                          size: 14, color: Colors.grey[400]),
                      SizedBox(width: 5),
                      Text(
                        _formatDate(data['createdAt']),
                        style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                      Spacer(),
                      Text("Detayları Gör",
                          style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12)),
                      Icon(Icons.chevron_right_rounded,
                          color: AppColors.primary, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String durum) {
    Color bColor;
    switch (durum) {
      case 'Açık': bColor = Colors.red; break;
      case 'İnceleniyor': bColor = Colors.orange; break;
      case 'Çözüldü': bColor = Colors.green; break;
      default: bColor = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10)),
      child: Text(durum.toUpperCase(),
          style: TextStyle(
              color: bColor, fontWeight: FontWeight.bold, fontSize: 10)),
    );
  }

  Color _getCategoryColor(String tur) {
    switch (tur) {
      case 'Sağlık': return Color(0xFFFF5A5F);
      case 'Güvenlik': return Color(0xFF415EB6);
      case 'Teknik': return Color(0xFFFFB400);
      case 'Çevre': return Color(0xFF00A699);
      case 'Kayıp-Buluntu': return Color(0xFF8E44AD);
      default: return Colors.blueGrey;
    }
  }

  IconData _getCategoryIcon(String tur) {
    switch (tur) {
      case 'Sağlık': return Icons.local_hospital_rounded;
      case 'Güvenlik': return Icons.admin_panel_settings_rounded;
      case 'Teknik': return Icons.settings_suggest_rounded;
      case 'Çevre': return Icons.eco_rounded;
      case 'Kayıp-Buluntu': return Icons.person_search_rounded;
      default: return Icons.info_rounded;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Şimdi";
    DateTime date = (timestamp as Timestamp).toDate();
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}