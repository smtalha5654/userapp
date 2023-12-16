import 'dart:convert';
import 'dart:developer';
import 'dart:math' hide log;

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;

import '../models/route_argument.dart';
import '../repository/user_repository.dart';
import 'pages.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';

typedef OnSCommentSend = Function(String);
typedef OnUpdateUserCount = Function(String);

class LiveStream extends StatefulWidget {
  String channel;
  String token;
  bool isHost;
  int remoteUid;
  bool isJoined;
  RtcEngine engine;
  AgoraRtmClient client;
  int index;
  int currentItem;
  Map data;
  String marketId;
  String productId;
  OnUpdateUserCount onFetchUserCount;
  ScrollController scrollController;
  Function onGetAllLiveStream;
  LiveStream(
      {Key key,
      @required this.channel,
      @required this.token,
      @required this.isHost,
      @required this.remoteUid,
      @required this.isJoined,
      @required this.engine,
      @required this.index,
      @required this.currentItem,
      @required this.data,
      @required this.scrollController,
      @required this.client,
      @required this.marketId,
      @required this.productId,
      @required this.onFetchUserCount,
      @required this.onGetAllLiveStream})
      : super(key: key);

  @override
  State<LiveStream> createState() => _LiveStreamState();
}

class _LiveStreamState extends State<LiveStream> {
  // @override
  // void initState() {
  //   // onGetToken();
  //   if (widget.index != widget.currentItem) {
  //     // onLiveCountRemove();
  //     // _channel?.leave();
  //     // setState(() {
  //     //   comments = [];
  //     //   _isInChannel = false;
  //     // });
  //     // widget.engine.leaveChannel();
  //   } else {
  //     onGetToken();
  //   }
  //   super.initState();
  // }

  // @override
  // void dispose() async {
  //   // leave();
  //   // if (widget.index != widget.currentItem) {
  //   //   onLiveCountRemove();
  //   //   _channel?.leave();
  //   //   setState(() {
  //   //     comments = [];
  //   //     _isInChannel = false;
  //   //   });
  //   //   // widget.engine.leaveChannel();
  //   // }
  //   // super.dispose();
  // }

  // Future<dynamic> getProductById() async {
  //   var product = await getProduct(widget.productId);
  //   return product;
  // }

  bool isLoader = false;
  Future<void> onGetToken() async {
    try {
      // await getProductById();
      setState(() {
        isLoader = true;
      });
      Random random = new Random();
      var uid = random.nextInt(10000);
      // var chName = Uuid().generateV4();
      http.Response response = await http.post(
          Uri.parse(
              GlobalConfiguration().get('base_url') + "api/createRTCToken"),
          body: {
            "chName": widget.channel,
            "uid": uid.toString(),
            "role": "Subscriber",
          });
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        await onGoLive(data['token'], uid);
        setState(() {
          isLoader = false;
        });
      }
    } on http.ClientException catch (e) {
      print(e.message);
    }
    setState(() {
      isLoader = false;
    });
  }

  Future<void> onGoLive(String RtcToken, int uid) async {
    ChannelMediaOptions options;
    if (widget.isHost) {
      options = const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      );
      await widget.engine.startPreview();
    } else {
      options = const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      );
    }
    await widget.engine.joinChannel(
      token: RtcToken,
      channelId: widget.channel,
      options: options,
      uid: uid,
    );
    joinChannel();
  }

  void leave() {
    setState(() {
      widget.isJoined = false;
      widget.remoteUid = null;
    });
    onLiveCountRemove();
    _channel.leave();
    setState(() {
      comments = [];
      _isInChannel = false;
    });
    widget.engine.leaveChannel();
  }

  TextEditingController commentTxt = TextEditingController();
  var s;
  AgoraRtmChannel _channel;
  bool isLogin = false;
  bool _isInChannel = false;
  List<dynamic> comments = [];
  Future<AgoraRtmChannel> _createChannel(String name) async {
    AgoraRtmChannel _channel = await widget.client.createChannel(name);
    _channel.onError = (error) {
      log("Channel error: $error");
    };
    _channel.onMemberCountUpdated = (int memberCount) {
      log("Member count updated: $memberCount");
    };
    _channel.onAttributesUpdated = (List<RtmChannelAttribute> attributes) {
      log("Channel attributes updated: ${attributes.toString()}");
    };
    _channel.onMessageReceived =
        (RtmMessage message, RtmChannelMember member) {
      log("Channel msg: ${member.userId}, msg: ${message.messageType} ${message.text}");
      var message12 = jsonDecode(message.text);

      if (message12['type'] == "comments") {
        setState(() {
          comments.add(message12['payload']);
        });
        // _scrollController.animateTo(
        //   0.0,
        //   curve: Curves.easeOut,
        //   duration: const Duration(milliseconds: 300),
        // );
      } else if (message12['type'] == "Product") {
        print(message12);
        setState(() {
          var product = jsonDecode(message12['payload']['product']);
          s = product;
        });
      }
    };
    _channel.onMemberJoined = (RtmChannelMember member) {
      log('Member joined: ${member.userId}, channel: ${member.channelId}');
    };
    _channel.onMemberLeft = (RtmChannelMember member) {
      log('Member left: ${member.userId}, channel: ${member.channelId}');
    };
      return _channel;
  }

  Future<void> joinChannel() async {
    if (!_isInChannel) {
      try {
        _channel = await _createChannel(widget.channel);
        await _channel.join();
        log('Join channel success');
        setState(() {
          _isInChannel = true;
        });
        await _channel.sendMessage2(RtmMessage.fromText(jsonEncode({
          "type": "UserCount",
          "payload": {"id": widget.channel}
        })));
        await _channel.sendMessage2(RtmMessage.fromText(jsonEncode({
          "type": "GetProduct",
          "payload": {"isProductRequest": true}
        })));
        widget.onFetchUserCount(widget.channel);
      } catch (errorCode) {
        log('Join channel error: $errorCode');
      }
    }
  }

  onSendComment(String text) async {
    if (text.isNotEmpty) {
      var data = {
        "type": "comments",
        "payload": {
          "text": text,
          "userInfo": {
            "id": currentUser.value.id.toString(),
            "name": currentUser.value.name.toString(),
            // "image": jsonEncode(currentUser.value.image),
          }
        }
      };
      setState(() {
        comments.add(data['payload']);
      });
      await _channel.sendMessage2(RtmMessage.fromText(jsonEncode(data)));
    }
    }

  bool isHideProduct = true;

  Future<void> onLiveCountRemove() async {
    await _channel.sendMessage2(RtmMessage.fromText(jsonEncode({
      "type": "UserCountRemove",
      "payload": {"id": widget.channel}
    })));
    await onFetchUserCountRemove();
  }

  Future<void> onFetchUserCountRemove() async {
    try {
      http.Response response = await http.post(
          Uri.parse(GlobalConfiguration().getValue('base_url') +
              "api/fetch/history/update_live_count_remove/${widget.channel}"),
          body: {"id": widget.channel});
      if (response.statusCode == 200) {}
    } catch (e) {
      print(e);
    }
  }
  // update_live_count_remove

  Future<void> onRemoveUser() async {
    onLiveCountRemove();
    _channel.leave();
    setState(() {
      comments = [];
      _isInChannel = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.index != widget.currentItem) {
      onLiveCountRemove();
      _channel.leave();
      setState(() {
        comments = [];
        _isInChannel = false;
      });
    }
    var image = widget.data['user']['markets'][0]['has_media']
        ? widget.data['user']['markets'][0]['media'][0]['url']
        : "https://static.thenounproject.com/png/363633-200.png";
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          flexibleSpace: Container(
            height: 60,
            padding: EdgeInsets.symmetric(horizontal: 20),
            width: MediaQuery.of(context).size.width,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.5,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(100)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(image),
                      ),
                      SizedBox(width: 6),
                      Container(
                        width: 60,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${widget.data['user']['markets'][0]['name']}",
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white),
                            ),
                            // Text(
                            //   "12k",
                            //   style: TextStyle(
                            //       fontSize: 12,
                            //       fontWeight: FontWeight.w600,
                            //       color: Colors.white),
                            // ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8),
                      GestureDetector(
                        child: Container(
                          height: 20,
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                              color: Color.fromARGB(255, 203, 30, 18),
                              borderRadius: BorderRadius.circular(100)),
                          child: Text(
                            "Live",
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(child: Text("")),
                Container(
                  width: MediaQuery.of(context).size.width * 0.15,
                  height: 30,
                  padding: EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                      color: Color.fromARGB(81, 100, 99, 99),
                      borderRadius: BorderRadius.circular(100)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Icon(
                        Icons.remove_red_eye,
                        color: Colors.white,
                        size: 18,
                      ),
                      ValueListenableBuilder<Map<String, dynamic>>(
                          valueListenable: userCount,
                          builder: (context, Map<String, dynamic> uc, _) {
                            print(uc);
                            if (uc.containsKey("${widget.data['id']}")) {
                              return Text(
                                "${uc["${widget.data['id']}"]['userCount']}",
                                style: TextStyle(color: Colors.white),
                              );
                            } else {
                              return Text(
                                "0",
                                style: TextStyle(color: Colors.white),
                              );
                            }
                          })
                    ],
                  ),
                ),
                // MaterialButton(
                //     minWidth: 20,
                //     color: Colors.transparent,
                //     padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
                //     onPressed: () async {
                //       await leave();
                //       Navigator.pop(context);
                //     },
                //     child: Icon(
                //       Icons.close,
                //       color: Colors.white,
                //     ))
              ],
            ),
          ),
        ),
        backgroundColor: Colors.black,
        body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.9,
          child: !widget.isJoined
              ? Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.9,
                      decoration: BoxDecoration(
                          // color: Colors.grye)
                          image: DecorationImage(
                              image: AssetImage("assets/img/liveStream.jpg"))),
                    ),
                    GlassContainer(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.9,
                      blur: 10,
                      border: Border.fromBorderSide(BorderSide.none),
                      shadowStrength: 10,

                      borderRadius: BorderRadius.circular(16),
                      // shadowColor: Colors.white.withOpacity(0.24),
                    ),
                    Center(
                      child: MaterialButton(
                        height: 50,
                        minWidth: 50,
                        padding: EdgeInsets.zero,
                        color: Color.fromARGB(69, 179, 173, 173),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(1000)),
                        onPressed: () {
                          if (widget.currentItem != widget.index) {
                            print("object");
                          } else {
                            onGetToken();
                          }
                        },
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height * 0.9,
                      child: videoPanel(),
                    ),
                    Positioned(
                        bottom: MediaQuery.of(context).size.height * 0.1,
                        child: Column(
                          children: [
                            Container(
                                width: MediaQuery.of(context).size.width,
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
                                color: Colors.transparent,
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                child:
                                    // ValueListenableBuilder<List<dynamic>>(
                                    //     valueListenable: comments,
                                    //     builder: (context, c, _) {
                                    //       return
                                    comments.length <= 0
                                        ? Text("")
                                        : ListView.builder(
                                            itemCount: comments.length,
                                            itemBuilder: (context, i) {
                                              return Container(
                                                margin: EdgeInsets.symmetric(
                                                    vertical: 4),
                                                decoration: BoxDecoration(
                                                    color: Color.fromARGB(
                                                        7, 216, 213, 213),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5)),
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 10,
                                                    horizontal: 10),
                                                child: Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 20,
                                                      backgroundColor:
                                                          Color.fromARGB(
                                                              7, 216, 213, 213),
                                                      child: Icon(
                                                        Icons
                                                            .account_circle_outlined,
                                                        color: Colors.white,
                                                        size: 25,
                                                      ),
                                                    ),
                                                    SizedBox(width: 5),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          "${comments[i]['userInfo']['name']}",
                                                          style: TextStyle(
                                                              fontSize: 15,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.white),
                                                        ),
                                                        Text(
                                                          "${comments[i]['text']}",
                                                          style: TextStyle(
                                                              fontSize: 13,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  Colors.white),
                                                        )
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              );
                                            })),
                            !isHideProduct
                                ? SizedBox()
                                : s == null
                                    ? SizedBox()
                                    : Container(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.93,
                                        padding:
                                            EdgeInsets.symmetric(horizontal: 5),
                                        height: 80,
                                        margin: EdgeInsets.symmetric(
                                            horizontal: 10),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 70,
                                              height: 70,
                                              decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  image: DecorationImage(
                                                      fit: BoxFit.fill,
                                                      image: NetworkImage(
                                                          s['image']['url']))),
                                            ),
                                            SizedBox(width: 5),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  "${s['name']}",
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.black),
                                                ),
                                                // Text(
                                                //     "Category:${snapshot.data.category.name}"),
                                                SizedBox(height: 2),
                                                // Text(p1['productReviews'].isEmpty
                                                //     ? "★ 0"
                                                //     : "★ ${p1.productReviews.map((e) => e.rate).toString().replaceAll("(", "").replaceAll(")", "")}"),
                                                SizedBox(height: 10),
                                                s['discountPrice'] != null
                                                    ? Row(
                                                        children: [
                                                          Text(
                                                              "\$${s['discountPrice']}",
                                                              style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color:
                                                                    Colors.red,
                                                              )),
                                                          SizedBox(width: 5),
                                                          Text(
                                                            "\$${s['price']}",
                                                            style: TextStyle(
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                                color: Colors
                                                                    .black,
                                                                decoration:
                                                                    TextDecoration
                                                                        .lineThrough),
                                                          )
                                                        ],
                                                      )
                                                    : Text(
                                                        "\$ ${s['price']}",
                                                        style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color:
                                                                Colors.black),
                                                      ),
                                              ],
                                            ),
                                            Spacer(),
                                            Container(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.end,
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  GestureDetector(
                                                      onTap: () {
                                                        setState(() {
                                                          isHideProduct = false;
                                                        });
                                                      },
                                                      child: Icon(Icons.close)),
                                                  MaterialButton(
                                                    padding: EdgeInsets.zero,
                                                    height: 30,
                                                    minWidth: 50,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5)),
                                                    color: Colors.red,
                                                    onPressed: () {
                                                      Navigator.of(context).pushNamed(
                                                          '/Product',
                                                          arguments:
                                                              new RouteArgument(
                                                                  heroTag:
                                                                      "LiveProduct",
                                                                  id: s['id']));
                                                    },
                                                    child: Text(
                                                      "Buy",
                                                      style: TextStyle(
                                                          color: Colors.white),
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                          ],
                        )),
                    // }),
                    // )),
                    Positioned(
                      bottom: 0,
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        height: 60,
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                            // color: Color.fromARGB(179, 20, 20, 20),
                            color: Colors.transparent,
                            borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                topRight: Radius.circular(10))),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).pushNamed('/Details',
                                    arguments: RouteArgument(
                                      id: widget.marketId,
                                      heroTag: 'my_markets',
                                    ));
                              },
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.store,
                                    color: Colors.white,
                                  ),
                                  // padding: EdgeInsets.zero),
                                  Text("Shop",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600))
                                ],
                              ),
                            ),
                            Container(
                              width: MediaQuery.of(context).size.width * 0.8,
                              height: 35,
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              color: Colors.transparent,
                              child: TextFormField(
                                keyboardAppearance: Brightness.dark,
                                scrollPadding: EdgeInsets.zero,
                                controller: commentTxt,
                                textInputAction: TextInputAction.send,
                                onFieldSubmitted: (value) {
                                  print("search");
                                  onSendComment(value);
                                  commentTxt.clear();
                                },
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                    hintText: "Add Comment",
                                    hintStyle: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600),
                                    contentPadding: EdgeInsets.zero,
                                    border: OutlineInputBorder(
                                        borderSide: BorderSide.none)),
                              ),
                            ),
                            // IconButton(
                            //     onPressed: () {
                            //       onSendComment(commentTxt.text);
                            //       commentTxt.clear();
                            //     },
                            //     icon: Icon(
                            //       Icons.send,
                            //       color: Colors.white,
                            //     )),
                            // Column(
                            //   mainAxisSize: MainAxisSize.min,
                            //   children: [
                            //     Icon(
                            //       Icons.share_rounded,
                            //       color: Colors.grey,
                            //     ),
                            //     Text("Share",
                            //         style: TextStyle(
                            //             color: Colors.grey,
                            //             fontSize: 12,
                            //             fontWeight: FontWeight.w600))
                            //   ],
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget videoPanel() {
    if (!widget.isJoined) {
      return const Text(
        'Join a channel',
        textAlign: TextAlign.center,
      );
    } else if (widget.isHost) {
      // Show local video preview
      return AgoraVideoView(
        controller: VideoViewController(
          rtcEngine: widget.engine,
          canvas: VideoCanvas(uid: 0),
        ),
      );
    } else {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: widget.engine,
          canvas: VideoCanvas(uid: widget.remoteUid),
          connection: RtcConnection(channelId: widget.channel),
        ),
      );
        }
  }
}
