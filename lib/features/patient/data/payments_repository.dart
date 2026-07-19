import 'package:url_launcher/url_launcher.dart';

import '../../../core/network/api_client.dart';

class PaymentsRepository {
  Future<PaymentCheckout> startCheckout({
    required int amountMinor,
    String currency = 'GHS',
  }) async {
    final response = await ApiClient.instance.post(
      '/api/v1/payments/paystack/initialize',
      body: {'amountMinor': amountMinor, 'currency': currency},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    final url = data['authorizationUrl'] as String?;
    if (url == null || url.isEmpty) {
      throw const ApiException(
        statusCode: 502,
        code: 'CHECKOUT_URL_MISSING',
        message: 'Paystack did not return a checkout URL.',
      );
    }
    return PaymentCheckout(
      reference: data['reference'] as String,
      authorizationUrl: url,
    );
  }

  Future<PaymentStatus> getStatus(String reference) async {
    final response = await ApiClient.instance.get(
      '/api/v1/payments/paystack/status',
      query: {'reference': reference},
    );
    final data = Map<String, dynamic>.from(response.data as Map);
    return PaymentStatus(
      reference: data['reference'] as String,
      status: data['status'] as String? ?? 'pending',
      amountMinor: data['amountMinor'] as int? ?? 0,
      currency: data['currency'] as String? ?? 'GHS',
    );
  }

  Future<void> openCheckout(String checkoutUrl) async {
    if (!await launchUrl(
      Uri.parse(checkoutUrl),
      mode: LaunchMode.externalApplication,
    )) {
      throw const ApiException(
        statusCode: 500,
        code: 'CHECKOUT_OPEN_FAILED',
        message: 'The secure Paystack checkout could not be opened.',
      );
    }
  }
}

class PaymentCheckout {
  const PaymentCheckout({
    required this.reference,
    required this.authorizationUrl,
  });

  final String reference;
  final String authorizationUrl;
}

class PaymentStatus {
  const PaymentStatus({
    required this.reference,
    required this.status,
    required this.amountMinor,
    required this.currency,
  });

  final String reference;
  final String status;
  final int amountMinor;
  final String currency;

  bool get isSuccess => status == 'success';
}
