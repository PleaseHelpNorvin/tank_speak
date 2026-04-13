class TankReading {
  final String id;
  final String tankName;
  final double volume;
  final String timeStamp;
  final double? addedVolume;

  TankReading({
    required this.id,
    required this.tankName,
    required this.volume,
    required this.timeStamp,
    this.addedVolume,
  });

  factory TankReading.fromJson(Map<String, dynamic> json) {
    return TankReading(
      id: json['id'],
      tankName: json['tankName'],
      volume: json['volume'].toDouble(),
      timeStamp: json['timeStamp'],
      addedVolume: json['addedVolume']?.toDouble(),
    );
  }
}