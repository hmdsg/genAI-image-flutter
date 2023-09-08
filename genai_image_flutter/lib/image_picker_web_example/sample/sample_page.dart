import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class SamplePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SamplePageState();
}

class _SamplePageState extends State<SamplePage> {
  final _pickedImages = <Image>[];
  var uint8list;
  String _imageInfo = '';

  Future<void> _pickImage() async {
    final fromPicker = await ImagePickerWeb.getImageAsWidget();
    if (fromPicker != null) {
      setState(() {
        _pickedImages.clear();
        _pickedImages.add(fromPicker);
      });
    }
  }

//  バイトで画像を選択
  Future<void> _selectImage() async {
    uint8list = await ImagePickerWeb.getImageAsBytes();
    if (uint8list != null) {
      setState(() {
        //アップロードと画像表示
        _pickedImages.clear();
        _pickedImages.add(Image.memory(uint8list));
      });
    }
  }

  
// バイトをアップロード
  Future<void> _uploadImage() async {
    print("start");
    final response = await multipart(
      method: 'POST',
      url: Uri.http('127.0.0.1:5000', '/upload'),
      // url: Uri.http('127.0.0.1:5000', '/test'),

      files: [
        http.MultipartFile.fromBytes(
          'upfile',
          uint8list ,
          filename: "media1",
        ),
      ],
    );

    print(response.statusCode);
    print(response.body);

    // Uri url = Uri.parse("http://127.0.0.1:5000/test");
    // Map<String, String> headers = {'content-type': 'application/json'};
    // String body = json.encode({'name': 'moke'});
    //
    // http.Response resp = await http.post(url, headers: headers, body: body);
    // if (resp.statusCode != 200) {
    //   setState(() {
    //     int statusCode = resp.statusCode;
    //     print("Failed to post $statusCode");
    //   });
    //   return;
    // }
    // setState(() {
    //   print(resp.body);
    // });

  }

  Future<http.Response> multipart({
    required String method,
    required Uri url,
    required List<http.MultipartFile> files,
  }) async {
    final request = http.MultipartRequest(method, url);

    request.files.addAll(files); // 送信するファイルのバイナリデータを追加
    // request.headers.addAll({'Authorization': 'Bearer xxxxxx'}); // 認証情報などを追加

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sample 1'),
      ),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Wrap(
                // spacing: 15.0,
                children: <Widget>[
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeIn,
                    child: SizedBox(
                      width: 500,
                      height: 200,
                      child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _pickedImages.length,
                          itemBuilder: (_, index) => _pickedImages[index]),
                    ),
                  ),
                  Container(
                    height: 200,
                    width: 200,
                    child: Text(_imageInfo, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              ButtonBar(alignment: MainAxisAlignment.center, children: <Widget>[
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Select Image'),
                ),
                ElevatedButton(
                  onPressed: _selectImage,
                  child: const Text('select byte Image'),
                ),
                ElevatedButton(
                  onPressed: _uploadImage,
                  child: const Text('upload byte Image'),
                ),
              ]),
            ]),
      ),
    );
  }
}
