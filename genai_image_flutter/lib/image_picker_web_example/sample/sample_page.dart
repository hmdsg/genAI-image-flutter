import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SamplePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SamplePageState();
}

class _SamplePageState extends State<SamplePage> {
  String BackendURL = "https://backend-image-67idgn363a-an.a.run.app";
  // String BackendURL = "http://localhost:8080";
  final _pickedImages = <Image>[];
  var _imageCaption;
  var uint8list;
  bool _isEnabledGetDescription = false;
  bool _isEnabledSelectImage = true;
  String _SelectImageButtonTitle = "Select item image";
  String _itemDescription = 'The description will be displayed here.';
  String _DescriptionButtonTitle = 'Get item description';
  var selectedLangValue = "English";
  final langLists = <String>["English", "Japanese", "Indonesian"];

//  バイトで画像を選択
  Future<void> _selectImage() async {
    uint8list = await ImagePickerWeb.getImageAsBytes();
    if (uint8list != null) {

      setState(() {
        //アップロードと画像表示
        _isEnabledGetDescription = false;
        _isEnabledSelectImage = false;
        _pickedImages.clear();
        _pickedImages.add(Image.memory(uint8list));
        _itemDescription = 'The description will be displayed here.';
        _SelectImageButtonTitle = "loading...";

      });
      _uploadImage();

    }
  }

// バイトをアップロード
  Future<void> _uploadImage() async {
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

    setState(() {
      _isEnabledGetDescription = true;
      _isEnabledSelectImage = true;
      _DescriptionButtonTitle = "Get item description";
      _SelectImageButtonTitle = "Select item image";

    });

    _imageCaption = response.body;

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

  // イメージキャプションから説明文を作成
  Future<void> _getDescriptionWithImageCaption() async {

    Uri url = Uri.parse("$BackendURL/description");
    Map<String, String> headers = {'content-type': 'application/json'};
    // パワメーターをあとで追加
    String body = json.encode({'imageCaption': _imageCaption,'lang': selectedLangValue});

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
      _isEnabledGetDescription = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Basic Sample'),
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
              ButtonBar(alignment: MainAxisAlignment.center, children: <Widget>[
                DropdownButton<String>(
                  value: selectedLangValue,
                  items: langLists
                      .map((String list) =>
                      DropdownMenuItem(value: list, child: Text(list)))
                      .toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedLangValue = value!;
                    });
                  },
                ),
              ]),
              ButtonBar(alignment: MainAxisAlignment.center, children: <Widget>[
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
              ]),
            ]),
      ),
    );
  }
}
