import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pathway.dart';

class AssignPathwaysTab extends StatefulWidget {
  final List<Pathway> pathways;
  final VoidCallback onAssignmentComplete;

  const AssignPathwaysTab({
    super.key,
    required this.pathways,
    required this.onAssignmentComplete,
  });

  @override
  State<AssignPathwaysTab> createState() => _AssignPathwaysTabState();
}

class _AssignPathwaysTabState extends State<AssignPathwaysTab> {
  String? _selectedUserId;
  String? _selectedPathwayId;
  bool _isAssigning = false;

  Future<void> _assignPathway() async {
    if (_selectedUserId == null || _selectedPathwayId == null) return;

    setState(() {
      _isAssigning = true;
    });

    try {
      final admin = Supabase.instance.client.auth.currentUser;
      if (admin == null) return;

      // Get pathway
      final pathway = widget.pathways.firstWhere(
        (p) => p.id == _selectedPathwayId,
      );

      // Check if already assigned
    final existing = await Supabase.instance.client
        .from('usr_dept')
        .select()
        .eq('user_id', _selectedUserId!)
        .eq('dept_id', _selectedPathwayId!)
        .maybeSingle();

    if (existing != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Department already assigned to this user'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() => _isAssigning = false);
      return;
    }

    // Assign pathway with questions using RPC function
    await Supabase.instance.client.rpc(
      'assign_pathway_with_questions',
      params: {
        'p_user_id': _selectedUserId,
        'p_dept_id': _selectedPathwayId,
        'p_assigned_by': admin.id,
      },
    );
      // Reset selections
      setState(() {
        _selectedUserId = null;
        _selectedPathwayId = null;
        _isAssigning = false;
      });

      widget.onAssignmentComplete();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isAssigning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Assign Pathway to User',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Selection
                  const Text(
                    'Select User',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<Map<String, dynamic>>>(
                    future: Supabase.instance.client
                        .from('profiles')
                        .select()
                        .eq('role', 'user'),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const CircularProgressIndicator();
                      }
                      final users = snapshot.data!;
                      return DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          hintText: 'Choose a user',
                        ),
                        value: _selectedUserId,
                        items: users.map((user) {
                          return DropdownMenuItem<String>(
                            value: user['user_id']?.toString(),
                            child: Text(
                              user['email']?.toString() ?? 'Unknown',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUserId = value;
                          });
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  // Pathway Selection
                  const Text(
                    'Select Pathway',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: 'Choose a pathway',
                    ),
                    value: _selectedPathwayId,
                    items: widget.pathways.map((pathway) {
                      return DropdownMenuItem<String>(
                        value: pathway.id,
                        child: Text(
                          pathway.title,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPathwayId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 32),
                  // Assign Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: (_selectedUserId != null &&
                              _selectedPathwayId != null &&
                              !_isAssigning)
                          ? _assignPathway
                          : null,
                      icon: _isAssigning
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.assignment_turned_in),
                      label: Text(_isAssigning ? 'Assigning...' : 'Assign Pathway'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3498DB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
