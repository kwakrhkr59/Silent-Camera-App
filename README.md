## 📷 Silent Camera App (Flutter)
수업 중 조용히 자료를 촬영하고 싶은 순간, 시중에 있는 **무음 카메라 앱**들은 대부분 **낮은 해상도**, **과도한 광고**, **느린 저장 속도** 등으로 만족스럽지 못했습니다.
이 프로젝트는 그 불편함에서 출발한 **개인 개발 프로젝트**로, 고품질 촬영과 동시에 **무음 촬영**, **갤러리 저장**, **간결한 UI**를 갖춘 앱을 직접 구현하고자 했습니다.

---

### 🧠 프로젝트 개요

* **개발 목적:** 광고 없는 고화질 무음 카메라 앱 직접 개발
* **사용 사례:** 강의 중 조용히 자료 촬영, 정숙한 환경에서 기록
* **주요 기능:** MediaStore 기반 Android 갤러리 저장, 실시간 프리뷰, 커스텀 갤러리 UI
* **플랫폼:** Android

---

### 🛠 기술 스택 및 아키텍처

| 영역             | 사용 기술                                                               | 설명                                 |
| -------------- | ------------------------------------------------------------------- | ---------------------------------- |
| **UI 프레임워크**   | Flutter (Dart)                                                      | 크로스 플랫폼 앱 개발을 위한 프레임워크             |
| **카메라 기능**     | [`camera`](https://pub.dev/packages/camera)                         | 실시간 프리뷰 및 무음 촬영 기능 구현              |
| **이미지 저장**     | Android MediaStore API (커스텀 구현)                                     | 외부 저장소에 고화질 이미지 저장 및 미디어 라이브러리에 등록 |
| **권한 관리**      | [`permission_handler`](https://pub.dev/packages/permission_handler) | 저장소 및 카메라 접근 권한 요청                 |
| **갤러리 표시**     | [`photo_manager`](https://pub.dev/packages/photo_manager)           | 저장된 이미지 목록 로딩 및 커스텀 썸네일 구성         |
| **디바이스 경로 처리** | [`path_provider`](https://pub.dev/packages/path_provider)           | OS별 저장소 위치 확인 및 활용                 |

---

### ✨ 주요 기능

* 📸 **무음으로 고화질 사진 촬영**
* 💾 **MediaStore를 활용한 외부 저장소 갤러리 저장**
* 🗂️ **앱 내 커스텀 갤러리 UI로 저장 이미지 확인**
* 🔐 **미디어 권한 자동 요청 및 안내**

---

### 📂 폴더 구조 예시

```
lib/
├── main.dart
├── screens/
│   ├── camera_screen.dart
│   └── gallery_screen.dart
│   └── single_image_view.dart
```

---

### ⚙️ 실행 방법

```bash
git clone https://github.com/yourusername/silent_camera_flutter.git
cd silent_camera_flutter
flutter pub get
flutter run
```
