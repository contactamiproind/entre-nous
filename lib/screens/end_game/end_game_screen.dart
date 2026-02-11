import 'package:flutter/material.dart';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game_models.dart';
import '../../models/end_game_config.dart';
import '../../services/end_game_config_loader.dart';
import '../../services/end_game_service.dart';
import '../../services/progress_service.dart';

class EndGameScreen extends StatefulWidget {
  const EndGameScreen({super.key});

  @override
  State<EndGameScreen> createState() => _EndGameScreenState();
}

class _EndGameScreenState extends State<EndGameScreen> with TickerProviderStateMixin {
  final EndGameService _endGameService = EndGameService();
  final ProgressService _progressService = ProgressService();
  String? _activeEndGameId;

  // Game State
  final List<PlacedObject> _placedObjects = [];
  final Set<String> _disruptionsTriggered = {};
  
  // Scores
  double _guestScore = 100;
  double _safetyScore = 100;
  double _budgetScore = 100;
  double _aestheticsScore = 100;
  double _eventScore = 100;
  int _disruptionsHandled = 0;
  int _placementScore = 0; // Score for correct item placement

  // Calculate placement score based on Exact Match
  void _calculatePlacementScore() {
    if (_venueConfig == null) return;
    
    int newScore = 0;
    // Iterate through Admin's correct placements
    for (var correctPlacement in _venueConfig!.placements) {
        // Find if user has placed this item type
        // We look for any user placed object of the same item ID that is "close enough"
        
        // Filter user objects by same Item ID
        var matchingUserObjects = _placedObjects.where((obj) => obj.id == correctPlacement.itemId);
        
        // Check distance for each match
        bool foundMatch = false;
        for (var userObj in matchingUserObjects) {
             // Calculate distance (Euclidean)
             double adminX = correctPlacement.x * 100;
             double adminY = correctPlacement.y * 100;
             
             double dist = sqrt(pow(userObj.x - adminX, 2) + pow(userObj.y - adminY, 2));
             
             // Threshold: 15% of screen width/height
             if (dist <= 15.0) {
                 foundMatch = true;
                 break;
             }
        }
        
        if (foundMatch) {
            newScore += 10;
        }
    }
    
    setState(() {
        _placementScore = newScore;
    });
  }
  
  // Drag State
  bool _isDraggingPlacedObject = false;
  
  late TabController _tabController;
  
  // Configuration loaded from JSON
  VenueConfig? _venueConfig;
  ItemsConfig? _itemsConfig;
  bool _isLoading = true;
  Map<String, Rect> _zones = {}; // Zone key -> Rect mapping

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadConfiguration();
  }

  Future<void> _loadConfiguration() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      
      VenueConfig? venue;
      ItemsConfig? items;
      
      if (userId != null) {
        // Try loading from DB first to get the ID
        final config = await _endGameService.getActiveConfigForUser(userId);
        if (config != null) {
          _activeEndGameId = config['id'];
          if (config['venue_data'] != null) {
             venue = VenueConfig.fromJson(config['venue_data']);
          }
          if (config['items_data'] != null) {
             items = ItemsConfig.fromJson(config['items_data']);
          }
        }
      }
      
      // Fallback if not found in DB
      if (venue == null) {
         venue = await EndGameConfigLoader.loadActiveVenue();
      }
      if (items == null) {
         items = await EndGameConfigLoader.loadItems();
      }
      
      // Build zones map
      final zonesMap = <String, Rect>{};
      for (final zone in venue.zones) {
        zonesMap[zone.key] = zone.toRect();
      }
      
      setState(() {
        _venueConfig = venue;
        _itemsConfig = items;
        _zones = zonesMap;
        _isLoading = false;
      });
      
      _updateStats();
    } catch (e) {
      debugPrint('Error loading configuration: $e');
      // ... error handling ...
      setState(() => _isLoading = false);
    }
  }

  Future<void> _markGameAsCompleted(int score) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && _activeEndGameId != null) {
       try {
         // 1. Mark End Game as completed
         await _endGameService.markAsCompleted(user.id, _activeEndGameId!, score);
         debugPrint('✅ End Game marked as completed!');
         
         // 2. Attempt Level Promotion
         // We must promote EACH restricted department individually because
         // each department has its own 'current_level' in the usr_dept table.
         
         final userDepts = await Supabase.instance.client
             .from('usr_dept')
             .select('dept_id')
             .eq('user_id', user.id);
             
         for (var row in userDepts) {
           await _progressService.attemptLevelPromotion(user.id, row['dept_id']);
         }
         
       } catch (e) {
         debugPrint('❌ Error marking game complete/promoting: $e');
       }
    }
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateStats() {
    setState(() {
      _calculatePlacementScore(); // Recalculate placement score whenever stats update
      // Total score now includes placement score
      // Normalize: (Guest + Safety + Budget + Aesthetic + Placement) / 5 ?
      // Or just add it as a bonus? Let's keep it simple for now and blend it in.
      // The user wants "Exact Match" so this is likely the primary mechanic.
      
      // Let's make Event Score the average of all categories including Placement
       _eventScore = max(0, min(100, (_guestScore + _safetyScore + _budgetScore + _aestheticsScore + _placementScore) / 5));
    });
  }

  void _handleDrop(GameItemDef item, Offset localPosition, Size venueSize) {
    // Center the item (add 22.5px offset for 45x45 item)
    double x = ((localPosition.dx + 22.5) / venueSize.width) * 100;
    double y = ((localPosition.dy + 22.5) / venueSize.height) * 100;

    x = max(5, min(95, x));
    y = max(5, min(95, y));

    setState(() {
      _placedObjects.add(PlacedObject(
        id: item.id,
        category: item.category,
        x: x,
        y: y,
      ));
      _updateStats();
    });
    
    _checkForDisruptions(item.id);
    _checkGameEnd();
  }
  
  void _updateObjectPosition(PlacedObject object, Offset localPosition, Size venueSize) {
    // Center the item (add 22.5px offset for 45x45 item)
    double x = ((localPosition.dx + 22.5) / venueSize.width) * 100;
    double y = ((localPosition.dy + 22.5) / venueSize.height) * 100;
    
    setState(() {
      object.x = max(5, min(95, x));
      object.y = max(5, min(95, y));
    });
  }

  void _removeObject(String objectId) {
    setState(() {
      _placedObjects.removeWhere((obj) => obj.id == objectId);
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
       content: Text("Object removed", style: TextStyle(color: Colors.black)),
       backgroundColor: Color(0xFFF4EF8B),
       duration: Duration(milliseconds: 500),
    ));
  }

  void _moveObjectToZone(String objectId, Rect zone) {
    final obj = _placedObjects.where((element) => element.id == objectId).firstOrNull;
    if (obj != null) {
      setState(() {
        obj.x = zone.left + (zone.width / 2);
        obj.y = zone.top + (zone.height / 2);
      });
    }
  }

  void _moveObjectToCenter(String objectId) {
     final obj = _placedObjects.where((element) => element.id == objectId).firstOrNull;
    if (obj != null) {
      setState(() {
        obj.x = 50.0;
      });
    }
  }

  void _checkGameEnd() {
    // Auto-end disabled, user clicks DONE
  }

  void _checkForDisruptions(String objectId) {
    // 1. Cake Blocking
    if (objectId == 'cake-table' && !_disruptionsTriggered.contains('cake-blocking')) {
      final guestSeating = _placedObjects.any((o) => o.id == 'guest-seating');
      if (guestSeating) {
        _triggerDisruption(Disruption(
          id: 'cake-blocking',
          title: 'Cake Cutting Blocked',
          message: 'Oh no! The client wants a cake-cutting moment near the stage, but guests are blocking the aisle.',
          highlightObjects: ['cake-table', 'guest-seating'],
          actions: [
            DisruptionAction(
              id: 'move-cake',
              text: 'Move cake table closer to stage',
              effect: () {
                final stageZone = _zones['stage'];
                if (stageZone != null) _moveObjectToZone('cake-table', stageZone);
                setState(() {
                  _guestScore += 10;
                  _eventScore += 5;
                });
              }
            ),
            DisruptionAction(
              id: 'reroute-guests',
              text: 'Re-route guest seating',
              effect: () {
                final diningZone = _zones['dining'];
                if (diningZone != null) _moveObjectToZone('guest-seating', diningZone);
                setState(() {
                  _guestScore += 5;
                  _budgetScore -= 5;
                });
              }
            ),
          ],
        ));
      }
    }

    // 2. Power Alert
    if ((['fairy-lights', 'speaker-left', 'speaker-right'].contains(objectId)) && 
        !_disruptionsTriggered.contains('power-alert')) {
      final hasLights = _placedObjects.any((o) => o.id == 'fairy-lights');
      final hasSpeakerL = _placedObjects.any((o) => o.id == 'speaker-left');
      final hasSpeakerR = _placedObjects.any((o) => o.id == 'speaker-right');
      final hasGenset = _placedObjects.any((o) => o.id == 'genset');

      if (hasLights && hasSpeakerL && hasSpeakerR && hasGenset) {
        _triggerDisruption(Disruption(
          id: 'power-alert',
          title: 'Power Alert',
          message: 'Power Alert! Your sound and lighting load is exceeding the genset capacity.',
          highlightObjects: ['genset', 'fairy-lights', 'speaker-left', 'speaker-right'],
          actions: [
             DisruptionAction(
              id: 'reduce-lighting',
              text: 'Reduce lighting fixtures',
              effect: () {
                _removeObject('fairy-lights');
                setState(() {
                  _safetyScore += 15;
                  _guestScore -= 10;
                });
              }
            ),
            DisruptionAction(
              id: 'add-backup-genset',
              text: 'Add a backup genset',
              effect: () {
                 setState(() {
                  _safetyScore += 20;
                  _budgetScore -= 15;
                  _eventScore += 5;
                });
              }
            ),
          ],
        ));
      }
    }

    // 3. Noise Complaint
    if ((['speaker-left', 'speaker-right'].contains(objectId)) && 
        !_disruptionsTriggered.contains('noise-complaint')) {
       final spL = _placedObjects.where((o) => o.id == 'speaker-left').firstOrNull;
       final spR = _placedObjects.where((o) => o.id == 'speaker-right').firstOrNull;

       if (spL != null && spR != null) {
         if (spL.x < 15 || spL.x > 85 || spR.x < 15 || spR.x > 85) {
           _triggerDisruption(Disruption(
            id: 'noise-complaint',
            title: 'Noise Complaint Incoming',
            message: 'Noise Complaint Incoming! The neighbor has complained about speaker direction.',
            highlightObjects: ['speaker-left', 'speaker-right'],
            actions: [
               DisruptionAction(
                id: 'rotate-speakers',
                text: 'Rotate speakers inward',
                effect: () {
                  _moveObjectToCenter('speaker-left');
                  _moveObjectToCenter('speaker-right');
                  setState(() {
                    _safetyScore += 10;
                    _guestScore += 5;
                  });
                }
              ),
              DisruptionAction(
                id: 'reduce-bass',
                text: 'Reduce bass output',
                effect: () {
                   setState(() {
                    _guestScore -= 5;
                    _safetyScore += 15;
                    _eventScore -= 3;
                  });
                }
              ),
            ],
          ));
         }
       }
    }

    // 4. Weather Twist
    if ((['candles', 'centerpieces'].contains(objectId)) && 
        !_disruptionsTriggered.contains('weather-twist')) {
       final hasEntrance = _placedObjects.any((o) => o.id == 'entrance-arch');
       final decor = _placedObjects.where((o) => o.id == 'candles' || o.id == 'centerpieces').firstOrNull;

       if (hasEntrance && decor != null && decor.y < 20) {
          _triggerDisruption(Disruption(
            id: 'weather-twist',
            title: 'Weather Twist',
            message: 'Weather Twist! Unexpected wind has knocked over décor near the entrance.',
            highlightObjects: ['candles', 'centerpieces', 'entrance-arch'],
            actions: [
               DisruptionAction(
                id: 'remove-decor',
                text: 'Remove loose décor',
                effect: () {
                  _removeObject('candles');
                   setState(() {
                    _safetyScore += 15;
                    _guestScore -= 8;
                  });
                }
              ),
              DisruptionAction(
                id: 'shift-decor',
                text: 'Shift décor to sheltered zone',
                effect: () {
                   final diningZone = _zones['dining'];
                   if (diningZone != null) _moveObjectToZone('candles', diningZone);
                   setState(() {
                    _safetyScore += 10;
                    _budgetScore -= 5;
                  });
                }
              ),
            ],
          ));
       }
    }

    // 5. Safety Breach
    if (objectId == 'bar-counter' && !_disruptionsTriggered.contains('safety-breach')) {
       final hasBar = _placedObjects.any((o) => o.id == 'bar-counter');
       final hasWalkway = _placedObjects.any((o) => o.id == 'walkway');
       final hasDistBox = _placedObjects.any((o) => o.id == 'distribution-box');

       if (hasBar && (hasWalkway || hasDistBox)) {
          _triggerDisruption(Disruption(
            id: 'safety-breach',
            title: 'Safety Breach',
            message: 'Safety Breach! Cables are crossing the guest walkway.',
            highlightObjects: ['bar-counter', 'walkway', 'distribution-box'],
            actions: [
               DisruptionAction(
                id: 'reroute-cables',
                text: 'Reroute cables via barricade',
                effect: () {
                   setState(() {
                    _safetyScore += 20;
                    _budgetScore -= 10;
                    _eventScore += 5;
                  });
                }
              ),
              DisruptionAction(
                id: 'move-bar',
                text: 'Move bar setup slightly',
                effect: () {
                   final barZone = _zones['bar'];
                   if (barZone != null) _moveObjectToZone('bar-counter', barZone);
                   setState(() {
                    _safetyScore += 15;
                    _guestScore -= 5;
                  });
                }
              ),
            ],
          ));
       }
    }
  }

  void _triggerDisruption(Disruption disruption) {
    if (_disruptionsTriggered.contains(disruption.id)) return;
    
    setState(() {
      _disruptionsTriggered.add(disruption.id);
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF4EF8B), width: 4),
        ),
        title: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 32)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                disruption.title.toUpperCase(),
                style: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          disruption.message,
          style: const TextStyle(color: Colors.black87, fontSize: 16),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ...disruption.actions.map((action) => 
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4EF8B),
                foregroundColor: Colors.black,
                elevation: 4,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                if (action.effect != null) {
                  action.effect!();
                }
                setState(() {
                  _disruptionsHandled++;
                });
                _updateStats();
                _checkGameEnd();
              },
              child: Text(action.text, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            )
          ),
        ],
      ),
    );
  }

  void _showGameSummary() {
    // 1. Calculate Event Readiness (based on config total)
    int totalItems = _venueConfig?.placements.length ?? 40;
    if (totalItems == 0) totalItems = 1; // Prevent division by zero
    final readinessScore = (_placedObjects.length / totalItems * 100).clamp(0, 100).toInt();

    // 2. Normalize Placement Score (Exact Match)
    // Max Placement Score = totalItems * 10.
    // Normalized = (current / max) * 100
    int maxPlacementScore = totalItems * 10;
    if (maxPlacementScore == 0) maxPlacementScore = 1;
    final normalizedPlacementScore = ((_placementScore / maxPlacementScore) * 100).clamp(0, 100).toInt();
    
    // 3. Calculate Final Score (Based ONLY on Exact Match as requested)
    final finalScore = normalizedPlacementScore;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
         shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFF4EF8B), width: 4),
        ),
        title: const Row(
          children: [
            Text('🎉', style: TextStyle(fontSize: 32)),
            SizedBox(width: 10),
            Expanded(child: Text(
              'EVENT SETUP COMPLETE!',
              style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
            )),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             // _buildSummaryRow('Guest Experience', _guestScore.toInt()),
             // _buildSummaryRow('Safety', _safetyScore.toInt()),
             // _buildSummaryRow('Budget Control', _budgetScore.toInt()),
             // _buildSummaryRow('Aesthetics', _aestheticsScore.toInt()),
             _buildSummaryRow('Exact Match', normalizedPlacementScore), // Display normalized score (0-100)
             _buildSummaryRow('Event Readiness', readinessScore),
             const Divider(color: Colors.grey),
             Container(
               margin: const EdgeInsets.only(top: 10),
               padding: const EdgeInsets.all(16),
               decoration: BoxDecoration(
                 color: const Color(0xFFFFF9E6),
                 borderRadius: BorderRadius.circular(12),
                 border: Border.all(color: const Color(0xFFF4EF8B)),
               ),
               child: Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Final Score:', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text('$finalScore/100', style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
               ),
             )
          ],
        ),
        actions: [
          ElevatedButton(
             style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4EF8B),
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                if (finalScore == 100) {
                  // Save navigator reference before closing dialog
                  final navigator = Navigator.of(context);
                  // Close dialog
                  navigator.pop();
                  // Mark as completed and wait for promotion
                  await _markGameAsCompleted(finalScore);
                  // Return to dashboard using saved navigator reference
                  if (mounted) {
                    navigator.pop(true); // Pass true to indicate refresh needed
                  }
                } else {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (c) => const EndGameScreen())
                  );
                }
              },
              child: Text(finalScore == 100 ? 'RETURN TO DASHBOARD' : 'PLAY AGAIN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, int value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: Color(0xFFF4EF8B), width: 4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87, fontSize: 16)),
          Text('$value', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFF9E6), // Very light yellow
              Color(0xFFF4EF8B), // Main yellow
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.black,
                ),
              )
            : _venueConfig == null || _itemsConfig == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load game configuration',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Go Back'),
                        ),
                      ],
                    ),
                  )
                : Column(
          children: [
            // Safe Area for Status Bar
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    // Header Row with Back Button and Title
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const Expanded(
                          child: Text(
                            'EVENT VERIFICATION',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        
                        // DONE Button
                        ElevatedButton(
                          onPressed: () {
                             _showGameSummary();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: const Color(0xFFF4EF8B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            minimumSize: const Size(0, 36),
                          ),
                          child: const Text('DONE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Stats Row
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildHeaderStat('Placed', '${_placedObjects.length}/${_venueConfig?.placements.length ?? 0}', Icons.check_circle_outline),
                          // _buildHeaderDivider(),
                          // _buildHeaderStat('Alerts', '$_disruptionsHandled/5', Icons.warning_amber_rounded),
                          // _buildHeaderDivider(),
                          // Removed redundant Score placeholder as we have DONE button now
                          // _buildHeaderStat('Score', '-', Icons.star_border_rounded),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Expanded Venue Area
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                   return Stack(
                     children: [
                       // Venue Container
                       Positioned.fill(
                         child: Padding(
                           padding: const EdgeInsets.all(8),
                           child: Center(
                             child: LayoutBuilder(
                               builder: (context, constraints) {
                                 // Calculate a 3:4 aspect ratio size (wider than 9:16)
                                 double width = constraints.maxWidth;
                                 double height = constraints.maxHeight;
                                 
                                 // Target aspect ratio 3:4 = 0.75
                                 if (width / height > 3 / 4) {
                                   width = height * (3 / 4);
                                 } else {
                                   height = width * (4 / 3);
                                 }
                                 
                                 return SizedBox(
                                   width: width,
                                   height: height,
                                   child: DragTarget<Object>(
                                 onAcceptWithDetails: (details) {
                                   final RenderBox box = context.findRenderObject() as RenderBox;
                                   final localPos = box.globalToLocal(details.offset);
                                 },
                                 builder: (context, candidateData, rejectedData) {
                                   return LayoutBuilder(
                                     builder: (context, venueConstraints) {
                                       return DragTarget<Object>(
                                         onAcceptWithDetails: (details) {
                                             final RenderBox box = context.findRenderObject() as RenderBox;
                                             final localPos = box.globalToLocal(details.offset);
                                             
                                             if (details.data is GameItemDef) {
                                               _handleDrop(details.data as GameItemDef, localPos, venueConstraints.biggest);
                                             } else if (details.data is PlacedObject) {
                                               _updateObjectPosition(details.data as PlacedObject, localPos, venueConstraints.biggest);
                                               // We also check here if we dragged it to a "trash" zone, 
                                               // but for now I'll use a dedicated trash target
                                             }
                                         },
                                          builder: (context, candidates, rejects) {
                                            return Container(
                                               decoration: BoxDecoration(
                                                 border: Border.all(color: const Color(0xFFF4EF8B), width: 4),
                                                 borderRadius: BorderRadius.circular(20),
                                                 boxShadow: [
                                                   BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8)),
                                                 ],
                                               ),
                                               child: ClipRRect(
                                                 borderRadius: BorderRadius.circular(16),
                                                 child: Stack(
                                                 children: [
                                                   // Multi-colored venue background
                                                   _buildVenueBackground(venueConstraints),
                                                   
                                                   
                                                    
                                                    // Zone labels (text only, no colored overlays)







                                                   // Trash Zone (Only visible when dragging)
                                                  if (_isDraggingPlacedObject)
                                                    Positioned(
                                                      right: 10,
                                                      bottom: 10,
                                                      child: DragTarget<PlacedObject>(
                                                        onAccept: (object) => _removeObject(object.id),
                                                        builder: (context, candidates, rejected) {
                                                           final isCandidate = candidates.isNotEmpty;
                                                           return Container(
                                                             width: 60,
                                                             height: 60,
                                                             decoration: BoxDecoration(
                                                               color: isCandidate ? Colors.redAccent : Colors.white.withOpacity(0.8),
                                                               borderRadius: BorderRadius.circular(30),
                                                               border: Border.all(color: Colors.red, width: 2),
                                                             ),
                                                             child: Icon(
                                                               Icons.delete_outline,
                                                               color: isCandidate ? Colors.white : Colors.red,
                                                               size: 30,
                                                             ),
                                                           );
                                                        },
                                                      ),
                                                    ),

                                                   ..._placedObjects.map((obj) => _buildPlacedWidget(obj, venueConstraints)),
                                                 ],
                                               ),
                                               ),
                                            );
                                         }
                                       );
                                     }
                                   );
                                 },
                               ),
                                 );
                               }
                             ),
                           ),
                         ),
                       ),
                     ],
                   );
                }
              ),
            ),
            
            // Bottom Object Picker
            Container(
              height: 220,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                boxShadow: [
                   BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5)),
                ],
              ),
              child: Column(
                children: [
                  TabBar(
                    controller: _tabController,
                    isScrollable: true,
                    labelColor: Colors.black,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: const Color(0xFFF4EF8B),
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    tabs: const [
                       Tab(text: "INFRASTRUCTURE"),
                       Tab(text: "GUEST & FLOW"),
                       Tab(text: "DECOR"),
                       Tab(text: "UTILITY"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildHorizontalList('infrastructure'),
                        _buildHorizontalList('guest'),
                        _buildHorizontalList('decor'),
                        _buildHorizontalList('utility'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHorizontalList(String categoryId) {
    if (_itemsConfig == null || _venueConfig == null) return const SizedBox.shrink();
    
    // Filter to only show items that exist in the admin's placement config
    final allowedItemIds = _venueConfig!.placements.map((p) => p.itemId).toSet();

    final items = _itemsConfig!.getItemsByCategory(categoryId)
        .where((config) => allowedItemIds.contains(config.id))
        .map((config) => GameItemDef.fromConfig(config))
        .toList();
        
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No items in this category',
          style: TextStyle(color: Colors.grey[400], fontSize: 12),
        ),
      );
    }
    
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Draggable<GameItemDef>(
             data: item,
             feedback: Transform.scale(
               scale: 1.2,
               child: Material(
                 color: Colors.transparent,
                 child: _buildItemCard(item, isFeedback: true),
               ),
             ),
             child: _buildItemCard(item),
          ),
        );
      },
    );
  }
  
  Widget _buildItemCard(GameItemDef item, {bool isFeedback = false}) {
    return Container(
      width: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white, // White card
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF4EF8B)),
        boxShadow: isFeedback ? [] : [
           BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(item.icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Text(
            item.name,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.black, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  
  Widget _buildZoneWidget(Rect rect, String label, BoxConstraints constraints, [Color? overlayColor]) {
     return Positioned(
       left: (rect.left / 100) * constraints.maxWidth,
       top: (rect.top / 100) * constraints.maxHeight,
       width: (rect.width / 100) * constraints.maxWidth,
       height: (rect.height / 100) * constraints.maxHeight,
       child: Container(
         decoration: BoxDecoration(
           color: overlayColor ?? const Color(0xFFF4EF8B).withOpacity(0.04),
           border: Border.all(color: const Color(0xFFF4EF8B).withOpacity(0.3)), 
           borderRadius: BorderRadius.circular(8),
         ),
         child: Center(
           child: Padding(
             padding: const EdgeInsets.all(2.0),
             child: FittedBox(
               fit: BoxFit.scaleDown,
               child: Text(
                 label.toUpperCase(), 
                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, shadows: [Shadow(color: Colors.black, blurRadius: 2)]),
                 textAlign: TextAlign.center,
               ),
             ),
           ),
         ),
       ),
     );
  }
  
  Widget _buildZoneLabel(Rect rect, String label, BoxConstraints constraints) {
    return Positioned(
      left: (rect.left / 100) * constraints.maxWidth,
      top: (rect.top / 100) * constraints.maxHeight,
      width: (rect.width / 100) * constraints.maxWidth,
      height: (rect.height / 100) * constraints.maxHeight,
      child: IgnorePointer(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: const Color(0xFFFFC107),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.8), blurRadius: 6, offset: const Offset(0, 1)),
                    Shadow(color: Colors.black.withOpacity(0.4), blurRadius: 3),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  
  
  

  // Check if a placed object is in the correct zone

  
  // Helper to check if a point is within a zone

  Widget _buildVenueBackground(BoxConstraints constraints) {
    if (_venueConfig == null) return Container(color: Colors.grey[200]);

    return Stack(
      children: [
        // Base grass/ground layer
        Container(
          color: const Color(0xFF6aa882), // Default grass color
        ),
        
        // Dynamically rendered zones from config
        ..._venueConfig!.zones.map((zone) {
          return Positioned(
            left: zone.x * constraints.maxWidth,
            top: zone.y * constraints.maxHeight,
            width: zone.width * constraints.maxWidth,
            height: zone.height * constraints.maxHeight,
            child: Container(
              decoration: BoxDecoration(
                color: zone.getColor(),
                border: Border.all(color: Colors.black.withOpacity(0.3), width: 1),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 2))
                ],
              ),
              child: Center(
                child: Text(
                  zone.label,
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.6),
                    fontWeight: FontWeight.bold,
                    fontSize: 10 * (constraints.maxWidth / 400),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
  
  Widget _buildPlacedWidget(PlacedObject obj, BoxConstraints constraints) {
     return Positioned(
       left: (obj.x / 100) * constraints.maxWidth - 22.5, // Offset by half size (22.5)
       top: (obj.y / 100) * constraints.maxHeight - 22.5, 
       child: GestureDetector(
         onDoubleTap: () => _removeObject(obj.id),
         child: Draggable<PlacedObject>(
            data: obj,
            onDragStarted: () => setState(() => _isDraggingPlacedObject = true),
            onDragEnd: (details) => setState(() => _isDraggingPlacedObject = false),
            onDraggableCanceled: (velocity, offset) => setState(() => _isDraggingPlacedObject = false),
            feedback: Material(color: Colors.transparent, child: _buildPlacedObjectContent(obj, true)),
            childWhenDragging: Opacity(opacity: 0.3, child: _buildPlacedObjectContent(obj, false)),
            child: _buildPlacedObjectContent(obj, false),
         ),
       ),
     );
  }
  
  Widget _buildPlacedObjectContent(PlacedObject obj, bool isFeedback) {
    // Look up the item icon from config
    String icon = '❓'; // Default icon
    if (_itemsConfig != null) {
      final itemDef = _itemsConfig!.items.firstWhere(
        (item) => item.id == obj.id,
        orElse: () => ItemConfig(
          id: obj.id,
          category: obj.category,
          icon: '❓',
          name: '',
          validZones: [],
          points: 0,
          displayOrder: 0,
        ),
      );
      icon = itemDef.icon;
    }
    
    return Container(
      width: 45, // Reduced size (was 60)
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(22.5), // Circled placed objects
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Center(
        child: Text(icon, style: const TextStyle(fontSize: 24)), // Smaller icon size
      ),
    );
  }
  
  Widget _buildHeaderStat(String label, String value, IconData icon) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900)),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }
  
  Widget _buildHeaderDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[200]);
  }

}
// Tile grid painter for venue floor
class TileGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..strokeWidth = 0.5;

    // Draw vertical lines
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
