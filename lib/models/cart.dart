import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'class.dart';

class Cart with ChangeNotifier {
  final List<String> _items = [];
  final String _cartCollection = 'carts';
  String? _documentId;
  final Uuid _uuid = Uuid();

  List<String> get items => _items;

  Future<void> addItem(String yogaClassId) async {
    if (!_items.contains(yogaClassId)) {
      _items.add(yogaClassId);
      notifyListeners();
      await _saveCartToFirestore();
    }
  }

  Future<void> removeItem(String yogaClassId) async {
    _items.remove(yogaClassId);
    notifyListeners();
    await _saveCartToFirestore();
  }

  bool contains(String yogaClassId) {
    return _items.contains(yogaClassId);
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _saveCartToFirestore();
  }

  Future<void> _saveCartToFirestore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId'); 
    if (userId != null) {
      if (_documentId == null) {
        _documentId = _uuid.v4(); 
      }
      CollectionReference cartCollection = FirebaseFirestore.instance.collection(_cartCollection);
      await cartCollection.doc(_documentId).set({
        'id': _documentId,
        'user_id': userId,
        'items': _items,
      });
    }
  }

  Future<void> loadCartFromFirestore() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId'); 
    if (userId != null) {
      CollectionReference cartCollection = FirebaseFirestore.instance.collection(_cartCollection);
      QuerySnapshot querySnapshot = await cartCollection.where('user_id', isEqualTo: userId).get();
      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot cartSnapshot = querySnapshot.docs.first;
        _documentId = cartSnapshot.id; 
        List<dynamic> items = cartSnapshot['items'];
        _items.clear();
        _items.addAll(items.map((item) => item.toString()).toList());
        notifyListeners();
      }
    }
  }
}
