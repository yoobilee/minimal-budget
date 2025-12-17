import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // 달력 언어 설정
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initializeDateFormatting(); // 한국어 달력 데이터 초기화
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
        fontFamily: 'Pretendard', // 폰트가 없으면 기본 폰트로 나옵니다
        scaffoldBackgroundColor: const Color(0xFFF5F5F5), // 연한 회색 배경
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          primary: Colors.black,
          secondary: Colors.grey,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF5F5F5),
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black, 
            fontSize: 20, 
            fontWeight: FontWeight.bold
          ),
          iconTheme: IconThemeData(color: Colors.black),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// 로그인 상태에 따라 화면 분기
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}

// ---------------------------------------------------------
// 1. 로그인 화면 (LoginScreen)
// ---------------------------------------------------------
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> signInWithGoogle(BuildContext context) async {
    try {
      // ★ 중요: 여기에 아까 복사한 웹 클라이언트 ID를 넣으세요!
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        clientId: 'YOUR_CLIENT_ID_HERE', 
      ).signIn();

      if (googleUser == null) return; // 사용자가 취소함

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context, 
          builder: (context) => AlertDialog(
            title: const Text("로그인 에러"),
            content: Text(e.toString()),
            actions: [TextButton(onPressed: ()=>Navigator.pop(context), child: const Text("확인"))],
          )
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_wallet, size: 80, color: Colors.black),
            const SizedBox(height: 24),
            const Text("Minimal Budget", 
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)
            ),
            const SizedBox(height: 10),
            Text("복잡한 건 빼고, 핵심만 담았습니다.", style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 60),
            
            // 구글 로그인 버튼
            ElevatedButton.icon(
              onPressed: () => signInWithGoogle(context),
              icon: const Icon(Icons.g_mobiledata, size: 28),
              label: const Text("Google로 계속하기"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// 2. 메인 홈 화면 (HomeScreen)
// ---------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  
  // 달력 상태 변수
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // 입력용 변수
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  String _type = '지출';
  String _category = '식비';

  final List<String> _expenseCategories = ['식비', '교통', '쇼핑', '주거', '통신', '기타'];
  final List<String> _incomeCategories = ['월급', '용돈', '이자', '부수입', '기타'];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  // --- [UI 위젯] 앱바 오른쪽 '알약 팝업 버튼' ---
  Widget _buildViewSelector() {
    String text;
    switch (_calendarFormat) {
      case CalendarFormat.month: text = "월간"; break;
      case CalendarFormat.twoWeeks: text = "2주"; break;
      case CalendarFormat.week: text = "주간"; break;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: PopupMenuButton<CalendarFormat>(
        offset: const Offset(0, 50),
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Colors.white,
        tooltip: "보기 방식 변경",
        
        // 캡슐 모양 버튼 디자인
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6, offset: const Offset(0, 2))
            ],
          ),
          child: Row(
            children: [
              Text(text, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
        
        onSelected: (format) => setState(() => _calendarFormat = format),
        
        itemBuilder: (context) => [
          _buildPopupItem(CalendarFormat.month, "월간 보기"),
          _buildPopupItem(CalendarFormat.twoWeeks, "2주 보기"),
          _buildPopupItem(CalendarFormat.week, "주간 보기"),
        ],
      ),
    );
  }

  PopupMenuItem<CalendarFormat> _buildPopupItem(CalendarFormat format, String text) {
    bool isSelected = _calendarFormat == format;
    return PopupMenuItem(
      value: format,
      child: Row(
        children: [
          Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, 
               size: 18, color: isSelected ? Colors.black : Colors.grey.shade300),
          const SizedBox(width: 10),
          Text(text, style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : Colors.grey[600],
            fontSize: 14
          )),
        ],
      ),
    );
  }

  // --- [기능] 데이터 추가 ---
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
      'createdAt': FieldValue.serverTimestamp(),
    });
    _amountController.clear();
    _titleController.clear();
    if (mounted) Navigator.pop(context);
  }

  // --- [기능] 데이터 삭제 ---
  void _deleteTransaction(String docId) {
    FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('transactions')
        .doc(docId)
        .delete();
  }

  // --- [기능] 달력 점(Event) 표시를 위한 데이터 필터링 ---
  List<dynamic> _getEventsForDay(DateTime day, List<QueryDocumentSnapshot> docs) {
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      return isSameDay(date, day);
    }).toList();
  }

  // --- [UI] 추가 다이얼로그 ---
  void _showAddDialog() {
    _type = '지출';
    _category = '식비';
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text("내역 추가", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 수입/지출 선택 토글
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      children: [
                        _buildTypeButton("지출", Colors.redAccent, setState),
                        _buildTypeButton("수입", Colors.blueAccent, setState),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: (_type == '지출' ? _expenseCategories : _incomeCategories)
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                    decoration: _inputDecoration("카테고리"),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _titleController, decoration: _inputDecoration("내역 (예: 점심값)")),
                  const SizedBox(height: 12),
                  TextField(controller: _amountController, keyboardType: TextInputType.number, decoration: _inputDecoration("금액")),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: Text("취소", style: TextStyle(color: Colors.grey[600]))),
                ElevatedButton(
                  onPressed: _addTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text("저장"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTypeButton(String text, Color color, StateSetter setState) {
    bool isSelected = _type == text;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() {
          _type = text;
          _category = text == '지출' ? '식비' : '월급';
        }),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)] : [],
          ),
          child: Center(
            child: Text(text, style: TextStyle(
              color: isSelected ? color : Colors.grey, 
              fontWeight: FontWeight.bold
            )),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      floatingLabelStyle: const TextStyle(color: Colors.black),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("내 가계부"),
        centerTitle: false,
        actions: [
          _buildViewSelector(), // 여기에 알약 버튼 들어감
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).collection('transactions').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("데이터 로드 실패"));
          
          final docs = snapshot.data?.docs ?? [];
          final selectedDocs = docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            return isSameDay(date, _selectedDay);
          }).toList();

          return Column(
            children: [
              // 1. 달력 카드
              Container(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: TableCalendar(
                  locale: 'ko_KR',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  
                  // 스타일링
                  headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true), // 버튼 숨김
                  calendarStyle: CalendarStyle(
                    todayDecoration: BoxDecoration(color: Colors.grey.shade200, shape: BoxShape.circle),
                    selectedDecoration: const BoxDecoration(color: Colors.black, shape: BoxShape.circle),
                    todayTextStyle: const TextStyle(color: Colors.black),
                    weekendTextStyle: const TextStyle(color: Colors.redAccent),
                    outsideDaysVisible: false,
                  ),
                  
                  // 날짜 선택 로직
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (s, f) => setState(() { _selectedDay = s; _focusedDay = f; }),
                  onFormatChanged: (f) => setState(() => _calendarFormat = f),
                  
                  // 점 찍기 로직
                  eventLoader: (day) => _getEventsForDay(day, docs),
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      if (events.isEmpty) return null;
                      int income = 0;
                      int expense = 0;
                      for (var event in events) {
                        final data = (event as QueryDocumentSnapshot).data() as Map<String, dynamic>;
                        if (data['type'] == '수입') income++; else expense++;
                      }
                      return Positioned(
                        bottom: 5,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (income > 0) Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle)),
                            if (expense > 0) Container(width: 5, height: 5, margin: const EdgeInsets.symmetric(horizontal: 1), decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 2. 리스트 헤더
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Row(
                  children: [
                    Text(
                      _selectedDay == null ? "전체 내역" : "${_selectedDay!.day}일 내역", 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    const Spacer(),
                    Text("총 ${selectedDocs.length}건", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
              ),

              // 3. 내역 리스트 (카드형)
              Expanded(
                child: selectedDocs.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.receipt_long, size: 40, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text("작성된 내역이 없어요", style: TextStyle(color: Colors.grey[400]))
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: selectedDocs.length,
                        itemBuilder: (context, index) {
                          final doc = selectedDocs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final isIncome = data['type'] == '수입';

                          return Dismissible(
                            key: Key(doc.id),
                            onDismissed: (_) => _deleteTransaction(doc.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(16)),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(Icons.delete_outline, color: Colors.red),
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
                              ),
                              child: Row(
                                children: [
                                  // 아이콘
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isIncome ? Colors.blue[50] : Colors.red[50],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isIncome ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, 
                                      color: isIncome ? Colors.blue : Colors.red, 
                                      size: 20
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  // 내용
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(data['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 4),
                                        Text(data['category'], style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  // 금액
                                  Text(
                                    "${isIncome ? '+' : '-'}${NumberFormat('#,###').format(data['amount'])}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold, 
                                      color: isIncome ? Colors.blue[700] : Colors.red[700], 
                                      fontSize: 16
                                    ),
                                  ),
                                ],
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
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}