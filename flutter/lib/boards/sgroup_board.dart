import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart';
import 'package:material_tag_editor/tag_editor.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usdh/Widget/widget.dart';
import 'package:usdh/login/firebase_provider.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:date_format/date_format.dart';
import 'package:usdh/chat/home.dart';
import 'package:autocomplete_textfield/autocomplete_textfield.dart';
// import 'package:validators/validators.dart';
import 'package:usdh/function/chip.dart';

late SgroupWriteState pageState;
late SgroupListState pageState1;
late SgroupShowState pageState2;
late SgroupModifyState pageState3;

bool isAvailable(String time, int n1, int n2) {
  if (n1 >= n2) {
    return false;
  }
  String now = formatDate(DateTime.now(), [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss]);
  DateTime d1 = DateTime.parse(now);
  DateTime d2 = DateTime.parse(time);
  Duration diff = d1.difference(d2);
  if (diff.isNegative) {
    return true;
  } else {
    return false;
  }
}

bool isTomorrow(String time) {
  String now = formatDate(DateTime.now(), [HH, ':', nn, ':', ss]);
  print("마감 " + time);
  print("현재 " + now);
  if (time.compareTo(now) == -1) {
    print("내일");
    return true;
  } else {
    print("오늘");
    return false;
  }
}

/* ---------------------- Write Board (Sgroup) ---------------------- */

class SgroupWrite extends StatefulWidget {
  @override
  SgroupWriteState createState() {
    pageState = SgroupWriteState();
    return pageState;
  }
}

class SgroupWriteState extends State<SgroupWrite> {
  late FirebaseProvider fp;
  TextEditingController titleInput = TextEditingController();
  TextEditingController contentInput = TextEditingController();
  TextEditingController timeInput = TextEditingController();
  TextEditingController memberInput = TextEditingController();
  TextEditingController stuidInput = TextEditingController();
  TextEditingController subjectInput = TextEditingController();
  TextEditingController tagInput = TextEditingController();
  TextEditingController myintroInput = TextEditingController();
  FirebaseStorage storage = FirebaseStorage.instance;
  FirebaseFirestore fs = FirebaseFirestore.instance;
  List tagList = [];
  TimeOfDay _time = TimeOfDay.now();

  final _formKey = GlobalKey<FormState>();
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();
  DateTime selectedDate = DateTime.now();

  _onDelete(index) {
    setState(() {
      tagList.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    titleInput.dispose();
    contentInput.dispose();
    timeInput.dispose();
    memberInput.dispose();
    stuidInput.dispose();
    subjectInput.dispose();
    tagInput.dispose();
    myintroInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    fp = Provider.of<FirebaseProvider>(context);
    fp.setInfo();

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    void onTimeChanged(TimeOfDay newTime) {
      setState(() {
        _time = newTime;
        timeInput.text = _time.format(context);
      });
    }

    return Scaffold(
      appBar: CustomAppBar("글 작성", [
        IconButton(
            icon: Icon(
              Icons.check,
              color: Color(0xff639ee1),
            ),
            onPressed: () {
              FocusScope.of(context).requestFocus(new FocusNode());
              if (_formKey.currentState!.validate()) {
                uploadOnFS();
                Navigator.pop(context);
              }
            }
        )]),
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(width * 0.1, height * 0.03, width * 0.1, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      cSizedBox(height*0.01, 0),
                      Text("모집조건", style: TextStyle(fontFamily: "SCDream", color: Color(0xff639ee1), fontWeight: FontWeight.w600, fontSize: 15)),
                      cSizedBox(height*0.02, 0),
                      Wrap(
                        direction: Axis.vertical,
                        spacing: -8,
                        children: [
                          Wrap(
                            spacing: 15,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                alignment: Alignment(0.0, 0.0),
                                child: cond2Text("마감 날짜"),
                              ),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                ),
                                onPressed: () {
                                  Future<DateTime?> future = showDatePicker(
                                    context: context,
                                    initialDate: selectedDate,
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime(2025),
                                    builder: (BuildContext context, Widget? child) {
                                      return Theme(
                                        data: ThemeData.light(),
                                        child: child!,
                                      );
                                    },
                                  );
                                  future.then((date) {
                                    if (date == null) {
                                      print("날짜를 선택해주십시오.");
                                    } else {
                                      setState(() {
                                        selectedDate = date;
                                      });
                                    }
                                  });
                                },
                                child: condText(formatDate(selectedDate, [yyyy, '-', mm, '-', dd,]).toString()),
                              ),
                            ]
                          ),
                          Wrap(
                            spacing: 15,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Container(
                                width: 60,
                                alignment: Alignment(0.0, 0.0),
                                child: cond2Text("마감 시간"),
                              ),
                              GestureDetector(
                                  child: Container(width: width * 0.4,
                                      child: ccondField(timeInput, "마감 시간을 선택하세요.", "마감 시간은 필수 입력 사항입니다.")
                                  ),
                                  onTap: (){TimePicker(context, _time, onTimeChanged);}
                              )
                            ],
                          ),
                          condWrap("모집인원", memberInput, "인원을 입력하세요. (숫자 형태)", "인원은 필수 입력 사항입니다."),
                          condWrap("학번", stuidInput, "요구 학번 (ex 18~21, 상관없음)", "필수 입력 사항입니다."),
                          condWrap("주제", subjectInput, "주제를 입력하세요.", "주제는 필수 입력 사항입니다."),
                        ],
                      )
                  ],
                )),
              Divider(
                color: Color(0xffe9e9e9),
                thickness: 17,
              ),
              Padding(
                  padding: EdgeInsets.fromLTRB(40, 10, 40, 10),
                  child: Wrap(direction: Axis.vertical, spacing: -10, children: [
                    Container(
                        width: MediaQuery.of(context).size.width * 0.8,
                        child: TagEditor(
                          key: key,
                          controller: tagInput,
                          keyboardType: TextInputType.multiline,
                          length: tagList.length,
                          delimiters: [',', ' '],
                          hasAddButton: false,
                          resetTextOnSubmitted: true,
                          textStyle: TextStyle(fontFamily: "SCDream", color: Color(0xffa9aaaf), fontWeight: FontWeight.w500, fontSize: 11.5),
                          inputDecoration: InputDecoration(hintText: "스페이스바로 #태그 입력!", hintStyle: TextStyle(color: Color(0xffa9aaaf), fontSize: 11.5), border: InputBorder.none, focusedBorder: InputBorder.none),
                          onSubmitted: (outstandingValue) {
                            setState(() {
                              tagList.add(outstandingValue);
                            });
                          },
                          onTagChanged: (newValue) {
                            setState(() {
                              tagList.add("#" + newValue + " ");
                            });
                          },
                          tagBuilder: (context, index) => ChipState(
                            index: index,
                            label: tagList[index],
                            onDeleted: _onDelete,
                          ),
                        )),
                    Container(width: MediaQuery.of(context).size.width * 0.8, child: titleField(titleInput)),
                  ])),
                  Divider(
                    color: Color(0xffe9e9e9),
                    thickness: 2.5,
                  ),
                  Container(
                  padding: EdgeInsets.fromLTRB(40, 10, 40, 0),
                  child: TextFormField(
                      controller: contentInput,
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      style: TextStyle(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: "내용을 입력하세요.",
                        border: InputBorder.none,
                      ),
                      validator: (text) {
                        if (text == null || text.isEmpty) {
                          return "내용은 필수 입력 사항입니다.";
                        }
                        return null;
                      })),
              cSizedBox(350, 0)
            ],
          ),
        )));
  }

  void uploadOnFS() async {
    var myInfo = fp.getInfo();
    await fs.collection('sgroup_board').doc(myInfo['nick'] + myInfo['postcount'].toString()).set({
      'title': titleInput.text,
      'write_time': formatDate(DateTime.now(), [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss]),
      'writer': myInfo['nick'],
      'contents': contentInput.text,
      'time': formatDate(selectedDate, [yyyy, '-', mm, '-', dd]) + " " + _time.toString().substring(10, 15) + ":00",
      'currentMember': 1,
      'limitedMember': int.parse(memberInput.text),
      'stuid': stuidInput.text,
      'subject': subjectInput.text,
      'tagList': tagList,
      'views': 0,
    });
    await fs.collection('users').doc(myInfo['email']).collection('applicants').doc(myInfo['nick'] + myInfo['postcount'].toString()).set({
      'where': 'sgroup_board',
      'title': titleInput.text,
      'isFineForMembers': [],
      'messages': [],
      'members': [],
      'write_time' : formatDate(DateTime.now(), [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss]),
    });
    fp.updateIntInfo('postcount', 1);
  }
}

/* ---------------------- Board List (Sgroup) ---------------------- */

class SgroupList extends StatefulWidget {
  @override
  SgroupListState createState() {
    pageState1 = SgroupListState();
    return pageState1;
  }
}

class SgroupListState extends State<SgroupList> {
  Stream<QuerySnapshot> colstream = FirebaseFirestore.instance.collection('sgroup_board').orderBy("write_time", descending: true).snapshots();
  late FirebaseProvider fp;
  final _formKey = GlobalKey<FormState>();
  TextEditingController searchInput = TextEditingController();
  String search = "";
  bool status = false;
  String limit = "";

  @override
  void initState() {
    search = "제목";
    super.initState();
  }

  @override
  void dispose() {
    searchInput.dispose();
    super.dispose();
  }

  bool isToday(String time) {
    String now = formatDate(DateTime.now(), [yyyy, '-', mm, '-', dd]);
    if (time.split(" ")[0] == now) {
      return true;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    fp = Provider.of<FirebaseProvider>(context);
    fp.setInfo();
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: CustomAppBar("소모임", [
        //새로고침 기능
        IconButton(
          icon: Image.asset('assets/images/icon/iconrefresh.png', width: 18, height: 18),
          onPressed: () {
            setState(() {
              colstream = FirebaseFirestore.instance.collection('sgroup_board').orderBy("write_time", descending: true).snapshots();
            });
          },
        ),
        //검색 기능 팝업
        IconButton(
          icon: Image.asset('assets/images/icon/iconsearch.png', width: 20, height: 20),
          onPressed: () {
            showDialog(
                context: context,
                builder: (BuildContext con) {
                  return StatefulBuilder(builder: (con, setS) {
                    return Form(
                        key: _formKey,
                        child: AlertDialog(
                          title: Row(
                            children: [
                              Theme(
                                data: ThemeData(unselectedWidgetColor: Colors.black38),
                                child: Radio(
                                    value: "제목",
                                    activeColor: Colors.black38,
                                    groupValue: search,
                                    onChanged: (String? value) {
                                      setS(() {
                                        search = value!;
                                      });
                                    }),
                              ),
                              Text(
                                "제목 검색",
                                style: TextStyle(
                                  fontSize: 10,
                                ),
                              ),
                              Theme(
                                data: ThemeData(unselectedWidgetColor: Colors.black38),
                                child: Radio(
                                    value: "태그",
                                    activeColor: Colors.black38,
                                    groupValue: search,
                                    onChanged: (String? value) {
                                      setS(() {
                                        search = value!;
                                      });
                                    }),
                              ),
                              Text(
                                "태그 검색",
                                style: TextStyle(
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          content: TextFormField(
                              controller: searchInput,
                              decoration: (search == "제목") ? InputDecoration(hintText: "검색할 제목을 입력하세요.") : InputDecoration(hintText: "검색할 태그를 입력하세요."),
                              validator: (text) {
                                if (text == null || text.isEmpty) {
                                  return "검색어를 입력하지 않으셨습니다.";
                                }
                                return null;
                              }),
                          actions: <Widget>[
                            TextButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    if (search == "제목") {
                                      setState(() {
                                        colstream = FirebaseFirestore.instance.collection('sgroup_board').orderBy('title').startAt([searchInput.text]).endAt([searchInput.text + '\uf8ff']).snapshots();
                                      });
                                      searchInput.clear();
                                      Navigator.pop(con);
                                    } else {
                                      setState(() {
                                        colstream = FirebaseFirestore.instance.collection('sgroup_board').where('tagList', arrayContains: "#" + searchInput.text + " ").snapshots();
                                      });
                                      searchInput.clear();
                                      Navigator.pop(con);
                                    }
                                  }
                                },
                                child: Text("검색")),
                            TextButton(
                                onPressed: () {
                                  Navigator.pop(con);
                                  searchInput.clear();
                                },
                                child: Text("취소")),
                          ],
                        ));
                  });
                });
          },
        ),
        IconButton(
          icon: Image.asset('assets/images/icon/iconmessage.png', width: 19, height: 19),
          onPressed: () {
            var myInfo = fp.getInfo();
            Navigator.push(context, MaterialPageRoute(builder: (context) => HomeScreen(myId: myInfo['email'])));
          },
        ),
      ]),
      body: RefreshIndicator(
        //당겨서 새로고침
        onRefresh: () async {
          setState(() {
            colstream = FirebaseFirestore.instance.collection('sgroup_board').orderBy("write_time", descending: true).snapshots();
          });
        },
        child: StreamBuilder<QuerySnapshot>(
            stream: colstream,
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (!snapshot.hasData) {
                return CircularProgressIndicator();
              }
              return Column(children: [
                Container(
                    padding: EdgeInsets.fromLTRB(0, 10, 25, 5),
                    child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                      Container(
                        width: 15,
                        height: 15,
                        child: Transform.scale(
                          scale: 0.7,
                          child: Theme(
                            data: ThemeData(unselectedWidgetColor: Colors.indigo.shade300),
                            child: Checkbox(
                              value: status,
                              activeColor: Colors.indigo.shade300,
                              onChanged: (val) {
                                setState(() {
                                  status = val ?? false;
                                  if (status) {
                                    colstream = FirebaseFirestore.instance.collection('sgroup_board').where('time', isGreaterThan: formatDate(DateTime.now(), [yyyy, '-', mm, '-', dd, ' ', HH, ':', nn, ':', ss])).snapshots();
                                  } else {
                                    colstream = FirebaseFirestore.instance.collection('sgroup_board').orderBy("write_time", descending: true).snapshots();
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                      cSizedBox(5, 5),
                      Text(
                        "모집중만 보기",
                        style: TextStyle(fontFamily: "NSRound", fontWeight: FontWeight.w400, fontSize: 13, color: Colors.indigo.shade300),
                      ),
                    ])),
                // Container or Expanded or Flexible 사용
                Expanded(
                    // 아래 간격 두고 싶으면 Container, height 사용
                    //height: MediaQuery.of(context).size.height * 0.8,
                    child: MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  child: ListView.separated(
                      separatorBuilder: (context, index) => middleDivider(),
                      shrinkWrap: true,
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final DocumentSnapshot doc = snapshot.data!.docs[index];
                        String member = doc['currentMember'].toString() + '/' + doc['limitedMember'].toString();
                        String info = doc['write_time'].substring(5, 7) + "/" + doc['write_time'].substring(8, 10) + doc['write_time'].substring(10, 16);
                        String time = ' | ' + '마감 ' + doc['time'].substring(5, 7) + "/" + doc['time'].substring(8, 10) + doc['time'].substring(10, 16) + ' | ';
                        String writer = doc['writer'];
                        return Column(children: [
                          InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => SgroupShow(doc.id)));
                                FirebaseFirestore.instance.collection('sgroup_board').doc(doc.id).update({"views": doc["views"] + 1});
                              },
                              child: Container(
                                  margin: EdgeInsets.fromLTRB(width*0.07, height*0.018, 0, 0),
                                  child: Column(children: [
                                    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                                      cSizedBox(0, width*0.01),
                                      Container(
                                          width: width * 0.63,
                                          height: 13,
                                          child: ListView.builder(
                                              scrollDirection: Axis.horizontal,
                                              itemCount: doc['tagList'].length,
                                              itemBuilder: (context, index) {
                                                String tag = doc['tagList'][index].toString();
                                                return GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        colstream = FirebaseFirestore.instance.collection('sgroup_board').where('tagList', arrayContains: tag).snapshots();
                                                      });
                                                    },
                                                    child: smallText(tag, 12, Color(0xffa9aaaf)));
                                              })),
                                      cSizedBox(0, width*0.08),
                                      Container(
                                          width: width*0.2,
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              isAvailable(doc['time'], doc['currentMember'], doc['limitedMember'])
                                                  ? Image(
                                                image: AssetImage('assets/images/icon/iconminiperson.png'),
                                                height: 15,
                                                width: 15,
                                              )
                                                  : Image(
                                                image: AssetImage('assets/images/icon/iconminiperson2.png'),
                                                height: 15,
                                                width: 15,
                                              ),
                                              cSizedBox(20, width*0.02),
                                              Container(width: width*0.13, child: smallText(member, 13, Color(0xffa9aaaf)))
                                            ],
                                          ))
                                    ]),
                                    Row(children: [
                                      isAvailable(doc['time'], doc['currentMember'], doc['limitedMember']) ? statusText("모집중") : statusText("모집완료"),
                                      cSizedBox(0, 10),
                                      Container(
                                        width: width * 0.6,
                                        child: cond2Text(doc['title'].toString()),
                                      ),
                                      cSizedBox(35, 0),
                                    ]),
                                    Row(
                                      children: [
                                        cSizedBox(20, 5),
                                        smallText(info, 10, Color(0xffa9aaaf)),
                                        smallText(time, 10, Color(0xffa9aaaf)),
                                        smallText(writer, 10, Color(0xffa9aaaf)),
                                      ],
                                    ),
                                    cSizedBox(10, 0),
                                  ])))
                        ]);
                      }),
                )),
              ]);
            }),
      ),
      floatingActionButton: FloatingActionButton(
          backgroundColor: Color(0xff639ee1),
          child: Image(
            image: AssetImage('assets/images/icon/iconpencil.png'),
            height: 28,
            width: 28,
          ),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SgroupWrite()));
          }),
    );
  }
}

/* ---------------------- Show Board (Sgroup) ---------------------- */

class SgroupShow extends StatefulWidget {
  SgroupShow(this.id);
  final String id;

  @override
  SgroupShowState createState() {
    pageState2 = SgroupShowState();
    return pageState2;
  }
}

class SgroupShowState extends State<SgroupShow> {
  late FirebaseProvider fp;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final FirebaseFirestore fs = FirebaseFirestore.instance;
  TextEditingController commentInput = TextEditingController();

  SharedPreferences? prefs;
  bool alreadyLiked = false;
  bool status = false;

  final _formKey = GlobalKey<FormState>();
  TextEditingController msgInput = TextEditingController();
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    commentInput.dispose();
    msgInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    fp = Provider.of<FirebaseProvider>(context);
    fp.setInfo();

    return Scaffold(
        appBar: CustomAppBar("소모임", []),
        body: StreamBuilder(
            stream: fs.collection('sgroup_board').doc(widget.id).snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              fp.setInfo();
              final width = MediaQuery.of(context).size.width;
              final height = MediaQuery.of(context).size.height;

              if (snapshot.hasData && !snapshot.data!.exists) {
                return CircularProgressIndicator();
              } else if (snapshot.hasData) {
                String info = snapshot.data!['write_time'].substring(5, 7) + "/" + snapshot.data!['write_time'].substring(8, 10) + snapshot.data!['write_time'].substring(10, 16) + ' | ';
                String time = snapshot.data!['time'].substring(5, 7) + "/" + snapshot.data!['time'].substring(8, 10) + snapshot.data!['time'].substring(10, 16);
                String writer = snapshot.data!['writer'];

                return SingleChildScrollView(
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
                        child: Wrap(direction: Axis.vertical, spacing: 15, children: [
                          Container(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: tagText(snapshot.data!['tagList'].join('')),
                          ),
                          Container(width: MediaQuery.of(context).size.width * 0.8, child: titleText(snapshot.data!['title'])),
                          smallText("등록일 " + info + "마감 " + time + ' | ' + "작성자 " + writer, 11.5, Color(0xffa9aaaf))
                        ])),
                    Divider(
                      color: Color(0xffe9e9e9),
                      thickness: 15,
                    ),
                    Padding(
                        padding: EdgeInsets.fromLTRB(40, 20, 40, 20),
                        child: Wrap(
                          direction: Axis.vertical,
                          spacing: 15,
                          children: [
                            Text("모집조건", style: TextStyle(fontFamily: "SCDream", color: Color(0xff639ee1), fontWeight: FontWeight.w600, fontSize: 15)),
                            Padding(
                                padding: EdgeInsets.fromLTRB(7, 5, 20, 0),
                                child: Wrap(
                                  direction: Axis.vertical,
                                  spacing: 15,
                                  children: [
                                    cond2Wrap("모집기간", "~ " + time),
                                    cond2Wrap("모집인원", snapshot.data!['currentMember'].toString() + "/" + snapshot.data!['limitedMember'].toString()),
                                    cond2Wrap("학번", snapshot.data!['stuid']),
                                    cond2Wrap("주제", snapshot.data!['subject']),
                                  ],
                                ))
                          ],
                        )),
                    Divider(
                      color: Color(0xffe9e9e9),
                      thickness: 15,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(50, 30, 50, 30),
                      child: Text(snapshot.data!['contents'], style: TextStyle(fontSize: 14)),
                    ),
                    TextButton(
                      onPressed: () {
                        if (status == false) {
                          setState(() {
                            status = true;
                          });
                        } else {
                          setState(() {
                            status = false;
                          });
                        }
                      },
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(width*0.1, 20, 0, 20),
                        child: infoText("팀장 정보 V"),
                      ),
                    ),
                    FutureBuilder<QuerySnapshot>(
                        future: fs.collection('users').where('nick', isEqualTo: writer).get(),
                        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snap) {
                          if (snap.hasData) {
                            DocumentSnapshot doc = snap.data!.docs[0];
                            return Visibility(
                              visible: status,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      cSizedBox(0, width*0.12),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(60),
                                        child: Image.network(
                                          doc['photoUrl'],
                                          width: 50,
                                          height: 50,
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                      cSizedBox(10, 20),
                                      cond2Text(doc['nick'] + "(" + doc['num'].toString() + ")"),
                                    ],
                                  ),
                                  //포트폴리오 onoff표시
                                  (doc['coverletter'].length == 0)
                                    ? Container(
                                      margin: EdgeInsets.fromLTRB(0, 20, 0, 40),
                                      child: smallText("자기소개서를 작성하지 않으셨습니다.", 12, Colors.grey),
                                    )
                                    : Column(
                                      children: [
                                      Container(
                                        padding: EdgeInsets.fromLTRB(width * 0.1, height*0.04, width * 0.03, 0),
                                        child: inputNav2('assets/images/icon/iconme.png', "  자기소개"),
                                      ),
                                      Container(
                                        width: width * 0.67,
                                        height: height * 0.12,
                                        padding: EdgeInsets.fromLTRB(width * 0.05, height * 0.02, width * 0.05, height * 0.02),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 0.5,
                                            ),
                                            borderRadius: BorderRadius.circular(10)),
                                        child: SingleChildScrollView(
                                          child: (doc['coverletter'].length == 0) ? condText("작성 X") : info2Text(doc['coverletter'][0]),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.fromLTRB(width * 0.1, height*0.04, width * 0.03, 0),
                                        child: inputNav2('assets/images/icon/iconwin.png', "  경력"),
                                      ),
                                      Container(
                                        width: width * 0.67,
                                        height: height * 0.12,
                                        padding: EdgeInsets.fromLTRB(width * 0.05, height * 0.02, width * 0.05, height * 0.02),
                                        decoration: BoxDecoration(
                                            border: Border.all(
                                              color: Colors.grey,
                                              width: 0.5,
                                            ),
                                            borderRadius: BorderRadius.circular(10)),
                                        child: SingleChildScrollView(
                                          child: (doc['coverletter'].length == 0) ? condText("작성 X") : info2Text(doc['coverletter'][1]),
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.fromLTRB(width * 0.1, height*0.04, width * 0.03, 0),
                                        child: inputNav2('assets/images/icon/icontag.png', "  태그"),
                                      ),
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: (doc['coverletter_tag'].length == 0) ? tagText("태그없음") : tagText(doc['coverletter_tag'].join(', ')),
                                      ),
                                      cSizedBox(height*0.05, 0)
                                    ],
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return CircularProgressIndicator();
                          }
                        }),
                  ],
                  ));
              } else {
                return CircularProgressIndicator();
              }
            }),
        bottomNavigationBar: StreamBuilder(
            stream: fs.collection('sgroup_board').doc(widget.id).snapshots(),
            builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
              final width = MediaQuery.of(context).size.width;
              final height = MediaQuery.of(context).size.height;
              if (snapshot.hasData && !snapshot.data!.exists) {
                return CircularProgressIndicator();
              } else if (snapshot.hasData) {
                fp.setInfo();
                if (fp.getInfo()['nick'] == snapshot.data!['writer']) {
                  if (isAvailable(snapshot.data!['time'], snapshot.data!['currentMember'], snapshot.data!['limitedMember']))
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 삭제
                        Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xffcacaca),
                          ),
                          child: GestureDetector(
                            child: Align(alignment: Alignment.center, child: smallText("삭제", 14, Colors.white)),
                            onTap: () async {
                              Navigator.pop(context);
                              List<String> isFineForMemberNicks = [];
                              List<String> isFineForMemberIds = [];
                              await fs.collection('users').doc(fp.getInfo()['email']).collection('applicants').doc(snapshot.data!.id).get().then((DocumentSnapshot snap) {
                                if (snap.get('isFineForMembers').length != 0) {
                                  for (String iFFMember in snap.get('isFineForMembers')) {
                                    isFineForMemberNicks.add(iFFMember);
                                  }
                                } else {
                                  print(snapshot.data!['title'] + '에는 참가자가 없었습니다.');
                                }
                              });

                              if (isFineForMemberNicks.length != 0) {
                                for (String iFFmember in isFineForMemberNicks) {
                                  await fs.collection('users').where('nick', isEqualTo: iFFmember).get().then((QuerySnapshot snap) {
                                    isFineForMemberIds.add(snap.docs[0].get('email'));
                                  });
                                }
                              }
                              if (isFineForMemberIds.length != 0) {
                                for (String iFFMember in isFineForMemberIds) {
                                  await fs.collection('users').doc(iFFMember).collection('myApplication').doc(snapshot.data!.id).update({'where': 'deleted'});
                                }
                              }

                              await fs.collection('sgroup_board').doc(widget.id).delete();
                              await fs.collection('users').doc(fp.getInfo()['email']).collection('applicants').doc(snapshot.data!.id).delete();
                              fp.updateIntInfo('postcount', -1);
                            },
                          ),
                        ),
                        // 수정
                        Container(
                          width: MediaQuery.of(context).size.width * 0.5,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Color(0xff639ee1),
                          ),
                          child: GestureDetector(
                            child: Align(alignment: Alignment.center, child: smallText("수정", 14, Colors.white)),
                            onTap: () async {
                              var tmp;
                              await fs.collection('sgroup_board').doc(widget.id).get().then((snap) {
                                tmp = snap.data() as Map<String, dynamic>;
                              });
                              Navigator.push(context, MaterialPageRoute(builder: (context) => SgroupModify(widget.id, tmp)));
                              setState(() {});
                            },
                          ),
                        )
                    ],
                  );
                  else return Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Color(0xffcacaca),
                    ),
                    child: GestureDetector(
                      child: Align(alignment: Alignment.center, child: smallText("삭제", 14, Colors.white)),
                      onTap: () async {
                        Navigator.pop(context);
                        List<String> isFineForMemberNicks = [];
                        List<String> isFineForMemberIds = [];
                        await fs.collection('users').doc(fp.getInfo()['email']).collection('applicants').doc(snapshot.data!.id).get().then((DocumentSnapshot snap) {
                          if (snap.get('isFineForMembers').length != 0) {
                            for (String iFFMember in snap.get('isFineForMembers')) {
                              isFineForMemberNicks.add(iFFMember);
                            }
                          } else {
                            print(snapshot.data!['title'] + '에는 참가자가 없었습니다.');
                          }
                        });

                        if (isFineForMemberNicks.length != 0) {
                          for (String iFFmember in isFineForMemberNicks) {
                            await fs.collection('users').where('nick', isEqualTo: iFFmember).get().then((QuerySnapshot snap) {
                              isFineForMemberIds.add(snap.docs[0].get('email'));
                            });
                          }
                        }
                        if (isFineForMemberIds.length != 0) {
                          for (String iFFMember in isFineForMemberIds) {
                            await fs.collection('users').doc(iFFMember).collection('myApplication').doc(snapshot.data!.id).update({'where': 'deleted'});
                          }
                        }

                        await fs.collection('sgroup_board').doc(widget.id).delete();
                        await fs.collection('users').doc(fp.getInfo()['email']).collection('applicants').doc(snapshot.data!.id).delete();
                        fp.updateIntInfo('postcount', -1);
                      },
                    ),
                  );
                } else {
                  if (isAvailable(snapshot.data!['time'], snapshot.data!['currentMember'], snapshot.data!['limitedMember'])){
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xffcacaca),
                        ),
                        child: GestureDetector(
                          child: Align(alignment: Alignment.center, child: smallText("신청취소", 14, Colors.white)),
                          onTap: () async {
                            var myInfo = fp.getInfo();
                            String title = widget.id;
                            String hostId = '';
                            List<String> _myApplication = [];

                            await fs.collection('users').where('nick', isEqualTo: snapshot.data!['writer']).get().then((QuerySnapshot snap) {
                              DocumentSnapshot tmp = snap.docs[0];
                              hostId = tmp['email'];
                            });
                            await fs.collection('users').doc(myInfo['email']).collection('myApplication').get().then((QuerySnapshot snap) {
                              if (snap.docs.length != 0) {
                                for (DocumentSnapshot doc in snap.docs) {
                                  _myApplication.add(doc.id);
                                }
                              } else {
                                print('참가 신청 내역이 비어있습니다.');
                              }
                            });

                            if (!_myApplication.contains(title)) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              showMessage("참가 신청하지 않은 방입니다.");
                            } else {
                              List<dynamic> _messages = [];
                              List<dynamic> _isFineForMember = [];
                              await fs.collection('users').doc(hostId).collection('applicants').doc(widget.id).get().then((value) {
                                _messages = value['messages'];
                              });
                              await fs.collection('users').doc(hostId).collection('applicants').doc(widget.id).get().then((value) {
                                _isFineForMember = value['isFineForMembers'];
                              });
                              int _msgIndex = _isFineForMember.indexWhere((element) => element == myInfo['nick']);
                              if (_msgIndex >= 0) {
                                await fs.collection('users').doc(hostId).collection('applicants').doc(widget.id).update({
                                  'isFineForMembers': FieldValue.arrayRemove([myInfo['nick']]),
                                  'messages': FieldValue.arrayRemove([_messages[_msgIndex]])
                                });
                              }
                              await fs.collection('users').doc(myInfo['email']).collection('myApplication').doc(title).delete();
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              showMessage("참가 신청을 취소했습니다.");
                            }
                          },
                        ),
                      ),
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xff639ee1),
                        ),
                        child: GestureDetector(
                          child: Align(alignment: Alignment.center, child: smallText("참가신청", 14, Colors.white)),
                          onTap: () async {
                            var myInfo = fp.getInfo();
                            int _currentMember = snapshot.data!['currentMember'];
                            int _limitedMember = snapshot.data!['limitedMember'];
                            String title = widget.id;
                            String hostId = await fs.collection('users').where('nick', isEqualTo: snapshot.data!['writer']).get().then((QuerySnapshot snap) {
                              DocumentSnapshot tmp = snap.docs[0];
                              return tmp['email'];
                            });
                            List<String> _myApplication = [];

                            showDialog(
                              context: context,
                              barrierColor: null,
                              builder: (BuildContext con) {
                                return Form(
                                    key: _formKey,
                                    child: AlertDialog(
                                        elevation: 0.3,
                                        contentPadding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                                        backgroundColor: Colors.grey[200],
                                        content: Container(
                                          height: height * 0.32,
                                          width: width*0.8,
                                          padding: EdgeInsets.fromLTRB(0, height*0.05, 0, 0),
                                          child: Column(
                                            children: [
                                              Container(width: width*0.65, child: smallText("팀장한테 보낼 메세지를 입력하세요\n(20자 이내)", 16, Color(0xB2000000))),
                                              Container(width: width*0.65,
                                                padding: EdgeInsets.fromLTRB(0, height*0.02, 0, 0),
                                                child: TextFormField(
                                                  controller: msgInput,
                                                  keyboardType: TextInputType.multiline,
                                                  inputFormatters: [
                                                    LengthLimitingTextInputFormatter(20),
                                                  ],
                                                  style: TextStyle(fontFamily: "SCDream", color: Colors.black87, fontWeight: FontWeight.w500, fontSize: 14),
                                                  decoration: InputDecoration(
                                                      focusedBorder: UnderlineInputBorder(
                                                        borderSide: BorderSide(color: Colors.black87, width: 1.5),
                                                      ),
                                                      hintText: "메세지를 입력하세요.", hintStyle: TextStyle(fontFamily: "SCDream", color: Colors.black45, fontWeight: FontWeight.w500, fontSize: 14)
                                                  ),
                                                  validator: (text) {
                                                    if (text == null || text.isEmpty) {
                                                      return "메세지를 입력하지 않으셨습니다.";
                                                    }
                                                    return null;
                                                  }
                                                ),
                                              ),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.end,
                                                children: [
                                                  TextButton(
                                                    onPressed: () async {
                                                      if (_formKey.currentState!.validate()) {
                                                        await fs.collection('users').doc(myInfo['email']).collection('myApplication').get().then((QuerySnapshot snap) {
                                                          if (snap.docs.length != 0) {
                                                            for (DocumentSnapshot doc in snap.docs) {
                                                              _myApplication.add(doc.id);
                                                            }
                                                          } else {
                                                            print('myApplication 콜렉션이 비어있읍니다.');
                                                          }
                                                        });

                                                        if (_myApplication.contains(title)) {
                                                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                          showMessage("이미 신청한 방입니다.");
                                                        } else if (_currentMember >= _limitedMember) {
                                                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                          showMessage("방이 모두 차있습니다.");
                                                        } else {
                                                          // 방장에게 날리는 메세지
                                                          await fs.collection('users').doc(hostId).collection('applicants').doc(widget.id).update({
                                                            'isFineForMembers': FieldValue.arrayUnion([myInfo['nick']]),
                                                            'messages': FieldValue.arrayUnion([msgInput.text]),
                                                          });
                                                          // 내 정보에 신청 정보를 기록
                                                          await fs.collection('users').doc(myInfo['email']).collection('myApplication').doc(title).set({'where': "sgroup_board", 'isRejected': false, 'isJoined': false});
                                                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                                          showMessage("참가 신청을 보냈습니다.");
                                                        }
                                                        Navigator.pop(con);
                                                      }
                                                    },
                                                    child: info2Text("확인")
                                                  ),
                                                  TextButton(onPressed: (){
                                                    Navigator.pop(con);
                                                  },
                                                      child: info2Text("취소")
                                                  ),
                                                  cSizedBox(0, width*0.05)
                                                ],
                                              )
                                            ],
                                          )
                                        )
                                    ));
                                });
                            },
                          ),
                        ),
                      ],
                    );
                  }
                  else return SizedBox.shrink();
                }
              } else
                return CircularProgressIndicator();
            }));
  }

  showMessage(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.blue[200],
      duration: Duration(seconds: 10),
      content: Text(msg),
      action: SnackBarAction(
        label: "확인",
        textColor: Colors.black,
        onPressed: () {},
      ),
    ));
  }
}

/* ---------------------- Modify Board (Sgroup) ---------------------- */

class SgroupModify extends StatefulWidget {
  SgroupModify(this.id, this.datas);
  final String id;
  final Map<String, dynamic> datas;
  @override
  State<StatefulWidget> createState() {
    pageState3 = SgroupModifyState();
    return pageState3;
  }
}

class SgroupModifyState extends State<SgroupModify> {
  late FirebaseProvider fp;
  final FirebaseFirestore fs = FirebaseFirestore.instance;
  late TextEditingController titleInput;
  late TextEditingController contentInput;
  late TextEditingController timeInput;
  late TextEditingController memberInput;
  late TextEditingController stuidInput;
  late TextEditingController subjectInput;
  late TextEditingController tagInput;
  List<dynamic> tagList = [];
  late DateTime selectedDate;
  TimeOfDay _time = TimeOfDay.now();

  final _formKey = GlobalKey<FormState>();
  GlobalKey<AutoCompleteTextFieldState<String>> key = new GlobalKey();

  _onDelete(index) {
    setState(() {
      tagList.removeAt(index);
    });
  }

  @override
  void initState() {
    setState(() {
      tagList = widget.datas['tagList'];
      selectedDate = DateTime.parse(widget.datas['time']);
      titleInput = TextEditingController(text: widget.datas['title']);
      timeInput = TextEditingController(text: formatDate(selectedDate, [HH, ':', nn]));
      contentInput = TextEditingController(text: widget.datas['contents']);
      memberInput = TextEditingController(text: widget.datas['limitedMember'].toString());
      stuidInput = TextEditingController(text: widget.datas['stuid']);
      subjectInput = TextEditingController(text: widget.datas['subject']);
      tagInput = TextEditingController();
    });
    super.initState();
  }

  @override
  void dispose() {
    titleInput.dispose();
    contentInput.dispose();
    timeInput.dispose();
    memberInput.dispose();
    stuidInput.dispose();
    subjectInput.dispose();
    tagInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    fp = Provider.of<FirebaseProvider>(context);
    fp.setInfo();

    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    void onTimeChanged(TimeOfDay newTime) {
      setState(() {
        _time = newTime;
        timeInput.text = _time.format(context);
      });
    }

    return Scaffold(
        appBar: CustomAppBar("글 수정", [
          IconButton(
              icon: Icon(
                Icons.check,
                color: Color(0xff639ee1),
              ),
              onPressed: () {
                FocusScope.of(context).requestFocus(new FocusNode());
                if (_formKey.currentState!.validate()) {
                  updateOnFS();
                  Navigator.pop(context);
                }
              }
          )]),
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
            child: StreamBuilder(
                stream: fs.collection('sgroup_board').doc(widget.id).snapshots(),
                builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                  if (snapshot.hasData && !snapshot.data!.exists) return CircularProgressIndicator();
                  if (snapshot.hasData) {
                    return Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                                padding: EdgeInsets.fromLTRB(width * 0.1, height * 0.03, width * 0.1, 20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    cSizedBox(height*0.01, 0),
                                    Text("모집조건", style: TextStyle(fontFamily: "SCDream", color: Color(0xff639ee1), fontWeight: FontWeight.w600, fontSize: 15)),
                                    cSizedBox(height*0.02, 0),
                                    Wrap(
                                      direction: Axis.vertical,
                                      spacing: -8,
                                      children: [
                                        Wrap(
                                            spacing: 15,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              Container(
                                                width: 60,
                                                alignment: Alignment(0.0, 0.0),
                                                child: cond2Text("마감 날짜"),
                                              ),
                                              TextButton(
                                                style: TextButton.styleFrom(
                                                  padding: EdgeInsets.zero,
                                                ),
                                                onPressed: () {
                                                  Future<DateTime?> future = showDatePicker(
                                                    context: context,
                                                    initialDate: selectedDate,
                                                    firstDate: DateTime.now(),
                                                    lastDate: DateTime(2025),
                                                    builder: (BuildContext context, Widget? child) {
                                                      return Theme(
                                                        data: ThemeData.light(),
                                                        child: child!,
                                                      );
                                                    },
                                                  );
                                                  future.then((date) {
                                                    if (date == null) {
                                                      print("날짜를 선택해주십시오.");
                                                    } else {
                                                      setState(() {
                                                        selectedDate = date;
                                                      });
                                                    }
                                                  });
                                                },
                                                child: condText(formatDate(selectedDate, [yyyy, '-', mm, '-', dd,]).toString()),
                                              ),
                                            ]
                                        ),
                                        Wrap(
                                          spacing: 15,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Container(
                                              width: 60,
                                              alignment: Alignment(0.0, 0.0),
                                              child: cond2Text("마감 시간"),
                                            ),
                                            GestureDetector(
                                                child: Container(width: width * 0.4,
                                                    child: ccondField(timeInput, "마감 시간을 선택하세요.", "마감 시간은 필수 입력 사항입니다.")
                                                ),
                                                onTap: (){TimePicker(context, _time, onTimeChanged);}
                                            )
                                          ],
                                        ),
                                        condWrap("모집인원", memberInput, "인원을 입력하세요. (숫자 형태)", "인원은 필수 입력 사항입니다."),
                                        condWrap("학번", stuidInput, "요구 학번 (ex 18~21, 상관없음)", "필수 입력 사항입니다."),
                                        condWrap("주제", subjectInput, "주제를 입력하세요.", "주제는 필수 입력 사항입니다."),
                                      ],
                                    )
                                  ],
                                )),
                            Divider(
                              color: Color(0xffe9e9e9),
                              thickness: 17,
                            ),
                            Padding(
                                padding: EdgeInsets.fromLTRB(40, 10, 40, 10),
                                child: Wrap(direction: Axis.vertical, spacing: -10, children: [
                                  Container(
                                      width: MediaQuery.of(context).size.width * 0.8,
                                      child: TagEditor(
                                        key: key,
                                        controller: tagInput,
                                        keyboardType: TextInputType.multiline,
                                        length: tagList.length,
                                        delimiters: [',', ' '],
                                        hasAddButton: false,
                                        resetTextOnSubmitted: true,
                                        textStyle: TextStyle(fontFamily: "SCDream", color: Color(0xffa9aaaf), fontWeight: FontWeight.w500, fontSize: 11.5),
                                        inputDecoration:
                                            InputDecoration(hintText: "스페이스바로 #태그 입력!", hintStyle: TextStyle(color: Color(0xffa9aaaf), fontSize: 11.5), border: InputBorder.none, focusedBorder: InputBorder.none),
                                        onSubmitted: (outstandingValue) {
                                          setState(() {
                                            tagList.add(outstandingValue);
                                          });
                                        },
                                        onTagChanged: (newValue) {
                                          setState(() {
                                            tagList.add("#" + newValue + " ");
                                          });
                                        },
                                        tagBuilder: (context, index) => ChipState(
                                          index: index,
                                          label: tagList[index],
                                          onDeleted: _onDelete,
                                        ),
                                      )),
                                  Container(width: MediaQuery.of(context).size.width * 0.8, child: titleField(titleInput)),
                                ])),
                            Divider(
                              color: Color(0xffe9e9e9),
                              thickness: 2.5,
                            ),
                            Container(
                                padding: EdgeInsets.fromLTRB(40, 10, 40, 0),
                                child: TextFormField(
                                    controller: contentInput,
                                    keyboardType: TextInputType.multiline,
                                    maxLines: null,
                                    style: TextStyle(fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: "내용을 입력하세요.",
                                      border: InputBorder.none,
                                    ),
                                    validator: (text) {
                                      if (text == null || text.isEmpty) {
                                        return "내용은 필수 입력 사항입니다.";
                                      }
                                      return null;
                                    })),
                            cSizedBox(350, 0)
                          ],
                        ));
                  }
                  return CircularProgressIndicator();
                })));
  }

  void updateOnFS() async {
    var myInfo = fp.getInfo();
    await fs.collection('sgroup_board').doc(widget.id).update({
      'title': titleInput.text,
      'contents': contentInput.text,
      'time': formatDate(selectedDate, [yyyy, '-', mm, '-', dd]) + " " + _time.toString().substring(10, 15) + ":00",
      'limitedMember': int.parse(memberInput.text),
      'stuid': stuidInput.text,
      'subject': subjectInput.text,
      'tagList': tagList,
      'members': [],
    });
    await fs.collection('users').doc(myInfo['email']).collection('applicants').doc(widget.id).update({
      'where': 'sgroup_board',
      'title': titleInput.text,
      'members': [],
    });
  }
}
