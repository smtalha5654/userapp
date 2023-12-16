import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

import '../../generated/l10n.dart';
import '../models/chat.dart';
import '../models/conversation.dart';
import '../repository/chat_repository.dart';
import '../repository/notification_repository.dart';
import '../repository/user_repository.dart';

class ChatController extends ControllerMVC {
  Conversation? conversation;
  ChatRepository _chatRepository;
  Stream<QuerySnapshot>? conversations;
  Stream<QuerySnapshot>? chats;
  GlobalKey<ScaffoldState> scaffoldKey;
  File? imageFile;
  bool uploading = false;
  final chatTextController = TextEditingController();

  // Store the BuildContext
  BuildContext context;

  ChatController(this.context)
      : _chatRepository = ChatRepository(),
        scaffoldKey = GlobalKey<ScaffoldState>(),
        super();

  void signIn() {
    // _chatRepository.signUpWithEmailAndPassword(currentUser.value.email, currentUser.value.apiToken);
    // _chatRepository.signInWithToken(currentUser.value.apiToken);
  }

  void createConversation(Conversation _conversation) async {
    _conversation.users.insert(0, currentUser.value);
    _conversation.lastMessageTime =
        DateTime.now().toUtc().millisecondsSinceEpoch;
    _conversation.readByUsers = [currentUser.value.id];
    setState(() {
      conversation = _conversation;
    });
    await _chatRepository.createConversation(conversation!);
    listenForChats(conversation!);
  }

  void listenForConversations() async {
    _chatRepository
        .getUserConversations(currentUser.value.id)
        .then((snapshots) {
      setState(() {
        conversations = snapshots;
      });
    });
  }

  void listenForChats(Conversation _conversation) async {
    _conversation.readByUsers.add(currentUser.value.id);
    await _chatRepository.getChats(_conversation).then((snapshots) {
      setState(() {
        chats = snapshots;
      });
    });
  }

  void addMessage(Conversation _conversation, String text) async {
    Chat _chat = Chat(text, DateTime.now().toUtc().millisecondsSinceEpoch,
        currentUser.value.id);
    _conversation.lastMessage = text;
    _conversation.lastMessageTime = _chat.time;
    _conversation.readByUsers = [currentUser.value.id];
    await _chatRepository.addMessage(_conversation, _chat).then((value) {
      _conversation.users.forEach((_user) {
        if (_user.id != currentUser.value.id) {
          sendNotification(
              text,
              S.of(context).newMessageFrom + " " + currentUser.value.name,
              _user);
        }
      });
    });
  }

  List<QueryDocumentSnapshot>? orderSnapshotByTime(AsyncSnapshot snapshot) {
    final docs = snapshot.data?.docs;
    docs?.sort((QueryDocumentSnapshot a, QueryDocumentSnapshot b) {
      var time1 = a.get('time');
      var time2 = b.get('time');
      return time2.compareTo(time1) as int;
    });
    return docs;
  }

  Future<void> getImage(ImageSource source) async {
    ImagePicker imagePicker = ImagePicker();
    PickedFile? pickedFile;

    try {
      pickedFile = await imagePicker.getImage(source: source);
      setState(() {
        imageFile = File(pickedFile?.path ?? '');
      });

      uploading = true;
      await _chatRepository.uploadFile(imageFile!);
    } catch (e) {
      ScaffoldMessenger.of(scaffoldKey.currentContext!).showSnackBar(SnackBar(
        content: Text(e.toString()),
      ));
    }
  }
}
