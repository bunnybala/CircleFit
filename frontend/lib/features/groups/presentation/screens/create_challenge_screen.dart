import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/group_provider.dart';

class ChallengeTemplate {
  final String title;
  final String description;
  final String type;
  final int targetValue;
  final int durationDays;
  final IconData icon;
  final Color color;

  const ChallengeTemplate({
    required this.title,
    required this.description,
    required this.type,
    required this.targetValue,
    required this.durationDays,
    required this.icon,
    required this.color,
  });
}

const List<ChallengeTemplate> _templates = [
  ChallengeTemplate(
    title: '10K Steps Daily',
    description: 'Maintain an active routine by hitting 70,000 steps over a week!',
    type: 'STEPS',
    targetValue: 70000,
    durationDays: 7,
    icon: Icons.directions_walk,
    color: Color(0xFF6C63FF),
  ),
  ChallengeTemplate(
    title: 'Calorie Crusher',
    description: 'Burn 3,000 kcal through active tracking and workouts.',
    type: 'CALORIES',
    targetValue: 3000,
    durationDays: 5,
    icon: Icons.local_fire_department,
    color: Colors.orange,
  ),
  ChallengeTemplate(
    title: 'Weekend Warrior',
    description: 'Push your limits over the weekend with a 25,000 step challenge.',
    type: 'STEPS',
    targetValue: 25000,
    durationDays: 2,
    icon: Icons.bolt,
    color: Colors.amber,
  ),
  ChallengeTemplate(
    title: 'Active Lifestyle',
    description: 'Keep the flame going by burning 6,000 kcal over 10 days.',
    type: 'CALORIES',
    targetValue: 6000,
    durationDays: 10,
    icon: Icons.fitness_center,
    color: Colors.pink,
  ),
  ChallengeTemplate(
    title: 'Marathon Steps Prep',
    description: 'Prepare your endurance with 120,000 steps over 2 weeks.',
    type: 'STEPS',
    targetValue: 120000,
    durationDays: 14,
    icon: Icons.directions_run,
    color: Colors.teal,
  ),
];

class CreateChallengeScreen extends ConsumerStatefulWidget {
  final int groupId;
  const CreateChallengeScreen({super.key, required this.groupId});

  @override
  ConsumerState<CreateChallengeScreen> createState() => _CreateChallengeScreenState();
}

class _CreateChallengeScreenState extends ConsumerState<CreateChallengeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  String _type = 'STEPS';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to force live preview rebuilds
    _titleCtrl.addListener(_onFieldChanged);
    _descCtrl.addListener(_onFieldChanged);
    _targetCtrl.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _titleCtrl.removeListener(_onFieldChanged);
    _descCtrl.removeListener(_onFieldChanged);
    _targetCtrl.removeListener(_onFieldChanged);
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  void _applyTemplate(ChallengeTemplate template) {
    setState(() {
      _titleCtrl.text = template.title;
      _descCtrl.text = template.description;
      _targetCtrl.text = template.targetValue.toString();
      _type = template.type;
      _startDate = DateTime.now();
      _endDate = DateTime.now().add(Duration(days: template.durationDays));
    });
  }

  Widget _buildLivePreview() {
    final titleText = _titleCtrl.text.isEmpty ? 'Your Challenge Title' : _titleCtrl.text;
    final descText = _descCtrl.text.isEmpty ? 'Short description of your fitness goals...' : _descCtrl.text;
    final targetVal = int.tryParse(_targetCtrl.text) ?? 0;
    final unit = _type == 'STEPS' ? 'steps' : 'kcal';
    final days = _endDate.difference(_startDate).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _type == 'STEPS'
              ? [const Color(0xFF6C63FF).withOpacity(0.08), const Color(0xFF8E87FF).withOpacity(0.02)]
              : [Colors.orange.withOpacity(0.08), Colors.deepOrange.withOpacity(0.02)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _type == 'STEPS'
              ? const Color(0xFF6C63FF).withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (_type == 'STEPS' ? const Color(0xFF6C63FF) : Colors.orange).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _type == 'STEPS'
                        ? const Color(0xFF6C63FF).withOpacity(0.15)
                        : Colors.orange.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _type == 'STEPS' ? Icons.directions_walk : Icons.local_fire_department,
                    color: _type == 'STEPS' ? const Color(0xFF6C63FF) : Colors.orange,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3142),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.timer_outlined, size: 13, color: Colors.orange),
                          const SizedBox(width: 4),
                          Text(
                            days <= 0 ? 'Ends today' : '$days days duration',
                            style: const TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F7FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF1890FF).withOpacity(0.2)),
                  ),
                  child: const Text(
                    'LIVE PREVIEW',
                    style: TextStyle(
                      fontSize: 9,
                      color: Color(0xFF1890FF),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              descText,
              style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(Icons.flag_rounded, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  'Goal: $targetVal $unit',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Icon(Icons.people_alt_rounded, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(
                  '1 joined',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresets() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 16, color: Color(0xFF6C63FF)),
            const SizedBox(width: 6),
            const Text(
              'Select a Preset Template',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final template = _templates[index];
              final isSelected = _titleCtrl.text == template.title && _type == template.type;
              return GestureDetector(
                onTap: () => _applyTemplate(template),
                child: Container(
                  width: 170,
                  margin: const EdgeInsets.only(right: 12, bottom: 4),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF6C63FF) : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Icon(template.icon, color: template.color, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              template.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, overflow: TextOverflow.ellipsis),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${template.targetValue} ${template.type == 'STEPS' ? 'steps' : 'kcal'} • ${template.durationDays}d',
                        style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        title: const Text('Create Challenge', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLivePreview(),
              _buildPresets(),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 20),
              
              _label('Challenge Title'),
              _field(_titleCtrl, 'e.g. 10K Steps Daily'),

              const SizedBox(height: 16),
              _label('Description (optional)'),
              TextFormField(
                controller: _descCtrl,
                maxLines: 2,
                decoration: _inputDec('Short description of the challenge'),
              ),

              const SizedBox(height: 16),
              _label('Type'),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: _type == 'STEPS' ? const Color(0xFF6C63FF) : Colors.orange,
                    selectedForegroundColor: Colors.white,
                  ),
                  segments: const [
                    ButtonSegment(value: 'STEPS', label: Text('Steps'), icon: Icon(Icons.directions_walk)),
                    ButtonSegment(value: 'CALORIES', label: Text('Calories'), icon: Icon(Icons.local_fire_department)),
                  ],
                  selected: {_type},
                  onSelectionChanged: (v) {
                    setState(() {
                      _type = v.first;
                      // Adjust default preset target value if empty
                      if (_targetCtrl.text.isEmpty) {
                        _targetCtrl.text = _type == 'STEPS' ? '70000' : '3000';
                      }
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),
              _label('Target (${_type == 'STEPS' ? 'steps' : 'kcal'})'),
              TextFormField(
                controller: _targetCtrl,
                keyboardType: TextInputType.number,
                decoration: _inputDec(_type == 'STEPS' ? 'e.g. 70000' : 'e.g. 3000'),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final parsed = int.tryParse(v);
                  if (parsed == null) return 'Must be a number';
                  if (parsed <= 0) return 'Must be greater than 0';
                  return null;
                },
              ),

              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _datePicker('Start Date', _startDate, (d) => setState(() => _startDate = d))),
                  const SizedBox(width: 12),
                  Expanded(child: _datePicker('End Date', _endDate, (d) => setState(() => _endDate = d))),
                ],
              ),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == 'STEPS' ? const Color(0xFF6C63FF) : Colors.orange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                    shadowColor: (_type == 'STEPS' ? const Color(0xFF6C63FF) : Colors.orange).withOpacity(0.3),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Create Challenge',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2D3142))),
      );

  Widget _field(TextEditingController ctrl, String hint) => TextFormField(
        controller: ctrl,
        decoration: _inputDec(hint),
        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
      );

  InputDecoration _inputDec(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: _type == 'STEPS' ? const Color(0xFF6C63FF) : Colors.orange,
            width: 1.5,
          ),
        ),
      );

  Widget _datePicker(String label, DateTime date, Function(DateTime) onChanged) => GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: date,
            firstDate: DateTime.now().subtract(const Duration(days: 30)),
            lastDate: DateTime.now().add(const Duration(days: 365)),
          );
          if (picked != null) onChanged(picked);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.calendar_month_rounded, size: 14, color: _type == 'STEPS' ? const Color(0xFF6C63FF) : Colors.orange),
                  const SizedBox(width: 6),
                  Text('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF2D3142))),
                ],
              ),
            ],
          ),
        ),
      );

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate dates
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: End Date cannot be before Start Date.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await ref.read(challengesMutationProvider.notifier).createChallenge(
            groupId: widget.groupId,
            title: _titleCtrl.text.trim(),
            description: _descCtrl.text.trim(),
            type: _type,
            targetValue: int.parse(_targetCtrl.text.trim()),
            startDate: _fmt(_startDate),
            endDate: _fmt(_endDate),
          );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _loading = false);
    }
  }
}
