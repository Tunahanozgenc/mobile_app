import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/stumedia_text_field.dart';
import '../../core/services/auth_service.dart';

class GirisScreen extends StatefulWidget {//Giriş ekranı
  @override
  _GirisScreenState createState() => _GirisScreenState();
}

class _GirisScreenState extends State<GirisScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _girisYap() async {
    FocusScope.of(context).unfocus(); // Klavyeyi indir

    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();

    if (email.isEmpty) { _showError("E-posta adresi boş bırakılamaz."); return; }//hata mesajları e-posta yoksa
    if (!email.contains('@')) { _showError("Geçerli bir e-posta girin."); return; }//hata mesajları @ yoksa
    if (password.isEmpty) { _showError("Şifrenizi girmeyi unuttunuz."); return; }//hata mesajları şifre yoksa

    setState(() => _isLoading = true);//yüklenme

    // Servis Çağrısı
    String? hata = await _authService.signIn(email, password);

    if (hata == null) {
      // Giriş Başarılı -> Rol Kontrolü
      try {
        final user = _authService.currentUser;
        if (user != null) {
          String role = await _authService.getUserRole(user);

          setState(() => _isLoading = false);

          // Role göre yönlendirme
          if (role == 'admin') {
            Navigator.pushReplacementNamed(context, '/admin');
          } else {
            Navigator.pushReplacementNamed(context, '/anasayfa');
          }
        }
      } catch (e) {
        setState(() => _isLoading = false);
        _showError("Rol bilgisi alınırken hata: $e");
      }
    } else {
      // Giriş Başarısız
      setState(() => _isLoading = false);
      _showError(hata);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          Icon(Icons.error_outline, color: Colors.white),
          SizedBox(width: 10),
          Expanded(child: Text(message))
        ]),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.school, size: 60, color: AppColors.primary),
                  ),
                ),
                SizedBox(height: 24),
                //giriş başlığı
                Text('Tekrar Hoş Geldin!', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('Kampüs hayatına giriş yap.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                SizedBox(height: 40),

                mobileTextField(controller: _emailController, hintText: 'E-posta Adresi', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                mobileTextField(
                  controller: _passwordController, hintText: 'Şifre', icon: Icons.lock_outline, isPassword: true, isVisible: _isPasswordVisible,
                  onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),

                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/sifremi-unuttum'),
                    child: Text('Şifreni mi unuttun?', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ),
                SizedBox(height: 24),

                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _girisYap,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8),
                    child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Giriş Yap', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Hesabın yok mu?", style: TextStyle(color: Colors.grey)),
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/kayit'),
                      child: Text('Hemen Kayıt Ol', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}