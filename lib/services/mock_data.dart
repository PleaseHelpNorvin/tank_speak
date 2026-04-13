import '../models/gas_station.dart';
import '../models/fuel.dart';
import '../models/tank_reading.dart';

class MockData {

  static List<TankReading> generateReadings({
    required String tankName,
    required int startVolume,
    required int steps,
    int stepDrop = 200,
  }) {
    List<TankReading> readings = [];

    int volume = startVolume;
    DateTime now = DateTime.now();

    for (int i = 0; i < steps; i++) {
      readings.add(
        TankReading(
          id: "r_${tankName}_$i",
          tankName: tankName,
          volume: volume.toDouble(),

          /// FIXED TIMESTAMP (this is the key fix)
          timeStamp: now
              .subtract(Duration(days: steps - i))
              .toString(),

          addedVolume: stepDrop.toDouble(),
        ),
      );

      volume -= stepDrop;
      if (volume < 0) volume = 0;
    }

    return readings; // already oldest → newest
  }

  static List<GasStation> getStations() {
    return [
      GasStation(
        id: "1",
        name: "TankSpeak Station",
        address: "Cebu City",
        manager: "Juan Dela Cruz",
        contactNumber: "09123456789",
        businessHours: "8AM - 10PM",
        timeStamp: DateTime.now().toString(),
        fuels: [
          Fuel(
            id: "f1",
            name: "Diesel",
            tankCapacity: 10000,
            averageThroughput: 500,
            anticipatedDryUp: "2 days",
            fillAlert: "Low",
            timeStamp: DateTime.now().toString(),
            readings: generateReadings(
              tankName: "Diesel Tank",
              startVolume: 8000,
              steps: 20,
              stepDrop: 300,
            ),
          ),

          Fuel(
            id: "f2",
            name: "Unleaded",
            tankCapacity: 8000,
            averageThroughput: 600,
            anticipatedDryUp: "1 day",
            fillAlert: "High",
            timeStamp: DateTime.now().toString(),
            readings: generateReadings(
              tankName: "Unleaded Tank",
              startVolume: 6000,
              steps: 20,
              stepDrop: 250,
            ),
          ),

          Fuel(
            id: "f3",
            name: "Premium",
            tankCapacity: 12000,
            averageThroughput: 700,
            anticipatedDryUp: "3 days",
            fillAlert: "Normal",
            timeStamp: DateTime.now().toString(),
            readings: generateReadings(
              tankName: "Premium Tank",
              startVolume: 9000,
              steps: 20,
              stepDrop: 300,
            ),
          ),
        ],
      ),
    ];
  }
}