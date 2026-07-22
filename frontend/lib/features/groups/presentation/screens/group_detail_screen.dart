import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/group_provider.dart';
import '../../domain/group_models.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import 'chat_tab.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  final int groupId;
  const GroupDetailScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_tabController.index == 1) {
        ref.invalidate(leaderboardProvider(widget.groupId));
      } else if (_tabController.index == 2) {
        ref.invalidate(challengesProvider(widget.groupId));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final groups = ref.watch(myGroupsProvider).value ?? [];
    final group = groups.where((g) => g.id == widget.groupId).firstOrNull;
    final sortBy = ref.watch(leaderboardSortProvider);
    final leaderboard = ref.watch(leaderboardProvider(widget.groupId));
    final challenges = ref.watch(challengesProvider(widget.groupId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: Text(group?.name ?? 'Group', style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF6C63FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF6C63FF),
          tabs: const [
            Tab(text: 'Chat', icon: Icon(Icons.chat, size: 18)),
            Tab(text: 'Leaderboard', icon: Icon(Icons.leaderboard, size: 18)),
            Tab(text: 'Challenges', icon: Icon(Icons.flag, size: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_chart),
            tooltip: 'Create Challenge',
            onPressed: () async {
              await context.push('/groups/${widget.groupId}/challenge');
              ref.invalidate(challengesProvider(widget.groupId));
            },
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // CHAT TAB
          ChatTab(groupId: widget.groupId),

          // LEADERBOARD TAB
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(leaderboardProvider(widget.groupId));
              ref.invalidate(myGroupsProvider);
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'total', label: Text('All-Time'), icon: Icon(Icons.star)),
                      ButtonSegment(value: 'today', label: Text("Today"), icon: Icon(Icons.today)),
                    ],
                    selected: {sortBy},
                    onSelectionChanged: (val) {
                      ref.read(leaderboardSortProvider.notifier).set(val.first);
                      ref.invalidate(leaderboardProvider(widget.groupId));
                    },
                  ),
                ),
                Expanded(
                  child: leaderboard.when(
                    data: (entries) {
                      if (entries.isEmpty) {
                        return ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 100),
                            Center(
                              child: Text(
                                'No steps logged yet.',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ),
                          ],
                        );
                      }
                      
                      final skippedEntries = entries.skip(3).toList();
                      
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          _LeaderboardPodium(entries: entries, sortBy: sortBy),
                          if (skippedEntries.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'All Rankings',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3142),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(
                              skippedEntries.length,
                              (index) => _LeaderboardTile(
                                entry: skippedEntries[index],
                                sortBy: sortBy,
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Error: $e')),
                  ),
                ),
              ],
            ),
          ),

          // CHALLENGES TAB
          RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(challengesProvider(widget.groupId));
            },
            child: challenges.when(
              data: (list) => list.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 100),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.flag_outlined, size: 60, color: Colors.grey[300]),
                              const SizedBox(height: 12),
                              Text('No challenges yet', style: TextStyle(color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  await context.push('/groups/${widget.groupId}/challenge');
                                  ref.invalidate(challengesProvider(widget.groupId));
                                },
                                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                                child: const Text('Create First Challenge', style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _ChallengeTile(challenge: list[i], groupId: widget.groupId),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardPodium extends StatelessWidget {
  final List<LeaderboardEntry> entries;
  final String sortBy;

  const _LeaderboardPodium({required this.entries, required this.sortBy});

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();

    final first = entries.length >= 1 ? entries[0] : null;
    final second = entries.length >= 2 ? entries[1] : null;
    final third = entries.length >= 3 ? entries[2] : null;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Silver)
          if (second != null)
            Expanded(child: _buildPodiumPillar(context, second, 2, 75, const [Color(0xFFE2E2E2), Color(0xFFB5B5B5)], sortBy))
          else
            const Expanded(child: SizedBox.shrink()),

          const SizedBox(width: 8),

          // 1st Place (Gold)
          if (first != null)
            Expanded(child: _buildPodiumPillar(context, first, 1, 105, const [Color(0xFFFFD93D), Color(0xFFFF9F29)], sortBy))
          else
            const Expanded(child: SizedBox.shrink()),

          const SizedBox(width: 8),

          // 3rd Place (Bronze)
          if (third != null)
            Expanded(child: _buildPodiumPillar(context, third, 3, 60, const [Color(0xFFFFB37C), Color(0xFFD67229)], sortBy))
          else
            const Expanded(child: SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _buildPodiumPillar(
    BuildContext context,
    LeaderboardEntry entry,
    int rank,
    double height,
    List<Color> colors,
    String sortBy,
  ) {
    final steps = sortBy == 'today' ? entry.todaySteps : entry.totalSteps;
    final double avatarSize = rank == 1 ? 26 : 22;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Crown icon on 1st place
        if (rank == 1)
          const Icon(Icons.workspace_premium, color: Color(0xFFFFD700), size: 24)
        else
          const SizedBox(height: 24),
          
        const SizedBox(height: 4),

        // Glowing Avatar
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: colors[0],
              width: rank == 1 ? 3 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: colors[0].withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: avatarSize,
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
            child: Text(
              entry.name[0].toUpperCase(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: rank == 1 ? 16 : 14,
                color: const Color(0xFF6C63FF),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // User Name
        Text(
          entry.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        
        // Steps count
        Text(
          '$steps steps',
          style: TextStyle(
            fontSize: 11,
            color: const Color(0xFF6C63FF),
            fontWeight: rank == 1 ? FontWeight.bold : FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),

        // The Pillar
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: [
              BoxShadow(
                color: colors[1].withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LeaderboardTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final String sortBy;
  const _LeaderboardTile({required this.entry, required this.sortBy});

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    final medals = ['🥇', '🥈', '🥉'];
    final steps = sortBy == 'today' ? entry.todaySteps : entry.totalSteps;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isTop3 ? const Color(0xFF6C63FF).withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isTop3
            ? Border.all(color: const Color(0xFF6C63FF).withOpacity(0.2))
            : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              isTop3 ? medals[entry.rank - 1] : '#${entry.rank}',
              style: TextStyle(fontSize: isTop3 ? 22 : 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF6C63FF).withOpacity(0.15),
            child: Text(
              entry.name[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
            ),
          ),
          const SizedBox(width: 12),
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
              Text('$steps',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                      color: Color(0xFF6C63FF))),
              Text('steps', style: TextStyle(fontSize: 11, color: Colors.grey[400])),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeTile extends ConsumerWidget {
  final Challenge challenge;
  final int groupId;
  const _ChallengeTile({required this.challenge, required this.groupId});

  String _getRemainingTime(String endDateStr) {
    try {
      final endDate = DateTime.parse(endDateStr);
      final now = DateTime.now();
      final difference = endDate.difference(now);

      if (difference.isNegative) {
        return 'Ended';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d left';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h left';
      } else {
        return '${difference.inMinutes}m left';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isActive = challenge.status == 'ACTIVE';
    final profile = ref.watch(profileProvider).value;
    final progressAsync = ref.watch(challengeProgressProvider(challenge.id));

    final userProgress = progressAsync.whenOrNull(
      data: (list) => list.where((p) => p.username == profile?.username).firstOrNull,
    );

    final isJoined = userProgress != null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push('/challenges/${challenge.id}'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: challenge.type == 'STEPS'
                          ? const Color(0xFF6C63FF).withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      challenge.type == 'STEPS' ? Icons.directions_walk : Icons.local_fire_department,
                      color: challenge.type == 'STEPS' ? const Color(0xFF6C63FF) : Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(challenge.title,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
                        if (isActive) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.timer_outlined, size: 12, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                _getRemainingTime(challenge.endDate),
                                style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      challenge.status,
                      style: TextStyle(
                          fontSize: 10,
                          color: isActive ? Colors.green.shade700 : Colors.grey,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              if (challenge.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(challenge.description,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
              const SizedBox(height: 14),
              
              Row(
                children: [
                  Icon(Icons.flag, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text(
                    'Goal: ${challenge.targetValue} ${challenge.type == 'STEPS' ? 'steps' : 'kcal'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                  const Spacer(),
                  Icon(Icons.people, size: 14, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('${challenge.participantCount} joined',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                ],
              ),

              if (isJoined) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Progress: ${userProgress.currentProgress} / ${userProgress.targetValue}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                    ),
                    Text(
                      '${userProgress.percentComplete.toInt()}%',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6C63FF)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: userProgress.percentComplete / 100,
                    backgroundColor: const Color(0xFFF5F7FB),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      userProgress.percentComplete >= 100 ? Colors.green : const Color(0xFF6C63FF),
                    ),
                    minHeight: 6,
                  ),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 4),
                  Text('${challenge.startDate} → ${challenge.endDate}',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400])),
                  const Spacer(),
                  if (isJoined)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFFFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF48CFAD).withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Color(0xFF48CFAD), size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Joined',
                            style: TextStyle(color: Color(0xFF48CFAD), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    )
                  else
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        backgroundColor: const Color(0xFFF0EFFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        try {
                          await ref
                              .read(challengesMutationProvider.notifier)
                              .joinChallenge(challenge.id, groupId);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Joined challenge!'), backgroundColor: Colors.green));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                          }
                        }
                      },
                      child: const Text('Join', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
