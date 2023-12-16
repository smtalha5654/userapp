import 'dart:convert';
import 'dart:developer';

import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:mvc_pattern/mvc_pattern.dart';

import '../elements/DrawerWidget.dart';
import '../elements/FilterWidget.dart';
import '../helpers/helper.dart';
import '../models/route_argument.dart';
import '../pages/home.dart';
import '../pages/map.dart';
import '../pages/notifications.dart';
import '../pages/orders.dart';
import 'live_shop.dart';

// ignore: must_be_immutable
ValueNotifier<List<dynamic>> comments = new ValueNotifier([]);
ValueNotifier<List<dynamic>> liveStreams = new ValueNotifier<List<dynamic>>([]);
ValueNotifier<Map<String, dynamic>> userCount =
    new ValueNotifier<Map<String, dynamic>>({});

class PagesWidget extends StatefulWidget {
  dynamic currentTab;
  RouteArgument routeArgument;
  Widget currentPage = HomeWidget();
  final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();

  PagesWidget({
    Key key,
    this.currentTab,
  }) {
    if (currentTab != null) {
      if (currentTab is RouteArgument) {
        routeArgument = currentTab;
        currentTab = int.parse(currentTab.id);
      }
    } else {
      currentTab = 2;
    }
  }

  @override
  _PagesWidgetState createState() {
    return _PagesWidgetState();
  }
}

class _PagesWidgetState extends State<PagesWidget> {
  bool isLogin = false;
  bool _isInChannel = false;
  initState() {
    super.initState();
    onGetAllLiveStream();
    createRTMToken();
    _selectTab(widget.currentTab);
  }

  @override
  void didUpdateWidget(PagesWidget oldWidget) {
    _selectTab(oldWidget.currentTab);
    super.didUpdateWidget(oldWidget);
  }

  Future<void> createRTMToken() async {
    var uid = Uuid().generateV4().substring(1, 4);
    try {
      http.Response response = await http.post(
          Uri.parse(GlobalConfiguration().getValue('base_url') +
              "api/createRTMToken"),
          body: {"uid": uid});
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        _createClient(uid, data['token']);
      }
    } on http.ClientException catch (e) {
      print(e.message);
    }
  }

  AgoraRtmClient client;
  AgoraRtmChannel channel;
  List<dynamic> liveStream = [];

  void _createClient(String uid, String token) async {
    try {
      client = await AgoraRtmClient.createInstance(
          "13c3073d62644c148ecd1be0c02438cb");
      log(await AgoraRtmClient.getSdkVersion());
      print(client != null);
      // await client?.setParameters('{"rtm.log_filter": 15}');
      // await client?.setLogFile('');
      // await client?.setLogFilter(RtmLogFilter.info);
      // await client?.setLogFileSize(10240);
      client.onError = (error) {
        log("Client error: $error");
      };
      client.onConnectionStateChanged2 =
          (RtmConnectionState state, RtmConnectionChangeReason reason) {
        log('Connection state changed: $state, reason: $reason');
        if (state == RtmConnectionState.aborted) {
          client.logout();
          log('Logout');
          setState(() {
            isLogin = false;
          });
        }
      };
      client.onMessageReceived = (RtmMessage message, String peerId) {
        log("Peer msg: $peerId, msg: ${message.messageType} ${message.text}");
      };
      client.onTokenExpired = () {
        log("Token expired");
      };
      client.onTokenPrivilegeWillExpire = () {
        log("Token privilege will expire");
      };
      client.onPeersOnlineStatusChanged =
          (Map<String, RtmPeerOnlineState> peersStatus) {
        log("Peers online status changed ${peersStatus.toString()}");
      };
      // var id = Random().nextInt(30);
      await client.login(token, uid);
      joinChannel();
    } on AgoraRtmClientException catch (e) {
      print(e.reason);
    }
  }

  Future<void> onGetAllLiveStream() async {
    try {
      http.Response response = await http.get(Uri.parse(
          GlobalConfiguration().getValue('base_url') +
              "api/fetch/history/live"));
      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print(data['history'].length);
        if (data['history'].length <= 0) {
          // Navigator.pop(context);
          _selectTab(2);
        } else {
          setState(() {
            liveStreams.value = data['history'];
          });
        }
      }
    } on http.ClientException catch (e) {
      print(e.message);
    }
  }

  ScrollController _scrollController = new ScrollController();

  Future<AgoraRtmChannel> _createChannel(String name) async {
    AgoraRtmChannel channel = await client.createChannel(name);
    channel.onError = (error) {
      log("Channel error: $error");
    };
    channel.onMemberCountUpdated = (int memberCount) {
      log("Member count updated: $memberCount");
    };
    channel.onAttributesUpdated = (List<RtmChannelAttribute> attributes) {
      log("Channel attributes updated: ${attributes.toString()}");
    };
    channel.onMessageReceived =
        (RtmMessage message, RtmChannelMember member) {
      log("Channel msg: ${member.userId}, msg: ${message.messageType} ${message.text}");
      var message12 = jsonDecode(message.text);
      if (message12['type'] == "live") {
        onGetAllLiveStream();
      }
      log("Channel msg: ${member.userId}, msg: ${message.messageType} ${message.text}");
    };
    channel.onMemberJoined = (RtmChannelMember member) {
      log('Member joined: ${member.userId}, channel: ${member.channelId}');
    };
    channel.onMemberLeft = (RtmChannelMember member) {
      onGetAllLiveStream();
      log('Member left: ${member.userId}, channel: ${member.channelId}');
    };
      return channel;
  }

  Future<void> onFetchUserCount(String ch) async {
    try {
      http.Response response = await http.post(
          Uri.parse(GlobalConfiguration().getValue('base_url') +
              "api/fetch/history/update_live_count/$ch"),
          body: {"id": ch});
      if (response.statusCode == 200) {
        // await channel.sendMessage2(RtmMessage.fromText(jsonEncode({
        //   "type": "UserCount",
        //   "payload": {"id": ch}
        // })));
        setState(() {
          userCount.value['${ch}'] = {"id": ch, "userCount": 0};
        });
      }
    } catch (e) {
      print(e);
    }
  }

  Future<void> joinChannel() async {
    if (!_isInChannel) {
      try {
        channel = await _createChannel("SingleChannel");
        await channel.join();
        log('Join channel success');
        setState(() {
          _isInChannel = true;
        });
      } catch (errorCode) {
        log('Join channel error: $errorCode');
      }
    }
  }

  Future<void> onBackLive() async {
    await onGetAllLiveStream();
    _selectTab(2);
  }

  void _selectTab(int tabItem) {
    setState(() {
      widget.currentTab = tabItem;
      switch (tabItem) {
        case 0:
          widget.currentPage =
              NotificationsWidget(parentScaffoldKey: widget.scaffoldKey);
          break;
        case 1:
          widget.currentPage = MapWidget(
              parentScaffoldKey: widget.scaffoldKey,
              routeArgument: widget.routeArgument);
          break;
        case 2:
          widget.currentPage =
              HomeWidget(parentScaffoldKey: widget.scaffoldKey);
          break;
        case 3:
          widget.currentPage = LiveShop(
              parentScaffoldKey: widget.scaffoldKey,
              liveVideos: liveStream,
              scrollController: _scrollController,
              client: client,
              onBackLive: onBackLive,
              onFetchUserCount: onFetchUserCount,
              onGetAllLiveStream: onGetAllLiveStream);
          break;
        case 4:
          widget.currentPage =
              OrdersWidget(parentScaffoldKey: widget.scaffoldKey);
          // widget.currentPage = MessagesWidget(
          //     parentScaffoldKey: widget
          //         .scaffoldKey); //FavoritesWidget(parentScaffoldKey: widget.scaffoldKey);
          break;
      }
    });
  }

  @override
  void dispose() {
    client.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: widget.currentTab == 3
          ? () async {
              setState(() {
                _selectTab(2);
              });
              return await false;
            }
          : Helper.of(context).onWillPop,
      child: Scaffold(
        key: widget.scaffoldKey,
        drawer: DrawerWidget(),
        endDrawer: FilterWidget(onFilter: (filter) {
          Navigator.of(context)
              .pushReplacementNamed('/Pages', arguments: widget.currentTab);
        }),
        body: widget.currentPage,
        bottomNavigationBar: widget.currentTab == 3
            ? SizedBox()
            : BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                selectedItemColor: Theme.of(context).colorScheme.secondary,
                selectedFontSize: 0,
                unselectedFontSize: 0,
                iconSize: 22,
                elevation: 0,
                backgroundColor: Colors.transparent,
                selectedIconTheme: IconThemeData(size: 28),
                unselectedItemColor:
                    Theme.of(context).focusColor.withOpacity(1),
                currentIndex: widget.currentTab,
                onTap: (int i) {
                  if (i == 3) {
                    this._selectTab(i);
                                    } else {
                    this._selectTab(i);
                  }
                },
                // this will be set when a new tab is tapped
                items: [
                  BottomNavigationBarItem(
                    icon: Icon(widget.currentTab == 0
                        ? Icons.notifications
                        : Icons.notifications_outlined),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(widget.currentTab == 1
                        ? Icons.location_on
                        : Icons.location_on_outlined),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                      label: '',
                      icon: Container(
                        width: 42,
                        height: 42,
                        margin: EdgeInsets.only(bottom: 5),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          borderRadius: BorderRadius.all(
                            Radius.circular(50),
                          ),
                          boxShadow: [
                            BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme.secondary
                                    .withOpacity(0.4),
                                blurRadius: 40,
                                offset: Offset(0, 15)),
                            BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme.secondary
                                    .withOpacity(0.4),
                                blurRadius: 13,
                                offset: Offset(0, 3))
                          ],
                        ),
                        child: new Icon(
                            widget.currentTab == 2
                                ? Icons.home
                                : Icons.home_outlined,
                            color: Theme.of(context).primaryColor),
                      )),
                  BottomNavigationBarItem(
                    icon: new Icon(widget.currentTab == 4
                        ? Icons.shop_outlined
                        : Icons.shop_outlined),
                    label: '',
                  ),
                  BottomNavigationBarItem(
                    icon: new Icon(widget.currentTab == 3
                        ? Icons.local_mall
                        : Icons.local_mall_outlined),
                    label: '',
                  ),
                ],
              ),
      ),
    );
  }
}
