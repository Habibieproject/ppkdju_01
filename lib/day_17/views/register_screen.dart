import 'package:flutter/material.dart';
import 'package:ppkdju_01/day_17/models/user_models_sql.dart';
import 'package:ppkdju_01/day_17/services/db_helper.dart';
import 'package:ppkdju_01/day_17/views/login_screen.dart';
import 'package:ppkdju_01/extension/navigator.dart';

/// ============================================================================
/// VIEW: RegisterScreenDay17
/// ============================================================================
/// Halaman pendaftaran (registrasi) akun pengguna baru.
/// Data yang diinputkan akan disimpan secara permanen ke dalam tabel 'users'
/// di database lokal SQLite.
class RegisterScreenDay17 extends StatefulWidget {
  const RegisterScreenDay17({super.key});

  @override
  State<RegisterScreenDay17> createState() => _RegisterScreenDay17State();
}

class _RegisterScreenDay17State extends State<RegisterScreenDay17> {
  // Kontrol visibilitas password (true = disamarkan dengan tanda titik)
  bool obsecure = true;

  // Key untuk validasi form
  final _formKey = GlobalKey<FormState>();

  // Controller untuk membaca inputan email dan password
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  /// --------------------------------------------------------------------------
  /// Logika Registrasi
  /// --------------------------------------------------------------------------
  void register() async {
    final user = emailController.text.trim();
    final pass = passwordController.text;

    // 1. Validasi awal kelengkapan input
    if (user.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Isi semua field!')));
      return;
    }

    // 2. Bungkus data ke dalam objek model UserModelsSQL
    final pengguna = UserModelsSQL(email: user, password: pass);

    // 3. Simpan ke database via DBHelper.
    // Catatan untuk dipelajari:
    // Pada tabel SQLite kita mendefinisikan "email TEXT UNIQUE".
    // Jika email sudah pernah didaftarkan, db.insert akan gagal dan
    // registerUser() akan mengembalikan false.
    bool success = await DBHelper().registerUser(pengguna);

    // 4. Pastikan context masih mounted sebelum menampilkan UI / berpindah halaman
    if (!mounted) return;

    // 5. Berikan respon sesuai hasil penyimpanan
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Akun berhasil dibuat! Silakan login.')));
      // Pindah ke halaman Login jika pendaftaran berhasil
      context.push(LoginScreenDay17());
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email sudah terdaftar! Gunakan email lain.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // =========================
                    // ICON
                    // =========================
                    const Icon(Icons.lock, size: 80, color: Colors.blue),

                    const SizedBox(height: 24),

                    // =========================
                    // TITLE
                    // =========================
                    const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // =========================
                    // SUBTITLE
                    // =========================
                    const Text(
                      'Silakan masuk ke akun Anda',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),

                    const SizedBox(height: 32),

                    // =========================
                    // EMAIL
                    // =========================
                    TextFormField(
                      controller: emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Email wajib diisi';
                        } else if (!value.contains('@')) {
                          return 'Format email tidak valid';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'Masukkan email',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // =========================
                    // PASSWORD
                    // =========================
                    TextFormField(
                      controller: passwordController,
                      obscureText: obsecure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Masukkan password',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              obsecure = !obsecure;
                            });
                          },
                          icon: Icon(
                            obsecure ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================
                    // BUTTON
                    // =========================
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          // textStyle: TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            register();
                            // showDialog(
                            //   context: context,
                            //   builder: (_) => AlertDialog(
                            //     title: Text('Data '),
                            //     content: Column(
                            //       mainAxisSize: MainAxisSize.min,
                            //       crossAxisAlignment: CrossAxisAlignment.start,
                            //       children: [
                            //         Text('Email: ${emailController.text}'),
                            //       ],
                            //     ), // Column
                            //     actions: [
                            //       TextButton(
                            //         onPressed: () {
                            //           context.pop();
                            //           PreferenceHandler.setLogin(true);
                            //           // context.push(
                            //           //   HalamanTerimaKasih(
                            //           //     email: emailController.text,
                            //           //   ),
                            //           // );
                            //           // Navigator.push(
                            //           //   context,
                            //           //   MaterialPageRoute(
                            //           //     builder: (context) =>
                            //           //         HalamanTerimaKasih(
                            //           //           email: emailController.text,
                            //           //         ),
                            //           //   ), // MaterialPageRoute
                            //           // );
                            //         },
                            //         child: Text('Lanjutkan'),
                            //       ), // TextButtontton
                            //     ],
                            //   ), // AlertDialog
                            // );
                          }
                        },
                        child: const Text(
                          'Register',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
