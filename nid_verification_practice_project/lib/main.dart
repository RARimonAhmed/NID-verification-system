import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text('EID Card Scanner'),
        ),
        body: Center(
          child: ElevatedButton(
            onPressed: _scanEIDCard,
            child: Text('Scan EID Card'),
          ),
        ),
      ),
    );
  }
  void _scanEIDCard() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.camera);
      final data = await EIDScanner.scanEmirateId(image: File(image!.path));
      if (data != null) {
        print(data.toString());
      }
    } catch (e) {
      print(e);
    }
  }
}

class EIDScanner {
  /// this method will process the images and extract information from the card
  static Future<EmirateIdModel?> scanEmirateId({
    required File image,
  }) async {
    List<String> eIdDates = [];
    // GoogleMlKit vision languageModelManager
    TextRecognizer textDetector = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognisedText = await textDetector.processImage(
      InputImage.fromFilePath(image.path),
    );

    // to check it is Emirate Card
    if (!recognisedText.text
        .toString()
        .toLowerCase()
        .contains("National ID Card".toLowerCase()) &&
        !recognisedText.text
            .toString()
            .toLowerCase()
            .contains("Government of the People's Republic of Bangladesh".toLowerCase())) {
      //throw "Invalid Emirate Card";
      return null;
    }

    final listText = recognisedText.text.split('\n');

    // attributes
    String? enName;
    String? bnName;
    String? fathersName;
    String? mothersName;
    String? nationality;
    String? nidNumber;

    listText.forEach((element) {
      if (_isDate(text: element.trim())) {
        eIdDates.add(element.trim());
      } else if (_isEnName(text: element.trim()) != null) {
        enName = _isEnName(text: element.trim());
      } else if (_isBnName(text: element.trim()) != null) {
        bnName = _isBnName(text: element.trim());
      }else if (_isFathersName(text: element.trim()) != null) {
        fathersName = _isFathersName(text: element.trim());
      }else if (_isMothersName(text: element.trim()) != null) {
        mothersName = _isMothersName(text: element.trim());
      }else if (_isNationality(text: element.trim()) != null) {
        nationality = _isNationality(text: element.trim());
      }else if (_isNumberID(text: element.trim()) != null) {
        nidNumber = element.trim();
      }
    });

    eIdDates = _sortDateList(dates: eIdDates);

    textDetector.close();

    return EmirateIdModel(
      enName: enName ?? "Cannot collect enName",
      bnName: bnName ?? "Cannot collect bnName",
      fathersName: fathersName ?? "Cannot collect nationality",
      nationality: nationality?? "Cannot collect nationality",
      dateOfBirth: eIdDates.length == 3 ? eIdDates[0]: "Cannot collect date of birth",
      mothersName: mothersName?? "Cannot collect mothers name", nidNumber: nidNumber ?? "Cannot collect NID Number",
    );
  }

  /// it will sort the dates
  static List<String> _sortDateList({required List<String> dates}) {
    List<DateTime> tempList = [];
    DateFormat format = DateFormat("dd MMM yyyy");
    for (int i = 0; i < dates.length; i++) {
      tempList.add(format.parse(dates[i]));
    }
    tempList.sort((a, b) => a.compareTo(b));
    dates.clear();
    for (int i = 0; i < tempList.length; i++) {
      dates.add(format.format(tempList[i]));
    }
    return dates;
  }

  /// it will sort the dates
  static bool _isDate({required String text}) {
    RegExp pattern = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    return pattern.hasMatch(text);
  }

  /// it will get the value of enName
  static String? _isEnName({required String text}) {
    return text.startsWith("Name:") ? text.split(":").last.trim() : null;
  }

  /// it will get the value of bnName
  static String? _isBnName({required String text}) {
    return text.startsWith("নাম:") ? text.split(":").last.trim() : null;
  }

  /// it will get the value of fathersName
  static String? _isFathersName({required String text}) {
    return text.startsWith("পিতা:") ? text.split(":").last.trim() : null;
  }

  /// it will get the value of fathersName
  static String? _isMothersName({required String text}) {
    return text.startsWith("মাতা:") ? text.split(":").last.trim() : null;
  }

  /// it will get the value of Nationality
  static String? _isNationality({required String text}) {
    return text.startsWith("Nationality:") ? text.split(":").last.trim() : null;
  }

  static String? _isNumberID({required String text}) {
    return text.startsWith("ID NO:") ? text.split(":").last.trim() : null;
  }

  /// it will get the value of Number ID
  // static bool _isNumberID({required String text}) {
  //   RegExp pattern = RegExp(r'^\d{3}-\d{4}-\d{7}-\d{1}$');
  //   return pattern.hasMatch(text);
  // }
}

/// this class is used to store data from package and display data on user screen

class EmirateIdModel {
  late String enName;
  late String bnName;
  late String fathersName;
  late String mothersName;
  String dateOfBirth;
  String nationality;
  String nidNumber;

  EmirateIdModel({
    required this.enName,
    required this.bnName,
    required this.fathersName,
    required this.mothersName,
    required this.dateOfBirth,
    required this.nationality,
    required this.nidNumber,
  });

  @override
  String toString() {
    var string = '';
    string += enName.isEmpty ? "" : 'Holder enName = $enName\n';
    string += bnName.isEmpty ? "" : 'Holder bnName = $bnName\n';
    string += fathersName.isEmpty ? "" : 'Holder fathersName = $fathersName\n';
    string += mothersName.isEmpty ? "" : 'Holder mothersName = $mothersName\n';
    string += dateOfBirth.isEmpty ? "" : 'Holder date of birth = $dateOfBirth\n';
    string += nationality.isEmpty ? "" : 'Nationality = $nationality\n';
    string += nidNumber.isEmpty ? "" : 'NID number = $nidNumber\n';
    return string;
  }
}