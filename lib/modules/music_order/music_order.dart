// ignore_for_file: use_build_context_synchronously

import "dart:async";

import "package:bobomusic/components/custom_dialog/custom_dialog.dart";
import "package:bobomusic/components/delete_orders/delete_orders.dart";
import "package:bobomusic/modules/music_order/components/top_bar.dart";
import "package:bobomusic/db/db.dart";
import "package:bobomusic/event_bus/event_bus.dart";
import "package:bobomusic/modules/music_order/components/edit_order.dart";
import "package:bobomusic/modules/music_order/pages/music_list_common.dart";
import "package:bobomusic/modules/music_order/pages/music_local.dart";
import "package:bobomusic/modules/music_order/pages/search.dart";
import "package:bobomusic/modules/music_order/utils.dart";
import "package:bot_toast/bot_toast.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:bobomusic/components/sheet/bottom_sheet.dart";
import "package:bobomusic/origin_sdk/origin_types.dart";
import "package:flutter_easyloading/flutter_easyloading.dart";

final DBOrder db = DBOrder(version: 2);

typedef OnItemHandler = void Function(
  MusicOrderItem data,
);

class Menus {
  static String newOrder = "新建歌单";
  static String editOrder = "编辑歌单";
  static String deleteOrders = "删除歌单";
}

class MusicOrderView extends StatefulWidget {
  final MusicOrderItem? musicOrder;
  const MusicOrderView({super.key, this.musicOrder});

  @override
  State<MusicOrderView> createState() => UserMusicOrderView();
}

class UserMusicOrderView extends State<MusicOrderView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;


  List<String> customOrderList = [];
  List<SheetItem> orderSheetList = [];
  List<dynamic> musicListCommonList = [];
  List<String> tabList = [
    TableName.musicLocal,
    TableName.musicILike,
  ];
  final Map<String, IconData> menuBtnMap = {
    Menus.newOrder: Icons.create_new_folder_outlined,
    Menus.editOrder: Icons.edit_note,
    Menus.deleteOrders: Icons.delete_forever,
  };
  final List<StreamSubscription?> _subscriptions = [];

  @override
  void initState() {
    super.initState();

    _subscriptions.add(eventBus.on<ShowLocalAction>().listen((event) {
      showDialog(
        context: context,
        builder: (ctx) => Container(
          alignment: Alignment.bottomCenter,
          child: CupertinoActionSheet(
            title: const Text("请选择操作", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            message: Container(
              margin: const EdgeInsets.only(top: 6),
              child: const Text("有时候重新扫描是必要的", style: TextStyle(fontSize: 10)),
            ),
            actions: [
              CupertinoActionSheetAction(
                onPressed: () {
                  eventBus.fire(ScanLocalList());
                  Navigator.of(context).pop();
                },
                child: const Text("重新扫描本地音乐", style: TextStyle(fontSize: 12, color: Colors.deepPurple))
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  deleteList(TableName.musicLocal);
                  Navigator.of(context).pop();
                },
                child: const Text("删除所有歌曲", style: TextStyle(fontSize: 12, color: Colors.deepPurple))
              ),
            ],
            cancelButton: CupertinoActionSheetAction(onPressed: () {
              Navigator.of(context).pop();
            }, child: Text("取消", style: TextStyle(fontSize: 12, color: Colors.grey[800]))),
          ),
        )
      );
    }));
    _subscriptions.add(eventBus.on<ShowDeleteListDialog>().listen((event) {
      deleteList(event.tabName);
    }));
    _subscriptions.add(eventBus.on<RefreshTabList>().listen((event) {
      _loadData();
    }));

    _loadData();
  }

  @override
  void dispose() {
    for (var sub in _subscriptions) {
      sub?.cancel();
    }
    super.dispose();
  }

  Future<void> refreshTabList() async {
    final orderList = await getCustomOrderList();

    setState(() {
      tabList = [
        TableName.musicLocal,
        TableName.musicILike,
        ...orderList,
      ];
    });
  }

  Future<void> _loadData() async {
    final orderList = await getCustomOrderList();

    setState(() {
      customOrderList = orderList;
      tabList = [
        TableName.musicLocal,
        TableName.musicILike,
        ...orderList,
      ];
      orderSheetList = orderList.map((e) {
        return SheetItem(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  e,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.bold,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const Icon(Icons.keyboard_arrow_right)
            ],
          ),
          onPressed: () {
            final NavigatorState navigator = Navigator.of(context, rootNavigator: false);
            navigator.push(ModalBottomSheetRoute(
              isScrollControlled: true,
              builder: (context) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: EditMusicOrder(name: e, update: _loadData),
                );
              },
            ));
          },
        );
      }).cast<SheetItem>().toList();
      musicListCommonList = orderList.map((e) {
        return MusicListCommon(tabName: e);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return const SearchOrderMusicView();
                },
              ),
            );
          },
          child: const TextField(
            enabled: false,
            decoration: InputDecoration(
              filled: true,
              fillColor: Color.fromARGB(255, 239, 240, 241),
              constraints: BoxConstraints(maxHeight: 35),
              border: UnderlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
              hintText: "搜索歌单中的歌曲",
              hintStyle: TextStyle(fontSize: 12),
              contentPadding: EdgeInsets.symmetric(vertical: 13.5, horizontal: 16),
            ),
          ),
        ),
        actions: [
          PopupMenuButton(
            icon: const Icon(Icons.menu),
            itemBuilder: (context) => _buildPopupBtnItems(),
            offset: const Offset(0, 46),
            constraints: const BoxConstraints(
              minWidth: 130,
              maxWidth: 130,
            ),
            onSelected: (e) {
              if (e == Menus.newOrder) {
                final NavigatorState navigator = Navigator.of(context, rootNavigator: false);
                navigator.push(ModalBottomSheetRoute(
                  isScrollControlled: true,
                  builder: (context) {
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: EditMusicOrder(name: "", update: _loadData),
                    );
                  },
                ));
              }
              if (e == Menus.editOrder) {
                if (orderSheetList.isNotEmpty) {
                  openBottomSheet(context, [
                    SheetItem(
                      title: Text(
                        "可编辑歌单",
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    ...orderSheetList,
                  ]);
                } else {
                  BotToast.showText(text: "没有可编辑的歌单", duration: const Duration(seconds: 2));
                }
              }
              if (e == Menus.deleteOrders) {
                if (customOrderList.isNotEmpty) {
                   Navigator.of(context, rootNavigator: false).push(ModalBottomSheetRoute(
                    isScrollControlled: true,
                    builder: (context) {
                      return DeleteOrders(onConfirm: _loadData);
                    },
                  ));
                } else {
                  BotToast.showText(text: "没有可删除的歌单", duration: const Duration(seconds: 2));
                }
              }
            },
          ),
          const SizedBox(width: 10)
        ],
      ),
      body: TopBar(
        tabList: tabList,
        contentList: [
          const MusicLocal(),
          MusicListCommon(tabName: TableName.musicILike),
          ...musicListCommonList,
        ],
      )
    );
  }

  List<PopupMenuItem<String>> _buildPopupBtnItems() {
    return menuBtnMap.keys.toList().map((btn) {
      return PopupMenuItem<String>(
        value: btn,
        child: SizedBox(
          width: 100, // 设置一个合适的宽度
          child: Row(
            children: [
              Icon(menuBtnMap[btn], color: Theme.of(context).primaryColor),
              const SizedBox(width: 10),
              Text(btn)
            ],
          ),
        ),
      );
    }).toList();
  }

  Future<void> deleteList(String tabName) async {
    final musicList = await db.queryAll(tabName);

    if (context.mounted && musicList.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return CustomDialog(
            body: const Text("删除此歌单所有歌曲?"),
            onConfirm: () async {
              EasyLoading.show(maskType: EasyLoadingMaskType.black);

              if (context.mounted) {
                Navigator.of(context).pop();
              }

              try {
                await db.deleteAll(tabName);
                eventBus.fire(ClearMusicList());
              } catch (error) {
                print(error);
              }
              EasyLoading.dismiss();
            },
            onCancel: () {
              Navigator.of(context).pop();
            },
          );
        },
      );
    }
  }
}
