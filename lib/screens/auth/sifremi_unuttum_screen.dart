import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/stumedia_text_field.dart';
import '../../core/services/auth_service.dart';

class SifremiUnuttumScreen extends StatefulWidget {
  @override
  _SifremiUnuttumScreenState createState() => _SifremiUnuttumScreenState();
}

class _SifremiUnuttumScreenState extends State<SifremiUnuttumScreen> {
  final TextEditingController _emailController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  void _gonder() async {
    FocusScope.of(context).unfocus();

    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lütfen e-posta adresinizi girin."), backgroundColor: AppColors.error));
      return;
    }

    setState(() => _isLoading = true);

    // Servis İsteği
    String? hata = await _authService.resetPassword(_emailController.text.trim());

    setState(() => _isLoading = false);

    if (hata == null) {
      // Başarılı -> POPUP AÇ
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 10))]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.mark_email_read, size: 48, color: AppColors.primary)),
                SizedBox(height: 20),
                Text("E-posta Yolda! 🚀", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
                SizedBox(height: 12),
                Text("Sıfırlama bağlantısını e-posta adresine gönderdik. Lütfen gelen kutunu (ve spam klasörünü) kontrol et.", style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5), textAlign: TextAlign.center),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () { Navigator.of(ctx).pop(); Navigator.of(context).pop(); },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: Text("Anlaşıldı", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Hata Mesajı
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(hata), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text("Şifre Sıfırlama"), centerTitle: true, backgroundColor: Colors.white, elevation: 0, leading: IconButton(icon: Icon(Icons.arrow_back, color: Colors.black), onPressed: () => Navigator.pop(context))),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.lock_reset, size: 100, color: AppColors.primary),
                SizedBox(height: 30),
                Text("Endişelenme, hallederiz.", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary), textAlign: TextAlign.center),
                SizedBox(height: 10),
                Text("Hesabına bağlı e-posta adresini gir, sana sıfırlama bağlantısını gönderelim.", textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                SizedBox(height: 40),
                mobileTextField(controller: _emailController, hintText: 'E-posta Adresin', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                SizedBox(height: 20),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _gonder,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8),
                    child: _isLoading ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text("Bağlantı Gönder", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}