import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_net_storage/utils/config.dart';

import '../utils/api_service.dart';
import 'exmodel.dart';

class PlateManagePage extends StatefulWidget {
  const PlateManagePage({super.key});

  @override
  State<PlateManagePage> createState() => _PlateManagePageState();
}

class _PlateManagePageState extends State<PlateManagePage> {
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
    try {
      List<EXModel> plates = await ApiService.getList<EXModel>(
        baseUrl,
        (json) => EXModel.fromJson(json),
      );

      // 原始 JSON 字符串（用于展示）
      setState(() {
        resultShowJson = jsonEncode(plates.map((e) => e.toJson()).toList());
      });

      // 格式化展示
      String formatted = plates
          .map(
            (plate) =>
                'Plate: ${plate.id}, Brand: ${plate.brand}, Model: ${plate.model}',
          )
          .join('\n');

      setState(() {
        resultShowMap = formatted;
      });
    } catch (e) {
      setState(() {
        resultShowMap = '获取失败: $e';
      });
    }
  }

  _doPostBtn() {
    return ElevatedButton(onPressed: _doPost, child: Text('Add a plate(POST)'));
  }

  void _doPost() async {
    try {
      var plate = EXModel(
        id: _plateController.text,
        brand: _brandController.text,
        model: _modelController.text,
      );

      var responseBody = await ApiService.postObject<EXModel>(
        baseUrl,
        plate,
        (model) => model.toJson(),
      );

      setState(() {
        resultShowJson = responseBody;
        resultShowMap = '添加成功';
      });
    } catch (e) {
      setState(() {
        resultShowJson = e.toString();
      });
    }
  }

  _doPatchBtn() {
    return ElevatedButton(
      onPressed: _doPatch,
      child: Text('Change a Plate(PATCH)'),
    );
  }

  void _doPatch() async {
    try {
      var updateData = {
        "brand": _brandController.text,
        "model": _modelController.text,
      };

      var responseBody = await ApiService.patchObject<EXModel>(
        baseUrl,
        _plateController.text,
        updateData,
      );

      setState(() {
        resultShowJson = responseBody;
        resultShowMap = '更新成功';
      });
    } catch (e) {
      setState(() {
        resultShowJson = e.toString();
      });
    }
  }

  _doDeleteBtn() {
    return ElevatedButton(
      onPressed: _doDelete,
      child: Text('Delete a Plate(DELETE)'),
    );
  }

  void _doDelete() async {
    try {
      var responseBody = await ApiService.deleteObject(
        baseUrl,
        _plateController.text,
      );

      setState(() {
        resultShowJson = responseBody;
        resultShowMap = '删除成功';
      });
    } catch (e) {
      setState(() {
        resultShowJson = e.toString();
      });
    }
  }
}
