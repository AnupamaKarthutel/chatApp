import 'package:chat_app/widgets/message_bubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

class Chatmessages extends StatefulWidget {
  const Chatmessages({super.key});

  @override
  State<Chatmessages> createState() => _ChatmessagesState();
}

class _ChatmessagesState extends State<Chatmessages> {
  void pushnotification() async {
    final fcm = FirebaseMessaging.instance;
    await fcm.requestPermission();
    await fcm.subscribeToTopic('chat');
  }

  @override
  void initState() {
    pushnotification();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final authenticatedUser = FirebaseAuth.instance.currentUser!;
    return StreamBuilder(
        stream: FirebaseFirestore.instance
            .collection('chat')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (ctx, chatsnapshot) {
          if (chatsnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!chatsnapshot.hasData || chatsnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No message yets'),
            );
          }
          if (chatsnapshot.hasError) {
            return const Center(
              child: Text('Something went wrong'),
            );
          }

          final messageList = chatsnapshot.data!.docs;
          return ListView.builder(
              padding: const EdgeInsets.only(bottom: 40, left: 30, right: 30),
              reverse: true,
              itemCount: messageList.length,
              itemBuilder: (context, index) {
                final chatMeassage = messageList[index].data();
                final nextChatMessage = index + 1 < messageList.length
                    ? messageList[index + 1].data()
                    : null;
                final currentMessageUserID = chatMeassage['userId'];
                final nextCurrentMessageUserID =
                    nextChatMessage != null ? nextChatMessage['userId'] : null;

                final isSameUserId =
                    currentMessageUserID == nextCurrentMessageUserID;

                if (isSameUserId) {
                  return MessageBubble.next(
                      message: chatMeassage['text'],
                      isMe: authenticatedUser.uid == currentMessageUserID);
                } else {
                  return MessageBubble.first(
                    userImage: chatMeassage['imageurl'],
                    username: chatMeassage['userName'],
                    message: chatMeassage['text'],
                    isMe: authenticatedUser.uid == currentMessageUserID,
                  );
                }
              });
        });
  }
}
