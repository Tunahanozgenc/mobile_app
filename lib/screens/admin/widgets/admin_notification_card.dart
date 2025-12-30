import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminNotificationCard extends StatelessWidget {//bildirim için
  final DocumentSnapshot doc;
  const AdminNotificationCard({required this.doc});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final String tur = data['tur'] ?? 'Genel';
    final String durum = data['durum'] ?? 'Açık';
    final String userName = data['userName'] ?? 'Anonim Kullanıcı';
    final Color color = _getCategoryColor(tur);
    final IconData icon = _getCategoryIcon(tur);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 15, offset: Offset(0, 8))],
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        tilePadding: const EdgeInsets.all(16),
        childrenPadding: EdgeInsets.zero,
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
          child: Icon(icon, color: color, size: 28),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tur.toUpperCase(),
                  style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                ),
                _buildStatusBadge(durum),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              data['baslik'] ?? 'Başlık Yok',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2D3142)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Icon(Icons.person_outline_rounded, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  userName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatDate(data['createdAt']),//tarih verisi için
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 10),
                Text(
                  "TAM AÇIKLAMA",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey[500], letterSpacing: 1),
                ),
                const SizedBox(height: 6),
                Text(
                  data['aciklama'] ?? 'Açıklama girilmemiş.',
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 20),

                Text(
                  "DURUMU GÜNCELLE",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.grey[500], letterSpacing: 1),
                ),
                const SizedBox(height: 10),
                Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      segments: [//durum güncellemesi için
                        ButtonSegment(value: "Açık", label: const Text("Açık"), icon: const Icon(Icons.radio_button_unchecked, size: 16)),
                        ButtonSegment(value: "İnceleniyor", label: const Text("İnceleme"), icon: const Icon(Icons.hourglass_empty, size: 16)),
                        ButtonSegment(value: "Çözüldü", label: const Text("Çözüldü"), icon: const Icon(Icons.check_circle_outline, size: 16)),
                      ],
                      selected: {durum},
                      onSelectionChanged: (val) => _updateStatus(context, val.first),
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: _getStatusColor(durum),
                        selectedForegroundColor: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),//boşluk ayarlamak için
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _showEditDialog(context),
                        icon: const Icon(Icons.edit_note_rounded),
                        label: const Text("Düzenle"),
                        style: TextButton.styleFrom(foregroundColor: Colors.blue, backgroundColor: Colors.blue.withOpacity(0.05), padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: const Icon(Icons.delete_sweep_rounded),
                        label: const Text("Sil"),
                        style: TextButton.styleFrom(foregroundColor: Colors.red, backgroundColor: Colors.red.withOpacity(0.05), padding: const EdgeInsets.symmetric(vertical: 12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12)),
                      child: IconButton(
                        onPressed: () => Navigator.pushNamed(context, '/bildirim-detay', arguments: doc),
                        icon: const Icon(Icons.map_rounded, color: Colors.black87),
                        tooltip: "Haritada Gör",
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateStatus(BuildContext context, String yeniDurum) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.update(doc.reference, {'durum': yeniDurum});
    batch.set(FirebaseFirestore.instance.collection('bildirim_loglari').doc(), {
      'bildirimId': doc.id,
      'baslik': doc['baslik'],
      'eskiDurum': doc['durum'],
      'yeniDurum': yeniDurum,
      'tarih': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Bildirimi Sil"),
        content: const Text("Bu işlem geri alınamaz. Emin misiniz?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İPTAL")),
          ElevatedButton(
              onPressed: () {
                doc.reference.delete();
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("SİL")),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final baslikCtrl = TextEditingController(text: data['baslik']);
    final aciklamaCtrl = TextEditingController(text: data['aciklama']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("İçeriği Düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: baslikCtrl, decoration: const InputDecoration(labelText: "Başlık")),
            TextField(controller: aciklamaCtrl, decoration: const InputDecoration(labelText: "Açıklama"), maxLines: 3),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("VAZGEÇ")),
          ElevatedButton(
              onPressed: () async {
                await doc.reference.update({'baslik': baslikCtrl.text, 'aciklama': aciklamaCtrl.text});
                Navigator.pop(ctx);
              },
              child: const Text("KAYDET")),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String durum) {
    Color bColor = _getStatusColor(durum);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: bColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Text(durum.toUpperCase(), style: TextStyle(color: bColor, fontWeight: FontWeight.bold, fontSize: 9)),
    );
  }

  Color _getCategoryColor(String tur) {
    switch (tur) {
      case 'Sağlık':
        return const Color(0xFFFF5A5F);
      case 'Güvenlik':
        return const Color(0xFF415EB6);
      case 'Teknik':
        return const Color(0xFFFFB400);
      case 'Çevre':
        return const Color(0xFF00A699);
      default:
        return Colors.blueGrey;
    }
  }

  IconData _getCategoryIcon(String tur) {
    switch (tur) {
      case 'Sağlık':
        return Icons.local_hospital_rounded;
      case 'Güvenlik':
        return Icons.admin_panel_settings_rounded;
      case 'Teknik':
        return Icons.settings_suggest_rounded;
      case 'Çevre':
        return Icons.eco_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Color _getStatusColor(String durum) {
    switch (durum) {
      case 'Açık':
        return Colors.red;
      case 'İnceleniyor':
        return Colors.orange;
      case 'Çözüldü':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Şimdi";
    DateTime date = (timestamp as Timestamp).toDate();
    return "${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}";
  }
}
