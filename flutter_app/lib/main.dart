import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:pytorch_lite/pigeon.dart';
// import 'package:pytorch_lite/pytorch_lite.dart';

import 'pylite2.dart';
import 'package:empty_widget/empty_widget.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ClassificationModel? _imageModel;
  String? _imagePrediction;
  String? _predictionConfidence;
  File? _image;
  final ImagePicker _picker = ImagePicker();
  int _inferenceTime = 0;
  final stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    loadModel();
  }

  double getMaxPredictionValue(Map<String, dynamic> data) {
    List<double> prediction =
        List.castFrom<dynamic, double>(data['probabilities']);
    return prediction.reduce((currMax, val) => currMax > val ? currMax : val);
  }

  //load your model
  Future loadModel() async {
    String pathImageModel = "assets/models/torchscript_edgenext_xx_small.pt";
    try {
      _imageModel = await PytorchLite.loadClassificationModel(
          pathImageModel, 224, 224,
          labelPath: "assets/labels/label_classification_paddy.txt");
    } on PlatformException {
      print("only supported for android");
    }
  }

  Future runClassification() async {
    //pick an image
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    stopwatch.start();

    // run inference
    var result = await _imageModel!
        .getImagePredictionMap(await File(image!.path).readAsBytes());

    // print(result);

    stopwatch.stop();

    setState(() {
      _imagePrediction = result['label'];
      _predictionConfidence = result['probabilities'];
      _image = File(image.path);
      _inferenceTime = stopwatch.elapsedMilliseconds;
    });
    stopwatch.reset();
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Paddy Disease Classifier'),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.camera),
          onPressed: runClassification,
        ),
        body: Container(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: Visibility(
                  visible: _imagePrediction != null,
                  child: Column(
                    children: [
                      Text("Disease: $_imagePrediction",
                          style: const TextStyle(fontSize: 20)),
                      Text("Confidence: $_predictionConfidence %",
                          style: const TextStyle(fontSize: 20)),
                      Text("Inference time: $_inferenceTime ms",
                          style: const TextStyle(fontSize: 20)),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _image == null
                    ? EmptyWidget(
                        image: null,
                        packageImage: PackageImage.Image_3,
                        title: 'No image',
                        // subTitle: 'Select an image or upload your own',
                        titleTextStyle: const TextStyle(
                          fontSize: 15,
                          color: Color(0xff9da9c7),
                          fontWeight: FontWeight.w500,
                        ),
                        subtitleTextStyle: const TextStyle(
                          fontSize: 14,
                          color: Color(0xffabb8d6),
                        ),
                      )
                    : Image.file(_image!),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Linkify(
                  onOpen: (link) async {
                    if (await canLaunch(link.url)) {
                      await launch(link.url);
                    } else {
                      throw 'Could not launch $link';
                    }
                  },
                  text: "Made by https://dicksonneoh.com",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
