import 'package:flutter/material.dart';
import '../../models/end_game_config.dart';

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

  /// Create from ItemConfig
  factory GameItemDef.fromConfig(ItemConfig config) {
    return GameItemDef(
      id: config.id,
      category: config.category,
      icon: config.icon,
      name: config.name,
      validZones: config.validZones,
    );
  }
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
