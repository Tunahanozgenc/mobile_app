import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  //Şu Anki Kullanıcı
  User? get currentUser => _auth.currentUser;

  //GİRİŞ YAP
  Future<String?> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Başarılıysa giriş
    } on FirebaseAuthException catch (e) {
      return _hataMesajiCevir(e.code);
    } catch (e) {
      return "Beklenmedik bir hata oluştu: $e";
    }
  }

  //KAYIT OL
  Future<String?> signUp(String email, String password, String name, String birim) async {
    try {
      //Auth: Kullanıcıyı oluştur
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      //Firestore: Kullanıcıyı kaydet
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);

        await _firestore.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'email': email,//email bilgisi
          'name': name,//isim bilgisi
          'birim': birim, //bölüm bilgisi
          'username': '@${name.replaceAll(' ', '').toLowerCase()}',
          'bio': 'Merhaba, ben Stumedia kullanıcısıyım!',
          'profileImage': '',
          'role': 'user',
          'takipEdilenler': [], // Profil sayfası için gerekli boş liste
          'ayarlar': {'saglik': true, 'guvenlik': true}, // Varsayılan bildirim ayarları
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return null; // Başarılı
    } on FirebaseAuthException catch (e) {
      return _hataMesajiCevir(e.code);
    } catch (e) {
      return "Kayıt sırasında hata: $e";
    }
  }

  Future<String> getUserRole(User user) async {
    try {
      //Admins tablosunu kontrol et --->  admin giriş için kullanılacak
      if (user.email != null) {
        final adminCheck = await _firestore
            .collection('admins')
            .where('email', isEqualTo: user.email)
            .limit(1)
            .get();

        if (adminCheck.docs.isNotEmpty) {
          return 'admin';
        }
      }

      //Users tablosunu kontrol et
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (userDoc.exists) {
        // Güvenli veri çekme
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        return data?['role'] ?? 'user';
      }

      return 'user';

    } catch (e) {
      print("Rol getirme hatası: $e");
      return 'user';
    }
  }


  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _hataMesajiCevir(e.code);
    } catch (e) {
      return "Hata oluştu: $e";
    }
  }

  Future<void> signOut() async {//çıkış işlemi
    await _auth.signOut();
  }

  String _hataMesajiCevir(String code) {//hata mesajlarını gönderme işlemleri
    switch (code) {
      case 'user-not-found': return 'Bu e-posta ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password': return 'Girdiğiniz şifre yanlış.';
      case 'email-already-in-use': return 'Bu e-posta adresi zaten kullanımda.';
      case 'invalid-email': return 'Geçersiz bir e-posta adresi girdiniz.';
      case 'weak-password': return 'Şifre çok zayıf. En az 6 karakter olmalı.';
      case 'network-request-failed': return 'İnternet bağlantınızı kontrol edin.';
      default: return 'Bir hata oluştu ($code).';
    }
  }
}