import 'package:flutter/material.dart';
import 'dart:convert';

/// Represents a venue configuration with zones
class VenueConfig {
  final String id;
  final String name;
  final String description;
  final String? backgroundImage; // Path to background image (asset or local file)
  final List<ZoneConfig> zones;
  final List<ItemPlacement> placements;

  const VenueConfig({
    required this.id,
    required this.name,
    required this.description,
    this.backgroundImage,
    required this.zones,
    this.placements = const [],
  });

  factory VenueConfig.fromJson(Map<String, dynamic> json) {
    return VenueConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      backgroundImage: json['backgroundImage'] as String?,
      zones: (json['zones'] as List)
          .map((z) => ZoneConfig.fromJson(z as Map<String, dynamic>))
          .toList(),
      placements: (json['placements'] as List? ?? [])
          .map((p) => ItemPlacement.fromJson(p as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'backgroundImage': backgroundImage,
      'zones': zones.map((z) => z.toJson()).toList(),
      'placements': placements.map((p) => p.toJson()).toList(),
    };
  }
}

/// Represents a zone within a venue
class ZoneConfig {
  final String key;
  final String label;
  final double x;
  final double y;
  final double width;
  final double height;
  final String color;

  const ZoneConfig({
    required this.key,
    required this.label,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.color,
  });

  /// Convert to Rect for positioning
  Rect toRect() => Rect.fromLTWH(x, y, width, height);

  /// Convert hex color string to Color
  Color getColor() {
    final hexColor = color.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  factory ZoneConfig.fromJson(Map<String, dynamic> json) {
    return ZoneConfig(
      key: json['key'] as String,
      label: json['label'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'label': label,
      'x': x,
      'y': y,
      'width': width,
      'height': height,
      'color': color,
    };
  }
}

/// Represents a specific placement of an item in the venue
class ItemPlacement {
  final String id;
  final String itemId;
  final double x;
  final double y;
  
  const ItemPlacement({
    required this.id,
    required this.itemId,
    required this.x,
    required this.y,
  });
  
  factory ItemPlacement.fromJson(Map<String, dynamic> json) {
    return ItemPlacement(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'x': x,
      'y': y,
    };
  }
}

/// Represents a category of items
class ItemCategory {
  final String id;
  final String name;
  final int displayOrder;

  const ItemCategory({
    required this.id,
    required this.name,
    required this.displayOrder,
  });

  factory ItemCategory.fromJson(Map<String, dynamic> json) {
    return ItemCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      displayOrder: json['displayOrder'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'displayOrder': displayOrder,
    };
  }
}

/// Represents a placeable item
class ItemConfig {
  final String id;
  final String category;
  final String icon;
  final String name;
  final List<String> validZones;
  final int points;
  final int displayOrder;

  const ItemConfig({
    required this.id,
    required this.category,
    required this.icon,
    required this.name,
    required this.validZones,
    required this.points,
    required this.displayOrder,
  });

  factory ItemConfig.fromJson(Map<String, dynamic> json) {
    return ItemConfig(
      id: json['id'] as String,
      category: json['category'] as String,
      icon: json['icon'] as String,
      name: json['name'] as String,
      validZones: (json['validZones'] as List).map((z) => z as String).toList(),
      points: json['points'] as int,
      displayOrder: json['displayOrder'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'icon': icon,
      'name': name,
      'validZones': validZones,
      'points': points,
      'displayOrder': displayOrder,
    };
  }
}

/// Container for all items configuration
class ItemsConfig {
  final List<ItemCategory> categories;
  final List<ItemConfig> items;

  const ItemsConfig({
    required this.categories,
    required this.items,
  });

  factory ItemsConfig.fromJson(Map<String, dynamic> json) {
    return ItemsConfig(
      categories: (json['categories'] as List)
          .map((c) => ItemCategory.fromJson(c as Map<String, dynamic>))
          .toList(),
      items: (json['items'] as List)
          .map((i) => ItemConfig.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((c) => c.toJson()).toList(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  /// Get items by category
  List<ItemConfig> getItemsByCategory(String categoryId) {
    return items
        .where((item) => item.category == categoryId)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
  }
}
