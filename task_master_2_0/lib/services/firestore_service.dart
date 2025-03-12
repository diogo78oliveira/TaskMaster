import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:task_master_2_0/models/user_model.dart';

class FirestoreService {
  final CollectionReference usersCollection = 
      FirebaseFirestore.instance.collection('users');

  // Create a new user
  Future<void> addUser(UserModel user) async {
    await usersCollection.add(user.toMap());
  }

  // Read all users
  Stream<List<UserModel>> getUsers() {
    return usersCollection.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => 
            UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  // Update a user
  Future<void> updateUser(UserModel user) async {
    await usersCollection.doc(user.id).update(user.toMap());
  }

  // Delete a user
  Future<void> deleteUser(String userId) async {
    await usersCollection.doc(userId).delete();
  }
}