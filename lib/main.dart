import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:developer';
import 'package:tflite_audio/tflite_audio.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

void main() => runApp(MyApp());

///This example showcases how to take advantage of all the futures and streams
///from the plugin.
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final isRecording = ValueNotifier<bool>(false);
  Stream<Map<dynamic, dynamic>> result;

  

  //!example values for google's teachable machine model
  final String model = 'assets/soundclassifier.tflite';
  final String label = 'assets/labels.txt';
  final String inputType = 'rawAudio';
  final int sampleRate = 44100;
  final int recordingLength = 44032;
  final int bufferSize = 22016;
  final int numOfInferences = 1;

  @override
  void initState() {
    super.initState();
    TfliteAudio.loadModel(
      numThreads: 1,
      isAsset: true,
      model: this.model,
      label: this.label,
    );
  }

  /// get result by calling the future startAudioRecognition future
  /// be sure to comment one of the other to switch model types.
  void getResult() {
    result = TfliteAudio.startAudioRecognition(
      numOfInferences: this.numOfInferences,
      inputType: this.inputType,
      sampleRate: this.sampleRate,
      recordingLength: this.recordingLength,
      bufferSize: this.bufferSize,
    );

    ///Logs the results and assigns false when stream is finished.
    result
        .listen((event) => log(event.toString()))
        .onDone(() => isRecording.value = false);
  }

  //fetches the labels from the text file in assets
  Future<List<String>> fetchLabelList() async {
    List<String> _labelList = [];
    await rootBundle.loadString(this.label).then((q) {
      for (String i in LineSplitter().convert(q)) {
        _labelList.add(i);
      }
    });
    return _labelList;
  }

  ///handles null exception if snapshot is null.
  String showResult(AsyncSnapshot snapshot, String key) =>
      snapshot.hasData ? snapshot.data[key].toString() : 'null ';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
            key: _scaffoldKey,
            appBar: AppBar(
              title: const Text('Tflite-audio/speech'),
            ),
            //Streambuilder for inference results
            body: StreamBuilder<Map<dynamic, dynamic>>(
                stream: result,
                builder: (BuildContext context,
                    AsyncSnapshot<Map<dynamic, dynamic>> inferenceSnapshot) {
                  //futurebuilder for getting the label list
                  return FutureBuilder(
                      future: fetchLabelList(),
                      builder: (BuildContext context,
                          AsyncSnapshot<List<String>> labelSnapshot) {
                        switch (inferenceSnapshot.connectionState) {
                          case ConnectionState.none:
                            //Loads the asset file.
                            if (labelSnapshot.hasData) {
                              return labelListWidget(labelSnapshot.data);
                            } else {
                              return CircularProgressIndicator();
                            }
                            break;
                          case ConnectionState.waiting:
                            //Widets will let the user know that its loading when waiting for results
                            return Stack(children: <Widget>[
                              Align(
                                  alignment: Alignment.bottomRight,
                                  child: inferenceTimeWidget('calculating..')),
                              labelListWidget(labelSnapshot.data),
                            ]);
                            break;
                          //Widgets will display the final results.
                          default:
                            return Stack(children: <Widget>[
                              Align(
                                  alignment: Alignment.bottomRight,
                                  child: inferenceTimeWidget(showResult(
                                          inferenceSnapshot, 'inferenceTime') +
                                      'ms')),
                              labelListWidget(
                                  labelSnapshot.data,
                                  showResult(
                                      inferenceSnapshot, 'recognitionResult'))
                            ]);
                        }
                      });
                }),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: Container(
                child: ValueListenableBuilder(
                    valueListenable: isRecording,
                    builder: (context, value, widget) {
                      if (value == false) {
                        return FloatingActionButton(
                          onPressed: () {
                            isRecording.value = true;
                            setState(() {
                              getResult();
                            });
                          },
                          backgroundColor: Colors.blue,
                          child: const Icon(Icons.mic),
                        );
                      } else {
                        return FloatingActionButton(
                          onPressed: () {
                            log('Audio Recognition Stopped');
                            //Press button again to cancel audio recognition
                            TfliteAudio.stopAudioRecognition();
                          },
                          backgroundColor: Colors.red,
                          child: const Icon(Icons.adjust),
                        );
                      }
                    }))));
  }

  ///  If snapshot data matches the label, it will change colour
  Widget labelListWidget(List<String> labelList, [String result]) {
    return Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: labelList.map((labels) {
              if (labels == result) {
                return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text(labels.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 25,
                          color: Colors.green,
                        )));
              } else {
                return Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text(labels.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        )));
              }
            }).toList()));
  }

  ///If the future isn't completed, shows 'calculating'. Else shows inference time.
  Widget inferenceTimeWidget(String result) {
    return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Text(result,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black,
            )));
  }
}