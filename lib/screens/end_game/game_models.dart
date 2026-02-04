import 'package:flutter/material.dart';

/// Represents a definition of an object available in the sidebar
class GameItemDef {
  final String id;
  final String category; // 'infrastructure', 'guest', 'decor', 'utility'
  final String icon;
  final String name;
  final List<String> validZones; // Zones where this item should be placed

  const GameItemDef({
    required this.id,
    required this.category,
    required this.icon,
    required this.name,
    this.validZones = const [], // Default to no specific zone requirement
  });
}

/// Represents an object that has been placed on the venue
class PlacedObject {
  final String id; // Matches GameItemDef.id
  final String category;
  double x; // Percentage (0-100)
  double y; // Percentage (0-100)
  final String uniqueId; // Unique identifier for this instance

  PlacedObject({
    required this.id,
    required this.category,
    required this.x,
    required this.y,
    String? uniqueId,
  }) : uniqueId = uniqueId ?? DateTime.now().millisecondsSinceEpoch.toString() + '_' + id;
  
  GameItemDef get definition => GameDefinitions.items.firstWhere((i) => i.id == id);
}

/// Represents a disruption event
class Disruption {
  final String id;
  final String title;
  final String message;
  final List<String> highlightObjects; // IDs of objects to highlight
  final List<DisruptionAction> actions;

  const Disruption({
    required this.id,
    required this.title,
    required this.message,
    required this.highlightObjects,
    required this.actions,
  });
}

class DisruptionAction {
  final String text;
  final VoidCallback? effect; // Logic to run when selected (will be handled by controller)
  // We'll use an ID to identify the action in the main controller since we can't pass closures easily here
  final String id; 

  const DisruptionAction({
    required this.text,
    required this.id,
    this.effect,
  });
}

/// Static definitions for the game
class GameDefinitions {
  static const List<GameItemDef> items = [
    // Core Infrastructure
    GameItemDef(id: 'stage', category: 'infrastructure', icon: '🎪', name: 'Stage', validZones: ['stage']),
    GameItemDef(id: 'stage-steps', category: 'infrastructure', icon: '🪜', name: 'Stage Steps', validZones: ['stage']),
    GameItemDef(id: 'dance-floor', category: 'infrastructure', icon: '💃', name: 'Dance Floor', validZones: ['stage', 'dining']),
    GameItemDef(id: 'sound-console', category: 'infrastructure', icon: '🎛️', name: 'Sound Console', validZones: ['stage']),
    GameItemDef(id: 'speaker-left', category: 'infrastructure', icon: '🔊', name: 'Speaker (Left)', validZones: ['stage', 'dining']),
    GameItemDef(id: 'speaker-right', category: 'infrastructure', icon: '🔊', name: 'Speaker (Right)', validZones: ['stage', 'dining']),
    GameItemDef(id: 'delay-speaker', category: 'infrastructure', icon: '📢', name: 'Delay Speaker', validZones: ['theater', 'dining']),
    GameItemDef(id: 'genset', category: 'infrastructure', icon: '⚡', name: 'Genset', validZones: ['lawn']),
    GameItemDef(id: 'backup-genset', category: 'infrastructure', icon: '🔋', name: 'Backup Genset', validZones: ['lawn']),
    GameItemDef(id: 'distribution-box', category: 'infrastructure', icon: '🔌', name: 'Distribution Box', validZones: ['lawn', 'stage']),

    // Guest & Flow
    GameItemDef(id: 'entrance-arch', category: 'guest', icon: '🏛️', name: 'Entrance Arch', validZones: ['entrance']),
    GameItemDef(id: 'registration-desk', category: 'guest', icon: '📋', name: 'Registration Desk', validZones: ['entrance']),
    GameItemDef(id: 'guest-seating', category: 'guest', icon: '🪑', name: 'Guest Seating', validZones: ['dining', 'theater']),
    GameItemDef(id: 'lounge-tables', category: 'guest', icon: '🪑', name: 'Lounge Tables', validZones: ['dining']),
    GameItemDef(id: 'walkway', category: 'guest', icon: '🚶', name: 'Walkway', validZones: ['entrance', 'dining']),

    // Decor & Ambience
    GameItemDef(id: 'backdrop', category: 'decor', icon: '🖼️', name: 'Backdrop', validZones: ['stage']),
    GameItemDef(id: 'fairy-lights', category: 'decor', icon: '✨', name: 'Fairy Lights', validZones: ['stage', 'dining', 'entrance']),
    GameItemDef(id: 'centerpieces', category: 'decor', icon: '💐', name: 'Centerpieces', validZones: ['dining']),
    GameItemDef(id: 'candles', category: 'decor', icon: '🕯️', name: 'Candles', validZones: ['dining']),
    GameItemDef(id: 'carpet', category: 'decor', icon: '🟫', name: 'Carpet', validZones: ['stage', 'entrance']),

    // F&B & Utility
    GameItemDef(id: 'bar-counter', category: 'utility', icon: '🍸', name: 'Bar Counter', validZones: ['bar']),
    GameItemDef(id: 'buffet-counter', category: 'utility', icon: '🍽️', name: 'Buffet Counter', validZones: ['buffet']),
    GameItemDef(id: 'cake-table', category: 'utility', icon: '🎂', name: 'Cake Table', validZones: ['dining', 'buffet']),
    GameItemDef(id: 'washroom-sign', category: 'utility', icon: '🚻', name: 'Washroom Sign', validZones: ['entrance', 'lawn']),
    GameItemDef(id: 'fire-extinguisher', category: 'utility', icon: '🧯', name: 'Fire Extinguisher', validZones: ['entrance', 'stage', 'bar', 'buffet']),
  ];
}
