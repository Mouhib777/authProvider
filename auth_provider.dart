import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:iheb_thouabtia1/screens/HomeScreen.dart';
import 'package:iheb_thouabtia1/services/user_services.dart';

class AuthProvider with ChangeNotifier {
  FirebaseAuth auth = FirebaseAuth.instance;
  late String smsOtp;
  late String verificationId;
  String error = '';
  UserServices _userServices = UserServices();
  Future<void> verifyPhone(BuildContext context, String number) async {
    verificationCompleted:
    (PhoneAuthCredential credential) async {
      await auth.signInWithCredential(credential);
    };

    //

    final PhoneVerificationFailed verificationFailed =
        (FirebaseAuthException e) {
      print(e.code);
    };

    //

    Future<void> Function(String verId, int resendToken) smsOtpsend =
        (String verId, int resendToken) async {
      verificationId = verId;

      smsOtpDialog(context, number);
    };

    await {
      auth.verifyPhoneNumber(
        phoneNumber: '+49$number',
        verificationCompleted: (PhoneAuthCredential Credential) async {
          await FirebaseAuth.instance
              .signInWithCredential(Credential)
              .then((value) async {
            if (value.user != null) {
              print('user loged in');
            }
          });
        },
        verificationFailed: (FirebaseAuthException e) {},
        codeSent: (String verificationId, int? resendToken) {},
        codeAutoRetrievalTimeout: (String verificationId) {},
      )
    };
  }

  Future<void> smsOtpDialog(BuildContext context, String number) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Column(
              children: [
                Text('verification code'),
                SizedBox(
                  height: 6,
                ),
                Text(
                  'Enter 6 digit OTP received as SMS',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            content: Container(
              height: 85,
              child: TextField(
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                maxLength: 6,
                onChanged: ((value) {
                  this.smsOtp = value;
                }),
              ),
            ),
            actions: [
              FlatButton(
                onPressed: () async {
                  try {
                    AuthCredential phoneAuthCredential =
                        PhoneAuthProvider.credential(
                            verificationId: verificationId, smsCode: smsOtp);

                    final User? user =
                        (await auth.signInWithCredential(phoneAuthCredential))
                            .user;

                    // create user data in firestore after registre
                    _createUser(id: user!.uid, number: user.phoneNumber);
                    // return to home after login

                    if (user != null) {
                      Navigator.of(context).pop();

                      // don't come back to welcome screen
                      Navigator.of(context).pushReplacement(MaterialPageRoute(
                          builder: (context) => HomeScreen()));
                    } else {
                      print('Login FAILED');
                    }
                  } catch (e) {
                    this.error = 'invalid OTP';
                    notifyListeners();
                    print(e.toString());
                    Navigator.of(context).pop();
                  }
                },
                child: Text('DONE'),
              )
            ],
          );
        });
  }

  void _createUser({required String id, required String? number}) {
    _userServices.createUser({
      'id': id,
      'number': number,
    });
  }
}
