enum DeliveryStatus { pending, inProgress, completed, cancelled }

class Delivery {
  final String userId;
  final int price;
  final String distance;
  final String startPoint;
  final String endPoint;
  final String deliveryType;
  final String transactionType;
  final String packageSize;
  final DeliveryStatus status;

  Delivery({
    required this.userId,
    required this.price,
    required this.distance,
    required this.startPoint,
    required this.endPoint,
    required this.deliveryType,
    required this.transactionType,
    required this.packageSize,
    required this.status,
  });

  // Convert JSON string to enum
  static DeliveryStatus _statusFromString(String status) {
    switch (status.toLowerCase()) {
      case 'inprogress':
        return DeliveryStatus.inProgress;
      case 'completed':
        return DeliveryStatus.completed;
      case 'cancelled':
        return DeliveryStatus.cancelled;
      default:
        return DeliveryStatus.pending;
    }
  }

  // Convert enum to JSON string
  static String _statusToString(DeliveryStatus status) {
    return status
        .name; // `name` converts enum to a string automatically in Dart 2.15+
  }

  // Factory constructor for JSON deserialization
  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      userId: json['user_id'] ?? '',
      price: (json['price'] as int?) ?? 0,
      distance: json['distance'] ?? 'Unknown',
      startPoint: json['startpoint'] ?? '',
      endPoint: json['endpoint'] ?? '',
      deliveryType: json['deliverytype'] ?? '',
      transactionType: json['transactiontype'] ?? '',
      packageSize: json['packagesize'] ?? '',
      status: _statusFromString(json['status'] ?? 'pending'),
    );
  }

  // Method to convert object to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'price': price,
      'distance': distance,
      'startpoint': startPoint,
      'endpoint': endPoint,
      'deliverytype': deliveryType,
      'transactiontype': transactionType,
      'packagesize': packageSize,
      'status': _statusToString(status),
    };
  }
}
