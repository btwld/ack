import 'package:ack/ack.dart';

part 'payment_method_model.g.dart';

/// A discriminated union representing different payment methods
/// This demonstrates the ideal developer experience for sealed classes with Ack
@Schema(
  description:
      'A payment method that can be credit card, bank transfer, or digital wallet',
  discriminatedKey: 'type',
)
sealed class PaymentMethod {
  /// The payment method type used for discrimination
  final String type;

  /// Optional payment amount limit
  final double? limit;

  /// Whether this payment method is the default
  final bool isDefault;

  const PaymentMethod({
    required this.type,
    this.limit,
    this.isDefault = false,
  });

  /// Convert to JSON representation
  Map<String, dynamic> toJson();
}

/// Credit card payment method
@Schema(
  description: 'Credit card payment with card details',
  discriminatedValue: 'credit_card',
)
class CreditCardPayment extends PaymentMethod {
  /// Card number (last 4 digits for security)
  @MinLength(4)
  final String cardNumber;

  /// Cardholder name
  @IsNotEmpty()
  final String cardholderName;

  /// Card expiry date
  final String expiryDate;

  /// Card brand (Visa, MasterCard, etc.)
  final String brand;

  const CreditCardPayment({
    super.limit,
    super.isDefault,
    required this.cardNumber,
    required this.cardholderName,
    required this.expiryDate,
    required this.brand,
  }) : super(type: 'credit_card');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'cardNumber': cardNumber,
      'cardholderName': cardholderName,
      'expiryDate': expiryDate,
      'brand': brand,
      if (limit != null) 'limit': limit,
      'isDefault': isDefault,
    };
  }
}

/// Bank transfer payment method
@Schema(
  description: 'Bank transfer payment with account details',
  discriminatedValue: 'bank_transfer',
)
class BankTransferPayment extends PaymentMethod {
  /// Bank account number
  @IsNotEmpty()
  final String accountNumber;

  /// Bank routing number
  @IsNotEmpty()
  final String routingNumber;

  /// Bank name
  @IsNotEmpty()
  final String bankName;

  /// Account holder name
  @IsNotEmpty()
  final String accountHolderName;

  const BankTransferPayment({
    super.limit,
    super.isDefault,
    required this.accountNumber,
    required this.routingNumber,
    required this.bankName,
    required this.accountHolderName,
  }) : super(type: 'bank_transfer');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'accountNumber': accountNumber,
      'routingNumber': routingNumber,
      'bankName': bankName,
      'accountHolderName': accountHolderName,
      if (limit != null) 'limit': limit,
      'isDefault': isDefault,
    };
  }
}

/// Digital wallet payment method
@Schema(
  description: 'Digital wallet payment like PayPal, Apple Pay, etc.',
  discriminatedValue: 'digital_wallet',
  additionalProperties: true,
  additionalPropertiesField: 'metadata',
)
class DigitalWalletPayment extends PaymentMethod {
  /// Wallet provider (PayPal, Apple Pay, Google Pay, etc.)
  @IsNotEmpty()
  final String provider;

  /// Wallet account identifier
  @IsEmail()
  final String walletId;

  /// Additional wallet-specific metadata
  final Map<String, dynamic> metadata;

  const DigitalWalletPayment({
    super.limit,
    super.isDefault,
    required this.provider,
    required this.walletId,
    this.metadata = const {},
  }) : super(type: 'digital_wallet');

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'provider': provider,
      'walletId': walletId,
      ...metadata,
      if (limit != null) 'limit': limit,
      'isDefault': isDefault,
    };
  }
}
