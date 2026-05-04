import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tank_speak/models/me_response.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  final MeResponse me;
  const ProfileScreen({super.key, required this.me});

  void logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ownerStations = me.owner;
    final managerStations = me.manager;

    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        title: const Text("Profile"),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // ================= USER CARD =================
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [

                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.person, size: 40, color: Colors.white),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    me.username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    me.email,
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                  ),

                  const SizedBox(height: 10),

                  // ================= INVITE CODE (COPY) =================
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                        ClipboardData(text: me.inviteCode),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Invite code copied!"),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Invite Code: ${me.inviteCode}",
                            style: const TextStyle(color: Colors.orange),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.copy,
                              color: Colors.orange, size: 16),
                        ],
                      ),
                    ),
                  ),

                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= STATS =================
            Row(
              children: [
                _statBox("Owner", ownerStations.length.toString()),
                const SizedBox(width: 10),
                _statBox("Manager", managerStations.length.toString()),
              ],
            ),

            const SizedBox(height: 20),

            // ================= OWNER SECTION =================
            if (ownerStations.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Owner Stations",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ListView.builder(
              //   shrinkWrap: true,
              //   physics: const NeverScrollableScrollPhysics(),
              //   itemCount: ownerStations.length,
              //   itemBuilder: (context, index) {
              //     final s = ownerStations[index];
              //
              //     return _stationCard(
              //       name: s.name,
              //       address: s.address,
              //       phone: s.phone,
              //       hours: s.businessHours,
              //     );
              //   },
              // ),
            ],

            // ================= MANAGER SECTION =================
            if (managerStations.isNotEmpty) ...[
              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Manager Stations",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: managerStations.length,
                itemBuilder: (context, index) {
                  final m = managerStations[index];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.name,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m.name,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 30),

            // ================= LOGOUT =================
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
                onPressed: () => logout(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= STATION CARD =================
  Widget _stationCard({
    required String name,
    required String address,
    required String phone,
    required String hours,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            address,
            style: TextStyle(color: Colors.white.withOpacity(0.6)),
          ),
          const SizedBox(height: 6),
          Text("Phone: $phone",
              style: const TextStyle(color: Colors.white70)),
          Text("Hours: $hours",
              style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // ================= STATS BOX =================
  Widget _statBox(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.orange,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}