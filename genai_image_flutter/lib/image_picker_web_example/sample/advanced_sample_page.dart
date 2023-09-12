import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdvancedSamplePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AdvancedSamplePageState();
}

class _AdvancedSamplePageState extends State<AdvancedSamplePage> {
  String BackendURL = "https://backend-image-67idgn363a-an.a.run.app";
  // String BackendURL = "http://localhost:8080";

  final _pickedImages = <Image>[];
  var _imageCaption;
  Map _option = {};

  var uint8list;
  bool _isEnabledGetDescription = false;
  bool _isEnabledSelectImage = true;
  String _itemDescription = 'The description will be displayed here.';
  String _SelectImageButtonTitle = "Select item image";
  String _DescriptionButtonTitle = 'Get item description';
  var selectedLangValue = "English";
  final langLists = <String>["English", "Japanese", "Indonesian"];
  var _keys = [];
  String selectedOption1Title = "";
  String selectedOption2Title = "";
  String selectedOption1Value = "";
  String selectedOption2Value = "";
  List<String> selectedOption1Lists = [""];
  List<String> selectedOption2Lists = [""];
  var _optionWidget;

  Widget _makeOption() {
    if (_keys.length != 0) {
      _optionWidget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 60,
            width: 300,
            alignment: Alignment.center,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(selectedOption1Title),
              Spacer(),
              DropdownButton<String>(
                value: selectedOption1Value,
                items: selectedOption1Lists
                    .map((String list) =>
                        DropdownMenuItem(value: list, child: Text(list)))
                    .toList(),
                onChanged: (String? value) {
                  setState(() {
                    selectedOption1Value = value!;
                  });
                },
              ),
            ]),
          ),
          Container(
            height: 60,
            width: 300,
            alignment: Alignment.center,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(selectedOption2Title),
              Spacer(),
              DropdownButton<String>(
                value: selectedOption2Value,
                items: selectedOption2Lists
                    .map((String list) =>
                        DropdownMenuItem(value: list, child: Text(list)))
                    .toList(),
                onChanged: (String? value) {
                  setState(() {
                    selectedOption2Value = value!;
                  });
                },
              ),
            ]),
          ),
        ],
      );
    } else {
      _optionWidget = Container(
        //SizedBoxでも同じ
        height: 10,
        width: 500,
      );
    }
    return _optionWidget;
  }

//  バイトで画像を選択
  Future<void> _selectImage() async {
    uint8list = await ImagePickerWeb.getImageAsBytes();
    if (uint8list != null) {
      setState(() {
        //リセット
        _isEnabledGetDescription = false;
        _isEnabledSelectImage = false;
        _pickedImages.clear();
        _keys = [];
        _imageCaption = "";
        _itemDescription = 'The description will be displayed here.';
        //アップロードと画像表示
        _pickedImages.add(Image.memory(uint8list));
        _SelectImageButtonTitle = "loading...";
      });
      await _uploadImage();
      await _getOptionWithImageCaption();
    }
  }

// バイトをアップロード
  Future<void> _uploadImage() async {
    print("start");
    if (uint8list == null) {
      print("no image data");
    }
    final response = await multipart(
      method: 'POST',
      url: Uri.parse("$BackendURL/upload"),
      files: [
        http.MultipartFile.fromBytes(
          'upfile',
          uint8list,
          filename: "media1",
        ),
      ],
    );

    _imageCaption = response.body;

    print(response.statusCode);
  }

  Future<http.Response> multipart({
    required String method,
    required Uri url,
    required List<http.MultipartFile> files,
  }) async {
    final request = http.MultipartRequest(method, url);

    request.files.addAll(files); // 送信するファイルのバイナリデータを追加

    final stream = await request.send();

    return http.Response.fromStream(stream).then((response) {
      if (response.statusCode == 200) {
        return response;
      }

      if (response.statusCode != 200) {
        return response;
      }

      return Future.error(response);
    });
  }

  // イメージキャプションからOptionを取得
  Future<void> _getOptionWithImageCaption() async {
    Uri url = Uri.parse("$BackendURL/option");
    Map<String, String> headers = {'content-type': 'application/json'};
    // パワメーターをあとで追加
    String body =
        json.encode({'imageCaption': _imageCaption, 'lang': selectedLangValue});

    http.Response resp = await http.post(url, headers: headers, body: body);
    if (resp.statusCode != 200) {
      setState(() {
        int statusCode = resp.statusCode;
        print("Failed to post $statusCode");
      });
      return;
    }

    print(resp.body);
    // Map<String, dynamic> res = json.decode(response.body);
    Map<dynamic, dynamic> res = json.decode(resp.body);
    //
    //
    _keys = List.from(res.keys);

    selectedOption1Lists = List<String>.from(res[_keys[0]] as List);
    selectedOption2Lists = List<String>.from(res[_keys[1]] as List);

    // selectedOption2Lists = _option[_keys[1]];
    selectedOption1Title = _keys[0];
    selectedOption2Title = _keys[1];
    selectedOption1Value = selectedOption1Lists[0];
    selectedOption2Value = selectedOption2Lists[1];

    setState(() {
      // get_descriptionを活性化
      _isEnabledGetDescription = true;
      _isEnabledSelectImage = true;
      _SelectImageButtonTitle = "Select item image";
      _DescriptionButtonTitle = "Get item description";
    });
  }

  // イメージキャプションから説明文を作成
  Future<void> _getDescriptionWithImageCaption() async {
    Uri url = Uri.parse("$BackendURL/description");
    Map<String, String> headers = {'content-type': 'application/json'};
    // パワメーターをあとで追加
    String body = json.encode({
      'imageCaption': _imageCaption,
      'lang': selectedLangValue,
      'option1_title': selectedOption1Title,
      'option1_value': selectedOption1Value,
      'option2_title': selectedOption2Title,
      'option2_value': selectedOption2Value
    });

    http.Response resp = await http.post(url, headers: headers, body: body);
    if (resp.statusCode != 200) {
      setState(() {
        int statusCode = resp.statusCode;
        print("Failed to post $statusCode");
      });
      return;
    }
    setState(() {
      // 完成品を表示
      _itemDescription = resp.body;
      // print(resp.body);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Sample'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 250,
              width: 500,
              color: Colors.white,
              alignment: Alignment.center,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeIn,
                child: SizedBox(
                  height: 250,
                  width: 250,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _pickedImages.length,
                    itemBuilder: (_, index) {
                      return Align(
                        alignment: Alignment.center,
                        child: _pickedImages[index],
                      );
                    },
                  ),
                ),
              ),
            ),
            Container(
              height: 10,
              width: 500,
              alignment: Alignment.center,
            ),
            Container(
              height: 100,
              width: 500,
              color: Colors.white,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                child: SelectableText(_itemDescription),
              ),
            ),
            _makeOption(),
            Container(
              height: 60,
              width: 300,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Language"),
                  Spacer(),
                  ButtonBar(
                    alignment: MainAxisAlignment.center,
                    children: <Widget>[
                      DropdownButton<String>(
                        value: selectedLangValue,
                        items: langLists
                            .map((String list) => DropdownMenuItem(
                                value: list, child: Text(list)))
                            .toList(),
                        onChanged: (String? value) {
                          setState(
                            () {
                              selectedLangValue = value!;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ButtonBar(
              alignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: !_isEnabledSelectImage
                      ? null
                      : () {
                          _selectImage();
                        },
                  child:  Text(_SelectImageButtonTitle),
                ),
                ElevatedButton(
                  onPressed: !_isEnabledGetDescription
                      ? null
                      : () {
                          _getDescriptionWithImageCaption();
                        },
                  child: Text(_DescriptionButtonTitle),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
