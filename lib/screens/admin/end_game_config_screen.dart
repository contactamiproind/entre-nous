import 'package:flutter/material.dart';
import 'dart:convert';
import '../../models/end_game_config.dart';
import '../../services/end_game_service.dart';
import '../../services/end_game_config_loader.dart';
import 'end_game_visual_editor.dart';

class EndGameConfigScreen extends StatefulWidget {
  final VoidCallback? onBack;
  
  const EndGameConfigScreen({super.key, this.onBack});

  @override
  State<EndGameConfigScreen> createState() => _EndGameConfigScreenState();
}

class _EndGameConfigScreenState extends State<EndGameConfigScreen> with SingleTickerProviderStateMixin {
  final EndGameService _service = EndGameService();
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  
  // Form fields
  final TextEditingController _nameController = TextEditingController();
  int _selectedLevel = 1;
  bool _isActive = false;
  
  // Venue & Items data (simplified JSON editing)
  final TextEditingController _venueJsonController = TextEditingController();
  final TextEditingController _itemsJsonController = TextEditingController();
  
  // User assignments
  List<Map<String, dynamic>> _allUsers = [];
  List<String> _selectedUserIds = [];
  
  // Current config
  String? _currentConfigId;
  List<Map<String, dynamic>> _allConfigs = [];
  VenueConfig? _currentVenue;
  ItemsConfig? _itemsConfig;
  
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _venueJsonController.dispose();
    _itemsJsonController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshConfigList() async {
    try {
      final configs = await _service.loadAllConfigs();
      setState(() {
        _allConfigs = configs;
      });
    } catch (e) {
      debugPrint('Error refreshing config list: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Load all configs
      await _refreshConfigList();
      
      // Load all users
      final users = await _service.loadAllUsers();
      
      // Load default venue and items from JSON as template
      final venue = await EndGameConfigLoader.loadActiveVenue();
      final items = await EndGameConfigLoader.loadItems();
      
      const encoder = JsonEncoder.withIndent('  ');
      
      setState(() {
        _allUsers = users;
        _currentVenue = venue;
        _itemsConfig = items;
        _venueJsonController.text = encoder.convert(venue.toJson());
        _itemsJsonController.text = encoder.convert(items.toJson());
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _loadConfig(String id) async {
    try {
      final config = await _service.loadConfigById(id);
      if (config == null) return;
      
      final assignedUsers = await _service.getAssignedUsers(id);
      
      const encoder = JsonEncoder.withIndent('  ');
      
      setState(() {
        _currentConfigId = id;
        _nameController.text = config['name'] ?? '';
        _selectedLevel = config['level'] ?? 1;
        _isActive = config['is_active'] ?? false;
        _venueJsonController.text = encoder.convert(config['venue_data']);
        _itemsJsonController.text = encoder.convert(config['items_data']);
        _selectedUserIds = assignedUsers;
        _currentVenue = VenueConfig.fromJson(config['venue_data']);
      });
      
      // Switch to editor tab if on mobile
      if (_tabController.index != 1) {
        _tabController.animateTo(1);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading config: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSaving = true);
    
    try {
      // Parse JSON
      final venueData = json.decode(_venueJsonController.text) as Map<String, dynamic>;
      final itemsData = json.decode(_itemsJsonController.text) as Map<String, dynamic>;
      
      // Save config
      final id = await _service.saveConfig(
        id: _currentConfigId,
        name: _nameController.text,
        level: _selectedLevel,
        venueData: venueData,
        itemsData: itemsData,
        isActive: _isActive,
      );
      
      // Assign to users
      await _service.assignToUsers(id, _selectedUserIds);
      
      // If set as active, update the active flag
      if (_isActive) {
        await _service.setActiveConfig(id);
      }
      
      setState(() => _isSaving = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuration saved successfully!'), backgroundColor: Colors.green),
        );
      }
      
      // Reload configs list only (preserve current editor state)
      await _refreshConfigList();
      
      // Update current ID if this was a new save
      setState(() {
         if (_currentConfigId == null) {
            _currentConfigId = id;
         }
      });
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _newConfig() {
    setState(() {
      _currentConfigId = null;
      _nameController.clear();
      _selectedLevel = 1;
      _isActive = false;
      _selectedUserIds = [];
      
      // Reset to empty venue
      _currentVenue = VenueConfig(
        id: 'new_${DateTime.now().millisecondsSinceEpoch}',
        name: 'New Venue',
        description: '',
        zones: [],
        placements: [],
      );
      
      const encoder = JsonEncoder.withIndent('  ');
      _venueJsonController.text = encoder.convert(_currentVenue!.toJson());
      if (_itemsConfig != null) {
        _itemsJsonController.text = encoder.convert(_itemsConfig!.toJson());
      }
    });
    
    // Switch to editor tab if on mobile
    if (_tabController.index != 1) {
      _tabController.animateTo(1);
    }
  } // End of _newConfig

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('End Game Configuration'),
        ),
        leading: widget.onBack != null
            ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack)
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _newConfig,
            tooltip: 'New Configuration',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  // Desktop / Tablet Landscape: 3-column layout
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left panel: Config list
                      SizedBox(
                        width: 280,
                        child: _buildConfigList(),
                      ),
                      
                      // Middle panel: Form
                      Expanded(
                        child: _buildForm(),
                      ),
                      
                      // Right panel: Preview  
                      Expanded(
                        child: _buildPreview(),
                      ),
                    ],
                  );
                } else {
                  // Mobile / Tablet Portrait: Tabbed layout
                  return Column(
                    children: [
                      Container(
                        color: Colors.blue[700],
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: Colors.white,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white70,
                          tabs: const [
                            Tab(icon: Icon(Icons.list), text: 'Configs'),
                            Tab(icon: Icon(Icons.edit), text: 'Editor'),
                            Tab(icon: Icon(Icons.visibility), text: 'Preview'),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildConfigList(),
                            _buildForm(),
                            _buildPreview(),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
    );
  }

  Widget _buildConfigList() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9C4), // Yellow theme
        border: Border(right: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                const Icon(Icons.list, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Configurations',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _allConfigs.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No configurations yet.\nClick + to create one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _allConfigs.length,
                    itemBuilder: (context, index) {
                      final config = _allConfigs[index];
                      final isSelected = config['id'] == _currentConfigId;
                      
                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[50] : null,
                          border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: ListTile(
                          selected: isSelected,
                          selectedTileColor: Colors.blue[50],
                          title: Text(
                            config['name'] ?? 'Unnamed',
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text('Level ${config['level']}'),
                          trailing: config['is_active'] == true
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                )
                              : null,
                          onTap: () => _loadConfig(config['id']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      color: const Color(0xFFFFF9C4), // Yellow theme
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                _currentConfigId == null ? 'New Configuration' : 'Edit Configuration',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Divider(height: 32),
              
              // Basic Info Section
              const Text(
                'Basic Information',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Configuration Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
            
            // Level
            DropdownButtonFormField<int>(
              value: _selectedLevel,
              decoration: const InputDecoration(
                labelText: 'Level',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 1, child: Text('Level 1 (Easy)')),
                DropdownMenuItem(value: 2, child: Text('Level 2 (Medium)')),
                DropdownMenuItem(value: 3, child: Text('Level 3 (Hard)')),
                DropdownMenuItem(value: 4, child: Text('Level 4 (Expert)')),
              ],
              onChanged: (v) => setState(() => _selectedLevel = v!),
            ),
            const SizedBox(height: 16),
            
            // Active checkbox
            CheckboxListTile(
              title: const Text('Set as Active Configuration'),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v!),
            ),
            const SizedBox(height: 24),
            
              // Visual Editor
            const Divider(),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                const Text(
                  'Venue & Items Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _showAddItemDialog,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Element', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero, 
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (_currentVenue != null)
              SizedBox(
                height: 950, // Increased height to match taller visual editor
                child: EndGameVisualEditor(
                  initialVenue: _currentVenue!,
                  itemConfig: _itemsConfig,
                  onUpdate: (updatedVenue, updatedItems) {
                     // We update the local state. updatedItems is List<ItemConfig>.
                     // We need to sync this back to _itemsConfig if items order changed?
                     // Currently Editor only changes Venue (Placement).
                     // But if we wanted to re-order items, we might need this.
                     
                     _currentVenue = updatedVenue;
                     const encoder = JsonEncoder.withIndent('  ');
                     _venueJsonController.text = encoder.convert(updatedVenue.toJson());
                  },
                ),
              ),
            const SizedBox(height: 24),

            // User Assignment Section
            const Divider(),
            const Text(
              'User Assignments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Select which users should see this End Game configuration',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ListView.builder(
                itemCount: _allUsers.length,
                itemBuilder: (context, index) {
                  final user = _allUsers[index];
                  final userId = user['user_id'];
                  final isSelected = _selectedUserIds.contains(userId);
                  
                  return CheckboxListTile(
                    title: Text(user['full_name'] ?? user['email'] ?? 'Unknown'),
                    subtitle: Text(user['email'] ?? ''),
                    value: isSelected,
                    onChanged: (v) {
                      setState(() {
                        if (v!) {
                          _selectedUserIds.add(userId);
                        } else {
                          _selectedUserIds.remove(userId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            
            // Save button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveConfig,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text('Save Configuration'),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildPreview() {
    return Container(
      color: Colors.grey[50],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
            ),
            child: const Row(
              children: [
                Icon(Icons.visibility, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Venue Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _currentVenue == null
                ? const Center(
                    child: Text(
                      'No preview available',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: [
                              // Background
                              Container(color: Colors.white),
                              
                              // Zones
                              ..._currentVenue!.zones.map((zone) {
                                final left = zone.x * constraints.maxWidth;
                                final top = zone.y * constraints.maxHeight;
                                final width = zone.width * constraints.maxWidth;
                                final height = zone.height * constraints.maxHeight;
                                
                                return Positioned(
                                  left: left,
                                  top: top,
                                  width: width,
                                  height: height,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: zone.getColor().withOpacity(0.3),
                                      border: Border.all(color: Colors.black, width: 1),
                                    ),
                                    child: Center(
                                      child: Text(
                                        zone.label,
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
          ),
        ],
      ),
    );
  }
  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final iconController = TextEditingController();
    final pointsController = TextEditingController(text: '10');
    // Default to first category if available
    String selectedCategory = _itemsConfig?.categories.firstOrNull?.id ?? 'infrastructure';
    if (_itemsConfig != null && _itemsConfig!.categories.isNotEmpty) {
      selectedCategory = _itemsConfig!.categories.first.id;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Element'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name (e.g. DJ Booth)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: iconController,
                decoration: const InputDecoration(labelText: 'Icon (Emoji e.g. 🎧)'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                items: (_itemsConfig?.categories ?? []).map((c) => DropdownMenuItem(
                  value: c.id,
                  child: Text(c.name),
                )).toList(),
                onChanged: (v) => selectedCategory = v!,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pointsController,
                decoration: const InputDecoration(labelText: 'Points'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty || iconController.text.isEmpty) return;
              _addNewItem(
                nameController.text,
                iconController.text,
                selectedCategory,
                int.tryParse(pointsController.text) ?? 10,
              );
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _addNewItem(String name, String icon, String categoryId, int points) {
    if (_itemsConfig == null) return;
    
    setState(() {
      final newItem = ItemConfig(
        id: name.toLowerCase().replaceAll(' ', '_'),
        category: categoryId,
        icon: icon,
        name: name,
        validZones: [], // Valid everywhere by default
        points: points,
        displayOrder: 99,
      );
      
      _itemsConfig!.items.add(newItem);
      
      // Update JSON controller
      const encoder = JsonEncoder.withIndent('  ');
      _itemsJsonController.text = encoder.convert(_itemsConfig!.toJson());
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added $name')),
    );
  }
}

