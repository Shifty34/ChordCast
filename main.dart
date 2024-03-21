import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:three/pdf_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() {
  initFirebase();

  runApp(const MyApp());
}

Future<void> initFirebase() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Get the Firebase Authentication service instance
  final FirebaseAuth auth = FirebaseAuth.instance;
  try {
    // Sign in anonymously
    UserCredential userCredential = await auth.signInAnonymously();

    if (userCredential.user != null && userCredential.user is User) {
      User user = userCredential.user!;

      // Check if the user is signed in anonymously
      if (user.isAnonymous) {
        // TODO
      }
    }
  } catch (e) {
    //TODO:
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const PdfUploadScreen(),
    );
  }
}
