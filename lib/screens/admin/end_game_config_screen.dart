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
  int _points = 100;
  
  // Venue & Items data (simplified JSON editing)
  final TextEditingController _venueJsonController = TextEditingController();
  final TextEditingController _itemsJsonController = TextEditingController();
  
  
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
      
      
      // Load default venue and items from JSON as template
      final venue = await EndGameConfigLoader.loadActiveVenue();
      final items = await EndGameConfigLoader.loadItems();
      
      const encoder = JsonEncoder.withIndent('  ');
      
      setState(() {
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
      
      
      const encoder = JsonEncoder.withIndent('  ');
      
      setState(() {
        _currentConfigId = id;
        _nameController.text = config['name'] ?? '';
        _selectedLevel = config['level'] ?? 1;
        _isActive = config['is_active'] ?? false;
        _points = config['points'] ?? 100;
        _venueJsonController.text = encoder.convert(config['venue_data']);
        _itemsJsonController.text = encoder.convert(config['items_data']);
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
        points: _points,
      );
      
      
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
      _points = 100;
      
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
      backgroundColor: const Color(0xFFFFFDE7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4EF8B),
        foregroundColor: const Color(0xFF1E293B),
        elevation: 1,
        title: const Text('End Game Configuration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: Color(0xFF1E293B))),
        leading: widget.onBack != null
            ? IconButton(icon: const Icon(Icons.arrow_back, color: Color(0xFF1E293B)), onPressed: widget.onBack)
            : null,
        actions: [
          IconButton(
            onPressed: _newConfig,
            icon: const Icon(Icons.add_circle_rounded, size: 28, color: Color(0xFF1E293B)),
            tooltip: 'New Configuration',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth >= 900) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 280, child: _buildConfigList()),
                      Expanded(child: _buildForm()),
                      Expanded(child: _buildPreview()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: const Color(0xFF1E293B),
                          indicatorWeight: 3,
                          labelColor: const Color(0xFF1E293B),
                          unselectedLabelColor: Colors.grey[500],
                          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                          tabs: const [
                            Tab(icon: Icon(Icons.list_alt_rounded, size: 20), text: 'Configs'),
                            Tab(icon: Icon(Icons.edit_rounded, size: 20), text: 'Editor'),
                            Tab(icon: Icon(Icons.visibility_rounded, size: 20), text: 'Preview'),
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
      color: const Color(0xFFFFFDE7),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EF8B).withOpacity(0.5),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                const Icon(Icons.folder_open_rounded, color: Color(0xFF8B5CF6), size: 20),
                const SizedBox(width: 10),
                const Text(
                  'Saved Configs',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E293B), fontSize: 15),
                ),
              ],
            ),
          ),
          Expanded(
            child: _allConfigs.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inbox_rounded, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No configurations yet.\nTap + New to create one.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _allConfigs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, index) {
                      final config = _allConfigs[index];
                      final isSelected = config['id'] == _currentConfigId;
                      final isActive = config['is_active'] == true;

                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFF4EF8B).withOpacity(0.4) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFE8D96F) : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          title: Text(
                            config['name'] ?? 'Unnamed',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          subtitle: Text(
                            'Level ${config['level']}',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12),
                          ),
                          trailing: isActive
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF6BCB9F),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'ACTIVE',
                                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                                  ),
                                )
                              : Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
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
      color: const Color(0xFFFFFDE7),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Basic Info Card ───────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings_rounded, color: Color(0xFF8B5CF6), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _currentConfigId == null ? 'New Configuration' : 'Edit Configuration',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Name
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Configuration Name',
                        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                        prefixIcon: const Icon(Icons.label_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Level
                    DropdownButtonFormField<int>(
                      value: _selectedLevel,
                      decoration: InputDecoration(
                        labelText: 'Level',
                        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('Level 1')),
                        DropdownMenuItem(value: 2, child: Text('Level 2')),
                        DropdownMenuItem(value: 3, child: Text('Level 3')),
                        DropdownMenuItem(value: 4, child: Text('Level 4')),
                      ],
                      onChanged: (v) => setState(() => _selectedLevel = v!),
                    ),
                    const SizedBox(height: 16),

                    // Points
                    TextFormField(
                      initialValue: _points.toString(),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Points',
                        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                        prefixIcon: const Icon(Icons.star_rounded, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1E293B), width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        helperText: 'Total points for this end game',
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final n = int.tryParse(v);
                        if (n == null || n <= 0) return 'Must be a positive number';
                        return null;
                      },
                      onChanged: (v) {
                        final n = int.tryParse(v);
                        if (n != null && n > 0) _points = n;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Active toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isActive ? const Color(0xFF6BCB9F).withOpacity(0.1) : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _isActive ? const Color(0xFF6BCB9F) : Colors.grey.shade300),
                      ),
                      child: SwitchListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          'Active Configuration',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: _isActive ? const Color(0xFF6BCB9F) : Colors.grey[600],
                          ),
                        ),
                        value: _isActive,
                        activeColor: const Color(0xFF6BCB9F),
                        onChanged: (v) => setState(() => _isActive = v),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Visual Editor Card ────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.map_rounded, color: Color(0xFFE8D96F), size: 20),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Venue & Items',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _showAddElementDialog,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Add Element', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E293B),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_currentVenue != null)
                      SizedBox(
                        height: 950,
                        child: EndGameVisualEditor(
                          initialVenue: _currentVenue!,
                          itemConfig: _itemsConfig,
                          onAddCustomZone: () => _showAddElementDialog(initialType: 'zone'),
                          onUpdate: (updatedVenue, updatedItems) {
                            _currentVenue = updatedVenue;
                            const encoder = JsonEncoder.withIndent('  ');
                            _venueJsonController.text = encoder.convert(updatedVenue.toJson());
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveConfig,
                  icon: _isSaving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.save_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Configuration',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E293B),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      color: const Color(0xFFFFFDE7),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4EF8B).withOpacity(0.5),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Row(
              children: [
                Icon(Icons.visibility_rounded, color: Color(0xFF8B5CF6), size: 20),
                SizedBox(width: 10),
                Text('Venue Preview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
              ],
            ),
          ),
          Expanded(
            child: _currentVenue == null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.preview_rounded, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No preview available', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  Container(color: Colors.white),
                                  ..._currentVenue!.zones.map((zone) {
                                    return Positioned(
                                      left: zone.x * constraints.maxWidth,
                                      top: zone.y * constraints.maxHeight,
                                      width: zone.width * constraints.maxWidth,
                                      height: zone.height * constraints.maxHeight,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: zone.getColor().withOpacity(0.3),
                                          border: Border.all(color: zone.getColor().withOpacity(0.6), width: 1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Center(
                                          child: Text(
                                            zone.label,
                                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: zone.getColor()),
                                          ),
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  void _showAddElementDialog({String initialType = 'item'}) {
    final nameController = TextEditingController();
    final iconController = TextEditingController();
    final pointsController = TextEditingController(text: '10');
    
    // Zone specific
    String elementType = initialType; // 'item' or 'zone'
    Color selectedColor = Colors.purple;
    
    // Default to first category if available
    String selectedCategory = _itemsConfig?.categories.firstOrNull?.id ?? 'infrastructure';
    if (_itemsConfig != null && _itemsConfig!.categories.isNotEmpty) {
      selectedCategory = _itemsConfig!.categories.first.id;
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Element'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Type Selector
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(
                      label: const Text('Item'),
                      selected: elementType == 'item',
                      onSelected: (b) => setDialogState(() => elementType = 'item'),
                    ),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('Zone'),
                      selected: elementType == 'zone',
                      onSelected: (b) => setDialogState(() => elementType = 'zone'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Common Fields
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: elementType == 'item' ? 'Name (e.g. DJ Booth)' : 'Zone Name (e.g. VIP Area)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Item Specific Fields
                if (elementType == 'item') ...[
                  TextField(
                    controller: iconController,
                    decoration: const InputDecoration(
                      labelText: 'Icon (Emoji e.g. 🎧)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    items: (_itemsConfig?.categories ?? []).map((c) => DropdownMenuItem(
                      value: c.id,
                      child: Text(c.name),
                    )).toList(),
                    onChanged: (v) => setDialogState(() => selectedCategory = v!),
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: pointsController,
                    decoration: const InputDecoration(
                      labelText: 'Points',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ],
                
                // Zone Specific Fields
                if (elementType == 'zone') ...[
                  const Text('Zone Color'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ColorOption(color: Colors.purple, selected: selectedColor == Colors.purple, onTap: () => setDialogState(() => selectedColor = Colors.purple)),
                      _ColorOption(color: Colors.green, selected: selectedColor == Colors.green, onTap: () => setDialogState(() => selectedColor = Colors.green)),
                      _ColorOption(color: Colors.orange, selected: selectedColor == Colors.orange, onTap: () => setDialogState(() => selectedColor = Colors.orange)),
                      _ColorOption(color: Colors.blue, selected: selectedColor == Colors.blue, onTap: () => setDialogState(() => selectedColor = Colors.blue)),
                      _ColorOption(color: Colors.red, selected: selectedColor == Colors.red, onTap: () => setDialogState(() => selectedColor = Colors.red)),
                      _ColorOption(color: Colors.teal, selected: selectedColor == Colors.teal, onTap: () => setDialogState(() => selectedColor = Colors.teal)),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                
                if (elementType == 'item') {
                   if (iconController.text.isEmpty) return;
                   _addNewItem(
                    nameController.text,
                    iconController.text,
                    selectedCategory,
                    int.tryParse(pointsController.text) ?? 10,
                  );
                } else {
                  _addNewZone(nameController.text, selectedColor);
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        ),
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
      SnackBar(content: Text('Added item: $name')),
    );
  }
  
  void _addNewZone(String name, Color color) {
    if (_currentVenue == null) return;
    
    setState(() {
      final newZone = ZoneConfig(
        key: DateTime.now().millisecondsSinceEpoch.toString(),
        label: name,
        x: 0.3, // Default center-ish
        y: 0.3,
        width: 0.3, 
        height: 0.2,
        color: '#${color.value.toRadixString(16).substring(2)}',
      );
      
      _currentVenue!.zones.add(newZone);
      
      // Update JSON controller
      const encoder = JsonEncoder.withIndent('  ');
      _venueJsonController.text = encoder.convert(_currentVenue!.toJson());
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added zone: $name')),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _ColorOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? Colors.black : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: selected 
          ? const Icon(Icons.check, color: Colors.white) 
          : null,
      ),
    );
  }
}

