import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:rxdart/rxdart.dart';

class ContractService {
  final CollectionReference contracts = FirebaseFirestore.instance.collection('contracts');
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create new contract
  Future<void> createContract(String title, String description, int duration, String consequences, List<String> sharedWith) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    await contracts.add({
      'title': title,
      'description': description,
      'duration': duration,
      'consequences': consequences,
      'createdAt': Timestamp.now(),
      'transgressions': {}, // Map to store transgressions by user
      'createdBy': user.uid,
      'createdByEmail': user.email, // Ajout de l'email du créateur
      'sharedWith': sharedWith,
    });
  }

  // Get contracts for current user
  Stream<QuerySnapshot> getActiveContracts() {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    // Requête modifiée pour ne pas filtrer sur les transgressions
    return contracts
        .where(
          Filter.or(
            Filter('createdBy', isEqualTo: user.uid),
            Filter('sharedWith', arrayContains: user.email),
          ),
        )
        .snapshots();
  }

  // Share contract with user
  Future<void> shareContract(String contractId, String email) async {
    final doc = await contracts.doc(contractId).get();
    if (!doc.exists) throw 'Contract not found';

    final data = doc.data() as Map<String, dynamic>;
    final List<String> sharedWith = List<String>.from(data['sharedWith'] ?? []);
    
    if (sharedWith.contains(email)) {
      throw 'Contract already shared with this user';
    }

    sharedWith.add(email);
    await contracts.doc(contractId).update({
      'sharedWith': sharedWith,
    });
  }

  // Remove shared user from contract
  Future<void> removeSharedUser(String contractId, String email) async {
    final doc = await contracts.doc(contractId).get();
    if (!doc.exists) throw 'Contract not found';

    final data = doc.data() as Map<String, dynamic>;
    final List<String> sharedWith = List<String>.from(data['sharedWith'] ?? []);
    
    sharedWith.remove(email);
    await contracts.doc(contractId).update({
      'sharedWith': sharedWith,
    });
  }

  // Report transgression
  Future<void> reportTransgression(String contractId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    try {
      final doc = await contracts.doc(contractId).get();
      if (!doc.exists) throw 'Contract not found';

      final data = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> transgressions = Map<String, dynamic>.from(data['transgressions'] ?? {});
      
      // Utiliser l'email au lieu de l'userId
      final currentCount = (transgressions[user.email!] as int?) ?? 0;
      transgressions[user.email!] = currentCount + 1;

      await contracts.doc(contractId).update({
        'transgressions': transgressions,
      });

      if (currentCount + 1 >= 5) {
        await triggerConsequence(contractId, user.email!);
      }
    } catch (e) {
      print('Error reporting transgression: $e');
      rethrow;
    }
  }

  // Remove transgression (good action)
  Future<void> removeTransgression(String contractId) async {
    final user = _auth.currentUser;
    if (user == null) throw 'User not authenticated';

    try {
      final doc = await contracts.doc(contractId).get();
      if (!doc.exists) throw 'Contract not found';

      final data = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> transgressions = Map<String, dynamic>.from(data['transgressions'] ?? {});
      
      // Utiliser l'email au lieu de l'userId
      final currentCount = (transgressions[user.email!] as int?) ?? 0;
      if (currentCount > 0) {
        transgressions[user.email!] = currentCount - 1;
        await contracts.doc(contractId).update({
          'transgressions': transgressions,
        });
      }
    } catch (e) {
      print('Error removing transgression: $e');
      rethrow;
    }
  }

  // Get user's transgression count for a contract
  int getTransgressionCount(Map<String, dynamic> contractData, String email) {
    try {
      final transgressions = contractData['transgressions'] as Map<String, dynamic>?;
      if (transgressions == null) return 0;
      return (transgressions[email] as int?) ?? 0;
    } catch (e) {
      print('Error getting transgression count: $e');
      return 0;
    }
  }

  // Check if user has failed the contract
  bool hasUserFailed(Map<String, dynamic> contractData, String email) {
    try {
      final count = getTransgressionCount(contractData, email);
      return count >= 5;
    } catch (e) {
      print('Error checking user failure: $e');
      return false;
    }
  }

  // Trigger consequence
  Future<void> triggerConsequence(String contractId, String userId) async {
    // Implement consequence triggering logic
  }
}
