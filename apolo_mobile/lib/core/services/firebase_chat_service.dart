import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../config/firebase_options.dart';
import '../../screens/widgets/chat_utils.dart';
import 'push_notification_service.dart';

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

  /// Currently open chat room doc ID (used to suppress duplicate in-app banners).
  static String? activeChatDocId;

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _conversations =>
      _db.collection('conversations');

  CollectionReference<Map<String, dynamic>> get _calls =>
      _db.collection('calls');

  CollectionReference<Map<String, dynamic>> get _reports =>
      _db.collection('reports');

  CollectionReference<Map<String, dynamic>> get _userBlocks =>
      _db.collection('user_blocks');

  final Set<String> _blockedKeys = {};
  final Map<String, Map<String, dynamic>> _blockedMeta = {};
  final Set<String> _markingReadDocs = {};

  bool isBlocked(dynamic targetId) => _blockedKeys.contains('$targetId');
  List<Map<String, dynamic>> get blockedList => _blockedMeta.values.toList();

  /// Safe initialization (never throws in headless widget tests).
  Future<bool> initialize() async {
    if (_isReady) return true;
    try {
      if (Firebase.apps.isEmpty) {
        if (kIsWeb) {
          await Firebase.initializeApp(
            options: ApoloFirebaseOptions.web,
          );
        } else {
          try {
            await Firebase.initializeApp();
          } catch (_) {
            await Firebase.initializeApp(
              options: ApoloFirebaseOptions.currentPlatform,
            );
          }
        }
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

  /// Always keeps `participants` in deterministic `[low, high]` order so
  /// Firestore security rules (`request.resource.data.participants == resource.data.participants`)
  /// never reject replies or updates from the second participant.
  List<String> _sortedParticipants(int userA, int userB) {
    final low = userA <= userB ? userA : userB;
    final high = userA <= userB ? userB : userA;
    return <String>['$low', '$high'];
  }

  /// Finds the most recent existing conversation document between [myUserId] and [peerUserId]
  /// (including any `ad_<adId>_u_<low>_<high>` document when [adId] wasn't passed),
  /// or falls back to [buildConversationDocId].
  Future<String> resolveBestConversationDocId({
    required int myUserId,
    required int peerUserId,
    int adId = 0,
  }) async {
    final defaultDocId = buildConversationDocId(
      myUserId: myUserId,
      peerUserId: peerUserId,
      adId: adId,
    );
    if (!_isReady || myUserId <= 0 || peerUserId <= 0) {
      return defaultDocId;
    }
    try {
      if (adId > 0) {
        final directSnap = await _conversations
            .doc(defaultDocId)
            .get()
            .timeout(const Duration(seconds: 3));
        if (directSnap.exists) {
          return defaultDocId;
        }
      }
      final myKey = '$myUserId';
      final peerKey = '$peerUserId';
      final snap = await _conversations
          .where('participants', arrayContains: myKey)
          .get()
          .timeout(const Duration(seconds: 3));
      String? bestSameAdDocId;
      int bestSameAdMs = -1;
      String? bestAnyDocId;
      int bestAnyMs = -1;
      for (final doc in snap.docs) {
        final data = doc.data();
        final parts = (data['participants'] is List)
            ? (data['participants'] as List).map((e) => '$e').toList()
            : const <String>[];
        if (parts.contains(peerKey) &&
            (myKey != peerKey || parts.where((p) => p == myKey).length >= 2)) {
          final updatedMs =
              int.tryParse('${data['updated_at_ms'] ?? 0}') ?? 0;
          final docAdId = int.tryParse('${data['ad_id'] ?? 0}') ?? 0;
          if (adId > 0 &&
              (docAdId == adId || doc.id.startsWith('ad_${adId}_'))) {
            if (updatedMs > bestSameAdMs) {
              bestSameAdMs = updatedMs;
              bestSameAdDocId = doc.id;
            }
          }
          if (updatedMs > bestAnyMs) {
            bestAnyMs = updatedMs;
            bestAnyDocId = doc.id;
          }
        }
      }
      if (adId > 0) {
        return bestSameAdDocId ?? defaultDocId;
      }
      return bestAnyDocId ?? defaultDocId;
    } catch (_) {
      return defaultDocId;
    }
  }

  /// When a seller taps "Chat" on their own ad, finds the most recent buyer conversation for [adId].
  Future<Map<String, dynamic>?> findLatestBuyerConversationForAd({
    required int sellerUserId,
    required int adId,
  }) async {
    if (!_isReady || sellerUserId <= 0 || adId <= 0) return null;
    try {
      final sellerKey = '$sellerUserId';
      final snap = await _conversations
          .where('participants', arrayContains: sellerKey)
          .get();
      Map<String, dynamic>? bestConv;
      int bestMs = -1;
      for (final doc in snap.docs) {
        final data = doc.data();
        final docAdId = int.tryParse('${data['ad_id'] ?? 0}') ?? 0;
        final parts = (data['participants'] is List)
            ? (data['participants'] as List).map((e) => '$e').toList()
            : const <String>[];
        final buyerKey = parts.firstWhere(
          (p) => p != sellerKey,
          orElse: () => '',
        );
        if (buyerKey.isEmpty) continue;
        if (docAdId == adId || doc.id.startsWith('ad_${adId}_')) {
          final updatedMs = int.tryParse('${data['updated_at_ms'] ?? 0}') ?? 0;
          if (updatedMs > bestMs) {
            bestMs = updatedMs;
            final metaMap = data['participants_meta'] is Map
                ? Map<String, dynamic>.from(data['participants_meta'] as Map)
                : const <String, dynamic>{};
            final buyerMeta = metaMap[buyerKey] is Map
                ? Map<String, dynamic>.from(metaMap[buyerKey] as Map)
                : const <String, dynamic>{};
            bestConv = {
              'firestore_doc_id': doc.id,
              'peer_id': int.tryParse(buyerKey) ?? 0,
              'peer_name': (buyerMeta['name'] ?? 'Apolo User').toString(),
              'peer_avatar': (buyerMeta['avatar'] ?? '').toString(),
            };
          }
        }
      }
      return bestConv;
    } catch (_) {
      return null;
    }
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
    final sortedParts = _sortedParticipants(myUserId, peerUserId);
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({
        'participants': sortedParts,
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
        .snapshots(includeMetadataChanges: true)
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
        } else if (lastType == 'audio') {
          displayLastMsg = '🎤 Voice message';
        } else {
          displayLastMsg = '';
        }

        final peerIdInt = int.tryParse('${peerMeta['id'] ?? peerKey}') ?? 0;
        // Skip empty self-conversations created when a seller clicked chat on their own ad
        if (peerKey == myKey && displayLastMsg.isEmpty) {
          continue;
        }
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
          'peer_online':
              peerMeta['is_online'] == true || data['peer_online'] == true,
          'last_message': displayLastMsg,
          'last_sender_id': (data['last_sender_id'] ?? '').toString(),
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
        .snapshots(includeMetadataChanges: true)
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

        final rawReactions = data['reactions'];
        final reactions = <String, String>{};
        if (rawReactions is Map) {
          rawReactions.forEach((k, v) {
            final vs = (v ?? '').toString().trim();
            if (vs.isNotEmpty) reactions['$k'] = vs;
          });
        }
        final starredBy = (data['starred_by'] is List)
            ? (data['starred_by'] as List).map((e) => '$e').toList()
            : const <String>[];

        result.add({
          'id': doc.id,
          'doc_id': doc.id,
          if ((data['client_message_id'] ?? '').toString().trim().isNotEmpty)
            'client_message_id': data['client_message_id'].toString().trim(),
          'sender_id': senderKey,
          'sender_name': (data['sender_name'] ?? '').toString(),
          'type': (data['type'] ?? 'text').toString(),
          'body': (data['body'] ?? '').toString(),
          'image_base64': (data['image_base64'] ?? '').toString(),
          'audio_base64': (data['audio_base64'] ?? '').toString(),
          'audio_mime': (data['audio_mime'] ?? 'audio/webm').toString(),
          'audio_duration': (data['audio_duration'] ?? '0:01').toString(),
          if (data['audio_waveform'] is List)
            'audio_waveform': (data['audio_waveform'] as List)
                .map((e) => double.tryParse('$e') ?? 0.35)
                .toList(),
          'is_mine': isMine,
          'read': isReadByPeer,
          'reactions': reactions,
          'pinned': data['pinned'] == true,
          'starred_by': starredBy,
          'created_at_ms': createdMs,
          'created_at_time': clock,
          if (data['reply_to'] is Map)
            'reply_to': Map<String, dynamic>.from(data['reply_to'] as Map),
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
    String? clientMessageId,
    Map<String, dynamic>? replyTo,
    int adId = 0,
    String adTitle = '',
    String adPrice = '',
    String adImage = '',
  }) async {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final myKey = '$myUserId';
    final peerKey = '$peerUserId';
    final sortedParts = _sortedParticipants(myUserId, peerUserId);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final convRef = _conversations.doc(docId);
    final msgRef = convRef.collection('messages').doc();

    // Single atomic WriteBatch cuts network latency in half (1 RTT instead of 2)
    final batch = _db.batch();
    batch.set(
      convRef,
      {
        'participants': sortedParts,
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
      },
      SetOptions(merge: true),
    );
    batch.set(msgRef, {
      'sender_id': myKey,
      'sender_name': myName,
      'type': 'text',
      'body': trimmed,
      if (clientMessageId != null && clientMessageId.trim().isNotEmpty)
        'client_message_id': clientMessageId.trim(),
      if (replyTo != null && replyTo.isNotEmpty) 'reply_to': replyTo,
      'created_at_ms': nowMs,
      'read_by': [myKey],
      'edited': false,
      'deleted_for_everyone': false,
      'deleted_for': <String>[],
    });
    await batch.commit().timeout(const Duration(seconds: 3));

    if (peerUserId != myUserId) {
      unawaited(
        ApoloPushNotificationService.instance.notifyRemoteUser(
          recipientUserId: peerUserId,
          title: myName.trim().isNotEmpty ? myName.trim() : 'Apolo.ma',
          body: trimmed,
          type: 'message',
          data: <String, dynamic>{
            'firestore_doc_id': docId,
            'peer_id': myKey,
            'peer_name': myName,
            'peer_avatar': myAvatar,
            if (adId > 0) 'ad_id': '$adId',
            if (adTitle.isNotEmpty) 'ad_title': adTitle,
            if (adPrice.isNotEmpty) 'ad_price': adPrice,
            if (adImage.isNotEmpty) 'ad_image': adImage,
          },
        ),
      );
    }
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
    final sortedParts = _sortedParticipants(myUserId, peerUserId);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final convRef = _conversations.doc(docId);

    await convRef.set({
      'participants': sortedParts,
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

    if (peerUserId != myUserId) {
      final preview = caption.trim().isNotEmpty ? caption.trim() : '📷 Photo';
      unawaited(
        ApoloPushNotificationService.instance.notifyRemoteUser(
          recipientUserId: peerUserId,
          title: myName.trim().isNotEmpty ? myName.trim() : 'Apolo.ma',
          body: preview,
          type: 'message',
          data: <String, dynamic>{
            'firestore_doc_id': docId,
            'peer_id': myKey,
            'peer_name': myName,
            'peer_avatar': myAvatar,
            if (adId > 0) 'ad_id': '$adId',
            if (adTitle.isNotEmpty) 'ad_title': adTitle,
            if (adPrice.isNotEmpty) 'ad_price': adPrice,
            if (adImage.isNotEmpty) 'ad_image': adImage,
          },
        ),
      );
    }
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
    if (_markingReadDocs.contains(docId)) return;
    _markingReadDocs.add(docId);
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
    } catch (_) {
    } finally {
      _markingReadDocs.remove(docId);
    }
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

  /// Sends a Voice Note message stored in Firestore.
  Future<void> sendAudioMessage({
    required String docId,
    required int myUserId,
    required String myName,
    String myAvatar = '',
    required int peerUserId,
    required String peerName,
    String peerAvatar = '',
    required String audioBase64,
    required String audioMime,
    required String audioDuration,
    List<double> audioWaveform = const <double>[],
    int adId = 0,
    String adTitle = '',
    String adPrice = '',
    String adImage = '',
  }) async {
    final myKey = '$myUserId';
    final peerKey = '$peerUserId';
    final sortedParts = _sortedParticipants(myUserId, peerUserId);
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final convRef = _conversations.doc(docId);

    await convRef.set({
      'participants': sortedParts,
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
      'last_message': '🎤 $audioDuration',
      'last_message_type': 'audio',
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
      'type': 'audio',
      'body': '',
      'audio_base64': audioBase64,
      'audio_mime': audioMime,
      'audio_duration': audioDuration,
      if (audioWaveform.isNotEmpty) 'audio_waveform': audioWaveform,
      'created_at_ms': nowMs,
      'read_by': [myKey],
      'edited': false,
      'deleted_for_everyone': false,
      'deleted_for': <String>[],
    });

    if (peerUserId != myUserId) {
      unawaited(
        ApoloPushNotificationService.instance.notifyRemoteUser(
          recipientUserId: peerUserId,
          title: myName.trim().isNotEmpty ? myName.trim() : 'Apolo.ma',
          body: '🎤 $audioDuration',
          type: 'message',
          data: <String, dynamic>{
            'firestore_doc_id': docId,
            'peer_id': myKey,
            'peer_name': myName,
            'peer_avatar': myAvatar,
            if (adId > 0) 'ad_id': '$adId',
            if (adTitle.isNotEmpty) 'ad_title': adTitle,
            if (adPrice.isNotEmpty) 'ad_price': adPrice,
            if (adImage.isNotEmpty) 'ad_image': adImage,
          },
        ),
      );
    }
  }

  // ───────────────────────── WebRTC Call Signaling ─────────────────────────

  Future<String> createCall({
    required String conversationDocId,
    required int callerId,
    required String callerName,
    String callerAvatar = '',
    required int calleeId,
    required String calleeName,
    String calleeAvatar = '',
    required bool isVideo,
    required String offerJson,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final ref = await _calls.add({
      'conversation_doc_id': conversationDocId,
      'caller_id': '$callerId',
      'caller_name': callerName,
      'caller_avatar': callerAvatar,
      'callee_id': '$calleeId',
      'callee_name': calleeName,
      'callee_avatar': calleeAvatar,
      'is_video': isVideo,
      'status': 'ringing',
      'offer': offerJson,
      'answer': '',
      'created_at_ms': nowMs,
      'updated_at_ms': nowMs,
    });
    if (calleeId != callerId) {
      unawaited(
        ApoloPushNotificationService.instance.notifyRemoteUser(
          recipientUserId: calleeId,
          title: callerName.trim().isNotEmpty ? callerName.trim() : 'Apolo.ma',
          body: isVideo ? 'Incoming video call' : 'Incoming voice call',
          type: 'call',
          data: <String, dynamic>{
            'call_id': ref.id,
            'firestore_doc_id': conversationDocId,
            'peer_id': '$callerId',
            'peer_name': callerName,
            'peer_avatar': callerAvatar,
            'is_video': isVideo ? 'true' : 'false',
          },
        ),
      );
    }
    return ref.id;
  }

  Future<void> answerCall({
    required String callId,
    required String answerJson,
  }) async {
    await _calls.doc(callId).update({
      'answer': answerJson,
      'status': 'connected',
      'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> addCallCandidate({
    required String callId,
    required bool isCaller,
    required String candidateJson,
  }) async {
    final sub = isCaller ? 'caller_candidates' : 'callee_candidates';
    await _calls.doc(callId).collection(sub).add({
      'candidate': candidateJson,
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> updateCallStatus({
    required String callId,
    required String status,
  }) async {
    try {
      await _calls.doc(callId).update({
        'status': status,
        'updated_at_ms': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (_) {}
  }

  Stream<Map<String, dynamic>?> watchCall(String callId) {
    return _calls.doc(callId).snapshots().map((doc) {
      final d = doc.data();
      if (d == null) return null;
      return {...d, 'id': doc.id};
    });
  }

  Stream<String> watchCallCandidates(
    String callId, {
    required bool watchCallerCandidates,
  }) {
    final sub = watchCallerCandidates ? 'caller_candidates' : 'callee_candidates';
    return _calls.doc(callId).collection(sub).snapshots().expand((snap) {
      return snap.docChanges
          .where((c) => c.type == DocumentChangeType.added)
          .map((c) => (c.doc.data()?['candidate'] ?? '').toString())
          .where((s) => s.isNotEmpty);
    });
  }

  /// Watches active incoming ringing calls for [myUserId] (no composite index needed).
  Stream<Map<String, dynamic>?> watchIncomingCalls(int myUserId) {
    final myKey = '$myUserId';
    return _calls
        .where('callee_id', isEqualTo: myKey)
        .snapshots()
        .map((snap) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      Map<String, dynamic>? latest;
      int latestMs = 0;
      for (final doc in snap.docs) {
        final d = doc.data();
        if (d['status'] != 'ringing') continue;
        if (isBlocked(d['caller_id'])) continue;
        final created = int.tryParse('${d['created_at_ms'] ?? 0}') ?? 0;
        if (nowMs - created > 90000) continue; // ignore stale calls > 90s
        if (created >= latestMs) {
          latestMs = created;
          latest = {...d, 'id': doc.id};
        }
      }
      return latest;
    });
  }

  // ───────────────────────── Emoji Reactions, Pin & Star ─────────────────────────

  Future<void> toggleMessageReaction({
    required String docId,
    required String messageDocId,
    required int myUserId,
    required String emoji,
  }) async {
    if (!_isReady) return;
    final msgRef = _conversations
        .doc(docId)
        .collection('messages')
        .doc(messageDocId);
    if (emoji.isEmpty) {
      await msgRef.update({'reactions.$myUserId': FieldValue.delete()});
    } else {
      await msgRef.set({
        'reactions': {'$myUserId': emoji},
      }, SetOptions(merge: true));
    }
  }

  Future<void> togglePinMessage({
    required String docId,
    required String messageDocId,
    required bool pinned,
  }) async {
    if (!_isReady) return;
    await _conversations
        .doc(docId)
        .collection('messages')
        .doc(messageDocId)
        .update({'pinned': pinned});
  }

  Future<void> toggleStarMessage({
    required String docId,
    required String messageDocId,
    required int myUserId,
    required bool starred,
  }) async {
    if (!_isReady) return;
    await _conversations
        .doc(docId)
        .collection('messages')
        .doc(messageDocId)
        .update({
      'starred_by': starred
          ? FieldValue.arrayUnion(['$myUserId'])
          : FieldValue.arrayRemove(['$myUserId']),
    });
  }

  // ───────────────────────── Safety: Reports & User Blocks ─────────────────────────

  Future<void> submitReport({
    required String targetType,
    required String targetId,
    required String targetTitle,
    required int reporterId,
    String reportedUserId = '',
    required String reason,
    String details = '',
    String messageExcerpt = '',
  }) async {
    if (!_isReady) return;
    await _reports.add({
      'target_type': targetType,
      'target_id': targetId,
      'target_title': targetTitle,
      'reporter_id': '$reporterId',
      'reported_user_id': reportedUserId,
      'reason': reason,
      'details': details,
      'message_excerpt': messageExcerpt,
      'status': 'pending',
      'created_at_ms': DateTime.now().millisecondsSinceEpoch,
    });
  }

  Future<void> blockTarget({
    required int myUserId,
    required String targetId,
    required String targetName,
    String targetAvatar = '',
    String targetType = 'user',
  }) async {
    final cleanId = targetId.trim();
    if (cleanId.isEmpty) return;
    final entry = <String, dynamic>{
      'id': cleanId,
      'name': targetName.trim().isNotEmpty ? targetName.trim() : 'Apolo User',
      'avatar': targetAvatar,
      'type': targetType,
      'blocked_at_ms': DateTime.now().millisecondsSinceEpoch,
    };
    _blockedKeys.add(cleanId);
    _blockedMeta[cleanId] = entry;
    if (_isReady && myUserId > 0) {
      await _userBlocks.doc('$myUserId').set({
        'blocked': {cleanId: entry},
      }, SetOptions(merge: true));
    }
  }

  Future<void> unblockTarget({
    required int myUserId,
    required String targetId,
  }) async {
    final cleanId = targetId.trim();
    if (cleanId.isEmpty) return;
    _blockedKeys.remove(cleanId);
    _blockedMeta.remove(cleanId);
    if (_isReady && myUserId > 0) {
      try {
        await _userBlocks.doc('$myUserId').update({
          FieldPath(['blocked', cleanId]): FieldValue.delete(),
        });
      } catch (_) {}
    }
  }

  Future<List<Map<String, dynamic>>> loadBlockedTargets(int myUserId) async {
    if (!_isReady || myUserId <= 0) return blockedList;
    try {
      final doc = await _userBlocks.doc('$myUserId').get();
      final data = doc.data();
      final rawBlocked = data?['blocked'];
      if (rawBlocked is Map) {
        _blockedKeys.clear();
        _blockedMeta.clear();
        rawBlocked.forEach((k, v) {
          final idStr = '$k'.trim();
          if (idStr.isEmpty || v is! Map) return;
          _blockedKeys.add(idStr);
          _blockedMeta[idStr] = {
            ...Map<String, dynamic>.from(v),
            'id': idStr,
          };
        });
      }
    } catch (_) {}
    return blockedList;
  }
}
