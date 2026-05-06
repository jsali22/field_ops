import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/labor_entry.dart';
import '../models/material_entry.dart';
import '../models/project.dart';

// Centralizes all Firestore reads and writes under the current user's
// `users/{uid}/...` path so ownership stays consistent across the app.
class DatabaseService {
  DatabaseService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // Project writes are normalized here so ownerUid always comes from the
  // signed-in user instead of being trusted from the UI layer.
  Future<void> createProject(Project project) async {
    final String uid = _requireCurrentUserUid();
    final Project ownedProject = _projectForCurrentUser(project, uid);

    await _projectsCollection(
      uid,
    ).doc(ownedProject.id).set(ownedProject.toMap());
  }

  Future<void> updateProject(Project project) async {
    final String uid = _requireCurrentUserUid();
    final Project ownedProject = _projectForCurrentUser(project, uid);

    await _projectsCollection(
      uid,
    ).doc(ownedProject.id).set(ownedProject.toMap());
  }

  Future<void> deleteProject(String projectId) async {
    final String uid = _requireCurrentUserUid();
    await _projectsCollection(uid).doc(projectId).delete();
  }

  // Firestore snapshots keep the project list live without any manual refresh.
  Stream<List<Project>> streamProjectsForCurrentUser() {
    final String uid = _requireCurrentUserUid();

    return _projectsCollection(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    Project.fromMap(<String, dynamic>{
                      ...doc.data(),
                      'id': (doc.data()['id'] as String?) ?? doc.id,
                      'ownerUid': uid,
                    }),
              )
              .toList(growable: false),
        );
  }

  Future<void> createLaborEntry(LaborEntry entry) async {
    final String uid = _requireCurrentUserUid();
    await _laborEntriesCollection(
      uid,
      entry.projectId,
    ).doc(entry.id).set(entry.toMap());
  }

  Stream<List<LaborEntry>> streamLaborEntriesForProject(String projectId) {
    final String uid = _requireCurrentUserUid();

    return _laborEntriesCollection(uid, projectId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    LaborEntry.fromMap(<String, dynamic>{
                      ...doc.data(),
                      'id': (doc.data()['id'] as String?) ?? doc.id,
                      'projectId':
                          (doc.data()['projectId'] as String?) ?? projectId,
                    }),
              )
              .toList(growable: false),
        );
  }

  Future<void> deleteLaborEntry(String projectId, String entryId) async {
    final String uid = _requireCurrentUserUid();
    await _laborEntriesCollection(uid, projectId).doc(entryId).delete();
  }

  Future<void> updateLaborEntry(LaborEntry entry) async {
    final String uid = _requireCurrentUserUid();
    await _laborEntriesCollection(
      uid,
      entry.projectId,
    ).doc(entry.id).set(entry.toMap());
  }

  Future<void> createMaterialEntry(MaterialEntry entry) async {
    final String uid = _requireCurrentUserUid();
    await _materialEntriesCollection(
      uid,
      entry.projectId,
    ).doc(entry.id).set(entry.toMap());
  }

  Stream<List<MaterialEntry>> streamMaterialEntriesForProject(
    String projectId,
  ) {
    final String uid = _requireCurrentUserUid();

    return _materialEntriesCollection(uid, projectId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot.docs
              .map(
                (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                    MaterialEntry.fromMap(<String, dynamic>{
                      ...doc.data(),
                      'id': (doc.data()['id'] as String?) ?? doc.id,
                      'projectId':
                          (doc.data()['projectId'] as String?) ?? projectId,
                    }),
              )
              .toList(growable: false),
        );
  }

  Future<void> deleteMaterialEntry(String projectId, String entryId) async {
    final String uid = _requireCurrentUserUid();
    await _materialEntriesCollection(uid, projectId).doc(entryId).delete();
  }

  Future<void> updateMaterialEntry(MaterialEntry entry) async {
    final String uid = _requireCurrentUserUid();
    await _materialEntriesCollection(
      uid,
      entry.projectId,
    ).doc(entry.id).set(entry.toMap());
  }

  // Collection helpers keep the Firestore path structure in one place.
  CollectionReference<Map<String, dynamic>> _projectsCollection(String uid) {
    return _firestore.collection('users').doc(uid).collection('projects');
  }

  CollectionReference<Map<String, dynamic>> _laborEntriesCollection(
    String uid,
    String projectId,
  ) {
    return _projectsCollection(uid).doc(projectId).collection('labor_entries');
  }

  CollectionReference<Map<String, dynamic>> _materialEntriesCollection(
    String uid,
    String projectId,
  ) {
    return _projectsCollection(
      uid,
    ).doc(projectId).collection('material_entries');
  }

  Project _projectForCurrentUser(Project project, String uid) {
    return project.copyWith(ownerUid: uid);
  }

  // Fail fast if auth disappears before a database call starts.
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
