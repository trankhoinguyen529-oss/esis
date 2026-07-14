import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream lắng nghe trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// User hiện tại
  User? get currentUser => _auth.currentUser;

  /// Kiểm tra user hiện tại có đăng nhập bằng Google không
  bool get isGoogleUser {
    final user = _auth.currentUser;
    if (user == null) return false;
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

  /// Đăng ký tài khoản bằng email + password
  Future<UserCredential> registerWithEmail(String email, String password) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Gửi email xác thực
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  /// Kiểm tra email đã verified chưa (reload trước khi check)
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser!.emailVerified;
  }

  /// Đăng nhập bằng email + password
  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Đăng nhập bằng Google
  /// Google account luôn được verified → không cần check emailVerified
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Mở Google account picker
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      // Người dùng hủy chọn tài khoản
      if (googleUser == null) return null;

      // Lấy auth credentials từ Google account
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Tạo Firebase credential từ Google tokens
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Đăng nhập vào Firebase bằng Google credential
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException {
      rethrow;
    }
  }

  /// Đăng xuất (Firebase + Google session)
  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }
}
