import 'dart:convert';

// ignore_for_file: public_member_api_docs, sort_constructors_first

/// ============================================================================
/// MODEL: UserModelsSQL
/// ============================================================================
/// Model ini berfungsi sebagai cetak biru (blueprint) data Pengguna / User.
/// Di Flutter & SQLite, kita membuat model class agar data lebih terstruktur,
/// type-safe (aman dari tipe data yang salah), dan mudah dimanipulasi.
class UserModelsSQL {
  // `id` bernilai int? (nullable / boleh null) karena saat pertama kali user
  // dibuat (sebelum disimpan ke database), database yang akan memberikan ID
  // secara otomatis (AUTOINCREMENT).
  final int? id;
  final String email;
  final String password;

  UserModelsSQL({this.id, required this.email, required this.password});

  /// --------------------------------------------------------------------------
  /// 1. toMap()
  /// --------------------------------------------------------------------------
  /// Mengubah objek Dart [UserModelsSQL] menjadi bentuk `Map<String, dynamic>`.
  /// Kenapa butuh ini?
  /// Karena database SQLite (sqflite) hanya menerima data dalam bentuk Map (Key-Value)
  /// saat melakukan INSERT atau UPDATE data tabel.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{'id': id, 'email': email, 'password': password};
  }

  /// --------------------------------------------------------------------------
  /// 2. fromMap()
  /// --------------------------------------------------------------------------
  /// Mengubah data `Map<String, dynamic>` dari hasil query database SQLite
  /// kembali menjadi objek Dart [UserModelsSQL].
  /// Dengan begitu, di UI kita bisa memanggil `user.email` alih-alih `map['email']`.
  factory UserModelsSQL.fromMap(Map<String, dynamic> map) {
    return UserModelsSQL(
      id: map['id'] != null ? map['id'] as int : null,
      email: map['email'] as String,
      password: map['password'] as String,
    );
  }

  /// --------------------------------------------------------------------------
  /// 3. toJson() & fromJson()
  /// --------------------------------------------------------------------------
  /// Digunakan jika suatu saat data ingin diubah ke format JSON string
  /// (misalnya untuk dikirim ke API / RESTful server).
  String toJson() => json.encode(toMap());

  factory UserModelsSQL.fromJson(String source) =>
      UserModelsSQL.fromMap(json.decode(source) as Map<String, dynamic>);
}
