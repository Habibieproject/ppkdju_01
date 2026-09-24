import 'package:flutter_test/flutter_test.dart';
import 'package:ppkdju_01/day_21/models/auth_response_model.dart';
import 'package:ppkdju_01/day_21/models/login_model.dart';
import 'package:ppkdju_01/day_21/models/register_model.dart';
import 'package:ppkdju_01/day_21/services/api_services.dart';
import 'package:ppkdju_01/day_21/services/dio_client.dart';

void main() {
  group('Day 21 Auth Models & Service Tests', () {
    test('LoginModel toJson & fromJson', () {
      final model = LoginModel(
        email: "budiabc@gmail.com",
        password: "Password123!",
      );
      final json = model.toJson();
      expect(json['email'], "budiabc@gmail.com");
      expect(json['password'], "Password123!");

      final fromJsonModel = LoginModel.fromJson(json);
      expect(fromJsonModel.email, "budiabc@gmail.com");
      expect(fromJsonModel.password, "Password123!");
    });

    test('RegisterModel toJson & fromJson', () {
      final model = RegisterModel(
        name: "Budi",
        email: "budis@sexamsplesss.com",
        password: "Password123!",
      );
      final json = model.toJson();
      expect(json['name'], "Budi");
      expect(json['email'], "budis@sexamsplesss.com");
      expect(json['password'], "Password123!");

      final fromJsonModel = RegisterModel.fromJson(json);
      expect(fromJsonModel.name, "Budi");
      expect(fromJsonModel.email, "budis@sexamsplesss.com");
      expect(fromJsonModel.password, "Password123!");
    });

    test('AuthResponseModel parses API response correctly', () {
      final rawJson = {
        "message": "Login berhasil",
        "data": {
          "token": "4184|cwXYzGOhWsIFVMP99VqFR01FJ86nNDVIFXe92fcza63aaef1",
          "user": {
            "id": 360,
            "name": "budianduks",
            "email": "budiabc@gmail.com",
            "email_verified_at": null,
            "created_at": "2025-08-28T02:13:58.000000Z",
            "updated_at": "2025-08-28T02:47:12.000000Z"
          }
        }
      };

      final response = AuthResponseModel.fromJson(rawJson);
      expect(response.message, "Login berhasil");
      expect(response.data?.token, startsWith("4184|"));
      expect(response.data?.user?.email, "budiabc@gmail.com");
      expect(response.data?.user?.id, 360);
    });

    test('ApiService live login test', () async {
      final dio = createDioClient();
      final apiService = ApiService(dio);

      final response = await apiService.login(
        LoginModel(
          email: "budiabc@gmail.com",
          password: "Password123!",
        ),
      );

      expect(response.message, contains("Login"));
      expect(response.data?.token, isNotEmpty);
      expect(response.data?.user?.email, "budiabc@gmail.com");
    });
  });
}
