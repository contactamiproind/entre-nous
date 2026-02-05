import 'package:flutter/material.dart';
import 'dart:math';
import 'game_models.dart';

class EndGameScreen extends StatefulWidget {
  const EndGameScreen({super.key});

  @override
  State<EndGameScreen> createState() => _EndGameScreenState();
}

class _EndGameScreenState extends State<EndGameScreen> with TickerProviderStateMixin {
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
  
  // Drag State
  bool _isDraggingPlacedObject = false;
  
  late TabController _tabController;
  
  // Constants for venue zones (percentages) - Based on SketchUp design
  final Rect _stageZone = const Rect.fromLTWH(20, 2, 60, 12);    // Stage platform at top
  final Rect _poolZone = const Rect.fromLTWH(35, 15, 30, 15);    // Pool centered below stage
  final Rect _guestZone = const Rect.fromLTWH(15, 40, 70, 25);   // Dining area (center floor)
  final Rect _theaterZone = const Rect.fromLTWH(15, 70, 70, 18); // Theater at bottom
  final Rect _lawnLeftZone = const Rect.fromLTWH(0, 0, 10, 100); // Left lawn strip
  final Rect _lawnRightZone = const Rect.fromLTWH(90, 0, 10, 100); // Right lawn strip
  final Rect _entranceZone = const Rect.fromLTWH(30, 90, 40, 8); // Entrance at bottom
  final Rect _barZone = const Rect.fromLTWH(11, 10, 15, 10);      // Bar top-left
  final Rect _buffetZone = const Rect.fromLTWH(72, 10, 15, 10);   // Buffet top-right

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _updateStats();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateStats() {
    setState(() {
      _eventScore = max(0, min(100, (_guestScore + _safetyScore + _budgetScore + _aestheticsScore) / 4));
    });
  }

  void _handleDrop(GameItemDef item, Offset localPosition, Size venueSize) {
    double x = (localPosition.dx / venueSize.width) * 100;
    double y = (localPosition.dy / venueSize.height) * 100;

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
    double x = (localPosition.dx / venueSize.width) * 100;
    double y = (localPosition.dy / venueSize.height) * 100;
    
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
    if (_disruptionsHandled >= 5 && _placedObjects.length >= 30) {
      Future.delayed(const Duration(milliseconds: 500), _showGameSummary);
    }
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
                _moveObjectToZone('cake-table', _stageZone);
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
                _moveObjectToZone('guest-seating', _guestZone);
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
                   _moveObjectToZone('candles', _guestZone);
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
                   _moveObjectToZone('bar-counter', _barZone);
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
    final readinessScore = (_placedObjects.length / 40 * 100).clamp(0, 100).toInt();
    final finalScore = ((_guestScore + _safetyScore + _budgetScore + _aestheticsScore + readinessScore) / 5).toInt();

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
             _buildSummaryRow('Guest Experience', _guestScore.toInt()),
             _buildSummaryRow('Safety', _safetyScore.toInt()),
             _buildSummaryRow('Budget Control', _budgetScore.toInt()),
             _buildSummaryRow('Aesthetics', _aestheticsScore.toInt()),
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
                   Text('$finalScore/100', style: const TextStyle(color: Colors.black, fontSize: 28, fontWeight: FontWeight.w900)),
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
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (c) => const EndGameScreen())
                );
              },
              child: const Text('PLAY AGAIN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        child: Column(
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
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Colors.black,
                              letterSpacing: 1,
                            ),
                          ),
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
                          _buildHeaderStat('Placed', '${_placedObjects.length}/40', Icons.check_circle_outline),
                          _buildHeaderDivider(),
                          _buildHeaderStat('Alerts', '$_disruptionsHandled/5', Icons.warning_amber_rounded),
                          _buildHeaderDivider(),
                          _buildHeaderStat('Score', '-', Icons.star_border_rounded),
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
                                                    _buildZoneLabel(_stageZone, 'STAGE', venueConstraints),
                                                    _buildZoneLabel(_poolZone, 'POOL', venueConstraints),
                                                    _buildZoneLabel(_guestZone, 'DINING AREA', venueConstraints),
                                                    _buildZoneLabel(_theaterZone, 'THEATER', venueConstraints),
                                                    _buildZoneLabel(_entranceZone, 'ENTRANCE', venueConstraints),
                                                    _buildZoneLabel(_barZone, 'BAR', venueConstraints),
                                                    _buildZoneLabel(_buffetZone, 'BUFFET', venueConstraints),
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
    final items = GameDefinitions.items.where((i) => i.category == categoryId).toList();
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
  bool _isInCorrectZone(PlacedObject obj) {
    final definition = obj.definition;
    if (definition.validZones.isEmpty) return true; // No zone requirement
    
    // Check which zone the object is in
    final x = obj.x;
    final y = obj.y;
    
    // Check each zone
    if (_isInZone(x, y, _stageZone) && definition.validZones.contains('stage')) return true;
    if (_isInZone(x, y, _poolZone) && definition.validZones.contains('pool')) return true;
    if (_isInZone(x, y, _guestZone) && definition.validZones.contains('dining')) return true;
    if (_isInZone(x, y, _theaterZone) && definition.validZones.contains('theater')) return true;
    if (_isInZone(x, y, _entranceZone) && definition.validZones.contains('entrance')) return true;
    if (_isInZone(x, y, _barZone) && definition.validZones.contains('bar')) return true;
    if (_isInZone(x, y, _buffetZone) && definition.validZones.contains('buffet')) return true;
    if ((_isInZone(x, y, _lawnLeftZone) || _isInZone(x, y, _lawnRightZone)) && definition.validZones.contains('lawn')) return true;
    
    return false;
  }
  
  // Helper to check if a point is within a zone
  bool _isInZone(double x, double y, Rect zone) {
    return x >= zone.left && x <= zone.right && y >= zone.top && y <= zone.bottom;
  }
  
  // Calculate placement score
  int _calculatePlacementScore() {
    int score = 0;
    for (var obj in _placedObjects) {
      if (_isInCorrectZone(obj)) {
        score += 10; // +10 points for correct placement
      }
    }
    return score;
  }
  Widget _buildVenueBackground(BoxConstraints constraints) {

    return Stack(

      children: [

        // Base: Light gray tiled floor with grid

        Container(

          color: const Color(0xFFD3D3D3),

          child: CustomPaint(

            painter: TileGridPainter(),

            size: Size(constraints.maxWidth, constraints.maxHeight),

          ),

        ),

        

        // Left lawn strip

        Positioned(

          left: 0,

          top: 0,

          width: constraints.maxWidth * 0.10,

          height: constraints.maxHeight,

          child: Container(color: const Color(0xFF4CAF50)),

        ),

        

        // Right lawn strip

        Positioned(

          right: 0,

          top: 0,

          width: constraints.maxWidth * 0.10,

          height: constraints.maxHeight,

          child: Container(color: const Color(0xFF4CAF50)),

        ),

        

        // Stage platform (top center, larger)

        Positioned(

          left: constraints.maxWidth * 0.22,

          top: constraints.maxHeight * 0.05,

          width: constraints.maxWidth * 0.56,

          height: constraints.maxHeight * 0.15,

          child: Container(

            decoration: BoxDecoration(

              color: const Color(0xFF5A5A5A),

              borderRadius: BorderRadius.circular(4),

              border: Border.all(color: Colors.black38, width: 2),

            ),

          ),

        ),

        

        // Bar structure (top-left, detailed)

        Positioned(

          left: constraints.maxWidth * 0.11,

          top: constraints.maxHeight * 0.10,

          width: constraints.maxWidth * 0.14,

          height: constraints.maxHeight * 0.10,

          child: Container(

            decoration: BoxDecoration(

              color: Colors.white,

              border: Border.all(color: Colors.black, width: 2),

              borderRadius: BorderRadius.circular(2),

            ),

          ),

        ),

        

        // Buffet structure (top-right, detailed)

        Positioned(

          right: constraints.maxWidth * 0.11,

          top: constraints.maxHeight * 0.10,

          width: constraints.maxWidth * 0.14,

          height: constraints.maxHeight * 0.10,

          child: Container(

            decoration: BoxDecoration(

              color: Colors.white,

              border: Border.all(color: Colors.black, width: 2),

              borderRadius: BorderRadius.circular(2),

            ),

          ),

        ),

        

        // Pool (centered, below stage)

        Positioned(

          left: constraints.maxWidth * 0.37,

          top: constraints.maxHeight * 0.22,

          width: constraints.maxWidth * 0.26,

          height: constraints.maxHeight * 0.12,

          child: Container(

            decoration: BoxDecoration(

              gradient: LinearGradient(

                colors: [const Color(0xFF87CEEB), const Color(0xFF4682B4)],

                begin: Alignment.topLeft,

                end: Alignment.bottomRight,

              ),

              border: Border.all(color: const Color(0xFF2C3E50), width: 3),

              borderRadius: BorderRadius.circular(4),

            ),

          ),

        ),

      ],

    );

  }
  
  Widget _buildPlacedWidget(PlacedObject obj, BoxConstraints constraints) {
     return Positioned(
       left: (obj.x / 100) * constraints.maxWidth - 25, 
       top: (obj.y / 100) * constraints.maxHeight - 25, 
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
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
        borderRadius: BorderRadius.circular(25), // Circled placed objects
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Center(
        child: Text(obj.definition.icon, style: const TextStyle(fontSize: 24)),
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
