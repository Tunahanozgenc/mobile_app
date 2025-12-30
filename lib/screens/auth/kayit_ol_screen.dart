import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/stumedia_text_field.dart';
import '../../core/services/auth_service.dart';

class KayitOlScreen extends StatefulWidget {
  @override
  _KayitOlScreenState createState() => _KayitOlScreenState();
}

class _KayitOlScreenState extends State<KayitOlScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  // --- BİRİM SEÇİMİ ---
  String? _secilenBirim;
  final List<String> _birimler = [
    'Bilgisayar Mühendisliği',
    'Elektrik-Elektronik Müh.',
    'Makine Mühendisliği',
    'İnşaat Mühendisliği',
    'Mimarlık Fakültesi',
    'Tıp Fakültesi',
    'Hukuk Fakültesi',
    'Edebiyat Fakültesi',
    'İdari Personel',
    'Diğer'
  ];

  void _kayitOl() async {
    FocusScope.of(context).unfocus();

    String name = _nameController.text.trim();
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPassword = _confirmPasswordController.text.trim();

    // 1. Validasyonlar
    if (name.isEmpty) { _showError("Ad Soyad girmelisiniz."); return; }
    if (_secilenBirim == null) { _showError("Lütfen bölüm/birim seçiniz."); return; } // <--- YENİ KONTROL
    if (email.isEmpty || !email.contains('@')) { _showError("Geçerli bir e-posta girin."); return; }
    if (password.length < 6) { _showError("Şifre en az 6 karakter olmalı."); return; }
    if (password != confirmPassword) { _showError("Şifreler uyuşmuyor!"); return; }

    setState(() => _isLoading = true);

    // 2. Servise İstek (Birim bilgisini de gönderiyoruz)
    String? hata = await _authService.signUp(email, password, name, _secilenBirim!);

    setState(() => _isLoading = false);

    if (hata == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Kayıt Başarılı!"), backgroundColor: Colors.green));
      // Başarılıysa her şeyi silip ana sayfaya yönlendir (AuthWrapper zaten yakalar ama garanti olsun)
      Navigator.pushNamedAndRemoveUntil(context, '/anasayfa', (route) => false);
    } else {
      _showError(hata);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () => Navigator.pop(context)
          )
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Aramıza Katıl 🚀', textAlign: TextAlign.center, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('Kampüsün nabzını tut.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                SizedBox(height: 30),

                // Ad Soyad
                mobileTextField(controller: _nameController, hintText: 'Ad Soyad', icon: Icons.person_outline),
                SizedBox(height: 16),

                // --- BİRİM SEÇİMİ (DROPDOWN) ---
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300), // TextField ile uyumlu çerçeve
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: Row(children: [Icon(Icons.school_outlined, color: Colors.grey), SizedBox(width: 12), Text("Bölüm/Birim Seçiniz")]),
                      value: _secilenBirim,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down),
                      items: _birimler.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _secilenBirim = newValue;
                        });
                      },
                    ),
                  ),
                ),
                SizedBox(height: 16),

                mobileTextField(controller: _emailController, hintText: 'E-posta Adresi', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                mobileTextField(controller: _passwordController, hintText: 'Şifre', icon: Icons.lock_outline, isPassword: true, isVisible: _isPasswordVisible, onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible)),
                mobileTextField(controller: _confirmPasswordController, hintText: 'Şifre Tekrar', icon: Icons.lock_clock, isPassword: true, isVisible: _isPasswordVisible),

                SizedBox(height: 24),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _kayitOl,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 8),
                    child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Kayıt Ol', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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