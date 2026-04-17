// import '../models/gas_station.dart';
// import '../models/owner.dart';
// import '../models/area_manager.dart';
// import '../models/tank.dart';
// import '../models/volume_reading.dart';
//
// class MockData {
//   static List<GasStation> getStations() {
//     return [
//       GasStation(
//         id: "gs_001",
//         companyName: "Shell Cebu Mabolo",
//         address: "Mabolo, Cebu City",
//         businessHours: "24/7",
//
//         owner: Owner(
//           id: "owner_001",
//           name: "Juan Dela Cruz",
//           contactInfo: "09171234567",
//         ),
//
//         areaManager: AreaManager(
//           id: "am_001",
//           name: "Maria Santos",
//           contactInfo: "maria.santos@email.com",
//           companyName: "Shell Philippines",
//         ),
//
//         tanks: [
//           Tank(
//             id: "tank_001",
//             productName: "Diesel",
//             currentVolume: 12000,
//             status: "normal",
//             maxCapacity: 20000,
//             radius: 2.5,
//             length: 8.0,
//             readings: _generateReadings(12000),
//           ),
//           Tank(
//             id: "tank_002",
//             productName: "Gasoline",
//             currentVolume: 3000,
//             status: "low",
//             maxCapacity: 20000,
//             radius: 2.5,
//             length: 8.0,
//             readings: _generateReadings(3000),
//           ),
//         ],
//       ),
//
//       GasStation(
//         id: "gs_002",
//         companyName: "Petron Colon",
//         address: "Colon Street, Cebu City",
//         businessHours: "5:00 AM - 11:00 PM",
//
//         owner: Owner(
//           id: "owner_002",
//           name: "Carlos Reyes",
//           contactInfo: "09981234567",
//         ),
//
//         areaManager: AreaManager(
//           id: "am_002",
//           name: "Anna Lopez",
//           contactInfo: "anna.lopez@email.com",
//           companyName: "Petron Corp",
//         ),
//
//         tanks: [
//           Tank(
//             id: "tank_003",
//             productName: "Diesel",
//             currentVolume: 18000,
//             status: "high",
//             maxCapacity: 20000,
//             radius: 3.0,
//             length: 10.0,
//             readings: _generateReadings(18000),
//           ),
//         ],
//       ),
//     ];
//   }
//
//   /// 🔥 Generate fake historical readings
//   static List<VolumeReading> _generateReadings(double baseVolume) {
//     final now = DateTime.now();
//
//     return List.generate(15, (i) {
//       return VolumeReading(
//         id: "r_$i",
//         volume: baseVolume - (i * 200),
//         timeStamp: now
//             .subtract(Duration(hours: 15 - i))
//             .toIso8601String(),
//       );
//     });
//   }
// }