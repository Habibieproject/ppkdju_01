import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ppkdju_01/day_17/models/user_models_sql.dart';
import 'package:ppkdju_01/day_17/services/db_helper.dart';
import 'package:sqlite_viewer/sqlite_viewer.dart';

/// ============================================================================
/// VIEW: HomeScreenDay17
/// ============================================================================
/// Halaman utama untuk menampilkan seluruh daftar pengguna yang tersimpan
/// di database lokal SQLite.
///
/// Kita menggunakan [StatefulWidget] agar halaman ini dapat me-refresh (memuat
/// ulang) data pengguna secara otomatis ketika ada aksi Tambah, Edit, atau Hapus.
class HomeScreenDay17 extends StatefulWidget {
  const HomeScreenDay17({super.key});

  @override
  State<HomeScreenDay17> createState() => _HomeScreenDay17State();
}

class _HomeScreenDay17State extends State<HomeScreenDay17> {
  // Variabel untuk menampung Future daftar pengguna.
  // Disimpan di state agar FutureBuilder tidak memanggil database berulang kali
  // saat build() dipanggil ulang oleh Flutter.
  late Future<List<UserModelsSQL>> _usersFuture;

  @override
  void initState() {
    super.initState();
    // Memuat data pertama kali ketika halaman dibuat
    _refreshUsers();
  }

  /// --------------------------------------------------------------------------
  /// Fungsi Refresh Data
  /// --------------------------------------------------------------------------
  /// Memanggil ulang database dan memperbarui UI dengan setState.
  void _refreshUsers() {
    setState(() {
      _usersFuture = DBHelper().getAllUsers();
    });
  }

  /// --------------------------------------------------------------------------
  /// DIALOG: Konfirmasi Hapus Data
  /// --------------------------------------------------------------------------
  /// Menggunakan [showDialog] & [AlertDialog] untuk konfirmasi agar pengguna
  /// tidak sengaja menekan tombol hapus.
  void _showDeleteDialog(UserModelsSQL user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Hapus Pengguna'),
          ],
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengguna "${user.email}"?',
        ),
        actions: [
          // Tombol Batal: Menutup dialog tanpa melakukan apapun
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Batal'),
          ),
          // Tombol Hapus: Menjalankan penghapusan ke SQLite
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // 1. Tutup dialog konfirmasi
              Navigator.pop(dialogContext);
              if (user.id != null) {
                // 2. Hapus data di database melalui DBHelper
                await DBHelper().deleteUser(user.id!);
                // 3. Pastikan widget masih ada di widget tree sebelum menampilkan SnackBar
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Pengguna ${user.email} berhasil dihapus'),
                    ),
                  );
                  // 4. Refresh tampilan agar baris yang dihapus hilang dari list
                  _refreshUsers();
                }
              }
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  /// --------------------------------------------------------------------------
  /// MODAL BOTTOM SHEET: Form Edit Pengguna
  /// --------------------------------------------------------------------------
  /// Menggunakan [showModalBottomSheet] untuk memunculkan lembar formulir edit dari bawah.
  void _showEditBottomSheet(UserModelsSQL user) {
    // Siapkan text controller yang sudah terisi data awal pengguna
    final emailController = TextEditingController(text: user.email);
    final passwordController = TextEditingController(text: user.password);
    final formKey = GlobalKey<FormState>();
    bool obscurePassword = true;

    showModalBottomSheet(
      context: context,
      // isScrollControlled: true memungkinkan ukuran bottom sheet menyesuaikan tinggi konten & keyboard
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        // StatefulBuilder digunakan agar state di dalam bottom sheet
        // (seperti toggle show/hide password) bisa di-update tanpa rebuild halaman utama
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Padding(
              // viewInsets.bottom memberikan padding setinggi keyboard virtual saat keyboard muncul
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Indikator garis pegangan (drag handle) di atas modal
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Edit Pengguna',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Input Email
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email tidak boleh kosong';
                          }
                          if (!value.contains('@')) {
                            return 'Format email tidak valid';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Input Password
                      TextFormField(
                        controller: passwordController,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              // Memperbarui state lokal bottom sheet
                              setModalState(() {
                                obscurePassword = !obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Tombol Simpan Perubahan
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            // Validasi form terlebih dahulu
                            if (formKey.currentState!.validate()) {
                              // 1. Buat model data baru dengan ID yang sama
                              final updatedUser = UserModelsSQL(
                                id: user.id,
                                email: emailController.text.trim(),
                                password: passwordController.text,
                              );
                              // 2. Tutup Modal Bottom Sheet
                              Navigator.pop(sheetContext);
                              // 3. Simpan perubahan ke SQLite
                              final success = await DBHelper().updateUser(
                                updatedUser,
                              );
                              // 4. Cek apakah halaman masih aktif
                              if (!mounted) return;
                              // 5. Berikan feedback ke pengguna dan refresh list
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    success
                                        ? 'Data pengguna berhasil diperbarui'
                                        : 'Gagal memperbarui data pengguna',
                                  ),
                                ),
                              );
                              if (success) {
                                _refreshUsers();
                              }
                            }
                          },
                          child: const Text('Simpan Perubahan'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Day 17 Home")),
      body: Column(
        children: [
          Expanded(
            // FutureBuilder menangani operasi asinkron secara otomatis
            child: FutureBuilder<List<UserModelsSQL>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                // Kondisi 1: Menunggu data selesai dimuat
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Kondisi 2: Terjadi error saat membaca database
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Terjadi kesalahan: ${snapshot.error}'),
                  );
                }

                // Kondisi 3: Data berhasil diambil tapi masih kosong
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada data pengguna.'),
                  );
                }

                // Kondisi 4: Data tersedia dan siap ditampilkan ke ListView
                final daftarPengguna = snapshot.data!;

                return ListView.builder(
                  itemCount: daftarPengguna.length,
                  itemBuilder: (context, index) {
                    final user = daftarPengguna[index];
                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        title: Text(user.email),
                        subtitle: Text('Password: ${user.password}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Tombol Edit -> Membuka Modal Bottom Sheet
                            IconButton(
                              onPressed: () => _showEditBottomSheet(user),
                              icon: const Icon(Icons.edit, color: Colors.blue),
                            ),
                            // Tombol Delete -> Membuka Dialog Konfirmasi
                            IconButton(
                              onPressed: () => _showDeleteDialog(user),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Khusus saat debug mode: Tombol untuk melihat isi tabel SQLite secara visual
          if (kDebugMode)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DatabaseList()),
                );
              },
              child: const Text("Lihat Database"),
            ),
        ],
      ),
    );
  }
}
