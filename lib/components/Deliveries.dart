class Delivery {
  final String id;
  final String status;
  final double cost;
  final String date;

  Delivery({
    required this.id,
    required this.status,
    required this.cost,
    required this.date,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id'] ?? '',
      status: json['status'] ?? 'Unknown',
      cost: (json['cost'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] ?? '',
    );
  }
}
