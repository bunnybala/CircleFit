import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/group_provider.dart';
import '../../domain/group_models.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  final int challengeId;
  const ChallengeDetailScreen({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressState = ref.watch(challengeProgressProvider(challengeId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Challenge Progress', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: progressState.when(
        data: (entries) => entries.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, size: 60, color: Colors.grey[300]),
                    const SizedBox(height: 12),
                    Text('No participants yet', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    Text('Join the challenge to appear here!',
                        style: TextStyle(color: Colors.grey[400], fontSize: 13)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                itemBuilder: (_, i) => _ProgressTile(entry: entries[i], rank: i + 1),
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ProgressTile extends StatelessWidget {
  final ChallengeProgress entry;
  final int rank;
  const _ProgressTile({required this.entry, required this.rank});

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    final isTop3 = rank <= 3;
    final unit = entry.type == 'STEPS' ? 'steps' : 'kcal';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  isTop3 ? medals[rank - 1] : '#$rank',
                  style: const TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 10),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFF6C63FF).withOpacity(0.15),
                child: Text(
                  entry.name[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('@${entry.username}', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${entry.currentProgress} / ${entry.targetValue}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(unit, style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: entry.percentComplete / 100,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(
              entry.percentComplete >= 100 ? Colors.green : const Color(0xFF6C63FF),
            ),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${entry.percentComplete.toInt()}% complete',
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }
}
