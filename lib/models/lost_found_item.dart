import 'package:cloud_firestore/cloud_firestore.dart';

class LostFoundItem {
  final String id;
  final String title;
  final String description;
  final String type; // lost or found
  final String category;
  final String status; // active, matched, returned
  final String createdBy;
  final DateTime eventDate;
  final DateTime createdAt;

  // We will use these later for camera + GPS.
  final String imageUrl;
  final String locationName;
  final double? latitude;
  final double? longitude;

  const LostFoundItem({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.category,
    required this.status,
    required this.createdBy,
    required this.eventDate,
    required this.createdAt,
    this.imageUrl = '',
    this.locationName = '',
    this.latitude,
    this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'type': type,
      'category': category,
      'status': status,
      'createdBy': createdBy,
      'eventDate': Timestamp.fromDate(eventDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'imageUrl': imageUrl,
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory LostFoundItem.fromMap(String id, Map<String, dynamic> map) {
    final eventTimestamp = map['eventDate'] as Timestamp?;
    final createdTimestamp = map['createdAt'] as Timestamp?;

    return LostFoundItem(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      type: map['type'] ?? 'lost',
      category: map['category'] ?? 'Other',
      status: map['status'] ?? 'active',
      createdBy: map['createdBy'] ?? '',
      eventDate: eventTimestamp?.toDate() ?? DateTime.now(),
      createdAt: createdTimestamp?.toDate() ?? DateTime.now(),
      imageUrl: map['imageUrl'] ?? '',
      locationName: map['locationName'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
    );
  }
}
