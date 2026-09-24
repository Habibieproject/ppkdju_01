import 'package:dio/dio.dart';
import 'package:ppkdju_01/day_21/models/auth_response_model.dart';
import 'package:ppkdju_01/day_21/models/login_model.dart';
import 'package:ppkdju_01/day_21/models/register_model.dart';
import 'package:retrofit/retrofit.dart';

part 'api_services.g.dart';

@RestApi(baseUrl: 'https://absensib1.mobileprojp.com')
abstract class ApiService {
  factory ApiService(Dio dio, {String baseUrl}) = _ApiService;

  @POST('/api/login')
  Future<AuthResponseModel> login(@Body() LoginModel body);

  @POST('/api/register')
  Future<AuthResponseModel> register(@Body() RegisterModel body);
}
