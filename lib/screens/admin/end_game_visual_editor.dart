import 'package:flutter/material.dart';
import '../../models/end_game_config.dart';
import '../../services/end_game_config_loader.dart';

class EndGameVisualEditor extends StatefulWidget {
  final VenueConfig initialVenue;
  final ItemsConfig? itemConfig; // Changed from List<ItemConfig> to ItemsConfig
  final Function(VenueConfig, List<ItemConfig>) onUpdate;

  const EndGameVisualEditor({
    super.key,
    required this.initialVenue,
    this.itemConfig,
    required this.onUpdate,
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

  void _addZone(String label, Color color) {
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
      
      // Reassign list to modify venue since zones list itself might be final in VenueConfig?
      // VenueConfig.zones is final List<ZoneConfig>. List is mutable.
      _venue.zones.add(newZone);
      
      _selectedZone = newZone;
      _selectedPlacement = null;
    });
    _notifyUpdate();
  }
  
  void _addItem(String type) {
    // For now, we simulate an item ID since we might not have a real catalog item yet
    // In a real app, we'd pick from _catalog.
    // Let's create a placement for a "Speaker".
    
    // We need a dummy ItemConfig if one doesn't exist for "Speaker"
    // Or we assume "Speaker" is a known type.
    
    // For this prototype, we'll generate a placement.
    // We assume 'speaker_item' is the ID of the speaker item in the catalog.
    // If not, we just use the type string as ID for visual purpose for now.
    
    setState(() {
      final newPlacement = ItemPlacement(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        itemId: type == 'SPEAKER' ? 'speaker_1' : 'item_${DateTime.now().millisecondsSinceEpoch}',
        x: 0.5,
        y: 0.5,
      );
      
      // We need to add this to _venue.placements
      // Since _venue.placements is final list in model (likely), we might need to recreate list
      // But usually in Dart List is mutable unless const.
      _venue.placements.add(newPlacement);
      
      _selectedPlacement = newPlacement;
      _selectedZone = null;
    });
    _notifyUpdate();
  }

  void _deleteSelected() {
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

  void _addItemAtLocation(ItemConfig item, double relX, double relY) {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.all(8),
          color: const Color(0xFFFFF9C4),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text('Add Zone:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                _ToolButton(
                  label: 'Stage',
                  color: Colors.purple[100]!,
                  onTap: () => _addZone('STAGE', const Color(0xFF9C27B0)),
                ),
                _ToolButton(
                  label: 'Lawn',
                  color: Colors.green[100]!,
                  onTap: () => _addZone('LAWN', const Color(0xFF4CAF50)),
                ),
                _ToolButton(
                  label: 'Bar',
                  color: Colors.orange[100]!,
                  onTap: () => _addZone('BAR', const Color(0xFFFF9800)),
                ),
                 _ToolButton(
                  label: 'Buffet',
                  color: Colors.blue[100]!,
                  onTap: () => _addZone('BUFFET', const Color(0xFF2196F3)),
                ),
                const SizedBox(width: 16),
                const Text('Add Item:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                _ToolButton(
                  label: 'Speaker',
                  color: Colors.red[100]!,
                  onTap: () => _addItem('SPEAKER'),
                ),
                const SizedBox(width: 24),
                if (_selectedZone != null || _selectedPlacement != null)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: _deleteSelected,
                    tooltip: 'Delete Selected',
                  ),
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

                  return DragTarget<ItemConfig>(
                    onAcceptWithDetails: (details) {
                        final RenderBox box = context.findRenderObject() as RenderBox;
                        final Offset localOffset = box.globalToLocal(details.offset);
                        final double relativeX = localOffset.dx / constraints.maxWidth;
                        final double relativeY = localOffset.dy / constraints.maxHeight;
                        
                        _addItemAtLocation(details.data, relativeX, relativeY);
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
                const Text('Drag or use sliders to move.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('X:'),
                    Expanded(
                      child: Slider(
                        value: (_selectedZone?.x ?? _selectedPlacement?.x ?? 0.0).clamp(0.0, 1.0),
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                           setState(() {
                             if (_selectedZone != null) {
                               final index = _venue.zones.indexWhere((z) => z.key == _selectedZone!.key);
                               if (index != -1) {
                                 final current = _venue.zones[index];
                                 _venue.zones[index] = ZoneConfig(
                                   key: current.key,
                                   label: current.label,
                                   x: val,
                                   y: current.y,
                                   width: current.width,
                                   height: current.height,
                                   color: current.color,
                                 );
                                 _selectedZone = _venue.zones[index];
                               }
                             } else if (_selectedPlacement != null) {
                               final index = _venue.placements.indexWhere((p) => p.id == _selectedPlacement!.id);
                               if (index != -1) {
                                 final current = _venue.placements[index];
                                 _venue.placements[index] = ItemPlacement(
                                   id: current.id,
                                   itemId: current.itemId,
                                   x: val,
                                   y: current.y,
                                 );
                                 _selectedPlacement = _venue.placements[index];
                               }
                             }
                           });
                        },
                        onChangeEnd: (_) => _notifyUpdate(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text('Y:'),
                    Expanded(
                      child: Slider(
                        value: (_selectedZone?.y ?? _selectedPlacement?.y ?? 0.0).clamp(0.0, 1.0),
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                           setState(() {
                             if (_selectedZone != null) {
                               final index = _venue.zones.indexWhere((z) => z.key == _selectedZone!.key);
                               if (index != -1) {
                                 final current = _venue.zones[index];
                                 _venue.zones[index] = ZoneConfig(
                                   key: current.key,
                                   label: current.label,
                                   x: current.x,
                                   y: val,
                                   width: current.width,
                                   height: current.height,
                                   color: current.color,
                                 );
                                 _selectedZone = _venue.zones[index];
                               }
                             } else if (_selectedPlacement != null) {
                               final index = _venue.placements.indexWhere((p) => p.id == _selectedPlacement!.id);
                               if (index != -1) {
                                 final current = _venue.placements[index];
                                 _venue.placements[index] = ItemPlacement(
                                   id: current.id,
                                   itemId: current.itemId,
                                   x: current.x,
                                   y: val,
                                 );
                                 _selectedPlacement = _venue.placements[index];
                               }
                             }
                           });
                        },
                        onChangeEnd: (_) => _notifyUpdate(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
        // Item Palette (Bottom Tabs)
        Container(
          height: 200,
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
                          return Draggable<ItemConfig>(
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
    IconData icon = Icons.volume_up;
    Color color = Colors.red;
    
    return Positioned(
      key: ValueKey('item_${placement.id}'),
      left: placement.x * constraints.maxWidth - 12,
      top: placement.y * constraints.maxHeight - 12,
      width: 24,
      height: 24,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _selectedPlacement = placement;
          _selectedZone = null;
        }),
        onScaleStart: (_) {
           setState(() {});
        },
        onScaleEnd: (_) {
           _notifyUpdate();
        },
        onScaleUpdate: (details) {
          setState(() {
            double dx = details.focalPointDelta.dx / constraints.maxWidth;
            double dy = details.focalPointDelta.dy / constraints.maxHeight;
            
            final index = _venue.placements.indexWhere((p) => p.id == placement.id);
            if (index != -1) {
              final current = _venue.placements[index];
              final newX = (current.x + dx).clamp(0.0, 1.0);
              final newY = (current.y + dy).clamp(0.0, 1.0);
              
              _venue.placements[index] = ItemPlacement(
                id: current.id,
                itemId: current.itemId,
                x: newX,
                y: newY,
              );
              
              _selectedPlacement = _venue.placements[index];
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isSelected ? Colors.yellow : Colors.white,
            border: Border.all(color: color, width: 2),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }

  Widget _buildZoneWidget(ZoneConfig zone, BoxConstraints constraints) {
    final isSelected = _selectedZone?.key == zone.key;
    
    return Positioned(
      key: ValueKey('zone_${zone.key}'),
      left: zone.x * constraints.maxWidth,
      top: zone.y * constraints.maxHeight,
      width: zone.width * constraints.maxWidth,
      height: zone.height * constraints.maxHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() {
          _selectedZone = zone;
          _selectedPlacement = null;
        }),
        onScaleStart: (_) {
           setState(() {});
        },
        onScaleEnd: (_) {
           // Sync with parent only when drag finishes to avoid rebuild loop
           _notifyUpdate();
        },
        onScaleUpdate: (details) {
          setState(() {
             // Scale gesture includes pan logic via focalPointDelta
             double dx = details.focalPointDelta.dx / constraints.maxWidth;
             double dy = details.focalPointDelta.dy / constraints.maxHeight;
             
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
        child: Container(
          decoration: BoxDecoration(
            color: Color(int.parse(zone.color.substring(1), radix: 16)).withOpacity(0.5),
            border: Border.all(
              color: isSelected ? Colors.blue : Colors.black,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Center(
            child: Text(
              zone.label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
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
