import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:ppkdju_01/constant/app_color.dart';
import 'package:ppkdju_01/day_15/services/preference_handler.dart';
import 'package:ppkdju_01/day_21/models/login_model.dart';
import 'package:ppkdju_01/day_21/services/api_services.dart';
import 'package:ppkdju_01/day_21/services/dio_client.dart';
import 'package:ppkdju_01/day_21/views/maps_screen.dart';
import 'package:ppkdju_01/day_21/views/register_screen.dart';
import 'package:ppkdju_01/extension/navigator.dart';

/// ============================================================================
/// VIEW: LoginScreenDay21
/// ============================================================================
/// Halaman Login Day 21 menggunakan Retrofit & Dio Client Service.
/// Mengirim request POST ke {{base_url}}/api/login dengan payload:
/// {
///   "email": "budiabc@gmail.com",
///   "password": "Password123!"
/// }
class LoginScreenDay21 extends StatefulWidget {
  const LoginScreenDay21({super.key});

  @override
  State<LoginScreenDay21> createState() => _LoginScreenDay21State();
}

class _LoginScreenDay21State extends State<LoginScreenDay21> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController(
    text: 'budiabc@gmail.com',
  );
  final TextEditingController _passwordController = TextEditingController(
    text: 'Password123!',
  );

  bool _obscurePassword = true;
  bool _isLoading = false;

  late final ApiService _apiService;

  @override
  void initState() {
    super.initState();
    final dio = createDioClient();
    _apiService = ApiService(dio);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final requestBody = LoginModel(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    try {
      final response = await _apiService.login(requestBody);

      if (!mounted) return;

      await PreferenceHandler.setLogin(true);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message ?? 'Login berhasil!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigasi ke Maps Screen Day 19/21
      context.pushReplacement(const GoogleMapsScreenDay19());
    } on DioException catch (e) {
      if (!mounted) return;

      String errorMessage = 'Terjadi kesalahan saat login';
      if (e.response?.data is Map<String, dynamic>) {
        final data = e.response!.data as Map<String, dynamic>;
        if (data['message'] != null) {
          errorMessage = data['message'].toString();
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Day 21'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.lock_person_rounded,
                    size: 80,
                    color: AppColor.primaryDay21,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Selamat Datang',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Silakan masuk dengan akun Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'budiabc@gmail.com',
                      prefixIcon: const Icon(Icons.email_outlined),
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

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Password123!',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (value.length < 6) {
                        return 'Password minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: AppColor.primaryDay21,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),

                  // Navigasi ke Register Screen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun? '),
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () {
                                context.push(const RegisterScreenDay21());
                              },
                        child: const Text(
                          'Register di sini',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColor.primaryDay21,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
