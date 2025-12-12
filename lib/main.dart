import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart'; // 달력 패키지
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '미니멀 가계부',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Pretendard',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        scaffoldBackgroundColor: Colors.white,
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
        if (snapshot.hasData) return const HomeScreen();
        return const LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      debugPrint("로그인 에러: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton.icon(
          onPressed: signInWithGoogle,
          icon: const Icon(Icons.login),
          label: const Text("구글로 시작하기"),
          style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black, foregroundColor: Colors.white),
        ),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;

  // 달력 설정
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 입력 컨트롤러
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  // 입력 상태
  String _type = '지출';
  String _category = '식비';

  final List<String> _expenseCategories = ['식비', '교통', '쇼핑', '주거', '기타'];
  final List<String> _incomeCategories = ['월급', '용돈', '부수입', '기타'];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  void _deleteTransaction(String docId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('transactions')
        .doc(docId)
        .delete();
  }

  void _addTransaction() async {
    if (_amountController.text.isEmpty || _titleController.text.isEmpty) return;

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('transactions')
        .add({
      'title': _titleController.text,
      'amount': int.parse(_amountController.text),
      'date': Timestamp.fromDate(_selectedDay ?? DateTime.now()),
      'type': _type,
      'category': _category,
    });

    _amountController.clear();
    _titleController.clear();
    if (mounted) Navigator.pop(context);
  }

  void _showAddDialog() {
    _type = '지출';
    _category = '식비';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("내역 입력"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text("지출")),
                          selected: _type == '지출',
                          onSelected: (selected) {
                            setState(() {
                              _type = '지출';
                              _category = '식비';
                            });
                          },
                          selectedColor: Colors.redAccent.shade100,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: const Center(child: Text("수입")),
                          selected: _type == '수입',
                          onSelected: (selected) {
                            setState(() {
                              _type = '수입';
                              _category = '월급';
                            });
                          },
                          selectedColor: Colors.blueAccent.shade100,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    key: ValueKey(_type), // 타입 변경 시 UI 갱신용 키
                    initialValue: _category, // 경고 해결된 최신 문법
                    items: (_type == '지출' ? _expenseCategories : _incomeCategories)
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) => setState(() => _category = value!),
                    decoration: const InputDecoration(labelText: "카테고리", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "내역", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "금액", border: OutlineInputBorder()),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
                ElevatedButton(onPressed: _addTransaction, child: const Text("저장")),
              ],
            );
          },
        );
      },
    );
  }

  List<dynamic> _getEventsForDay(DateTime day, List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      return isSameDay(date, day);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("내 가계부"), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('transactions')
            .snapshots(),
        builder: (context, snapshot) {
          // [★중요] 에러가 있으면 화면에 빨간 글씨로 띄워주는 부분
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "🚨 에러 발생!\n\n${snapshot.error}",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final docs = snapshot.data?.docs ?? []; // 데이터가 없으면 빈 리스트

          // 선택된 날짜의 목록만 필터링
          final selectedDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            return isSameDay(date, _selectedDay);
          }).toList();

          return Column(
            children: [
              TableCalendar(
                locale: 'ko_KR',
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                },
                eventLoader: (day) => _getEventsForDay(day, docs),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;
                    int income = 0;
                    int expense = 0;
                    for (var event in events) {
                      final data = (event as QueryDocumentSnapshot).data() as Map<String, dynamic>;
                      if (data['type'] == '수입') {
                        income += (data['amount'] as int);
                      } else {
                        expense += (data['amount'] as int);
                      }
                    }
                    return Positioned(
                      bottom: 1,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (income > 0) 
                            Text("+${NumberFormat.compact().format(income)}", style: const TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
                          if (expense > 0) 
                            Text("-${NumberFormat.compact().format(expense)}", style: const TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(thickness: 1),
              Expanded(
                child: selectedDocs.isEmpty
                    ? const Center(child: Text("내역이 없습니다."))
                    : ListView.builder(
                        itemCount: selectedDocs.length,
                        itemBuilder: (context, index) {
                          final doc = selectedDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final isIncome = data['type'] == '수입';

                          return Dismissible(
                            key: Key(doc.id),
                            onDismissed: (_) => _deleteTransaction(doc.id),
                            background: Container(color: Colors.red, alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20), child: const Icon(Icons.delete, color: Colors.white)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isIncome ? Colors.blue.shade100 : Colors.red.shade100,
                                child: Icon(isIncome ? Icons.arrow_upward : Icons.arrow_downward, color: isIncome ? Colors.blue : Colors.red),
                              ),
                              title: Text(data['title']),
                              subtitle: Text(data['category'] ?? '기타'),
                              trailing: Text(
                                "${isIncome ? '+' : '-'}${NumberFormat('#,###').format(data['amount'])}원",
                                style: TextStyle(fontWeight: FontWeight.bold, color: isIncome ? Colors.blue : Colors.red, fontSize: 16),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: Colors.black,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}