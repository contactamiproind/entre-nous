import 'package:flutter/material.dart';
import '../../models/end_game_config.dart';
import '../../services/end_game_config_loader.dart';

class EndGameVisualEditor extends StatefulWidget {
  final VenueConfig initialVenue;
  final ItemsConfig? itemConfig; // Changed from List<ItemConfig> to ItemsConfig
  final Function(VenueConfig, List<ItemConfig>) onUpdate;
  final VoidCallback? onAddCustomZone;

  const EndGameVisualEditor({
    super.key,
    required this.initialVenue,
    this.itemConfig,
    required this.onUpdate,
    this.onAddCustomZone,
  });

  @override
  State<EndGameVisualEditor> createState() => _EndGameVisualEditorState();
}

class _EndGameVisualEditorState extends State<EndGameVisualEditor> {
  late VenueConfig _venue;
  ItemsConfig? _catalog;
  
  // Selection state
  ZoneConfig? _selectedZone;
  ItemPlacement? _selectedPlacement;

  @override
  void initState() {
    super.initState();
    _venue = widget.initialVenue;
    
    // Use passed config if available, otherwise load from loader
    if (widget.itemConfig != null) {
      _catalog = widget.itemConfig;
    } else {
      _loadCatalog();
    }
  }

  @override
  void didUpdateWidget(EndGameVisualEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialVenue != oldWidget.initialVenue) {
      setState(() {
        _venue = widget.initialVenue;
        _selectedZone = null;
        _selectedPlacement = null;
      });
    }
    if (widget.itemConfig != oldWidget.itemConfig) {
      setState(() {
        _catalog = widget.itemConfig;
      });
    }
  }

  Future<void> _loadCatalog() async {
    try {
      final config = await EndGameConfigLoader.loadItems();
      if (mounted) {
        setState(() {
          _catalog = config;
        });
      }
    } catch (e) {
      debugPrint('Error loading items config: $e');
    }
  }

  // Undo/Redo Stacks
  final List<VenueConfig> _undoStack = [];
  final List<VenueConfig> _redoStack = [];

  void _saveForUndo() {
    // Deep copy current state via JSON
    final json = _venue.toJson();
    final snapshot = VenueConfig.fromJson(json);
    
    _undoStack.add(snapshot);
    _redoStack.clear();
    
    // Limit stack size
    if (_undoStack.length > 20) {
      _undoStack.removeAt(0);
    }
  }

  void _undo() {
    if (_undoStack.isEmpty) return;
    
    setState(() {
      // Save current state to redo stack
      final  currentJson = _venue.toJson();
      _redoStack.add(VenueConfig.fromJson(currentJson));
      
      // Restore from undo stack
      _venue = _undoStack.removeLast();
      
      // Clear selection if it no longer exists
      // (Simple approach: just clear selection to be safe)
      _selectedZone = null;
      _selectedPlacement = null;
    });
    _notifyUpdate();
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    
    setState(() {
      // Save current to undo
      final currentJson = _venue.toJson();
      _undoStack.add(VenueConfig.fromJson(currentJson));
      
      // Restore from redo
      _venue = _redoStack.removeLast();
      
      _selectedZone = null;
      _selectedPlacement = null;
    });
    _notifyUpdate();
  }

  void _addZone(String label, Color color) {
    _saveForUndo();
    setState(() {
      final newZone = ZoneConfig(
        key: DateTime.now().millisecondsSinceEpoch.toString(),
        label: label,
        x: 0.1 + (_venue.zones.length * 0.05) % 0.5,
        y: 0.1 + (_venue.zones.length * 0.05) % 0.5,
        width: 0.3, // Default size
        height: 0.2,
        color: '#${color.value.toRadixString(16).substring(2)}',
      );
      
      _venue.zones.add(newZone);
      
      _selectedZone = newZone;
      _selectedPlacement = null;
    });
    _notifyUpdate();
  }
  


  void _deleteSelected() {
    _saveForUndo();
    setState(() {
      if (_selectedZone != null) {
        _venue.zones.removeWhere((z) => z.key == _selectedZone!.key);
        _selectedZone = null;
      }
      if (_selectedPlacement != null) {
        _venue.placements.removeWhere((p) => p.id == _selectedPlacement!.id);
        _selectedPlacement = null;
      }
    });
    _notifyUpdate();
  }

  void _notifyUpdate() {
    widget.onUpdate(_venue, _catalog?.items ?? []);
  }

  void _moveItem(ItemPlacement item, double x, double y) {
    _saveForUndo();
    setState(() {
       final index = _venue.placements.indexWhere((p) => p.id == item.id);
       if (index != -1) {
          final current = _venue.placements[index];
          _venue.placements[index] = ItemPlacement(
             id: current.id,
             itemId: current.itemId,
             x: x.clamp(0.0, 1.0),
             y: y.clamp(0.0, 1.0),
          );
          _selectedPlacement = _venue.placements[index];
          _selectedZone = null;
       }
    });
    _notifyUpdate();
  }

  void _addItemAtLocation(ItemConfig item, double relX, double relY) {
    _saveForUndo();
    setState(() {
      final newItem = ItemPlacement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemId: item.id,
        x: relX.clamp(0.0, 1.0),
        y: relY.clamp(0.0, 1.0),
      );
      _venue.placements.add(newItem);
      _selectedPlacement = newItem;
      _selectedZone = null;
    });
    _notifyUpdate();
  }

  Widget _iconBtn(IconData icon, VoidCallback? onPressed, String tooltip) {
    return IconButton(
      icon: Icon(icon, color: onPressed == null ? Colors.grey[400] : const Color(0xFF1E293B), size: 20),
      onPressed: onPressed,
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      splashRadius: 18,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _iconBtn(Icons.undo_rounded, _undoStack.isEmpty ? null : _undo, 'Undo'),
                _iconBtn(Icons.redo_rounded, _redoStack.isEmpty ? null : _redo, 'Redo'),
                Container(width: 1, height: 24, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 8)),
                Text('Zones:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Colors.grey[700])),
                const SizedBox(width: 6),
                _ToolButton(label: 'Stage', color: const Color(0xFFE1BEE7), onTap: () => _addZone('STAGE', const Color(0xFF9C27B0))),
                _ToolButton(label: 'Lawn', color: const Color(0xFFC8E6C9), onTap: () => _addZone('LAWN', const Color(0xFF4CAF50))),
                _ToolButton(label: 'Bar', color: const Color(0xFFFFE0B2), onTap: () => _addZone('BAR', const Color(0xFFFF9800))),
                _ToolButton(label: 'Buffet', color: const Color(0xFFBBDEFB), onTap: () => _addZone('BUFFET', const Color(0xFF2196F3))),
                _ToolButton(label: 'Custom', color: Colors.grey.shade200, onTap: () => widget.onAddCustomZone?.call()),
                if (_selectedZone != null || _selectedPlacement != null) ...[
                  Container(width: 1, height: 24, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 8)),
                  InkWell(
                    onTap: _deleteSelected,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF08A7E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFF08A7E).withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.delete_rounded, color: Color(0xFFF08A7E), size: 16),
                          SizedBox(width: 4),
                          Text('Delete', style: TextStyle(color: Color(0xFFF08A7E), fontSize: 11, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        
        // Editor Canvas
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AspectRatio(
              aspectRatio: 1.0,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Sort zones so selected one is on top (last)
                  final sortedZones = _venue.zones.toList()
                    ..sort((a, b) {
                      if (_selectedZone?.key == a.key) return 1;
                      if (_selectedZone?.key == b.key) return -1;
                      return 0;
                    });

                  return DragTarget<Object>(
                    onAcceptWithDetails: (details) {
                        final RenderBox box = context.findRenderObject() as RenderBox;
                        final Offset localOffset = box.globalToLocal(details.offset);
                        // Adjust for center of the dragged item (assuming 45x45 feedback)
                        final double relativeX = (localOffset.dx) / constraints.maxWidth;
                        final double relativeY = (localOffset.dy) / constraints.maxHeight;
                        
                        if (details.data is ItemConfig) {
                          _addItemAtLocation(details.data as ItemConfig, relativeX, relativeY);
                        } else if (details.data is ItemPlacement) {
                          _moveItem(details.data as ItemPlacement, relativeX, relativeY);
                        }
                    },
                    builder: (context, candidateData, rejectedData) {
                      return Stack(
                        children: [
                          // Background (Plain White)
                           Positioned.fill(
                             child: Container(color: Colors.white), 
                           ),
                             
                          // Zones (Draw first so they are behind items)
                          ...sortedZones.map((zone) => _buildZoneWidget(zone, constraints)),
                          
                          // Item Placements
                          ..._venue.placements.map((placement) => _buildPlacementWidget(placement, constraints)),
                          
                          // Drag Highlight
                          if (candidateData.isNotEmpty)
                            Positioned.fill(
                              child: Container(
                                color: Colors.blue.withOpacity(0.1),
                                child: const Center(child: Icon(Icons.add_circle, color: Colors.blue, size: 48)),
                              ),
                            ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
        
        // Layers List (Simplified/Compact)
        if (_venue.zones.isNotEmpty)
          Container(
            height: 40,
            color: const Color(0xFFFFF9C4),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Center(child: Text('Layers:', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
                ),
                ..._venue.zones.map((zone) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ActionChip(
                    label: Text(zone.label, style: const TextStyle(fontSize: 10)),
                    backgroundColor: _selectedZone?.key == zone.key ? Colors.blue[100] : Colors.white,
                    onPressed: () => setState(() { _selectedZone = zone; _selectedPlacement = null; }),
                    visualDensity: VisualDensity.compact,
                  ),
                )),
              ],
            ),
          ),

        // Properties Panel (moved up)
        if (_selectedZone != null || _selectedPlacement != null)
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFFFFF9C4), // Yellow background
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Selected: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    Expanded(
                      child: Text(
                        _selectedZone?.label ?? (_selectedPlacement != null ? 'Item' : ''),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Text('Drag to move.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete, size: 16),
                    label: Text('Remove ${_selectedZone != null ? "Zone" : "Item"}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[100],
                      foregroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
        // Item Palette (Bottom Tabs)
        Container(
          height: 350, // Increased from 200 to show more items
          color: Colors.white,
          child: _catalog == null 
           ? const Center(child: CircularProgressIndicator())
           : DefaultTabController(
            length: _catalog!.categories.length,
            child: Column(
              children: [
                TabBar(
                  isScrollable: true,
                  labelColor: Colors.black,
                  indicatorColor: Colors.orange,
                  tabs: _catalog!.categories.map((c) => Tab(text: c.name)).toList(),
                ),
                Expanded(
                  child: TabBarView(
                    children: _catalog!.categories.map((category) {
                      final items = _catalog!.getItemsByCategory(category.id);
                      return GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return InkWell(
                            onTap: () {
                              // "Tap to Add" - adds to center
                              _addItemAtLocation(item, 0.5, 0.5);
                            },
                            child: Draggable<ItemConfig>(
                              data: item,
                              feedback: Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  padding: const EdgeInsets.all(8),
                                  color: Colors.white,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(item.icon, style: const TextStyle(fontSize: 32)),
                                    ],
                                  ),
                                ),
                              ),
                              child: Card(
                                elevation: 2,
                                color: const Color(0xFFFFF9C4), // Yellow cards
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(item.icon, style: const TextStyle(fontSize: 24)),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.name, 
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Properties Panel (bottom)
        // Properties Panel (bottom)

      ],
    );
  }

  Widget _buildPlacementWidget(ItemPlacement placement, BoxConstraints constraints) {
    final isSelected = _selectedPlacement?.id == placement.id;
    
    // Lookup item icon
    String iconText = '❓';
    if (_catalog != null) {
      final itemDef = _catalog!.items.firstWhere(
        (i) => i.id == placement.itemId,
        orElse: () => ItemConfig(
          id: placement.itemId,
          category: '',
          icon: '❓',
          name: '',
          validZones: [],
          points: 0,
          displayOrder: 0,
        ),
      );
      iconText = itemDef.icon;
    }
    
    return Positioned(
      key: ValueKey('item_${placement.id}'),
      left: placement.x * constraints.maxWidth - 22.5, // Centered (45/2)
      top: placement.y * constraints.maxHeight - 22.5, // Centered (45/2)
      width: 45,
      height: 45,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            _selectedPlacement = placement;
            _selectedZone = null;
          });
        },
        child: Draggable<ItemPlacement>(
          data: placement,
          feedback: Material(
            color: Colors.transparent,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.yellow.withOpacity(0.8) : Colors.white.withOpacity(0.8),
                border: Border.all(color: Colors.black, width: 1),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: Center(
                child: Text(
                  iconText,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.yellow : Colors.white,
                border: Border.all(color: Colors.black, width: 1),
              ),
              child: Center(
                child: Text(
                  iconText,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
          ),
          onDragStarted: () {
             // Select item when starting drag
             _saveForUndo();
             setState(() {
              _selectedPlacement = placement;
              _selectedZone = null;
             });
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.yellow : Colors.white,
              border: Border.all(color: Colors.black, width: 1),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
            ),
            child: Center(
              child: Text(
                iconText,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZoneWidget(ZoneConfig zone, BoxConstraints constraints) {
    final isSelected = _selectedZone?.key == zone.key;
    final zoneColor = zone.getColor();

    return Positioned(
      key: ValueKey('zone_${zone.key}'),
      left: zone.x * constraints.maxWidth,
      top: zone.y * constraints.maxHeight,
      width: zone.width * constraints.maxWidth,
      height: zone.height * constraints.maxHeight,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: (_) {
          _saveForUndo();
          setState(() {
            _selectedZone = zone;
            _selectedPlacement = null;
          });
        },
        onPointerUp: (_) => _notifyUpdate(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              _selectedZone = zone;
              _selectedPlacement = null;
            });
          },
          onPanUpdate: (details) {
            setState(() {
              double dx = details.delta.dx / constraints.maxWidth;
              double dy = details.delta.dy / constraints.maxHeight;

              final index = _venue.zones.indexWhere((z) => z.key == zone.key);
              if (index != -1) {
                final current = _venue.zones[index];
                final newX = (current.x + dx).clamp(0.0, 1.0 - current.width);
                final newY = (current.y + dy).clamp(0.0, 1.0 - current.height);

                _venue.zones[index] = ZoneConfig(
                  key: current.key,
                  label: current.label,
                  x: newX,
                  y: newY,
                  width: current.width,
                  height: current.height,
                  color: current.color,
                );

                _selectedZone = _venue.zones[index];
              }
            });
          },
          onPanEnd: (_) => _notifyUpdate(),
          child: Container(
            decoration: BoxDecoration(
              color: zoneColor.withOpacity(0.35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? const Color(0xFF1E293B) : zoneColor.withOpacity(0.7),
                width: isSelected ? 3 : 1.5,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    zone.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      color: zoneColor.withOpacity(0.9),
                    ),
                  ),
                ),
                if (isSelected)
                  const Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.open_with_rounded, size: 14, color: Color(0xFF8B5CF6)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ToolButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
      ),
    );
  }
}
