import 'package:flutter/material.dart';
import 'firebase_provider.dart';
import 'package:provider/provider.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:cloud_firestore/cloud_firestore.dart';

late SignUpPageState pageState;

class SignUpPage extends StatefulWidget {
  @override
  SignUpPageState createState() {
    pageState = SignUpPageState();
    return pageState;
  }
}

class SignUpPageState extends State<SignUpPage> {
  TextEditingController emailInput = TextEditingController();
  TextEditingController pwdInput = TextEditingController();
  TextEditingController nameInput = TextEditingController();
  TextEditingController repwdInput = TextEditingController();

  FirebaseFirestore fs = FirebaseFirestore.instance; // 파이어베이스 db 인스턴스 생성

  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  late FirebaseProvider fp;

  String gender = "";
  bool terms1 = false;
  bool terms2 = false;
  bool terms3 = false;
  bool terms4 = false;

  @override
  void dispose() {
    emailInput.dispose();
    pwdInput.dispose();
    nameInput.dispose();
    repwdInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    fp = Provider.of<FirebaseProvider>(context);

    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(title: Text("계정 생성 페이지")),
        body: ListView(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20, top: 10),
              child: Column(
                children: <Widget>[
                  Container(
                    height: 50,
                    decoration: BoxDecoration(color: Colors.amber),
                    child: Center(
                      child: Text(
                        "계정 생성",
                        style: TextStyle(
                            color: Colors.blueGrey,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // 입력 부분((추가예정))
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber, width: 1),
                    ),
                    child: Column(
                      children: <Widget>[
                        TextField(
                          controller: emailInput,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.mail),
                            hintText: "웹메일(학교 이메일)",
                          ),
                        ),
                        TextField(
                          controller: pwdInput,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock),
                            hintText: "비밀번호",
                          ),
                          obscureText: true,
                        ),
                        TextField(
                          controller: repwdInput,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock),
                            hintText: "비밀번호 확인",
                          ),
                          obscureText: true,
                        ),
                        TextField(
                          controller: nameInput,
                          decoration: InputDecoration(
                              prefixIcon: Icon(Icons.arrow_forward),
                              hintText: "이름(실명입력)"),
                        ),
                        Row(
                          children: [
                            Radio(
                                value: "여자",
                                groupValue: gender,
                                onChanged: (String? value) {
                                  setState(() {
                                    gender = value!;
                                  });
                                }),
                            Text("여자"),
                            Radio(
                                value: "남자",
                                groupValue: gender,
                                onChanged: (String? value) {
                                  setState(() {
                                    gender = value!;
                                  });
                                }),
                            Text("남자"),
                          ],
                        ),
                        ListTile(
                          title: Text("서비스 이용 약관 동의 (필수)"),
                          leading: Checkbox(
                              value: terms1,
                              onChanged: (bool? value) {
                                setState(() {
                                  terms1 = value!;
                                });
                              }),
                        ),
                        ListTile(
                          title: Text("개인 정보 수집 및 이용 동의 (필수)"),
                          leading: Checkbox(
                              value: terms2,
                              onChanged: (bool? value) {
                                setState(() {
                                  terms2 = value!;
                                });
                              }),
                        ),
                        ListTile(
                          title: Text("위치 정보 이용 약관 동의 (선택)"),
                          leading: Checkbox(
                              value: terms3,
                              onChanged: (bool? value) {
                                setState(() {
                                  terms3 = value!;
                                });
                              }),
                        ),
                        ListTile(
                          title: Text("알림 수신 동의 (선택)"),
                          leading: Checkbox(
                              value: terms4,
                              onChanged: (bool? value) {
                                setState(() {
                                  terms4 = value!;
                                });
                              }),
                        ),
                      ].map((c) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 10),
                          child: c,
                        );
                      }).toList(),
                    ),
                  )
                ],
              ),
            ),

            // 생성 버튼
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: Colors.indigo[300],
                ),
                child: Text(
                  "가입",
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  FocusScope.of(context)
                      .requestFocus(new FocusNode()); // 키보드 감춤
                  _signUp();
                },
              ),
            ),
          ],
        ));
  }

  void _signUp() async {
    if (pwdInput.text != repwdInput.text) {
      fp.setMessage("not-equal");
      showMessage();
      return;
    }

    if (!(terms1 && terms2)) {
      fp.setMessage("not-agree");
      showMessage();
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: Duration(seconds: 10),
      content: Row(
        children: <Widget>[CircularProgressIndicator(), Text("   계정생성 중...")],
      ),
    ));
    bool result = await fp.signUp(emailInput.text, pwdInput.text);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    if (result) {
      print(nameInput.text);
      print(emailInput.text);
      Navigator.pop(context);
      fs.collection('users').doc(emailInput.text).set({
        'name': nameInput.text,
        'gender': gender,
        'email': emailInput.text,
        'postcount': 0,
        'piccount': 0,
        // 추가- 이걸 회원가입에 넣으면 될듯
        'aboutMe': '한 줄 자기소개', // 이건 없어도 됨
        'nickname': '사용할 닉네임',
        'photoUrl': '프로필 사진'
      });
    } else {
      showMessage();
    }
  }

  showMessage() {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: Colors.red[400],
      duration: Duration(seconds: 10),
      content: Text(fp.getMessage()),
      action: SnackBarAction(
        label: "확인",
        textColor: Colors.white,
        onPressed: () {},
      ),
    ));
  }
}
