import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const moods = [
  'Happy',
  'Sad',
  'Calm',
  'Anxious',
  'Excited',
  'Tired',
  'Stressed',
  'Angry'
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary App',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFFF4A261),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFF7F0),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF4A261),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFFFFFE8D6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 3,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFFF4A261),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(fontSize: 16),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          return const DiaryPage();
        }
        return const WelcomePage();
      },
    );
  }
}

class NewEntryPage extends StatefulWidget {
  const NewEntryPage({super.key});

  @override
  State<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedMood = moods.first;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('entries')
        .add({
          'email': user.email ?? '',
          'date': Timestamp.fromDate(_selectedDate),
          'title': title,
          'mood': _selectedMood,
          'content': content,
          'createdAt': FieldValue.serverTimestamp(),
        });
  //      if (context.mounted) {
          Navigator.pop(context);
  //      }
      }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Entry')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('New Entry', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              title: Text('Date: ${_selectedDate.toLocal()}'.split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: const Color(0xFFFFE8D6),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedMood,
              items: moods
                .map((mood) => DropdownMenuItem(
                  value: mood,
                  child: Text(mood),
                  ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedMood = value);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Mood',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 6,
              decoration: const InputDecoration(labelText: 'Content'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveEntry,
              child: const Text('Save Entry'),
            ),
          ],
        ),
      ),
    );
  }
}

class EntryDetailPage extends StatelessWidget {
  final DiaryEntry entry;

  const EntryDetailPage({super.key, required this.entry});
  Future<void> _deleteEntry(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('entries')
        .doc(entry.id)
        .delete();
//    if (context.mounted) {
      Navigator.pop(context);
  //  }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(entry.title),
          actions: [
            IconButton(
              onPressed: () => _deleteEntry(context),
                icon: const Icon(Icons.delete),
            ),
          ],
        ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text(entry.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Date: ${entry.date.toLocal()}'.split(' ')[0]),
            const SizedBox(height: 8),
            Text('Mood: ${entry.mood}'),               
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(entry.content),
          ],
        ),
      ),
    );
  }
}

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  Future<void> _handleLogin(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DiaryPage()),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AuthOptionsPage()),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/Rainbow_bg.png', fit: BoxFit.cover),
          Container(
            color: Colors.black.withOpacity(0.35),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Welcome to your diary',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _handleLogin(context),
                      child: const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DiaryEntry {
  final String id;
  final String email;
  final DateTime date;
  final String title;
  final String mood;
  final String content;

  DiaryEntry({
    required this.id,
    required this.email,
    required this.date,
    required this.title,
    required this.mood,
    required this.content,
  });

  factory DiaryEntry.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DiaryEntry(
      id: doc.id,
      email: data['email'] as String,
      date: (data['date'] as Timestamp).toDate(),
      title: data['title'] as String,
      mood: data['mood'] as String,
      content: data['content'] as String,
    );
  }
}

class AuthOptionsPage extends StatefulWidget {
  const AuthOptionsPage({super.key});

  @override
  State<AuthOptionsPage> createState() => _AuthOptionsPageState();
}

class _AuthOptionsPageState extends State<AuthOptionsPage>
    with WidgetsBindingObserver {
  bool _isResumed = true;
  bool _needsLink = false;
  bool _isLinking = false;
  String? _pendingGithubAccessToken;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isResumed =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isResumed = state == AppLifecycleState.resumed;
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    if (FirebaseAuth.instance.currentUser != null) {
      if (context.mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DiaryPage()),
        );
      }
      return;
    }
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.linkWithCredential(credential);
      } else {
        await FirebaseAuth.instance.signInWithCredential(credential);
      }

      if (_needsLink && _pendingGithubAccessToken != null) {
        final githubCredential =
            GithubAuthProvider.credential(_pendingGithubAccessToken!);
        await FirebaseAuth.instance.currentUser
            ?.linkWithCredential(githubCredential);
        if (mounted) {
          setState(() {
            _needsLink = false;
            _pendingGithubAccessToken = null;
          });
        }
      }

      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DiaryPage()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        final email = e.email;
        if (email == null) return;

        final methods =
            await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);

        if (methods.contains('google.com')) {
          // Sign in with Google to get the existing user
          final googleUser = await GoogleSignIn().signIn();
          if (googleUser == null) return;

          final googleAuth = await googleUser.authentication;
          final googleCredential = GoogleAuthProvider.credential(
            accessToken: googleAuth.accessToken,
            idToken: googleAuth.idToken,
          );

          await FirebaseAuth.instance.signInWithCredential(googleCredential);
          // No need to link; we are already using Google for this account
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please sign in with your other provider.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: ${e.message}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: $e')),
      );
    }
  }

  Future<String?> _getGitHubAccessToken(BuildContext context) async {
    const clientId = 'Ov23lil2hL15i2xj0BDW';

    final deviceCodeRes = await http.post(
      Uri.parse('https://github.com/login/device/code'),
      headers: {'Accept': 'application/json'},
      body: {'client_id': clientId, 'scope': 'read:user user:email'},
    );

    final deviceData = jsonDecode(deviceCodeRes.body) as Map<String, dynamic>;
    final deviceCode = deviceData['device_code'] as String;
    final userCode = deviceData['user_code'] as String;
    final verificationUri = deviceData['verification_uri'] as String;
    var interval = deviceData['interval'] as int? ?? 5;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('GitHub sign‑in'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Go to: $verificationUri'),
              const SizedBox(height: 8),
              Text(
                'Code: $userCode',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: userCode));
              },
              child: const Text('Copy code'),
            ),
            TextButton(
              onPressed: () async {
                final uri = Uri.parse(verificationUri);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              },
              child: const Text('Open link'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done'),
            ),
          ],
        );
      },
    );

    while (true) {
      while (!_isResumed) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      await Future.delayed(Duration(seconds: interval));

      final tokenRes = await http.post(
        Uri.parse('https://github.com/login/oauth/access_token'),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': clientId,
          'device_code': deviceCode,
          'grant_type': 'urn:ietf:params:oauth:grant-type:device_code',
        },
      );

      final tokenData = jsonDecode(tokenRes.body) as Map<String, dynamic>;

      if (tokenData['access_token'] != null) {
        return tokenData['access_token'] as String;
      }

      final error = tokenData['error'] as String?;
      if (error == 'authorization_pending') continue;
      if (error == 'slow_down') {
        interval += 5;
        continue;
      }
      throw Exception('GitHub device flow failed: $error');
    }
  }

  Future<void> _signInWithGitHubDeviceFlow(BuildContext context) async {
    try {
      final accessToken = await _getGitHubAccessToken(context);
      if (accessToken == null) return;

      final credential = GithubAuthProvider.credential(accessToken);
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.linkWithCredential(credential);
        } else {
          await FirebaseAuth.instance.signInWithCredential(credential);
        }
      } on FirebaseAuthException catch (e) {
        if (e.code == 'account-exists-with-different-credential') {
          if (mounted) {
            setState(() {
              _needsLink = true;
              _pendingGithubAccessToken = accessToken;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in with your other provider.'),
            ),
          );
          return;
        } else {
          rethrow;
        }
      }

      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DiaryPage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('GitHub sign‑in failed: $e')),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_needsLink)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    const Text(
                      'To continue, sign in with Google to link accounts.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLinking
                            ? null
                            : () async {
                                setState(() => _isLinking = true);
                                await _signInWithGoogle(context);
                                if (mounted) {
                                  setState(() => _isLinking = false);
                                }
                              },
                        child: const Text('Sign in with Google to link'),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _signInWithGoogle(context),
                child: const Text('Continue with Google'),
              ),
            ),
            //Github oAuth client ID: Ov23lil2hL15i2xj0BD
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                //onPressed: () => _signInWithGitHub(context),
                onPressed: () => _signInWithGitHubDeviceFlow(context),
                child: const Text('Continue with GitHub'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Stream<QuerySnapshot> _entriesStream(String uid) {
  return FirebaseFirestore.instance
    .collection('users')
    .doc(uid)
    .collection('entries')
    .orderBy('createdAt', descending: true)
    .snapshots();
}

class DiaryPage extends StatelessWidget {
  const DiaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Diary'),
        actions: [
          IconButton(
            onPressed: () async {
              await GoogleSignIn().signOut();
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const WelcomePage()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NewEntryPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _entriesStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load entries'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No entries yet'));
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final entry = DiaryEntry.fromDoc(docs[index]);
              return Card(
                child: ListTile(
                  title: Text(entry.title, style: Theme.of(context).textTheme.titleMedium),
                  subtitle: Text('${entry.mood} * ${entry.date.toLocal()}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => EntryDetailPage(entry: entry),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}