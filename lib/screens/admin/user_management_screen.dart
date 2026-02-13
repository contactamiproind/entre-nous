import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'user_profile_detail_screen.dart';

class UserManagementScreen extends StatefulWidget {
  final VoidCallback? onBack;
  const UserManagementScreen({super.key, this.onBack});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _users = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showAddUserDialog() async {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    String selectedRole = 'user';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New User'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'user', child: Text('User')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (value) {
                    setDialogState(() {
                      selectedRole = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (emailController.text.isEmpty || passwordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all fields')),
                  );
                  return;
                }

                try {
                  // Create user with Supabase Auth
                  final response = await Supabase.instance.client.auth.signUp(
                    email: emailController.text.trim(),
                    password: passwordController.text,
                    emailRedirectTo: null,
                  );

                  if (response.user != null) {
                    // Wait for profile to be created by trigger
                    await Future.delayed(const Duration(milliseconds: 1000));

                    // Update role if needed
                    if (selectedRole != 'user') {
                      await Supabase.instance.client
                          .from('profiles')
                          .update({'role': selectedRole})
                          .eq('user_id', response.user!.id);
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('User created successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadUsers();
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Add User'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditUserDialog(Map<String, dynamic> user) async {
    String selectedRole = user['role'] ?? 'user';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit User'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Email: ${user['email']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'user', child: Text('User')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  setDialogState(() {
                    selectedRole = value!;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await Supabase.instance.client
                      .from('profiles')
                      .update({'role': selectedRole})
                      .eq('user_id', user['user_id']);

                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadUsers();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user['email']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final userId = user['user_id'];

        // 1. Delete end_game_assignments
        await Supabase.instance.client
            .from('end_game_assignments')
            .delete()
            .eq('user_id', userId);

        // 2. Delete user progress (must be before usr_dept due to FK)
        await Supabase.instance.client
            .from('usr_progress')
            .delete()
            .eq('user_id', userId);

        // 3. Delete department assignments
        await Supabase.instance.client
            .from('usr_dept')
            .delete()
            .eq('user_id', userId);

        // 4. Delete profile
        await Supabase.instance.client
            .from('profiles')
            .delete()
            .eq('user_id', userId);

        // 5. Delete auth account via admin RPC (if available)
        try {
          await Supabase.instance.client.rpc(
            'delete_user_auth',
            params: {'target_user_id': userId},
          );
        } catch (authErr) {
          // RPC may not exist yet — log but don't fail the whole operation
          debugPrint('Auth deletion skipped (RPC not available): $authErr');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User and all associated data deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadUsers();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting user: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF9E6), // Very light yellow
              Color(0xFFF4EF8B), // Main yellow #f4ef8b
              Color(0xFFE8D96F), // Darker yellow
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                InkWell(
                  onTap: widget.onBack,
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.arrow_back, size: 20, color: Color(0xFF1A2F4B)),
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'User Management',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A2F4B),
                    ),
                  ),
                ),
                SizedBox(
                  height: 32,
                  width: 32,
                  child: FloatingActionButton(
                    onPressed: _showAddUserDialog,
                    backgroundColor: const Color(0xFF3B82F6),
                    elevation: 2,
                    child: const Icon(Icons.person_add, color: Colors.white, size: 16),
                  ),
                ),
              ],
            ),
          ),
          // Users List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                    ? Center(
                        child: Text(
                          'No users found',
                          style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadUsers,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          itemCount: _users.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final user = _users[index];
                            final isAdmin = user['role'] == 'admin';
                            final email = user['email'] ?? 'No email';
                            final level = user['level'] as int? ?? 1;
                            
                            return Card(
                              margin: EdgeInsets.zero,
                              elevation: 0.5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserProfileDetailScreen(
                                        userId: user['user_id'],
                                        userEmail: email,
                                      ),
                                    ),
                                  );
                                  _loadUsers();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  child: Row(
                                    children: [
                                      // Avatar
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: isAdmin
                                            ? const Color(0xFFF08A7E).withOpacity(0.15)
                                            : const Color(0xFF6BCB9F).withOpacity(0.15),
                                        child: Icon(
                                          isAdmin ? Icons.admin_panel_settings : Icons.person,
                                          size: 16,
                                          color: isAdmin
                                              ? const Color(0xFFF08A7E)
                                              : const Color(0xFF6BCB9F),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Email + badges
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              email,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                                color: Color(0xFF1A2F4B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              children: [
                                                // Role badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: isAdmin
                                                        ? const Color(0xFFF08A7E).withOpacity(0.12)
                                                        : const Color(0xFF6BCB9F).withOpacity(0.12),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    isAdmin ? 'Admin' : 'User',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w700,
                                                      color: isAdmin
                                                          ? const Color(0xFFF08A7E)
                                                          : const Color(0xFF6BCB9F),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                // Level badge
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF1A2F4B).withOpacity(0.08),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    'Level $level',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: Color(0xFF1A2F4B),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Action buttons
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () => _showEditUserDialog(user),
                                            borderRadius: BorderRadius.circular(12),
                                            child: const Padding(
                                              padding: EdgeInsets.all(6),
                                              child: Icon(Icons.edit_outlined, size: 16, color: Colors.blue),
                                            ),
                                          ),
                                          const SizedBox(width: 2),
                                          InkWell(
                                            onTap: () => _deleteUser(user),
                                            borderRadius: BorderRadius.circular(12),
                                            child: Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade400),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Chevron
                                      Icon(Icons.chevron_right, size: 16, color: Colors.grey[400]),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
