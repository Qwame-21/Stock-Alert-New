import '../../../core/network/api_client.dart';
import 'models/reward_summary.dart';

class RewardsRepository {
  RewardsRepository({ApiClient? api}) : _api = api ?? ApiClient.instance;

  final ApiClient _api;

  Future<RewardSummary> load() async {
    final response = await _api.get('/api/v1/rewards');
    return RewardSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
