import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mobile_app/screens/notifications/bildirim_detay_screen.dart';
import 'package:mobile_app/screens/post/gonderi_ekle_screen.dart';

// --- CORE ---
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';

// --- SCREENS ---
import 'screens/auth/giris_screen.dart';
import 'screens/auth/kayit_ol_screen.dart';
import 'screens/auth/sifremi_unuttum_screen.dart';
import 'screens/layout/ana_iskelet_screen.dart';
import 'screens/profile/profil_screen.dart';
import 'screens/post/gonderi_ekle_screen.dart';
import 'screens/admin/admin_screen.dart';
import 'screens/notifications/bildirim_detay_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stumedia',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: AuthWrapper(),
      routes: {
        '/giris': (context) => GirisScreen(),
        '/kayit': (context) => KayitOlScreen(),
        '/sifremi-unuttum': (context) => SifremiUnuttumScreen(),
        '/anasayfa': (context) => AnaIskeletScreen(),
        '/profil': (context) => ProfilScreen(),
        '/gonderi-ekle': (context) => GonderiEkleScreen(),
        '/admin': (context) => AdminScreen(),
        '/bildirim-detay': (context) => BildirimDetayScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService().authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<String>(
            future: AuthService().getUserRole(snapshot.data!),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (roleSnapshot.hasData && roleSnapshot.data == 'admin') {
                return AdminScreen();
              }
              return AnaIskeletScreen();
            },
          );
        }
        return GirisScreen();
      },
    );
  }
}