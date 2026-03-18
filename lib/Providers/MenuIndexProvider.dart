import 'package:flutter/cupertino.dart';

class MenuindexProvider extends ChangeNotifier{
    int _menuIndex = 0;
    List<int> _historyTab = [0];

    void setHistoryTab(int index){
      _historyTab.add(index);
      notifyListeners();
    }

    List<int> getHistoryTab(){
      return _historyTab;
    }

    void removeHistoryTab(){
      _historyTab.removeLast();
      notifyListeners();
    }

    void setIndex(int index){
      _menuIndex = index;
      notifyListeners();
    }

    int getIndex(){
      return _menuIndex;
    }
}