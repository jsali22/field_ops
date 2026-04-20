import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/labor_entry.dart';
import '../models/material_entry.dart';
import '../models/project.dart';

// This file defines the DatabaseService class, which provides methods for interacting with the Firestore database.
// The DatabaseService class is responsible for creating projects and streaming projects for the current authenticated user, while ensuring that all operations are performed in the context of an authenticated user.
class DatabaseService {
  DatabaseService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    // Used constructor injection: The constructor optionally accepts instances of FirebaseFirestore and FirebaseAuth, allowing for easier testing and flexibility in providing mock instances during unit tests.
    // If no instances are provided, it defaults to using the singleton instances from the Firebase packages.
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  // These fields store the firebase services being used by this class, and are initialized in the constructor.
  // They are marked as final to indicate that they should not be changed after initialization.
  // _ means the identifier is private to this class, preventing external code from accessing these fields directly, which helps to encapsulate the implementation details and maintain control over how the database and authentication services are used within this class.
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // The createProject method takes a Project instance and saves it to the Firestore database under the current user's collection of projects, ensuring that the user is authenticated before performing the operation.
  // It doesn't return a value, just completion of creating  a project in the database
  Future<void> createProject(Project project) async {
    final String uid =
        _requireCurrentUserUid(); // Ensure we have a valid user ID before trying to access the database, which is crucial for security and data integrity, as it prevents unauthorized access to projects that do not belong to the current user.

    final Project ownedProject = _projectForCurrentUser(
      project,
      uid,
    ); // Create a new Project instance that includes the current user's UID as the ownerUid field, ensuring that the project is associated with the correct user in the database.

    // Find this user's projects collection and add the new project document with the provided data
    // First, it calls the _projectsCollection helper method to get a reference to the Firestore collection for the current user's projects.
    // Then, it uses the doc method to specify the document ID (which is the project's ID) inside the collection,
    // and the set method to save the project's data (converted to a map using the project.toMap method) to Firestore (because Firestore stores maps, not Dart objects).
    await _projectsCollection(
      uid,
    ).doc(ownedProject.id).set(ownedProject.toMap());
  }

  // The streamProjectsForCurrentUser method returns a stream of lists of Project instances (live) that belong to the currently authenticated user, ordered by the updatedAt timestamp in descending order.
  // This is what Riverpod will listen to in the UI to automatically update the project list whenever changes occur in the database.
  Stream<List<Project>> streamProjectsForCurrentUser() {
    // Every time a project is added, updated, or removed in the Firestore collection for the current user, this stream will emit a new list of Project instances reflecting the current state of the database.
    final String uid =
        _requireCurrentUserUid(); // Ensure we have a valid user ID before trying to access the database, which is crucial for security and data integrity, as it prevents unauthorized access to projects that do not belong to the current user.

    return _projectsCollection(
          uid,
        ) // Access the Firestore collection for the current user's projects
        .orderBy(
          'updatedAt',
          descending: true,
        ) // Order projects by the updatedAt timestamp in descending order (modified recently updated projects will appear first)
        .snapshots() // Firestore sends updates (snapshots) whenever a project is added, updated, or removed. (Don't just get the data once, but listen for changes over time)
        .map(
          // Transforms each firestore snapshot into a list of Project instances. (The map method is used to convert the raw Firestore data into our application's Project model, making it easier to work with in the UI and other parts of the app.)
          (QuerySnapshot<Map<String, dynamic>> snapshot) => snapshot
              .docs // A snapshot here represents the current state of the projects collection for the user. If the collection contains multiple projects, the snapshot will include all of them, and this code will convert each document in the snapshot into a Project instance.
              .map(
                // Maps each Firestore document into a Project object.
                (
                  QueryDocumentSnapshot<Map<String, dynamic>> doc,
                ) => // A snapshot here represents the current state of the projects collection for the user. If the collection contains multiple projects, the snapshot will include all of them, and this code will convert each document in the snapshot into a Project instance.
                Project.fromMap(
                  // Create a Project instance from the Firestore document data. The fromMap factory constructor is responsible for converting the raw data from Firestore into a structured Project object that our application can use.
                  <String, dynamic>{
                    ...doc
                        .data(), // Returns the Firestore document data as a map, which contains all the fields of the project (like name, description, etc.) that were saved in the database. The spread operator (...) is used to include all key-value pairs from the document data into the new map being created for the Project.fromMap constructor.
                    'id':
                        (doc.data()['id'] as String?) ??
                        doc.id, // If the docuement data contains an 'id' field, use it; otherwise, use the document's ID from Firestore (which is the unique identifier for that document in the collection).
                    'ownerUid': uid,
                  },
                ),
              )
              .toList(
                growable: false,
              ), // After mappng each document to a Project instance, we convert the resulting iterable into a list of projects. The growable: false parameter indicates that the list should be fixed-length, which can help with performance and memory usage since we don't need to add or remove items from this list after it's created.
        );
  }

  // The createLaborEntry method takes a LaborEntry instance and saves it to the Firestore database under the current user's collection of projects, ensuring that the user is authenticated before performing the operation. It saves the labor entry as a document in a subcollection called 'labor_entries' under the specific project document.
  Future<void> createLaborEntry(LaborEntry entry) async {
    final String uid = _requireCurrentUserUid();

    await _laborEntriesCollection(uid, entry.projectId)
        .doc(entry.id)
        .set(
          entry.toMap(),
        ); // Save the labor entry data (converted to a map using the entry.toMap method) to Firestore under the path: users/{uid}/projects/{projectId}/labor_entries/{entryId}, where {uid} is the current user's UID, {projectId} is the ID of the project that this labor entry belongs to, and {entryId} is the unique ID of the labor entry.
  }

  // The streamLaborEntriesForProject method returns a stream of lists of LaborEntry instances that belong to a specific project for the current authenticated user, ordered by the date field in descending order. This allows the UI to reactively update with the latest labor entries for a project whenever there are changes in the Firestore database.
  Stream<List<LaborEntry>> streamLaborEntriesForProject(String projectId) {
    final String uid = _requireCurrentUserUid();

    return _laborEntriesCollection(uid, projectId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          // Transforms each Firestore snapshot into a iterablelist of LaborEntry instances.
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

  // The deleteLaborEntry method deletes a specific labor entry from the Firestore database for a given project and entry ID, ensuring that the user is authenticated before performing the operation. It removes the document corresponding to the labor entry from the 'labor_entries' subcollection under the specified project document.
  Future<void> deleteLaborEntry(String projectId, String entryId) async {
    final String uid =
        _requireCurrentUserUid(); // Ensure we have a valid user ID before trying to access the database

    await _laborEntriesCollection(uid, projectId)
        .doc(entryId)
        .delete(); // Delete the labor entry document from Firestore at the path: users/{uid}/projects/{projectId}/labor_entries/{entryId}, where {uid} is the current user's UID, {projectId} is the ID of the project that this labor entry belongs to, and {entryId} is the unique ID of the labor entry to be deleted.
  }

  // The updateLaborEntry method takes a LaborEntry instance and updates the corresponding document in the Firestore database for the given project and entry ID, ensuring that the user is authenticated before performing the operation.
  Future<void> updateLaborEntry(LaborEntry entry) async {
    final String uid = _requireCurrentUserUid();

    // Save the updated labor entry data (converted to a map using the entry.toMap method) to Firestore under the path: users/{uid}/projects/{projectId}/labor_entries/{entryId}, where {uid} is the current user's UID, {projectId} is the ID of the project that this labor entry belongs to, and {entryId} is the unique ID of the labor entry. This will overwrite the existing document with the new data from the entry.
    await _laborEntriesCollection(
      uid,
      entry.projectId,
    ).doc(entry.id).set(entry.toMap());
  }

  // The createMaterialEntry method takes a MaterialEntry instance and saves it to the Firestore database under the current user's collection of projects, ensuring that the user is authenticated before performing the operation.
  Future<void> createMaterialEntry(MaterialEntry entry) async {
    final String uid = _requireCurrentUserUid();

    await _materialEntriesCollection(
      uid,
      entry.projectId,
    ).doc(entry.id).set(entry.toMap());
  }

  // The streamMaterialEntriesForProject method returns a stream of lists of MaterialEntry instances that belong to a specific project for the current authenticated user, ordered by the date field in descending order.
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

  // The deleteMaterialEntry method deletes a specific material entry from the Firestore database for a given project and entry ID, ensuring that the user is authenticated before performing the operation. It removes the document corresponding to the material entry from the 'material_entries' subcollection under the specified project document.
  Future<void> deleteMaterialEntry(String projectId, String entryId) async {
    final String uid = _requireCurrentUserUid();

    await _materialEntriesCollection(uid, projectId)
        .doc(entryId)
        .delete(); // Delete the material entry document from Firestore at the path: users/{uid}/projects/{projectId}/material_entries/{entryId}, where {uid} is the current user's UID, {projectId} is the ID of the project that this material entry belongs to, and {entryId} is the unique ID of the material entry to be deleted.
  }

  // The updateMaterialEntry method takes a MaterialEntry instance and updates the corresponding document in the Firestore database for the given project and entry ID, ensuring that the user is authenticated before performing the operation.
  Future<void> updateMaterialEntry(MaterialEntry entry) async {
    final String uid = _requireCurrentUserUid();

    // Save the updated material entry data (converted to a map using the entry.toMap method) to Firestore under the path: users/{uid}/projects/{projectId}/material_entries/{entryId}, where {uid} is the current user's UID, {projectId} is the ID of the project that this material entry belongs to, and {entryId} is the unique ID of the material entry. This will overwrite the existing document with the new data from the entry.
    await _materialEntriesCollection(
      uid,
      entry.projectId,
    ).doc(entry.id).set(entry.toMap());
  }

  // The _projectsCollection method is a helper function that returns a reference to the Firestore collection for the current user's projects ( tpo avoid repeating the collection path logic in multiple places).
  CollectionReference<Map<String, dynamic>> _projectsCollection(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection(
          'projects',
        ); // returns a Firestore reference to this path: users/{uid}/projects, where {uid} is the unique identifier of the currently authenticated user.
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

  // The _projectForCurrentUser method is a helper function that takes a Project instance and a user ID (uid) and returns a new Project instance with the ownerUid field set to the provided user ID. This ensures that when we create a project, it is associated with the correct user in the database.
  Project _projectForCurrentUser(Project project, String uid) {
    return project.copyWith(
      ownerUid: uid,
    ); // Creates a new Project instance by copying the existing project and setting the ownerUid field to the provided user ID (uid). This is important for ensuring that the project is associated with the correct user in the database
  }

  // helper function that retrieves the UID of the currently authenticated user and throws an error if no user is authenticated.
  String _requireCurrentUserUid() {
    final User? user = _auth
        .currentUser; // Get the currently authenticated user from FirebaseAuth. The currentUser property returns a User object if a user is logged in, or null (?) if no user is authenticated/ logged in.
    if (user == null) {
      throw StateError(
        'No authenticated user is available for project database operations.',
      );
    }

    return user.uid;
  }
}
