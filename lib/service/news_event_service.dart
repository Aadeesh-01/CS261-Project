import 'package:cloud_firestore/cloud_firestore.dart';
import '../model/news_event_model.dart';

class NewsEventService {
  final CollectionReference posts =
      FirebaseFirestore.instance.collection('news_events');

  Future<void> addPost(NewsEventPost post) async {
    await posts.add(post.toMap());
  }

  Stream<List<NewsEventPost>> getPosts() {
    return posts.orderBy('createdAt', descending: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => NewsEventPost.fromFirestore(doc))
            .toList());
  }

  Future<void> updatePost(String id, Map<String, dynamic> data) async {
    await posts.doc(id).update(data);
  }

  Future<void> deletePost(String id) async {
    await posts.doc(id).delete();
  }
}
