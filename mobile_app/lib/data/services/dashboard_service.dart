import '../models/dashboard_model.dart';
import 'api_client.dart';
import 'token_service.dart';

class DashboardService {
  DashboardService(TokenService tokenService)
    : _apiClient = ApiClient(tokenService);

  final ApiClient _apiClient;

  Future<DashboardModel> fetchDashboard() async {
    final response = await _apiClient.dio.get('/api/dashboard');
    return DashboardModel.fromJson(response.data as Map<String, dynamic>);
  }
}
