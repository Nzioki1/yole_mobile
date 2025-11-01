/// System status response model
class SystemStatus {
  final String status;
  final String version;
  final DateTime timestamp;
  final Map<String, dynamic>? services;
  final Map<String, dynamic>? maintenance;

  const SystemStatus({
    required this.status,
    required this.version,
    required this.timestamp,
    this.services,
    this.maintenance,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      status: json['status'] as String,
      version: json['version'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      services: json['services'] as Map<String, dynamic>?,
      maintenance: json['maintenance'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'version': version,
      'timestamp': timestamp.toIso8601String(),
      'services': services,
      'maintenance': maintenance,
    };
  }

  /// Check if system is operational
  bool get isOperational => status.toLowerCase() == 'operational';

  /// Check if system is under maintenance
  bool get isUnderMaintenance => status.toLowerCase() == 'maintenance';

  /// Check if system is down
  bool get isDown => status.toLowerCase() == 'down';

  /// Get service status
  String? getServiceStatus(String serviceName) {
    return services?[serviceName] as String?;
  }

  /// Check if specific service is available
  bool isServiceAvailable(String serviceName) {
    final serviceStatus = getServiceStatus(serviceName);
    return serviceStatus?.toLowerCase() == 'available';
  }

  @override
  String toString() {
    return 'SystemStatus(status: $status, version: $version, timestamp: $timestamp)';
  }
}





