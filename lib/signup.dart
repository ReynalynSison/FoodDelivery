import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hive/hive.dart';
import 'main.dart';
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final box = Hive.box("database");
  bool hidePassword = true;
  TextEditingController _username = TextEditingController();
  TextEditingController _password = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Create A local Account", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w200),),
          SizedBox(height: 10,),
          CupertinoTextField(
            controller: _username,
            placeholder: "_Username",
            prefix: Icon(CupertinoIcons.person),
            padding: EdgeInsets.all(10),
          ),
          SizedBox(height: 3,),
          CupertinoTextField(
            controller: _password,
            placeholder: "Password",
            prefix: Icon(CupertinoIcons.padlock),
            padding: EdgeInsets.all(10),
            obscureText: hidePassword,
            suffix: CupertinoButton(
                padding: EdgeInsets.zero,
                child: Icon(hidePassword  ?  CupertinoIcons.eye : CupertinoIcons.eye_slash), onPressed: (){
              setState(() {
                hidePassword = !hidePassword;
              });
            }),
          ),

          Center(
            child: Column(
              children: [
                CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: Text('Sign up'), onPressed: (){
                  setState(() {
                    box.put("username", _username.text.trim());
                    box.put("password", _password.text.trim());
                    box.put("biometrics", false);
                    _password.text = "";
                    Navigator.push(context, CupertinoPageRoute(builder: (context)=> LoginPage()));
                  });
                }),

              ],
            ),
          )
        ],
      ),
    ));();
  }
}