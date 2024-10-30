import 'package:logging/logging.dart';
import 'database_helper.dart';
import 'package:crypto/crypto.dart'; // Tambahkan ini untuk enkripsi
import 'dart:convert'; // Tambahkan ini untuk utf8
import '../models/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final log = Logger('AuthService');

  Future<bool> changePassword(
      String userId, String oldPassword, String newPassword) async {
    final db = await DatabaseHelper().database;
    try {
      // Ambil data user dari database berdasarkan userId
      var user = await db.query(
        'users',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (user.isEmpty) {
        log.warning('User tidak ditemukan dengan ID: $userId');
        return false;
      }

      // Verifikasi password lama
      var storedPassword = user.first['password'] as String;
      var hashedOldPassword = _hashPassword(oldPassword);

      if (storedPassword != hashedOldPassword) {
        log.warning('Password lama salah untuk user dengan ID: $userId');
        return false;
      }

      // Encrypt password baru
      var hashedNewPassword = _hashPassword(newPassword);

      // Update password di database
      int result = await db.update(
        'users',
        {'password': hashedNewPassword},
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (result > 0) {
        log.info('Password berhasil diubah untuk user dengan ID: $userId');
        return true;
      } else {
        log.warning('Gagal mengubah password untuk user dengan ID: $userId');
        return false;
      }
    } catch (e) {
      log.severe(
          'Gagal melakukan update password untuk user dengan ID: $userId', e);
      return false;
    }
  }

  Future<User?> loginUser(String role, String password) async {
    final db = await DatabaseHelper().database;
    try {
      log.info('Melakukan login untuk role: $role');

      // Encrypt the input password to compare with the stored hashed password
      print('Role: $role, CHECKING PASS: $password');

      final List<Map<String, dynamic>> maps = await db.query(
        'Users',
        where: 'role = ? AND password = ?',
        whereArgs: [role, password],
      );

      print('MAPS:$maps');

      if (maps.isNotEmpty) {
        log.info('USERPREF: $role');
        User user = User.fromMap(maps[0]);

        print('userId: ${user.user_id}');

        // Save user_id to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id',
            user.user_id); // Use user.user_id! assuming it's not null
        log.info('User ID ${user.user_id} saved to SharedPreferences');

        return user;
      } else {
        log.warning('Login gagal untuk role: $role - Role atau password salah');
        return null;
      }
    } catch (e) {
      log.severe('Gagal melakukan login untuk role: $role', e);
      rethrow;
    }
  }

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> logout() async {
    // Implementasi logout, misalnya menghapus token dari penyimpanan
    log.info('Logout dari aplikasi');
    // Hapus token atau sesi pengguna di penyimpanan lokal
    // Contoh: await SharedPreferences.getInstance().then((prefs) => prefs.remove('token'));
  }
}
