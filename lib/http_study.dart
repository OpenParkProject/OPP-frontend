import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class HttpStudy extends StatefulWidget {
  const HttpStudy({super.key});

  @override
  State<HttpStudy> createState() => _HttpStudyState();
}

class _HttpStudyState extends State<HttpStudy> {
  var resultShowJson = '';
  var resultShowMap = '';

  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('CDUR Test')),
      body: Column(
        children: [
          _doGetBtn(),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _plateController,
              decoration: const InputDecoration(labelText: 'Plate'),
            ),
          ),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _brandController,
              decoration: const InputDecoration(labelText: 'Brand'),
            ),
          ),
          SizedBox(
            width: 300,
            child: TextField(
              controller: _modelController,
              decoration: const InputDecoration(labelText: 'Model'),
            ),
          ),
          _doPostBtn(),
          _doPatchBtn(),
          _doDeleteBtn(),
          Text('Json:$resultShowJson'),
          Text('Dart Map:$resultShowMap'),
        ],
      ),
    );
  }

  _doGetBtn() {
    return ElevatedButton(onPressed: _doGet, child: Text('Get All Plate(GET)'));
  }

  void _doGet() async {
    var uri = Uri.parse('http://localhost:3000/posts');
    var response = await http.get(uri);
    if (response.statusCode == 200) {
      setState(() {
        resultShowJson = response.body;
      });
      var map = jsonDecode(response.body);
      setState(() {
        resultShowMap = map['msg'];
      });
    } else {
      resultShowJson =
          '请求失败: code:${response.statusCode}, body:${response.body}';
    }
  }

  _doPostBtn() {
    return ElevatedButton(onPressed: _doPost, child: Text('Add a plate(POST)'));
  }

  _doPost() async {
    var uri = Uri.parse('http://localhost:3000/posts');
    var params = {
      "id": _plateController.text,
      "brand": _brandController.text,
      "model": _modelController.text,
    };
    var response = await http.post(
      uri,
      body: jsonEncode(params),
      //headers: {'content-type': 'application/json'},
    );
    if (response.statusCode == 200) {
      setState(() {
        resultShowJson = response.body;
      });
      var map = jsonDecode(response.body);
      setState(() {
        resultShowMap = map['msg'];
      });
    } else {
      resultShowJson =
          '请求失败: code:${response.statusCode}, body:${response.body}';
    }
  }

  _doPatchBtn() {
    return ElevatedButton(
      onPressed: _doPatch,
      child: Text('Change a Plate(PATCH)'),
    );
  }

  _doPatch() async {
    var uri = Uri.parse(
      'http://localhost:3000/posts/${_plateController.text}',
    ); // 假设更新id为1的项
    var params = {
      "brand": _brandController.text,
      "model": _modelController.text,
    }; // 只更新部分字段
    var response = await http.patch(
      uri,
      body: jsonEncode(params),
      //headers: {'content-type': 'application/json'},
    );
    if (response.statusCode == 200) {
      setState(() {
        resultShowJson = response.body;
      });
      var map = jsonDecode(response.body);
      setState(() {
        resultShowMap = map['msg'];
      });
    } else {
      resultShowJson =
          '请求失败: code:${response.statusCode}, body:${response.body}';
    }
  }

  _doDeleteBtn() {
    return ElevatedButton(
      onPressed: _doDelete,
      child: Text('Delete a Plate(DELETE)'),
    );
  }

  _doDelete() async {
    var uri = Uri.parse(
      'http://localhost:3000/posts/${_plateController.text}',
    ); // 假设删除id为1的项
    var response = await http.delete(
      uri,
      //headers: {'content-type': 'application/json'},
    );
    if (response.statusCode == 200) {
      setState(() {
        resultShowJson = response.body;
      });
      var map = jsonDecode(response.body);
      setState(() {
        resultShowMap = map['msg'];
      });
    } else {
      resultShowJson =
          '请求失败: code:${response.statusCode}, body:${response.body}';
    }
  }
}

//Tested by a simple json-server
