import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/app_notification.dart';

/// One page of notifications plus the cursor needed to fetch the next page.
class NotificationPage {
  final List<AppNotification> items;
  final DocumentSnapshot<Map<String, dynamic>>? lastDoc;
  final bool hasMore;

  const NotificationPage({
    required this.items,
    required this.lastDoc,
    required this.hasMore,
  });
}

/// Firestore-backed notification history.
///
/// * `notifications` — shared, store-wide history written by the Cloud Function
///   (single source of truth). Queried here with date-range filters + cursor
///   pagination so we never load the whole collection.
/// * `notification_read_state/{uid}` — a per-user "last read" watermark. Read
///   state is purely chronological (a notification is read when its timestamp
///   is at or before `lastReadAt`). This keeps "mark all read" a single write
///   and syncs read state across all of that user's devices.
class NotificationRepository {
  NotificationRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  static const int pageSize = 30;

  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('notifications');

  DocumentReference<Map<String, dynamic>> get _readStateDoc {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Cannot access notifications: user not authenticated');
    }
    return _db.collection('notification_read_state').doc(uid);
  }

  // ── Read watermark ─────────────────────────────────────────────────────────

  Future<DateTime?> getLastReadAt() async {
    final snap = await _readStateDoc.get();
    final ts = snap.data()?['lastReadAt'];
    return ts is Timestamp ? ts.toDate() : null;
  }

  /// Mark everything read up to "now" — a single write that all of this user's
  /// devices observe.
  Future<void> markAllRead() async {
    await _readStateDoc.set(
      {'lastReadAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  /// Count of notifications newer than the watermark (cheap aggregation query).
  Future<int> unreadCount(DateTime? lastReadAt) async {
    Query<Map<String, dynamic>> q = _col;
    if (lastReadAt != null) {
      q = q.where('timestamp',
          isGreaterThan: Timestamp.fromDate(lastReadAt));
    }
    final agg = await q.count().get();
    return agg.count ?? 0;
  }

  // ── Paginated history ────────────────────────────────────────────────────

  Future<NotificationPage> fetchPage({
    DateTime? from,
    DateTime? to,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    required DateTime? lastReadAt,
    required Set<String> locallyRead,
  }) async {
    Query<Map<String, dynamic>> q =
        _col.orderBy('timestamp', descending: true);
    if (from != null) {
      q = q.where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
    }
    if (to != null) {
      q = q.where('timestamp', isLessThan: Timestamp.fromDate(to));
    }
    q = q.limit(pageSize);
    if (startAfter != null) {
      q = q.startAfterDocument(startAfter);
    }

    final snap = await q.get();
    final items = snap.docs
        .map((d) => _fromDoc(d, lastReadAt, locallyRead))
        .toList();

    return NotificationPage(
      items: items,
      lastDoc: snap.docs.isNotEmpty ? snap.docs.last : startAfter,
      hasMore: snap.docs.length == pageSize,
    );
  }

  Future<void> delete(String id) => _col.doc(id).delete();

  AppNotification _fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> d,
    DateTime? lastReadAt,
    Set<String> locallyRead,
  ) {
    final data = d.data();
    final ts = data['timestamp'];
    // serverTimestamp can be momentarily null on a just-written doc.
    final time = ts is Timestamp ? ts.toDate() : DateTime.now();
    final read = locallyRead.contains(d.id) ||
        (lastReadAt != null && !time.isAfter(lastReadAt));
    return AppNotification(
      id: d.id,
      title: data['title']?.toString() ?? '',
      body: data['body']?.toString() ?? '',
      data: Map<String, dynamic>.from(data['data'] as Map? ?? const {}),
      timestamp: time,
      isRead: read,
    );
  }
}
