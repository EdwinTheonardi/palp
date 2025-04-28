import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    return const FirebaseOptions(
      apiKey: 'AIzaSyA8aSXgLkH_PVoF0',
      appId: '1:607824099473:android:40115bf7db3b57daea6730',
      messagingSenderId: '607824099473',
      projectId: 'palpnote',
      storageBucket: 'palpnote.firebasestorage.app',
    );
  }
}