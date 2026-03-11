import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/project.dart';

// This file defines the DatabaseService class, which provides methods for interacting with the Firestore database.
// The DatabaseService class is responsible for creating projects and streaming projects for the current authenticated user, while ensuring that all operations are performed in the context of an authenticated user.
class DatabaseService {
  DatabaseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    // Used constructor injection so the service can still use the real Firebase singletons by default, but it’s easier to test or mock later if needed.
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

// The createProject method takes a Project instance and saves it to the Firestore database under the current user's collection of projects, ensuring that the user is authenticated before performing the operation.
  Future<void> createProject(Project project) async {
    final String uid = _requireCurrentUserUid();

    // Ensure the project has the correct ownerUid before saving to Firestore
    await _projectsCollection(uid).doc(project.id).set(project.toMap());
  }

// The streamProjectsForCurrentUser method returns a stream of lists of Project instances that belong to the currently authenticated user, ordered by the updatedAt timestamp in descending order. 
// It listens to changes in the Firestore collection and maps the documents to Project instances, ensuring that the ownerUid is set to the current user's UID if it's not already present in the document data.
  Stream<List<Project>> streamProjectsForCurrentUser() {
    final String uid = _requireCurrentUserUid();

    return _projectsCollection(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    Project.fromMap(
                  <String, dynamic>{
                    ...doc.data(),
                    'id': (doc.data()['id'] as String?) ?? doc.id,
                    'ownerUid':
                        (doc.data()['ownerUid'] as String?) ?? uid,
                  },
                ),
              )
              .toList(growable: false),
        );
  }

// The _projectsCollection method is a helper function that returns a reference to the Firestore collection for the current user's projects, 
  CollectionReference<Map<String, dynamic>> _projectsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('projects');
  }

  // helper function that retrieves the UID of the currently authenticated user and throws an error if no user is authenticated.
  String _requireCurrentUserUid() {
    final User? user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'No authenticated user is available for project database operations.',
      );
    }

    return user.uid;
  }
}
