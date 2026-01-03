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
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.asset(
            'assets/logo.png',
            fit: BoxFit.contain,
          ),
        ),
        title: Text(widget.pathwayName),
        backgroundColor: color,
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
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        color.withOpacity(0.1),
                        Colors.white,
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
                                          value: _getCurrentLevel() / _levels.length,
                                          backgroundColor: Colors.grey[300],
                                          valueColor: AlwaysStoppedAnimation<Color>(color),
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
                                final isUnlocked = _isLevelUnlocked(levelNumber);
                                final isCurrent = levelNumber == _getCurrentLevel();

                                return _LevelCard(
                                  level: level,
                                  isUnlocked: isUnlocked,
                                  isCurrent: isCurrent,
                                  color: color,
                                  onTap: isUnlocked
                                      ? () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => QuizScreen(
                                                level: level,
                                                pathwayName: widget.pathwayName,
                                                pathwayId: widget.pathwayId,
                                              ),
                                            ),
                                          );
                                          // Refresh progress if quiz was completed
                                          if (result == true && mounted) {
                                            _loadDepartmentData();
                                          }
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
          selectedItemColor: const Color(0xFF1A2F4B),
          unselectedItemColor: const Color(0xFF1A2F4B).withOpacity(0.4),
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
  final Color color;
  final VoidCallback? onTap;

  const _LevelCard({
    required this.level,
    required this.isUnlocked,
    required this.isCurrent,
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
                    child: isUnlocked
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
                      if (isCurrent)
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
                if (isUnlocked)
                  Icon(
                    isCurrent ? Icons.play_circle_filled : Icons.check_circle,
                    color: color,
                    size: 32,
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
