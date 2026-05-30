class ContainerMetrics {
  final String id;
  final String name;
  final String image;
  final String status;
  final String state;
  final int uptimeSeconds;
  final int restartCount;

  double? cpuPercent;
  double? memoryPercent;
  int? memoryUsageBytes;
  int? memoryLimitBytes;
  int? networkRxBytes;
  int? networkTxBytes;
  List<double> cpuHistory;
  List<double> memHistory;

  ContainerMetrics({
    required this.id,
    required this.name,
    required this.image,
    required this.status,
    required this.state,
    required this.uptimeSeconds,
    required this.restartCount,
    this.cpuPercent,
    this.memoryPercent,
    this.memoryUsageBytes,
    this.memoryLimitBytes,
    this.networkRxBytes,
    this.networkTxBytes,
    List<double>? cpuHistory,
    List<double>? memHistory,
  })  : cpuHistory = cpuHistory ?? [],
        memHistory = memHistory ?? [];
}
