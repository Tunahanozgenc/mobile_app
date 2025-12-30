import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class EmergencyDialog extends StatefulWidget {//acil durum sayfası (bildirim)
  @override
  _EmergencyDialogState createState() => _EmergencyDialogState();
}

class _EmergencyDialogState extends State<EmergencyDialog> {
  final baslikCtrl = TextEditingController(); //başlık verisini tutar
  final aciklamaCtrl = TextEditingController();// aciklama verisini tutar
  GeoPoint? konum;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(//acil durum sayfası (bildirim)
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text("Acil Duyuru Yayınla"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: baslikCtrl,
              decoration: InputDecoration(labelText: "Başlık"),//başlık ekleme
            ),
            SizedBox(height: 12),
            TextField(
              controller: aciklamaCtrl,
              maxLines: 3,
              decoration: InputDecoration(labelText: "Açıklama"),//açıklama ekleme
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _getCurrentLocation,//anlık konum alma işlemi burada
                    child: Text("Buradayım"),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickOnMap, //haritadan konum seçme işlemi burada
                    child: Text("Haritadan Seç"),
                  ),
                ),
              ],
            ),
            if (konum != null)
              Text("Konum Hazır", style: TextStyle(color: Colors.green)),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("İptal"),//iptal butonu
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text("Yayınla", style: TextStyle(color: Colors.white)),//yayınla butonu
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {//anlık konum alma işlemi burada
    Position pos = await Geolocator.getCurrentPosition();
    setState(() => konum = GeoPoint(pos.latitude, pos.longitude));
  }

  Future<void> _pickOnMap() async {//haritadan konum seçme işlemi burada
    //işlev yok şu an
  }

  void _submit() async {
    if (baslikCtrl.text.isEmpty) return;
    await FirebaseFirestore.instance.collection('acil_duyurular').add({
      'baslik': baslikCtrl.text,
      'aciklama': aciklamaCtrl.text,
      'konum': konum,
      'tarih': FieldValue.serverTimestamp(),
    });
    Navigator.pop(context);
  }
}
