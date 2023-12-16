import 'dart:developer';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../main.dart';
import 'live-stream.dart';
import 'pages.dart';

typedef OnSCommentSend = Function(String);
typedef OnUpdateUserCount = Function(String);

class LiveShop extends StatefulWidget {
  final GlobalKey<ScaffoldState> parentScaffoldKey;
  final List<dynamic> liveVideos;
  final ScrollController scrollController;
  Function onBackLive;
  AgoraRtmClient client;
  OnUpdateUserCount onFetchUserCount;
  Function onGetAllLiveStream;
  LiveShop(
      {Key key,
      this.parentScaffoldKey,
      this.liveVideos,
      this.scrollController,
      this.client,
      this.onBackLive,
      this.onFetchUserCount,
      this.onGetAllLiveStream})
      : super(key: key);

  @override
  _LiveShopState createState() => _LiveShopState();
}

class _LiveShopState extends StateMVC<LiveShop> {
  int remoteUid;
  bool isJoined = false;

  RtcEngine engine;
  Future<void> initAgora() async {
    await [Permission.microphone, Permission.camera].request();
    setState(() {
      engine = createAgoraRtcEngine();
    });
    await engine.initialize(const RtcEngineContext(appId: appId));
    await engine.enableVideo();
    await engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            isJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          log("remote user $remoteUid joined");
          setState(() {
            this.remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid,
            UserOfflineReasonType reason) {
          log("remote user $remoteUid left channel");
          setState(() {
            this.remoteUid = null;
          });
          widget.onBackLive();
        },
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint(
              '[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );
    // await onGetToken();
  }

  @override
  void initState() {
    initAgora();
    super.initState();
  }

  @override
  void dispose() async {
    await engine.leaveChannel();
    engine.release();
    super.dispose();
  }

  ScrollController sc = ScrollController();
  int centerItemIndex;
  double screenHeight;
  int currentPage = 0;
  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: ValueListenableBuilder<List<dynamic>>(
          valueListenable: liveStreams,
          builder: (context, liveStream, _) {
            return Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: (liveStream.isEmpty)
                    ? Center(child: CircularProgressIndicator())
                    // : liveStream.length == 1
                    //     ? Container(
                    //         width: MediaQuery.of(context).size.width,
                    //         height: MediaQuery.of(context).size.height,
                    //         color: Colors.transparent,
                    //         child: (currentPage == 0)
                    //             ? LiveStream(
                    //                 channel: liveStream[0]['channel_id'],
                    //                 token: liveStream[0]['live_token'],
                    //                 isHost: false,
                    //                 engine: engine,
                    //                 isJoined: isJoined,
                    //                 remoteUid: remoteUid,
                    //                 index: 0,
                    //                 currentItem: currentPage,
                    //                 data: liveStream[0],
                    //                 scrollController: widget.scrollController,
                    //                 client: widget.client,
                    //                 marketId:
                    //                     liveStream[0]['market_id'].toString(),
                    //                 productId:
                    //                     liveStream[0]['product_id'].toString(),
                    //                 onFetchUserCount: widget.onFetchUserCount)
                    //             : Text("data"),
                    //       )
                    //     :
                    : PageView.builder(
                        itemCount: liveStream.length,
                        scrollDirection: Axis.vertical,

                        // physics: BouncingScrollPhysics(),
                        onPageChanged: (e) {
                          if (centerItemIndex != e) {
                            engine.leaveChannel();
                            setState(() {
                              remoteUid = null;
                              isJoined = false;
                            });
                          }
                          setState(() {
                            currentPage = e;
                          });
                        },
                        itemBuilder: (context, i) {
                          return Container(
                              width: MediaQuery.of(context).size.width,
                              height: MediaQuery.of(context).size.height,
                              color: Colors.transparent,
                              child: LiveStream(
                                  channel: liveStream[currentPage]
                                      ['channel_id'],
                                  token: liveStream[currentPage]['live_token'],
                                  isHost: false,
                                  engine: engine,
                                  isJoined: isJoined,
                                  remoteUid: remoteUid,
                                  index: i,
                                  currentItem: currentPage,
                                  data: liveStream[currentPage],
                                  scrollController: widget.scrollController,
                                  client: widget.client,
                                  marketId: liveStream[currentPage]['market_id']
                                      .toString(),
                                  productId: liveStream[currentPage]
                                          ['product_id']
                                      .toString(),
                                  onFetchUserCount: widget.onFetchUserCount,
                                  onGetAllLiveStream: widget.onGetAllLiveStream)
                              // : Text("data"),
                              );
                        }));
          }),
    );
  }
}
