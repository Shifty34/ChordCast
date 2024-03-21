import 'dart:io';
import 'dart:js_util';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show ByteData, Uint8List, kIsWeb;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hand_signature/signature.dart';
import 'package:pdf_render/pdf_render_widgets.dart';
import 'package:searchable_listview/searchable_listview.dart';
import 'package:three/domain/entities/entities.dart';
import 'package:three/fade_atom.dart';

import 'core/utils/firebase_utils.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

class PdfUploadScreen extends StatefulWidget {
  const PdfUploadScreen({super.key});

  @override
  _PdfUploadScreenState createState() => _PdfUploadScreenState();
}

class _PdfUploadScreenState extends State<PdfUploadScreen> {
  // File data in bytes
  Uint8List? fileBytes;
  String? fileCloud;

  HandSignatureControl control = HandSignatureControl(
    threshold: 0.01,
    smoothRatio: 0.65,
    velocityRange: 2.0,
  );

  //
  List<List<dynamic>> fields = [];
  // Show file data info panel
  bool showMusicMenu = false;

  // Show document list panel
  bool showListMenu = false;

  // Cloud id - visible document
  String currentDocumentId = '';

  // Cloud path - document (when upload)
  String resultUploadFile = '';

  // Text fields controllers
  late TextEditingController titleController;
  late TextEditingController composerController;
  late TextEditingController genresController;
  late TextEditingController tagsController;
  late TextEditingController labelsController;
  late TextEditingController referenceController;
  late TextEditingController timeController;
  late TextEditingController keyController;

  // Coords new annotation
  double xNewAnnotation = 0;
  double yNewAnnotation = 0;

  // Show new text annotation
  bool showNewTextAnnotation = false;

  // Show new draw annotation
  bool showNewDrawAnnotation = false;

  // Enable annotations
  bool enableDrawAnnotation = false;
  bool enableTextAnnotation = false;

  late TextEditingController newTextController;

  String titlePage = '';
  String composerPage = '';

  bool enableAnnotations = false;

  int currentPage = 1;
  FilePickerResult? result;
  bool withTwoPages = false;

  // Is update or is new document
  bool isUpdate = false;

  int stars = 0;
  int difficulty = 0;

  List<TextAnnotationEntity> annotations = [];

  Future<Uint8List> _openFileExplorerWeb() async {
    // File picker
    result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        currentPage = 1;
        fileCloud = null;
        fileBytes = result!.files.first.bytes!;

        isUpdate = false;

        titlePage = '';
        composerPage = '';
        annotations.clear();
      });

      fillTitleWithFilename();

      showMenu();
    }

    return Uint8List.fromList([]);
  }

  // PDF Controller
  PdfViewerController? controller;
  PdfViewerController? controller2;

  // init a state
  @override
  void initState() {
    super.initState();

    titleController = TextEditingController();
    composerController = TextEditingController();

    genresController = TextEditingController();
    tagsController = TextEditingController();
    labelsController = TextEditingController();
    referenceController = TextEditingController();
    timeController = TextEditingController();
    keyController = TextEditingController();

    newTextController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text(
              'Chordcast',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w200,
              ),
            ),
            SizedBox(
              width: 16,
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  // Show or hide menur
                  showListMenu = false;

                  showMusicMenu = !showMusicMenu;
                });
              },
              splashRadius: 24,
              splashColor: Colors.white,
              icon: Icon(
                CupertinoIcons.music_note,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {});
              },
              splashRadius: 24,
              splashColor: Colors.white,
              icon: Icon(
                CupertinoIcons.book,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {});
              },
              splashRadius: 24,
              splashColor: Colors.white,
              icon: Icon(
                Icons.menu,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  showMusicMenu = false;

                  // Show or hide menu
                  showListMenu = !showListMenu;
                });
              },
              splashRadius: 24,
              splashColor: Colors.white,
              icon: Icon(
                CupertinoIcons.cloud,
                color: Colors.black,
              ),
            ),
            Spacer(),
            Center(
              child: Container(
                width: 400,
                padding: EdgeInsets.symmetric(
                  vertical: 4,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.white10,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.black87,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.settings,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            titlePage.isNotEmpty ? '$composerPage' : '',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: Colors.black54,
                            ),
                          ),
                          Text(
                            titlePage.isNotEmpty ? '$titlePage' : '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        color: Colors.black87,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.more_horiz_outlined,
                          size: 18,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Spacer(),
            IconButton(
              onPressed: () {
                onTapSignatureButton();
              },
              splashRadius: 24,
              splashColor: Colors.white,
              icon: Icon(
                CupertinoIcons.signature,
                color: enableAnnotations ? Colors.white : Colors.black,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {});
              },
              splashRadius: 24,
              splashColor: Colors.white,
              icon: Icon(
                CupertinoIcons.search,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {});
              },
              splashRadius: 24,
              splashColor: Colors.white,
              icon: Icon(
                CupertinoIcons.metronome,
                color: Colors.black,
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {});
              },
              splashRadius: 24,
              splashColor: Colors.white,
              icon: Icon(
                CupertinoIcons.bag,
                color: Colors.black,
              ),
            ),
            SizedBox(
              width: 16,
            ),
            ElevatedButton(
              style: ButtonStyle(
                backgroundColor:
                    MaterialStateProperty.all(Color.fromARGB(255, 0, 0, 0)),
              ),
              onPressed: _openFileExplorerWeb,
              child: const Text('Pick PDF file'),
            )
          ],
        ),
      ),
      body: Center(
        child: Stack(
          children: [
                Builder(builder: (context) {
                  if (fileCloud != null) {
                    // Load from cloud
                    return Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: FadeAtom(
                              child: FutureBuilder<File>(
                                future: DefaultCacheManager()
                                    .getSingleFile(fileCloud!),
                                builder: (context, snapshot) => snapshot.hasData
                                    ? PdfDocumentLoader.openFile(
                                        snapshot.data!.path,
                                        pageNumber: currentPage,
                                        pageBuilder: (context, textureBuilder,
                                                pageSize) =>
                                            FadeAtom(
                                                child: textureBuilder(
                                          backgroundFill: true,
                                          placeholderBuilder: (size, status) {
                                            return FadeAtom(
                                              withMovement: false,
                                              child: Container(
                                                color: Colors.white,
                                                child: SizedBox(
                                                  height: 500,
                                                  width: 400,
                                                ),
                                              ),
                                            );
                                          },
                                        )),
                                      )
                                    : Container(/* placeholder */),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 16,
                          ),
                          if (withTwoPages)
                            Flexible(
                              child: FadeAtom(
                                child: FutureBuilder<File>(
                                  future: DefaultCacheManager()
                                      .getSingleFile(fileCloud!),
                                  builder: (context, snapshot) => snapshot
                                          .hasData
                                      ? PdfDocumentLoader.openFile(
                                          snapshot.data!.path,
                                          pageNumber: currentPage + 1,
                                          pageBuilder: (context, textureBuilder,
                                                  pageSize) =>
                                              FadeAtom(
                                                  child: textureBuilder(
                                            backgroundFill: true,
                                            placeholderBuilder: (size, status) {
                                              return FadeAtom(
                                                withMovement: false,
                                                child: Container(
                                                  color: Colors.white,
                                                  child: SizedBox(
                                                    height: 500,
                                                    width: 400,
                                                  ),
                                                ),
                                              );
                                            },
                                          )),
                                        )
                                      : Container(/* placeholder */),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  } else if (fileBytes == null) {
                    return Center(
                        child: FadeAtom(child: Text('Select file, please')));
                  } else {
                    return GestureDetector(
                      onHorizontalDragEnd: (DragEndDetails details) {
                        // Swipe feature

                        // Calculate the horizontal distance of the swipe
                        double dx = details.velocity.pixelsPerSecond.dx;

                        if (dx > 0) {
                          // Swipe to the right
                          previousPage();
                        } else {
                          // Swipe to the left
                          nextPage();
                        }
                      },
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Flexible(
                              child: FadeAtom(
                                child: PdfDocumentLoader.openData(
                                  fileBytes!,
                                  pageNumber: currentPage,
                                  pageBuilder:
                                      (context, textureBuilder, pageSize) =>
                                          FadeAtom(
                                    child: textureBuilder(
                                      backgroundFill: true,
                                      placeholderBuilder: (size, status) {
                                        return FadeAtom(
                                          withMovement: false,
                                          child: Container(
                                            color: Colors.white,
                                            child: SizedBox(
                                              height: 500,
                                              width: 400,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 16,
                            ),
                            if (withTwoPages)
                              Flexible(
                                child: FadeAtom(
                                  child: PdfDocumentLoader.openData(
                                    fileBytes!,
                                    pageNumber: currentPage + 1,
                                    pageBuilder:
                                        (context, textureBuilder, pageSize) =>
                                            FadeAtom(
                                                child: textureBuilder(
                                      backgroundFill: true,
                                      placeholderBuilder: (size, status) {
                                        return FadeAtom(
                                          withMovement: false,
                                          child: Container(
                                            color: Colors.white,
                                            child: SizedBox(
                                              height: 500,
                                              width: 400,
                                            ),
                                          ),
                                        );
                                      },
                                    )),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                }),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () {
                      previousPage();
                    },
                    child: Container(
                      height: double.maxFinite,
                      width: MediaQuery.of(context).size.width / 6,
                      color: Color.fromRGBO(0, 0, 0, 0),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      nextPage();
                    },
                    child: Container(
                      height: double.maxFinite,
                      width: MediaQuery.of(context).size.width / 6,
                      color: Color.fromRGBO(0, 0, 0, 0),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 40),
                    child: Visibility(
                      visible: showMusicMenu,
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          width: MediaQuery.of(context).size.width / 2.3,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(243, 243, 247, 1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 1,
                              color: Color.fromRGBO(199, 199, 204, 1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(
                                    234, 234, 236, 1), //color of shadow
                                spreadRadius: 5, //spread radius
                                blurRadius: 7, // blur radius
                                offset:
                                    Offset(0, 2), // changes position of shadow
                                //first paramerter of offset is left-right
                                //second parameter is top to down
                              ),
                              //you can set more BoxShadow() here
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Container(
                                  height: 60,
                                  child: Stack(
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: GestureDetector(
                                          onTap: () {
                                            closeMenu();
                                          },
                                          child: Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.chevron_back,
                                                color:
                                                    CupertinoColors.systemBlue,
                                                size: 30.0,
                                              ),
                                              Text(
                                                'Back',
                                                style: TextStyle(
                                                  color: CupertinoColors
                                                      .systemBlue,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          '${titleController.text} - ${composerController.text}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Flexible(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 50,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              'Title',
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                          color: Colors.transparent,
                                        ),
                                        Container(
                                          height: 30,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              'Composers',
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                          color: Colors.transparent,
                                        ),
                                        Container(
                                          height: 50,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              'Genres',
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                          color: Colors.transparent,
                                        ),
                                        Container(
                                          height: 30,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              'Tags',
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                          color: Colors.transparent,
                                        ),
                                        Container(
                                          height: 50,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              'Labels',
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                          color: Colors.transparent,
                                        ),
                                        Container(
                                          height: 30,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              'Reference',
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                          color: Colors.transparent,
                                        ),
                                        Container(
                                          height: 50,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              'Rating',
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                          color: Colors.transparent,
                                        ),
                                        Container(
                                          height: 30,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              'Difficulty',
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                          color: Colors.transparent,
                                        ),
                                        Container(
                                          height: 50,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              'Time',
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                          color: Colors.transparent,
                                        ),
                                        Container(
                                          height: 30,
                                          child: Align(
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              'Key',
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                          color: Colors.transparent,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Flexible(
                                    flex: 4,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Container(
                                          height: 40,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: TextField(
                                              controller: titleController,
                                              cursorColor: Colors.blueAccent,
                                              decoration: InputDecoration(
                                                fillColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                filled: true,
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(
                                                  left: 15,
                                                  bottom: 11,
                                                  top: 11,
                                                  right: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                        ),
                                        Container(
                                          height: 40,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: TextField(
                                              controller: composerController,
                                              cursorColor: Colors.blueAccent,
                                              decoration: InputDecoration(
                                                fillColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                filled: true,
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(
                                                  left: 15,
                                                  bottom: 11,
                                                  top: 11,
                                                  right: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                        ),
                                        Container(
                                          height: 40,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: TextField(
                                              controller: genresController,
                                              cursorColor: Colors.blueAccent,
                                              decoration: InputDecoration(
                                                fillColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                filled: true,
                                                hintText: 'No Genres',
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(
                                                  left: 15,
                                                  bottom: 11,
                                                  top: 11,
                                                  right: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                        ),
                                        Container(
                                          height: 40,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: TextField(
                                              controller: tagsController,
                                              cursorColor: Colors.blueAccent,
                                              decoration: InputDecoration(
                                                fillColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                hintText: 'No Tags',
                                                filled: true,
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(
                                                  left: 15,
                                                  bottom: 11,
                                                  top: 11,
                                                  right: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                        ),
                                        Container(
                                          height: 40,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: TextField(
                                              controller: labelsController,
                                              cursorColor: Colors.blueAccent,
                                              decoration: InputDecoration(
                                                fillColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                filled: true,
                                                hintText: 'No Labels',
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(
                                                  left: 15,
                                                  bottom: 11,
                                                  top: 11,
                                                  right: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                        ),
                                        Container(
                                          height: 40,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: TextField(
                                              controller: referenceController,
                                              cursorColor: Colors.blueAccent,
                                              decoration: InputDecoration(
                                                fillColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                filled: true,
                                                border: InputBorder.none,
                                                hintText: 'No reference',
                                                contentPadding: EdgeInsets.only(
                                                  left: 15,
                                                  bottom: 11,
                                                  top: 11,
                                                  right: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          height: 40,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: Row(
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    if (stars == 1) {
                                                      setState(() {
                                                        stars = 0;
                                                      });
                                                      return;
                                                    }
                                                    setState(() {
                                                      stars = 1;
                                                    });
                                                  },
                                                  child: stars >= 1
                                                      ? Icon(
                                                          CupertinoIcons
                                                              .star_fill,
                                                          color: Colors.amber,
                                                        )
                                                      : Icon(
                                                          CupertinoIcons.star,
                                                        ),
                                                ),
                                                SizedBox(
                                                  width: 2,
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      stars = 2;
                                                    });
                                                  },
                                                  child: stars >= 2
                                                      ? Icon(
                                                          CupertinoIcons
                                                              .star_fill,
                                                          color: Colors.amber,
                                                        )
                                                      : Icon(
                                                          CupertinoIcons.star,
                                                        ),
                                                ),
                                                SizedBox(
                                                  width: 2,
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      stars = 3;
                                                    });
                                                  },
                                                  child: stars >= 3
                                                      ? Icon(
                                                          CupertinoIcons
                                                              .star_fill,
                                                          color: Colors.amber,
                                                        )
                                                      : Icon(
                                                          CupertinoIcons.star,
                                                        ),
                                                ),
                                                SizedBox(
                                                  width: 2,
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      stars = 4;
                                                    });
                                                  },
                                                  child: stars >= 4
                                                      ? Icon(
                                                          CupertinoIcons
                                                              .star_fill,
                                                          color: Colors.amber,
                                                        )
                                                      : Icon(
                                                          CupertinoIcons.star,
                                                        ),
                                                ),
                                                SizedBox(
                                                  width: 2,
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      stars = 5;
                                                    });
                                                  },
                                                  child: stars >= 5
                                                      ? Icon(
                                                          CupertinoIcons
                                                              .star_fill,
                                                          color: Colors.amber,
                                                        )
                                                      : Icon(
                                                          CupertinoIcons.star,
                                                        ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                        ),
                                        Container(
                                          height: 40,
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: Row(
                                              children: [
                                                InkWell(
                                                  onTap: () {
                                                    if (difficulty == 1) {
                                                      setState(() {
                                                        difficulty = 0;
                                                      });
                                                      return;
                                                    }
                                                    setState(() {
                                                      difficulty = 1;
                                                    });
                                                  },
                                                  child: Icon(
                                                    CupertinoIcons.circle_fill,
                                                    color: (difficulty == 3)
                                                        ? Colors.red
                                                        : (difficulty == 2)
                                                            ? Colors.amber
                                                            : (difficulty == 1)
                                                                ? Colors.green
                                                                : Colors.grey
                                                                    .shade300,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 2,
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      difficulty = 2;
                                                    });
                                                  },
                                                  child: Icon(
                                                    CupertinoIcons.circle_fill,
                                                    color: (difficulty == 3)
                                                        ? Colors.red
                                                        : (difficulty == 2)
                                                            ? Colors.amber
                                                            : Colors
                                                                .grey.shade300,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 2,
                                                ),
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      difficulty = 3;
                                                    });
                                                  },
                                                  child: Icon(
                                                    CupertinoIcons.circle_fill,
                                                    color: (difficulty == 3)
                                                        ? Colors.red
                                                        : Colors.grey.shade300,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                        ),
                                        Container(
                                          height: 40,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: TextField(
                                              controller: timeController,
                                              cursorColor: Colors.blueAccent,
                                              decoration: InputDecoration(
                                                fillColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                filled: true,
                                                hintText: '0:00',
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(
                                                  left: 15,
                                                  bottom: 11,
                                                  top: 11,
                                                  right: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Divider(
                                          endIndent: 0,
                                        ),
                                        Container(
                                          height: 40,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: TextField(
                                              controller: keyController,
                                              cursorColor: Colors.blueAccent,
                                              decoration: InputDecoration(
                                                fillColor: Colors.transparent,
                                                hoverColor: Colors.transparent,
                                                filled: true,
                                                hintText: '-',
                                                border: InputBorder.none,
                                                contentPadding: EdgeInsets.only(
                                                  left: 15,
                                                  bottom: 11,
                                                  top: 11,
                                                  right: 15,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 24,
                              ),
                              Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    border: Border(
                                      top: BorderSide(
                                        color: Theme.of(context).dividerColor,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CupertinoButton.filled(
                                          onPressed: () {
                                            swapValues();
                                          },
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: const Text('Swap title'),
                                        ),
                                        SizedBox(
                                          width: 16,
                                        ),
                                        CupertinoButton.filled(
                                          onPressed: () {
                                            setState(() {
                                              withTwoPages = !withTwoPages;
                                            });
                                          },
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(withTwoPages
                                              ? 'View one page'
                                              : 'View two pages'),
                                        ),
                                        SizedBox(
                                          width: 16,
                                        ),
                                        CupertinoButton.filled(
                                          onPressed: () {
                                            onDoneMenu();
                                          },
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16),
                                          child: Text(
                                            isUpdate ? 'Update' : 'Done',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: fileBytes != null,
                                child: Container(
                                  padding: EdgeInsets.all(20),
                                  color: Colors.black,
                                  child: AspectRatio(
                                    aspectRatio: 1.8,
                                    child: Row(
                                      children: [
                                        Flexible(
                                          child: Container(
                                            child: Builder(builder: (context) {
                                              if (fileCloud != null) {
                                                // Load from cloud
                                                return Center(
                                                  child: FutureBuilder<File>(
                                                    future:
                                                        DefaultCacheManager()
                                                            .getSingleFile(
                                                                fileCloud!),
                                                    builder: (context,
                                                            snapshot) =>
                                                        snapshot.hasData
                                                            ? PdfDocumentLoader
                                                                .openFile(
                                                                snapshot
                                                                    .data!.path,
                                                                pageNumber:
                                                                    currentPage,
                                                                pageBuilder: (context,
                                                                        textureBuilder,
                                                                        pageSize) =>
                                                                    FadeAtom(
                                                                        child:
                                                                            textureBuilder(
                                                                  backgroundFill:
                                                                      true,
                                                                  placeholderBuilder:
                                                                      (size,
                                                                          status) {
                                                                    return FadeAtom(
                                                                      withMovement:
                                                                          false,
                                                                      child:
                                                                          Container(
                                                                        color: Colors
                                                                            .white,
                                                                        child:
                                                                            SizedBox(
                                                                          height:
                                                                              500,
                                                                          width:
                                                                              400,
                                                                        ),
                                                                      ),
                                                                    );
                                                                  },
                                                                )),
                                                              )
                                                            : Container(
                                                                /* placeholder */),
                                                  ),
                                                );
                                              } else if (fileBytes == null) {
                                                return Center(
                                                  child: FadeAtom(
                                                    child: Text(
                                                      'Select file, please',
                                                    ),
                                                  ),
                                                );
                                              } else {
                                                return Center(
                                                    child: PdfDocumentLoader
                                                        .openData(
                                                  fileBytes!,
                                                  pageNumber: currentPage,
                                                  pageBuilder: (context,
                                                          textureBuilder,
                                                          pageSize) =>
                                                      textureBuilder(
                                                    backgroundFill: true,
                                                    placeholderBuilder:
                                                        (size, status) {
                                                      return Container(
                                                        color: Colors.black,
                                                        child: SizedBox(
                                                          height: 500,
                                                          width: 400,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ));
                                              }
                                            }),
                                          ),
                                        ),
                                        Flexible(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Page $currentPage',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                '${result?.names[0]}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Text(
                                                formatBytes(
                                                    result?.files[0].size ?? 0),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              Spacer(),
                                              Text(
                                                '$titlePage',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              SizedBox(
                                                height: 8,
                                              ),
                                              Text(
                                                '$composerPage',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w100,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 40),
                    child: Visibility(
                      visible: showListMenu,
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: Container(
                          clipBehavior: Clip.hardEdge,
                          width: MediaQuery.of(context).size.width / 2.3,
                          decoration: BoxDecoration(
                            color: Color.fromRGBO(243, 243, 247, 1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              width: 1,
                              color: Color.fromRGBO(199, 199, 204, 1),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Color.fromRGBO(
                                    234, 234, 236, 1), //color of shadow
                                spreadRadius: 5, //spread radius
                                blurRadius: 7, // blur radius
                                offset:
                                    Offset(0, 2), // changes position of shadow
                                //first paramerter of offset is left-right
                                //second parameter is top to down
                              ),
                              //you can set more BoxShadow() here
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: Container(
                                  height: 60,
                                  child: Stack(
                                    children: [
                                      Align(
                                        alignment: Alignment.centerLeft,
                                        child: GestureDetector(
                                          onTap: () {
                                            closeMenuList();
                                          },
                                          child: Row(
                                            children: [
                                              Icon(
                                                CupertinoIcons.chevron_back,
                                                color:
                                                    CupertinoColors.systemBlue,
                                                size: 30.0,
                                              ),
                                              Text(
                                                'Back',
                                                style: TextStyle(
                                                  color: CupertinoColors
                                                      .systemBlue,
                                                  fontSize: 20,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Text(
                                          'Cloud',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Divider(),
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: FutureBuilder(
                                  future: getData(),
                                  builder: (BuildContext context,
                                      AsyncSnapshot<List<DocumentEntity>?>
                                          snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                    if (snapshot.hasError) {
                                      return Container();
                                    }

                                    return SizedBox(
                                      height: (snapshot.data!.length * 50) + 82,
                                      child: SearchableList<DocumentEntity>(
                                        initialList: snapshot.data!,
                                        spaceBetweenSearchAndList: 4,
                                        builder: (List<DocumentEntity> user,
                                                index, item) =>
                                            InkWell(
                                          onTap: () {
                                            loadDataToForm(
                                              documentEntity: item,
                                            );
                                            getFileFromUrl(
                                              resourceURL: item.path ?? '',
                                            );
                                          },
                                          child: Container(
                                            height: 50,
                                            key: Key(index.toString()),
                                            decoration: BoxDecoration(
                                              border: Border(
                                                top: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                Flexible(
                                                    flex: 1,
                                                    child: Text(
                                                      item.title.toString(),
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    )),
                                                SizedBox(
                                                  width: 8,
                                                ),
                                                Text('-'),
                                                SizedBox(
                                                  width: 8,
                                                ),
                                                Flexible(
                                                  flex: 1,
                                                  child: Text(
                                                    (item.composers?.join(", "))
                                                        .toString(),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        filter: (value) =>
                                            snapshot.data!.where((element) {
                                          return (element.title ?? '')
                                                  .toLowerCase()
                                                  .contains(value) ||
                                              (element.composers ?? [])
                                                  .join('')
                                                  .toLowerCase()
                                                  .contains(value);
                                        }).toList(),
                                        emptyWidget: const Text('Empty'),
                                        inputDecoration: InputDecoration(
                                          fillColor: Colors.white,
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.grey.shade200,
                                              width: 1.0,
                                            ),
                                            borderRadius:
                                                BorderRadius.circular(4.0),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ] +
              renderAnnotations() +
              [
                if (showNewDrawAnnotation)
                  Positioned(
                    top: yNewAnnotation,
                    left: xNewAnnotation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 200,
                          height: 100,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.blue),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: HandSignature(
                            width: 0.1,
                            maxWidth: 1,
                            control: control,
                            color: Colors.black,
                            type: SignatureDrawType.shape,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CupertinoButton.filled(
                                onPressed: () {
                                  newDrawAnnotation();
                                },
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: const Text('Create'),
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              CupertinoButton(
                                onPressed: () {
                                  removeDrawAnnotation();
                                },
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (showNewTextAnnotation)
                  Positioned(
                    top: yNewAnnotation,
                    left: xNewAnnotation,
                    child: SizedBox(
                      width: 500,
                      height: 600,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: newTextController,
                            maxLines: null, // Permite múltiples líneas de texto
                            autofocus: true,
                            decoration: InputDecoration(
                              labelText: 'Write annotation',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CupertinoButton.filled(
                                  onPressed: () {
                                    newTextAnnotation();
                                  },
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: const Text('Create'),
                                ),
                                SizedBox(
                                  width: 8,
                                ),
                                CupertinoButton(
                                  onPressed: () {
                                    removeTextAnnotation();
                                  },
                                  padding: EdgeInsets.symmetric(horizontal: 16),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (enableAnnotations &&
                    ((enableTextAnnotation && !showNewTextAnnotation) ||
                        (enableDrawAnnotation && !showNewDrawAnnotation)))
                  GestureDetector(
                    onTapDown: (TapDownDetails details) {
                      onTapDocument(context, details);
                    },
                  ),
                if (enableAnnotations)
                  Container(
                    height: 60,
                    color: Colors.grey.shade200,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 16,
                        ),
                        CupertinoButton.filled(
                          onPressed: () {
                            onTapBarTextAnnotation();
                          },
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: const Text('New Text Annotation'),
                        ),
                        SizedBox(
                          width: 16,
                        ),
                        CupertinoButton.filled(
                          onPressed: () {
                            onTapBarDrawAnnotation();
                          },
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: const Text('New Draw Annotation'),
                        ),
                      ],
                    ),
                  ),
              ],
        ),
      ),
    );
  }

  String formatBytes(int bytes) {
    // Convert bytes to Megabytes / gigabytes ...

    var marker = 1000; // Change to 1000 if required
    var decimal = 3; // Change as required
    var kiloBytes = marker; // One Kilobyte is 1024 bytes
    var megaBytes = marker * marker; // One MB is 1024 KB
    var gigaBytes = marker * marker * marker; // One GB is 1024 MB
    var teraBytes = marker * marker * marker * marker; // One TB is 1024 GB

    // return bytes if less than a KB
    if (bytes < kiloBytes) {
      return "${bytes.toStringAsFixed(2)} Bytes";
    } else if (bytes < megaBytes) {
      return "${(bytes / kiloBytes).toStringAsFixed(2)} KB";
    } else if (bytes < gigaBytes) {
      return "${(bytes / megaBytes).toStringAsFixed(2)} MB";
    } else {
      return "${(bytes / gigaBytes).toStringAsFixed(2)} GB";
    }
  }

  void previousPage() {
    // Change to next page
    if (currentPage > 1) {
      var newPage = currentPage - 1;
      controller?.goToPage(pageNumber: newPage);
      setState(() {
        currentPage = newPage;
      });
    }
  }

  void nextPage() {
    // Change to previous page
    try {
      var newPage = currentPage + 1;
      controller?.goToPage(pageNumber: newPage);

      setState(() {
        currentPage = newPage;
      });
    } catch (e) {
      print('Error $e');
    }
  }

  void closeMenu() {
    // Close data menu
    setState(() {
      showMusicMenu = false;
    });
  }

  void showMenu() {
    setState(() {
      // Close other menu
      showListMenu = false;

      showMusicMenu = true;
    });
  }

  void closeMenuList() {
    // Close document list menu
    setState(() {
      showListMenu = false;
    });
  }

  void showMenuList() {
    setState(() {
      // Close other menu
      showMusicMenu = false;

      showListMenu = true;
    });
  }

  void saveTitle() {
    setState(() {
      titlePage = titleController.text;
      composerPage = composerController.text;
    });
  }

  void onDoneMenu() async {
    // When tap done button in menu
    saveTitle();

    uploadDatabase();

    closeMenu();
  }

  void swapValues() {
    var helper = composerController.text;
    setState(() {
      composerController.text = titleController.text;
      titleController.text = helper;
    });
  }

  void fillTitleWithFilename() {
    if (result != null && result?.names[0] != null) {
      if (result?.names[0]?.contains('-') ?? false) {
        var filename = result?.names[0]?.split('-');
        if (filename != null) {
          setState(() {
            titleController.text = filename.first.trim();
            composerController.text =
                filename.last.trim().replaceAll('.pdf', '');
          });
        }
      }
    }
  }

  void uploadDatabase() async {
    if (fileBytes != null) {
      // Upload to storage

      if (!isUpdate) {
        DocumentEntity documentEntityHelper = DocumentEntity(
          title: titleController.text,
          composers: composerController.text
              .split(',')
              .map((element) => element.trim())
              .toList(),
          genres: genresController.text
              .split(',')
              .map((element) => element.trim())
              .toList(),
          tags: tagsController.text
              .split(',')
              .map((element) => element.trim())
              .toList(),
          labels: labelsController.text
              .split(',')
              .map((element) => element.trim())
              .toList(),
          reference: referenceController.text,
          rating: stars == 0 ? null : stars,
          difficulty: difficulty == 0 ? null : difficulty,
          time: timeController.text,
          key: keyController.text,
          path: '',
        );

        resultUploadFile =
            await saveFileStorage(fileBytes!, documentEntityHelper) ?? '';
        //setState(() {});
      }

      if (resultUploadFile.isNotEmpty) {
        // Save in firestore

        DocumentEntity documentEntity = DocumentEntity(
          title: titleController.text,
          composers: composerController.text
              .split(',')
              .map((element) => element.trim())
              .toList(),
          genres: genresController.text
              .split(',')
              .map((element) => element.trim())
              .toList(),
          tags: tagsController.text
              .split(',')
              .map((element) => element.trim())
              .toList(),
          labels: labelsController.text
              .split(',')
              .map((element) => element.trim())
              .toList(),
          reference: referenceController.text,
          rating: stars == 0 ? null : stars,
          difficulty: difficulty == 0 ? null : difficulty,
          time: timeController.text,
          key: keyController.text,
          path: resultUploadFile,
        );

        if (isUpdate) {
          // Update

          updateData(
            documentId: currentDocumentId,
            document: documentEntity,
          );
        } else {
          // First upload
          var responseId = await uploadData(
            document: documentEntity,
          );

          if (responseId != null) {
            setState(() {
              // Set document id
              currentDocumentId = responseId;

              isUpdate = true;
            });
          }
        }
      }
    }
  }

  Future<void> getFileFromUrl({required String resourceURL}) async {
    // Create a storage reference from our app
    final storageRef = FirebaseStorage.instance.ref();

    // Create a reference with an initial file path and name
    final pathReference = storageRef.child(resourceURL);

    try {
      // Data for "files/document" is returned, use this as needed.
      final Uint8List? data = await pathReference.getData();

      setState(() {
        currentPage = 1;

        fileBytes = data;
      });

      getAnnotationsFromCloud();
    } on FirebaseException catch (e) {
      // Handle any errors.
    }
  }

  void loadDataToForm({required DocumentEntity documentEntity}) {
    setState(() {
      titleController.text = documentEntity.title ?? '';

      composerController.text = documentEntity.composers
              ?.join(', ')
              .replaceAll('[', '')
              .replaceAll(']', '') ??
          '';

      genresController.text = documentEntity.genres
              ?.join(', ')
              .replaceAll('[', '')
              .replaceAll(']', '') ??
          '';

      tagsController.text = documentEntity.tags
              ?.join(', ')
              .replaceAll('[', '')
              .replaceAll(']', '') ??
          '';

      labelsController.text = documentEntity.labels
              ?.join(', ')
              .replaceAll('[', '')
              .replaceAll(']', '') ??
          '';

      referenceController.text = documentEntity.reference ?? '';
      stars = documentEntity.rating ?? 0;
      difficulty = documentEntity.difficulty ?? 0;
      timeController.text = documentEntity.time ?? '';
      keyController.text = documentEntity.key ?? '';

      currentDocumentId = documentEntity.id;

      resultUploadFile = documentEntity.path ?? '';
      isUpdate = true;

      titlePage = titleController.text;
      composerPage = composerController.text;

      showListMenu = false;
    });
  }

  void onTapSignatureButton() {
    // Add annotations

    // Check if exists document

    if (fileBytes == null) {
      return;
    }

    setState(() {
      enableAnnotations = !enableAnnotations;
      showNewTextAnnotation = false;
      showNewDrawAnnotation = false;
    });
  }

  // Gesturedetector on tap document
  void onTapDocument(BuildContext context, TapDownDetails details) {
    // if (!enableAnnotations) {
    //   return;
    // }

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final localPosition = renderBox.globalToLocal(details.globalPosition);
    final x = localPosition.dx;
    final y = localPosition.dy;

    // Coords tap, then save
    setState(() {
      xNewAnnotation = x - 10;
      yNewAnnotation = y - 80;

      if (enableDrawAnnotation) {
        showNewDrawAnnotation = true;
      } else if (enableTextAnnotation) {
        showNewTextAnnotation = true;
      }
    });
  }

  void newTextAnnotation() {
    // Tap create annotation
    var annotation = TextAnnotationEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: newTextController.text,
      documentId: currentDocumentId,
      positionX: xNewAnnotation + 12,
      positionY: yNewAnnotation + 12,
      page: currentPage,
    );

    setState(() {
      annotations.add(annotation);
      removeTextAnnotation();
    });

    // Save text annotation in DB
    saveTextAnnotationDB(
      annotation: annotation,
    );
  }

  void removeTextAnnotation() {
    setState(() {
      showNewTextAnnotation = false;
      newTextController.clear();
    });
  }

  List<Widget> renderAnnotations() {
    // Filter only the current page (pages if view has two pages)... annotations
    var annotationsHelper = annotations.where((element) {
      if (withTwoPages) {
        if (element.page == currentPage || element.page == currentPage + 1) {
          return true;
        }
      } else {
        if (element.page == currentPage) {
          return true;
        }
      }
      return false;
    });

    return annotationsHelper.map((annotation) {
      var deleteWidget = (enableAnnotations)
          ? Container()
          : InkWell(
              onTap: () {
                deleteAnnotation(annotation: annotation);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(
                    10,
                  ),
                ),
                child: Icon(
                  Icons.clear,
                  size: 18,
                ),
              ),
            );

      // If annotation is Text, then render a Text widget
      if (annotation.type == 'text') {
        return Positioned(
          top: annotation.positionY,
          left: annotation.positionX,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!enableAnnotations) deleteWidget,
              SizedBox(
                width: 500,
                height: 600,
                child: Text(
                  annotation.text,
                ),
              ),
            ],
          ),
        );
      }

      // If annotation is DRAW, then render a SVG box
      return Positioned(
        top: annotation.positionY,
        left: annotation.positionX,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            deleteWidget,
            SvgPicture.string(
              annotation.text,
              fit: BoxFit.scaleDown,
            ),
          ],
        ),
      );
    }).toList();
  }

  void saveTextAnnotationDB({
    required TextAnnotationEntity annotation,
  }) {
    // Save text annotation in db
    uploadTextAnnotationData(
      annotation: annotation,
    );
  }

  Future<void> getAnnotationsFromCloud() async {
    // Make query

    var annotationsFromDB = await getAnnotationsDB(
      documentId: currentDocumentId,
    );

    annotations.clear();
    annotations.addAll(annotationsFromDB);

    setState(() {});
  }

  void onTapBarTextAnnotation() {
    setState(() {
      enableTextAnnotation = true;

      enableDrawAnnotation = false;
      showNewDrawAnnotation = false;
      showNewTextAnnotation = false;
    });
  }

  void onTapBarDrawAnnotation() {
    setState(() {
      enableDrawAnnotation = true;

      enableTextAnnotation = false;
      showNewDrawAnnotation = false;
      showNewTextAnnotation = false;
    });
  }

  void newDrawAnnotation() {
    var svg = control.toSvg(
          width: 200,
          height: 100,
          fit: false,
        ) ??
        '';

    // Tap create annotation
    var annotation = TextAnnotationEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: svg,
      documentId: currentDocumentId,
      positionX: xNewAnnotation + 12,
      positionY: yNewAnnotation + 12,
      page: currentPage,
      type: 'draw',
    );

    setState(() {
      annotations.add(annotation);
      removeDrawAnnotation();
    });

    //Save draw annotation in DB
    saveTextAnnotationDB(
      annotation: annotation,
    );
  }

  void removeDrawAnnotation() {
    // Remove new draw
    setState(() {
      showNewDrawAnnotation = false;
      control.clear();
    });
  }

  void deleteAnnotation({required TextAnnotationEntity annotation}) {
    // Delete from current list
    annotations.removeWhere((e) => e.id == annotation.id);

    // Delete in DB
    deleteAnnotationDB(annotation: annotation);

    setState(() {});
  }
}
