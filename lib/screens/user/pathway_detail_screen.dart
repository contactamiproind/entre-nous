import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'my_departments_screen.dart';
import 'quiz_screen.dart';

class DepartmentDetailScreen extends StatefulWidget {
  final String pathwayId;
  final String pathwayName;

  const DepartmentDetailScreen({
    super.key,
    required this.pathwayId,
    required this.pathwayName,
  });

  @override
  State<DepartmentDetailScreen> createState() => _DepartmentDetailScreenState();
}

class _DepartmentDetailScreenState extends State<DepartmentDetailScreen> {
  List<Map<String, dynamic>> _levels = [];
  Map<String, dynamic>? _userProgress;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDepartmentData();
  }

  Future<void> _loadDepartmentData() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      // Load department with levels from JSONB column
      final deptResponse = await Supabase.instance.client
          .from('departments')
          .select('levels')
          .eq('id', widget.pathwayId)
          .single();

      // Extract levels from JSONB
      List<Map<String, dynamic>> levels = [];
      if (deptResponse['levels'] != null) {
        final levelsJson = deptResponse['levels'] as List;
        for (int i = 0; i < levelsJson.length; i++) {
          final level = levelsJson[i] as Map<String, dynamic>;
          levels.add({
            'id': '${widget.pathwayId}_level_$i', // Generate unique ID
            'level_number': i + 1,
            'level_name': level['name'] ?? 'Level ${i + 1}',
            'title': level['name'] ?? 'Level ${i + 1}',
            'description': level['description'] ?? '',
            'required_score': level['required_score'] ?? 0,
          });
        }
      }

      debugPrint('🔍 Loaded ${levels.length} levels from departments.levels JSONB');

      // Load user progress for this specific pathway
      final progressResponse = await Supabase.instance.client
          .from('usr_dept')
          .select()
          .eq('user_id', user.id)
          .eq('dept_id', widget.pathwayId)
          .maybeSingle();

      setState(() {
        _levels = levels;
        _userProgress = progressResponse;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ ERROR loading pathway data: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  int _getCurrentLevel() {
    if (_userProgress == null) return 1;
    return _userProgress!['current_level'] ?? 1;
  }

  bool _isLevelUnlocked(int levelNumber) {
    return levelNumber <= _getCurrentLevel();
  }

  Color _getDepartmentColor() {
    switch (widget.pathwayName.toLowerCase()) {
      case 'communication':
        return Colors.blue;
      case 'creative':
        return Colors.purple;
      case 'ideation':
        return Colors.orange;
      case 'production':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getDepartmentColor();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.pathwayName, style: const TextStyle(color: Colors.white)),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard),
            tooltip: 'My Departments',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyDepartmentsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadDepartmentData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF6EC1E4), // Light blue
                        Color(0xFF9BA8E8), // Purple-blue
                        Color(0xFFE8A8D8), // Pink
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress indicator
                          Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Your Progress',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: LinearProgressIndicator(
                                          value: _levels.isEmpty ? 0.0 : _getCurrentLevel() / _levels.length,
                                          backgroundColor: Colors.white.withOpacity(0.3),
                                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24)),
                                          minHeight: 8,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Level ${_getCurrentLevel()}/${_levels.length}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Levels',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Levels list
                          Expanded(
                            child: ListView.builder(
                              itemCount: _levels.length,
                              itemBuilder: (context, index) {
                                final level = _levels[index];
                                final levelNumber = level['level_number'];
                                final currentLevel = _getCurrentLevel();
                                final isUnlocked = _isLevelUnlocked(levelNumber);
                                final isCurrent = levelNumber == currentLevel;
                                final isCompleted = levelNumber < currentLevel;

                                return _LevelCard(
                                  level: level,
                                  isUnlocked: isUnlocked,
                                  isCurrent: isCurrent,
                                  isCompleted: isCompleted,
                                  color: color,
                                  onTap: isUnlocked
                                      ? () async {
                                          // Add usr_dept_id to level before navigating
                                          final levelWithUsrDeptId = {
                                            ...level,
                                            'usr_dept_id': _userProgress?['id'],
                                            'dept_id': widget.pathwayId,
                                          };
                                          
                                          // TODO: Update to use category-based navigation
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Please use the new category-based navigation from the home screen'),
                                            ),
                                          );
                                          
                                          /* OLD CODE - TO BE REMOVED
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => QuizScreen(
                                                level: levelWithUsrDeptId,
                                                pathwayName: widget.pathwayName,
                                                pathwayId: widget.pathwayId,
                                              ),
                                            ),
                                          );
                                          */
                                          // Refresh progress if quiz was completed
                                          /* OLD CODE
                                          if (result == true && mounted) {
                                            _loadDepartmentData();
                                          }
                                          */
                                        }
                                      : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A2F4B).withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 1, // Pathway tab is selected
          onTap: (index) {
            if (index == 1) {
              // Already on pathway detail, do nothing
              return;
            }
            // Navigate back to dashboard with selected tab
            Navigator.pop(context, index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF8B5CF6),
          unselectedItemColor: const Color(0xFF8B5CF6).withOpacity(0.4),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_rounded),
              label: 'Department',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.info_rounded),
              label: 'Info',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final Map<String, dynamic> level;
  final bool isUnlocked;
  final bool isCurrent;
  final bool isCompleted;
  final Color color;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
    required this.isCompleted,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrent ? 8 : 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isCurrent
                ? Border.all(color: color, width: 2)
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Level icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isUnlocked ? color.withOpacity(0.2) : Colors.grey[300],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: isCompleted
                        ? Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 32,
                          )
                        : isUnlocked
                            ? Text(
                                '${level['level_number']}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              )
                            : const Icon(
                                Icons.lock,
                                color: Colors.grey,
                              ),
                  ),
                ),
                const SizedBox(width: 16),
                // Level info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        level['title'] ?? level['level_name'] ?? 'Level ${level['level_number']}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isUnlocked ? Colors.black : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level['description'] ?? 'Complete this level to unlock the next',
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnlocked ? Colors.grey[600] : Colors.grey[400],
                        ),
                      ),
                      if (isCompleted)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Completed',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isCurrent)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Current Level',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                // Action button
                if (isCompleted)
                  const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 32,
                  )
                else if (isCurrent)
                  Icon(
                    Icons.play_circle_filled,
                    color: color,
                    size: 32,
                  )
                else if (isUnlocked)
                  Icon(
                    Icons.arrow_forward_ios,
                    color: color,
                    size: 24,
                  )
                else
                  const Icon(
                    Icons.lock,
                    color: Colors.grey,
                    size: 32,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
