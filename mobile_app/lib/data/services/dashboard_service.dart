import '../models/dashboard_model.dart';
import 'api_client.dart';
import 'network_service.dart';
import 'offline_data_service.dart';
import 'token_service.dart';

class DashboardService {
  DashboardService(TokenService tokenService)
    : _tokenService = tokenService,
      _apiClient = ApiClient(tokenService);

  final TokenService _tokenService;
  final ApiClient _apiClient;
  final OfflineDataService _offlineDataService = OfflineDataService.instance;

  Future<DashboardModel> fetchDashboard() async {
    try {
      final response = await _apiClient.dio.get('/api/dashboard');
      final raw = Map<String, dynamic>.from(response.data as Map);
      final userInfo = await _tokenService.getUserInfo();
      await _offlineDataService.cacheDashboard(raw, userInfo.userId);
      return DashboardModel.fromJson(raw);
    } catch (error) {
      if (!NetworkService.isOfflineError(error)) {
        rethrow;
      }
      final userInfo = await _tokenService.getUserInfo();
      final cached = await _offlineDataService.readCachedDashboard(
        userInfo.userId,
      );
      if (cached != null) {
        return cached;
      }
      rethrow;
    }
  }
}
