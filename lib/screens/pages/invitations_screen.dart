import 'package:flutter/material.dart';
import 'package:tank_speak/models/me_response.dart';
import 'package:tank_speak/screens/pages/splash_screen.dart';
import '../../models/invitation.dart';
import '../../services/api_service.dart';


class InvitationsScreen extends StatefulWidget {
  final MeResponse me;
  const InvitationsScreen({super.key, required this.me});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  final ApiService api = ApiService();

  List<ReceivedInvitation> invitations = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadInvitations();
  }

  Future<void> loadInvitations() async {
    try {
      final data = await api.fetchInvitations();

      setState(() {
        invitations = data.items;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint(e.toString());
    }
  }

  Future<void> acceptInvite(int id) async {
    await api.acceptInvitation(id);
    loadInvitations();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
    );
  }

  Future<void> declineInvite(int id) async {
    await api.deleteInvitation(id);
    loadInvitations();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F2027),

      appBar: AppBar(
        title: const Text("Invitations"),
        backgroundColor: const Color(0xFF0F2027),
        foregroundColor: Colors.white,
        elevation: 0,
      ),

      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.orange),
      )
          : invitations.isEmpty
          ? _emptyState()
          : RefreshIndicator(
        color: Colors.orange,
        onRefresh: loadInvitations,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: invitations.length,
          itemBuilder: (context, index) {
            final invite = invitations[index];
            return _inviteCard(invite);
          },
        ),
      ),
    );
  }

  // ================= EMPTY =================
  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mail_outline, color: Colors.white54, size: 60),
          SizedBox(height: 10),
          Text("No invitations yet",
              style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // ================= CARD =================
  Widget _inviteCard(ReceivedInvitation invite) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // HEADER
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.orange.withOpacity(0.2),
                child: const Icon(Icons.person, color: Colors.orange),
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Station #${invite.gasStation}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Role: ${invite.role}",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // MESSAGE
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.message, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    invite.message,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ACTIONS
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => acceptInvite(invite.id),
                  icon: const Icon(Icons.check),
                  label: const Text("Accept"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => declineInvite(invite.id),
                  icon: const Icon(Icons.close),
                  label: const Text("Decline"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}