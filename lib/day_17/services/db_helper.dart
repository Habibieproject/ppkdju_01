import 'dart:developer';

import 'package:path/path.dart';
import 'package:ppkdju_01/day_17/models/user_models_sql.dart';
import 'package:sqflite/sqflite.dart';

/// ============================================================================
/// SERVICE / HELPER: DBHelper (Database Helper)
/// ============================================================================
/// Kelas ini bertugas sebagai jembatan penghubung antara aplikasi Flutter
/// kita dengan basis data lokal SQLite (sqflite).
///
/// Di sini kita menggunakan pola desain SINGLETON PATTERN:
/// Artinya, hanya ada satu objek / instance DBHelper yang aktif di memori aplikasi.
/// Ini penting agar koneksi ke database tidak dibuka berkali-kali secara boros.
class DBHelper {
  // 1. Instance statis tunggal dari DBHelper
  static final DBHelper _instance = DBHelper._internal();

  // 2. Factory constructor mengembalikan instance yang sama setiap kali dipanggil
  factory DBHelper() => _instance;

  // 3. Private constructor agar tidak bisa di-instansiasi sembarangan dari luar
  DBHelper._internal();

  // Variabel untuk menyimpan koneksi Database aktif (bisa null sebelum diinisialisasi)
  static Database? _database;

  /// Getter untuk mengambil objek Database.
  /// Jika database sudah terbuka, langsung kembalikan `_database`.
  /// Jika belum, jalankan `_initDB()` terlebih dahulu (Lazy Initialization).
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  /// --------------------------------------------------------------------------
  /// Inisialisasi & Pembuatan Database
  /// --------------------------------------------------------------------------
  Future<Database> _initDB() async {
    // Mendapatkan direktori standar penyimpanan database di sistem operasi (Android/iOS)
    final dbPath = await getDatabasesPath();
    // Menggabungkan path direktori dengan nama file database lokal, misalnya: ppkdju.db
    final path = join(dbPath, 'ppkdju.db');

    // Membuka database, jika file belum ada, method onCreate akan dipanggil otomatis
    return await openDatabase(
      path,
      version: 1, // Naikkan versi ini jika di kemudian hari ada perubahan struktur tabel
      onCreate: (db, version) async {
        // Eksekusi perintah DDL SQL untuk membuat tabel 'users'
        await db.execute('''
          CREATE TABLE users (
          id INTEGER PRIMARY KEY AUTOINCREMENT, 
          email TEXT UNIQUE, 
          password TEXT
          )
          ''');
      },
    );
  }

  /// --------------------------------------------------------------------------
  /// 1. CREATE (INSERT): Mendaftarkan Pengguna Baru
  /// --------------------------------------------------------------------------
  /// Menyimpan data user baru ke dalam tabel 'users'.
  /// Mengembalikan `true` jika berhasil, atau `false` jika gagal (misal email duplikat).
  Future<bool> registerUser(UserModelsSQL pengguna) async {
    final db = await database;

    try {
      // db.insert menerima nama tabel dan Map data dari model
      await db.insert('users', pengguna.toMap());
      return true;
    } catch (e) {
      log('Error saat registerUser: ${e.toString()}');
      return false;
    }
  }

  /// --------------------------------------------------------------------------
  /// 2. READ: Verifikasi Login Pengguna
  /// --------------------------------------------------------------------------
  /// Mencari user berdasarkan kombinasi email dan password.
  /// Tips Keamanan: Menggunakan `whereArgs` untuk mencegah SQL Injection!
  Future<UserModelsSQL?> loginUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password], // Parameter '?' akan digantikan oleh nilai ini secara aman
    );

    // Jika data ditemukan (results tidak kosong), kembalikan data user pertama
    if (results.isNotEmpty) {
      return UserModelsSQL.fromMap(results.first);
    }
    // Jika tidak ditemukan atau password salah, kembalikan null
    return null;
  }

  /// --------------------------------------------------------------------------
  /// 3. READ ALL: Mengambil Seluruh Data Pengguna
  /// --------------------------------------------------------------------------
  /// Mengambil semua baris data di tabel 'users' dan mengubahnya menjadi `List<UserModelsSQL>`.
  Future<List<UserModelsSQL>> getAllUsers() async {
    final db = await database;
    // Query tanpa 'where' akan mengambil seluruh record di tabel
    final List<Map<String, dynamic>> results = await db.query('users');

    // Konversi setiap Map hasil query menjadi objek UserModelsSQL menggunakan fromMap()
    return results.map((map) => UserModelsSQL.fromMap(map)).toList();
  }

  /// --------------------------------------------------------------------------
  /// 4. DELETE: Menghapus Pengguna Berdasarkan ID
  /// --------------------------------------------------------------------------
  /// Menghapus baris pada tabel 'users' yang memiliki ID yang cocok.
  Future<void> deleteUser(int id) async {
    final db = await database;
    await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// --------------------------------------------------------------------------
  /// 5. UPDATE: Memperbarui Data Pengguna
  /// --------------------------------------------------------------------------
  /// Mengubah data email / password pengguna berdasarkan ID-nya.
  /// Mengembalikan `true` jika setidaknya ada 1 baris yang terupdate.
  Future<bool> updateUser(UserModelsSQL pengguna) async {
    final db = await database;

    try {
      int count = await db.update(
        'users',
        pengguna.toMap(),
        where: 'id = ?',
        whereArgs: [pengguna.id],
      );
      // count adalah jumlah baris yang berhasil diubah di database
      return count > 0;
    } catch (e) {
      log('Error saat updateUser: ${e.toString()}');
      return false;
    }
  }
}
