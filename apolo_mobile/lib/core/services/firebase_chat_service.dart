import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_options.dart';
import '../../screens/widgets/chat_utils.dart';

/// Real-time Cloud Firestore Chat Service for Apolo (Web + Mobile).
///
/// Collections:
/// - `conversations/{docId}`
/// - `conversations/{docId}/messages/{messageId}`
class FirebaseChatService {
  FirebaseChatService._();
  static final FirebaseChatService instance = FirebaseChatService._();

  bool _isReady = false;
  bool get isReady => _isReady;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  /// Safe initialization (never throws in headless widget tests).
  Future<bool> initialize() async {
    if (_isReady) return true;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: ApoloFirebaseOptions.currentPlatform,
        );
      }
      _isReady = true;
      return true;
    } catch (e) {
      debugPrint('FirebaseChatService init skipped/failed: $e');
      _isReady = false;
      return false;
    }
  }

  /// Deterministic conversation document ID so buyer & seller always join the
  /// exact same room for a given ad.
  String buildConversationDocId({
    required int myUserId,
    required int peerUserId,
    int adId = 0,
  }) {
    final low = myUserId <= peerUserId ? myUserId : peerUserId;
    final high = myUserId <= peerUserId ? peerUserId : myUserId;
    if (adId > 0) {
      return 'ad_${adId}_u_${low}_$high';
    }
    return 'dm_u_${low}_$high';
  }

  /// Ensures a conversation document exists in Firestore and returns its docId.
  Future<String> ensureConversation({
    required int myUserId,
    required String myName,
    String myAvatar = '',
    required int peerUserId,
    required String peerName,
    String peerAvatar = '',
    int adId = 0,
    String adTitle = '',
    String adPrice = '',
    String adImage = '',
  }) async {
    final docId = buildConversationDocId(
      myUserId: myUserId,
      peerUserId: peerUserId,
      adId: adId,
    );
    final docRef = _conversations.doc(docId);
    final myKey = '$myUserId';
    final peerKey = '$peerUserId';
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'participants': [myKey, peerKey],
        'participants_meta': {
          myKey: {
            'id': myUserId,
            'name': myName.trim().isNotEmpty ? myName.trim() : 'Apolo User',
            'avatar': myAvatar,
          },
          peerKey: {
            'id': peerUserId,
            'name': peerName.trim().isNotEmpty ? peerName.trim() : 'Apolo Seller',
            'avatar': peerAvatar,
          },
        },
        'ad_id': adId,
        'ad_title': adTitle,
        'ad_price': adPrice,
        'ad_image': adImage,
        'last_message': '',
        'last_message_type': 'text',
        'last_sender_id': '',
        'updated_at_ms': nowMs,
        'unread_counts': {
          myKey: 0,
          peerKey: 0,
        },
        'typing': {
          myKey: false,
          peerKey: false,
        },
        'deleted_by': <String>[],
      });
    } else {
      // Un-hide if previously deleted by current user and refresh profile meta
      await docRef.set({
        'participants_meta': {
          myKey: {
            'id': myUserId,
            'name': myName.trim().isNotEmpty ? myName.trim() : 'Apolo User',
            'avatar': myAvatar,
          },
          peerKey: {
            'id': peerUserId,
            'name': peerName.trim().isNotEmpty ? peerName.trim() : 'Apolo Seller',
            'avatar': peerAvatar,
          },
        },
        if (adTitle.isNotEmpty) 'ad_title': adTitle,
        if (adPrice.isNotEmpty) 'ad_price': adPrice,
        if (adImage.isNotEmpty) 'ad_image': adImage,
        'deleted_by': FieldValue.arrayRemove([myKey]),
      }, SetOptions(merge: true));
    }

    return docId;
  }

  /// Real-time stream of all conversations for [myUserId], sorted newest first.
  Stream<List<Map<String, dynamic>>> watchConversations(int myUserId) {
    final myKey = '$myUserId';
    return _conversations
        .where('participants', arrayContains: myKey)
        .snapshots()
        .map((snapshot) {
      final list = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final deletedBy = (data['deleted_by'] is List)
            ? (data['deleted_by'] as List).map((e) => '$e').toList()
            : const <String>[];
        if (deletedBy.contains(myKey)) continue;

        final participants = (data['participants'] is List)
            ? (data['participants'] as List).map((e) => '$e').toList()
            : const <String>[];
        final peerKey = participants.firstWhere(
          (p) => p != myKey,
          orElse: () => myKey,
        );

        final metaMap = data['participants_meta'] is Map
            ? Map<String, dynamic>.from(data['participants_meta'] as Map)
            : const <String, dynamic>{};
        final peerMeta = metaMap[peerKey] is Map
            ? Map<String, dynamic>.from(metaMap[peerKey] as Map)
            : const <String, dynamic>{};

        final unreadMap = data['unread_counts'] is Map
            ? Map<String, dynamic>.from(data['unread_counts'] as Map)
            : const <String, dynamic>{};
        final unreadCount = int.tryParse('${unreadMap[myKey] ?? 0}') ?? 0;

        final updatedMs =
            int.tryParse('${data['updated_at_ms'] ?? 0}') ?? 0;
        final timeLabel = updatedMs > 0
            ? formatChatClock(DateTime.fromMillisecondsSinceEpoch(updatedMs))
            : '';

        final lastMsgRaw = (data['last_message'] ?? '').toString().trim();
        final lastType = (data['last_message_type'] ?? 'text').toString();
        final String displayLastMsg;
        if (lastMsgRaw.isNotEmpty) {
          displayLastMsg = lastMsgRaw;
        } else if (lastType == 'image') {
          displayLastMsg = '📷 Photo';
        } else {
          displayLastMsg = '';
        }

        final peerIdInt = int.tryParse('${peerMeta['id'] ?? peerKey}') ?? 0;
        final syntheticIntId = doc.id.hashCode.abs();

        list.add({
          'id': syntheticIntId,
          'firestore_doc_id': doc.id,
          'ad_id': int.tryParse('${data['ad_id'] ?? 0}') ?? 0,
          'ad_title': (data['ad_title'] ?? '').toString(),
          'ad_price': (data['ad_price'] ?? '').toString(),
          'ad_image': (data['ad_image'] ?? '').toString(),
          'peer_id': peerIdInt,
          'peer_name':
              (peerMeta['name'] ?? 'Apolo User').toString().trim(),
          'peer_avatar': (peerMeta['avatar'] ?? '').toString(),
          'peer_online': true,
          'last_message': displayLastMsg,
          'last_message_time': timeLabel,
          'updated_at_ms': updatedMs,
          'unread_count': unreadCount,
        });
      }

      list.sort((a, b) {
        final aMs = (a['updated_at_ms'] as int?) ?? 0;
        final bMs = (b['updated_at_ms'] as int?) ?? 0;
        return bMs.compareTo(aMs);
      });
      return list;
    });
  }

  /// Watches conversation metadata (typing state, participants, etc.).
  Stream<Map<String, dynamic>?> watchConversationDoc(String docId) {
    return _conversations.doc(docId).snapshots().map((doc) => doc.data());
  }

  /// Real-time stream of messages inside a conversation.
  Stream<List<Map<String, dynamic>>> watchMessages(
    String docId,
    int myUserId,
  ) {
    final myKey = '$myUserId';
    return _conversations
        .doc(docId)
        .collection('messages')
        .orderBy('created_at_ms', descending: false)
        .snapshots()
        .map((snapshot) {
      final result = <Map<String, dynamic>>[];

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final deletedFor = (data['deleted_for'] is List)
            ? (data['deleted_for'] as List).map((e) => '$e').toList()
            : const <String>[];
        if (deletedFor.contains(myKey)) continue;

        final senderKey = '${data['sender_id'] ?? ''}';
        final isMine = senderKey == myKey;
        final readBy = (data['read_by'] is List)
            ? (data['read_by'] as List).map((e) => '$e').toList()
            : const <String>[];
        final isReadByPeer = readBy.any((u) => u != myKey);

        final createdMs = int.tryParse('${data['created_at_ms'] ?? 0}') ?? 0;
        final clock = createdMs > 0
            ? formatChatClock(DateTime.fromMillisecondsSinceEpoch(createdMs))
            : '';

        result.add({
          'id': doc.id,
          'doc_id': doc.id,
          'sender_id': senderKey,
          'sender_name': (data['sender_name'] ?? '').toString(),
          'type': (data['type'] ?? 'text').toString(),
          'body': (data['body'] ?? '').toString(),
          'image_base64': (data['image_base64'] ?? '').toString(),
          'is_mine': isMine,
          'read': isReadByPeer,
          'created_at_ms': createdMs,
          'created_at_time': clock,
          '_edited': data['edited'] == true,
          '_deleted_for_everyone': data['deleted_for_everyone'] == true,
        });
      }

      return result;
    });
  }

  Future<void> sendTextMessage({
    required String docId,
    required int myUserId,
    required String myName,
    String myAvatar = '',
    required int peerUserId,
    required String peerName,
    String peerAvatar = '',
    required String body,
    int adId = 0,
    String adTitle = '',
    String adPrice = '',
    String adImage = '',
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final myKey = '$myUserId';
    final peerKey = '$peerUserId';
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final convRef = _conversations.doc(docId);

    // Ensure conversation doc exists & update summary atomically
    await convRef.set({
      'participants': [myKey, peerKey],
      'participants_meta': {
        myKey: {
          'id': myUserId,
          'name': myName.trim().isNotEmpty ? myName.trim() : 'Apolo User',
          'avatar': myAvatar,
        },
        peerKey: {
          'id': peerUserId,
          'name': peerName.trim().isNotEmpty ? peerName.trim() : 'Apolo Seller',
          'avatar': peerAvatar,
        },
      },
      if (adId > 0) 'ad_id': adId,
      if (adTitle.isNotEmpty) 'ad_title': adTitle,
      if (adPrice.isNotEmpty) 'ad_price': adPrice,
      if (adImage.isNotEmpty) 'ad_image': adImage,
      'last_message': trimmed,
      'last_message_type': 'text',
      'last_sender_id': myKey,
      'updated_at_ms': nowMs,
      'unread_counts': {
        myKey: 0,
        peerKey: FieldValue.increment(1),
      },
      'typing': {
        myKey: false,
      },
      'deleted_by': FieldValue.arrayRemove([myKey, peerKey]),
    }, SetOptions(merge: true));

    await convRef.collection('messages').add({
      'sender_id': myKey,
      'sender_name': myName,
      'type': 'text',
      'body': trimmed,
      'created_at_ms': nowMs,
      'read_by': [myKey],
      'edited': false,
      'deleted_for_everyone': false,
      'deleted_for': <String>[],
    });
  }

  Future<void> sendImageMessage({
    required String docId,
    required int myUserId,
    required String myName,
    String myAvatar = '',
    required int peerUserId,
    required String peerName,
    String peerAvatar = '',
    required String imageBase64,
    String caption = '',
    int adId = 0,
    String adTitle = '',
    String adPrice = '',
    String adImage = '',
  }) async {
    final myKey = '$myUserId';
    final peerKey = '$peerUserId';
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final convRef = _conversations.doc(docId);

    await convRef.set({
      'participants': [myKey, peerKey],
      'participants_meta': {
        myKey: {
          'id': myUserId,
          'name': myName.trim().isNotEmpty ? myName.trim() : 'Apolo User',
          'avatar': myAvatar,
        },
        peerKey: {
          'id': peerUserId,
          'name': peerName.trim().isNotEmpty ? peerName.trim() : 'Apolo Seller',
          'avatar': peerAvatar,
        },
      },
      if (adId > 0) 'ad_id': adId,
      if (adTitle.isNotEmpty) 'ad_title': adTitle,
      if (adPrice.isNotEmpty) 'ad_price': adPrice,
      if (adImage.isNotEmpty) 'ad_image': adImage,
      'last_message': caption.trim().isNotEmpty ? caption.trim() : '📷 Photo',
      'last_message_type': 'image',
      'last_sender_id': myKey,
      'updated_at_ms': nowMs,
      'unread_counts': {
        myKey: 0,
        peerKey: FieldValue.increment(1),
      },
      'typing': {
        myKey: false,
      },
      'deleted_by': FieldValue.arrayRemove([myKey, peerKey]),
    }, SetOptions(merge: true));

    await convRef.collection('messages').add({
      'sender_id': myKey,
      'sender_name': myName,
      'type': 'image',
      'body': caption.trim(),
      'image_base64': imageBase64,
      'created_at_ms': nowMs,
      'read_by': [myKey],
      'edited': false,
      'deleted_for_everyone': false,
      'deleted_for': <String>[],
    });
  }

  Future<void> editMessage({
    required String docId,
    required String messageDocId,
    required String newBody,
  }) async {
    final trimmed = newBody.trim();
    if (trimmed.isEmpty) return;
    await _conversations
        .doc(docId)
        .collection('messages')
        .doc(messageDocId)
        .update({
      'body': trimmed,
      'edited': true,
    });
  }

  Future<void> deleteMessageForMe({
    required String docId,
    required String messageDocId,
    required int myUserId,
  }) async {
    await _conversations
        .doc(docId)
        .collection('messages')
        .doc(messageDocId)
        .update({
      'deleted_for': FieldValue.arrayUnion(['$myUserId']),
    });
  }

  Future<void> deleteMessageForEveryone({
    required String docId,
    required String messageDocId,
  }) async {
    await _conversations
        .doc(docId)
        .collection('messages')
        .doc(messageDocId)
        .update({
      'deleted_for_everyone': true,
      'body': '',
      'image_base64': '',
    });
  }

  Future<void> markConversationRead({
    required String docId,
    required int myUserId,
  }) async {
    final myKey = '$myUserId';
    try {
      final convRef = _conversations.doc(docId);
      await convRef.set({
        'unread_counts': {myKey: 0},
      }, SetOptions(merge: true));

      final unreadMsgs = await convRef
          .collection('messages')
          .orderBy('created_at_ms', descending: true)
          .limit(30)
          .get();

      final batch = _db.batch();
      bool hasUpdates = false;
      for (final doc in unreadMsgs.docs) {
        final data = doc.data();
        final senderId = '${data['sender_id'] ?? ''}';
        final readBy = (data['read_by'] is List)
            ? (data['read_by'] as List).map((e) => '$e').toList()
            : const <String>[];
        if (senderId != myKey && !readBy.contains(myKey)) {
          batch.update(doc.reference, {
            'read_by': FieldValue.arrayUnion([myKey]),
          });
          hasUpdates = true;
        }
      }
      if (hasUpdates) {
        await batch.commit();
      }
    } catch (_) {}
  }

  Future<void> setTyping({
    required String docId,
    required int myUserId,
    required bool isTyping,
  }) async {
    try {
      await _conversations.doc(docId).set({
        'typing': {'$myUserId': isTyping},
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  Future<void> deleteConversationForMe({
    required String docId,
    required int myUserId,
  }) async {
    await _conversations.doc(docId).set({
      'deleted_by': FieldValue.arrayUnion(['$myUserId']),
    }, SetOptions(merge: true));
  }
}
