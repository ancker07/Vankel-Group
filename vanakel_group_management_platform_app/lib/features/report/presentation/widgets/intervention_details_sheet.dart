import 'package:flutter/material.dart';
import '../../../intervention/domain/intervention.dart';

class InterventionDetailsSheet extends StatelessWidget {
  final Intervention intervention;

  const InterventionDetailsSheet({
    super.key,
    required this.intervention,
  });

  @override
  Widget build(BuildContext context) {
    final isDelayed = intervention.status.name.toLowerCase() == 'delayed';
    final themeColor = isDelayed ? Colors.orange : const Color(0xFF22C55E);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header with Status
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatusBadge(intervention.status),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white30),
                ),
              ],
            ),
          ),

          // Title & Address
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  intervention.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: themeColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "${intervention.address}, ${intervention.city ?? ''}",
                        style: const TextStyle(color: Colors.white54, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Contact Section
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: themeColor.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "ON-SITE CONTACT",
                  style: TextStyle(
                    color: themeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, color: themeColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Jean Dupont", // Mock or from model if available
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            "Facility Manager",
                            style: TextStyle(color: Colors.white30, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white10, height: 1),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildQuickAction(Icons.phone, "Call"),
                    const SizedBox(width: 12),
                    _buildQuickAction(Icons.mail, "Email"),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "DESCRIPTION",
                  style: TextStyle(
                    color: Colors.white30,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  intervention.description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Action Button
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                "DOWNLOAD INTERVENTION SLIP",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(InterventionStatus status) {
    final isDelayed = status.name.toLowerCase() == 'delayed';
    final color = isDelayed ? Colors.orange : const Color(0xFF22C55E);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isDelayed ? Icons.warning_rounded : Icons.check_circle, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            status.name.toUpperCase(),
            style: TextStyle(
              color: color, 
              fontSize: 10, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.white54),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
