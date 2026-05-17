import "package:event_bus/event_bus.dart";
import "package:flutter/material.dart";

// 创建事件总线实例
final EventBus eventBus = EventBus();

// 定义事件类
class RefreshMusicList {
  final String tabName;
  RefreshMusicList({required this.tabName});
}

class ClearMusicList {}
class ShowDeleteListDialog {
  final String tabName;
  ShowDeleteListDialog({required this.tabName});
}
class ScanLocalList {}
class ScanLocalListWithoutLoading {}
class ShowLocalAction {}
class RefreshTabList {}
class RefreshCollectionList {}
class RefreshPlayerCard {}
class ScrollLyric {}

class ThemeColorChanged {
  final Color newColor;

  ThemeColorChanged(this.newColor);
}
