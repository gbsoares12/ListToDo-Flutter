import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];

  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;

  final _toDoController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void _addToDo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoController.text;
      _toDoController.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));

    setState(() {
      _toDoList.sort((mapA, mapB) {
        if (mapA["ok"] && !mapB["ok"])
          return 1;
        else if (!mapA["ok"] && mapB["ok"])
          return -1;
        else
          return 0;
      });

      _saveData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(20, 1, 1, 7),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Nova Tarefa',
                      labelStyle: TextStyle(color: Colors.blue),
                    ),
                    controller: _toDoController,
                  ),
                ),
                RaisedButton(
                  color: Colors.blue,
                  child: Text('Add'),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 10.0),
                      itemCount: _toDoList.length,
                      itemBuilder: buildItem),
                  onRefresh: _refresh))
        ],
      ),
    );
  }

  Widget buildItem(context, index) {
    return Dismissible(
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
      ),
      direction: DismissDirection.startToEnd,
      key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
      child: CheckboxListTile(
        title: Text(_toDoList[index]["title"]),
        value: _toDoList[index]["ok"],
        secondary: CircleAvatar(
          child: _toDoList[index]["ok"] ? Icon(Icons.check) : Icon(Icons.error),
        ),
        onChanged: (c) {
          setState(() {
            _toDoList[index]["ok"] = c;
            _saveData();
          });
        },
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          setState(() {
            _lastRemoved = Map.from(_toDoList[index]);
            _lastRemovedPos = index;
            _toDoList.removeAt(index);
            _saveData();

            final snack = SnackBar(
              content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
              action: SnackBarAction(
                  label: "Desfazer",
                  onPressed: () {
                    setState(() {
                      _toDoList.insert(_lastRemovedPos, _lastRemoved);
                    });
                  }),
              duration: Duration(seconds: 2),
            );
            Scaffold.of(context).removeCurrentSnackBar();
            Scaffold.of(context).showSnackBar(snack);
          });
        }
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();

      return file.readAsString();
    } catch (err) {
      return null;
    }
  }
}
