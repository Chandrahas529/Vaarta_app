import 'package:flutter/material.dart';

class Chatoptionprovider extends ChangeNotifier {
  int _noOfMessageSelected = 0;
  bool _selectMode = false;
  bool _isForrwardedMode = false;
  List<Map<String,String>> _selectedMessage = [];
  List<Map<String,String>> _selectedIds = [];

  void resetSelectionCount(){
    _noOfMessageSelected = 0;
    notifyListeners();
  }
  void incrementSelectionCount(){
    _noOfMessageSelected++;
    notifyListeners();
  }
  void decrementSelectionCount(){
    _noOfMessageSelected--;
    notifyListeners();
  }
  int getSelectionCount(){
    return _noOfMessageSelected;
  }
  void selectModeStatus(){
    _selectMode = !_selectMode;
    notifyListeners();
  }
  bool getSelectMode(){
    return _selectMode;
  }

  void selectForwardMode(bool value){
    _isForrwardedMode = value;
    notifyListeners();
  }

  bool getSelectForwardMode(){
    return _isForrwardedMode;
  }

  List<Map<String,String>> getSelectedIds(){
    return _selectedIds;
  }

  void addSelectedIds(String id,String type,String content){
    _selectedIds.add({"id":id,"type":type,"content":content});
    notifyListeners();
  }

  void removeSelectedIds(String id){
    _selectedIds.removeWhere((e) => e['id'] == id);
    notifyListeners();
  }

  void setSelectedMessage(){
    _selectedMessage.add(_selectedIds.last);
    notifyListeners();
  }

  void setSwipeSelectedMessage(String id,String type,String content){
    _selectedMessage.add({"id":id,"type":type,"content":content});
    notifyListeners();
  }

  Map<String,String>? getSelectedMessage(){
    return _selectedMessage.isNotEmpty ? _selectedMessage.first : null;
  }

  void removeSelectedMessage(){
    _selectedMessage = [];
    notifyListeners();
  }

  void removeAllSelectedIds(){
    _selectedIds.clear();
    _isForrwardedMode = false;
    notifyListeners();
  }

  void resetChatOption(){
    _noOfMessageSelected = 0;
    selectModeStatus();
    _isForrwardedMode = false;
    _selectedIds.clear();
    notifyListeners();
  }
}