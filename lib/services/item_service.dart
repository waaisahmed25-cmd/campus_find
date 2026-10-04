import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/lost_found_item.dart';

class ItemService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _itemsCollection {
    return _firestore.collection('items');
  }

  Future<String> createItem({required LostFoundItem item}) async {
    final document = await _itemsCollection.add({
      ...item.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });

    return document.id;
  }

  Stream<List<LostFoundItem>> getAllItems() {
    return _itemsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LostFoundItem.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<LostFoundItem>> getLostItems() {
    return _itemsCollection
        .where('type', isEqualTo: 'lost')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LostFoundItem.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<LostFoundItem>> getFoundItems() {
    return _itemsCollection
        .where('type', isEqualTo: 'found')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LostFoundItem.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Stream<List<LostFoundItem>> getItemsByUser(String userId) {
    return _itemsCollection
        .where('createdBy', isEqualTo: userId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LostFoundItem.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<void> updateItemStatus({
    required String itemId,
    required String status,
  }) async {
    await _itemsCollection.doc(itemId).update({'status': status});
  }

  Future<void> updateItem({
    required String itemId,
    required Map<String, dynamic> data,
  }) async {
    await _itemsCollection.doc(itemId).update(data);
  }

  Future<void> deleteItem({required String itemId}) async {
    await _itemsCollection.doc(itemId).delete();
  }
}
