import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final Color color;

  Category({
    required this.id,
    required this.name,
    required this.color,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'color': color.toARGB32(),
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      color: Color(json['color']),
    );
  }
}

// Default categories
final List<Category> defaultCategories = [
  Category(id: '1', name: 'Work', color: Colors.blue),
  Category(id: '2', name: 'Study', color: Colors.purple),
  Category(id: '3', name: 'Health', color: Colors.green),
  Category(id: '4', name: 'Personal', color: Colors.orange),
  Category(id: '5', name: 'Other', color: Colors.grey),
];
