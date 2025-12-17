# 💰 미니멀 가계부 (Minimal Budget)

![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

**Flutter**와 **Firebase**를 활용하여 개발한 심플하고 직관적인 개인 자산 관리(가계부) 애플리케이션입니다.  
복잡한 기능은 덜어내고, 사용자가 꼭 필요한 **수입/지출 내역**을 **달력(Calendar)** 형태로 한눈에 파악할 수 있도록 구현했습니다.

## 🔗 웹사이트 바로가기 (Live Demo)
앱 설치 없이 웹 브라우저에서 바로 사용해볼 수 있습니다. (Cloudflare Pages 배포)
👉 **[https://cool-frost-3481.yblrrto23.workers.dev](https://cool-frost-3481.yblrrto23.workers.dev)**

---

## ✨ 주요 기능 (Key Features)

* **🔒 간편 로그인**
    * Firebase Authentication을 연동한 **Google 로그인** 지원
    * 로그인 상태 유지 및 자동 로그인 (AuthGate)

* **📅 직관적인 캘린더 뷰**
    * `table_calendar` 패키지를 활용한 월간/주간/일간 보기
    * 날짜별 수입(+) / 지출(-) 합계를 캘린더 날짜 칸에 즉시 표시
    * 날짜 선택 시 하단에 해당 일자의 상세 내역 리스트업

* **💸 수입 및 지출 관리**
    * 직관적인 입력 다이얼로그 (Dialog)
    * **수입/지출** 타입 선택 (ChoiceChip) 및 **카테고리** 분류 (Dropdown)
    * 실시간 **Firestore Database** 연동으로 데이터 안전 저장

* **🎨 사용자 경험 (UX/UI)**
    * **밀어서 삭제 (Swipe to Delete):** 리스트 항목을 옆으로 밀어 간편하게 삭제
    * 카드(Card) 형태의 깔끔하고 모던한 리스트 디자인
    * 지출(Red) / 수입(Blue) 색상 구분을 통한 시각적 인지 강화

## 🛠 기술 스택 (Tech Stack)

### Environment
![Visual Studio Code](https://img.shields.io/badge/Visual%20Studio%20Code-0078d7.svg?style=for-the-badge&logo=visual-studio-code&logoColor=white)
![Android Studio](https://img.shields.io/badge/Android%20Studio-3DDC84.svg?style=for-the-badge&logo=android-studio&logoColor=white)
![Git](https://img.shields.io/badge/git-%23F05033.svg?style=for-the-badge&logo=git&logoColor=white)
![GitHub](https://img.shields.io/badge/github-%23121011.svg?style=for-the-badge&logo=github&logoColor=white)

### Development
![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)
![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)

### Backend & Database
![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)

### Key Packages
* `firebase_core`, `firebase_auth`, `cloud_firestore`
* `google_sign_in`
* `table_calendar`
* `intl`

## 📱 실행 방법 (Getting Started)

이 프로젝트는 **Firebase 설정 파일**이 필요합니다. 클론 후 본인의 Firebase 프로젝트를 연결해야 실행됩니다.

1.  **프로젝트 클론 (Clone)**
    ```bash
    git clone [https://github.com/YOUR-USERNAME/minimal-budget.git](https://github.com/YOUR-USERNAME/minimal-budget.git)
    ```

2.  **패키지 설치**
    ```bash
    flutter pub get
    ```

3.  **Firebase 설정 (중요)**
    * 본인의 [Firebase Console](https://console.firebase.google.com/)에서 프로젝트를 생성합니다.
    * `google-services.json` 파일을 다운로드하여 `android/app/` 폴더에 위치시킵니다.
    * Authentication(Google) 및 Firestore Database를 활성화해야 합니다.

4.  **앱 실행**
    ```bash
    flutter run
    ```

---
© 2025 Minimal Budget Project. All rights reserved.