🎮 Playtime – Ứng dụng trò chơi và kết nối bạn bèPlaytime – Giờ ra chơi là ứng dụng giải trí di động được xây dựng bằng Flutter, mang đến không gian thư giãn nhẹ nhàng, vui nhộn và kết nối bạn bè thông qua các trò chơi mini (minigame) trực tiếp trên mạng nội bộ.📋 Mục lụcThông tin nhóm thực hiệnGiới thiệu dự ánTính năng nổi bậtDanh sách MinigameKiến trúc & Công nghệ sử dụngCấu trúc thư mục dự ánHướng dẫn cài đặt và chạy thử👥 Thông tin nhóm thực hiệnTrường: Đại học Phenikaa – Trường Công nghệ Thông tinHọc phần: Lập trình thiết bị di động (2026_2027_1_1_LTTBDD_N01)Giảng viên hướng dẫn: ThS. Nguyễn Xuân QuếNhóm thực hiện: Nhóm 7Danh sách thành viênSTTHọ và tênMã sinh viênVai trò / Công việc phụ tráchĐóng góp1Nguyễn Xuân Chức23010452Phân tích yêu cầu, thiết kế hệ thống, lập trình Flutter, kiểm thử và viết báo cáo100%📖 Giới thiệu dự ánTrong môi trường học đường, nhu cầu giải trí và tương tác trực tiếp với bạn bè trong những giờ nghỉ giải lao rất cao, nhưng phần lớn các trò chơi hiện nay lại mang tính cạnh tranh gay gắt hoặc yêu cầu kết nối Internet phức tạp.Playtime ra đời nhằm giải quyết vấn đề đó:Giải trí lành mạnh: Các trò chơi có luật chơi đơn giản, ván đấu nhanh, giúp xả stress hiệu quả sau giờ học.Gắn kết bạn bè: Hỗ trợ chế độ chơi nhiều người qua mạng Wi-Fi/LAN nội bộ mà không cần máy chủ đám mây phức tạp.Cá nhân hóa trải nghiệm: Cho phép tùy chỉnh tên nhân vật, ảnh đại diện (avatar), cỡ chữ, ngôn ngữ và giao diện chủ đề (Đại dương...).✨ Tính năng nổi bậtChế độ chơi đa dạng:Chơi một mình (Offline): Thử sức với máy (AI) ở các mức độ Dễ, Trung bình, Khó.Chơi cùng bạn trên 1 máy: Hai người cùng thao tác luân phiên trên một thiết bị.Chơi qua mạng Wi-Fi (Host & Client): Một thiết bị mở bàn (Host) và thiết bị khác tham gia (Client) thông qua địa chỉ IP, Mã bàn hoặc quét mã QR.Phòng chờ & Trò chuyện (Lobby & Chat): Tích hợp tính năng nhắn tin trực tiếp trong bàn chơi trước và trong khi bắt đầu ván đấu.Quản lý hồ sơ & Thống kê: Lưu trữ lịch sử số ván đã chơi, danh sách bạn bè và cài đặt cá nhân cục bộ trên thiết bị.🕹️ Danh sách MinigameỨng dụng tích hợp nhiều trò chơi dân gian và trí tuệ kinh điển:Ô ăn quan: Trò chơi dân gian Việt Nam rải quân và ăn quan tính điểm.Cờ ca-rô (Gomoku): Đấu trí xếp 5 quân liên tiếp trên bàn cờ.Bắn máy bay: Trò chơi chiến thuật đoán tọa độ.Cờ vua: Đấu cờ trí tuệ cổ điển.Và các minigame mở rộng khác...🛠️ Kiến trúc & Công nghệ sử dụngỨng dụng được thiết kế theo mô hình phân tầng rõ ràng:Tầng Giao diện (Presentation): Flutter UI (SplashScreen, HomeScreen, ModeSelectScreen, OnlineLobbyScreen, GameScaffold...).Tầng Nghiệp vụ (Business Logic): TableService, OnlineService, PlayerService, FriendService, StatsService, SettingsService.Tầng Kết nối (Network): RelayServer sử dụng Socket (dart:io) truyền tải dữ liệu thời gian thực qua mạng LAN/Wi-Fi.Tầng Dữ liệu (Data): Lưu trữ dữ liệu cục bộ bằng SQLite (sqflite) và cài đặt người dùng.Công nghệ / Thư việnPhiên bảnVai tròFlutter SDK3.47.5Framework phát triển giao diện đa nền tảngDart3.13.4Ngôn ngữ lập trình chínhsqflite & pathLatestQuản lý cơ sở dữ liệu SQLite cục bộXcodeLatestCông cụ biên dịch và triển khai trên iOS / iPadOS📂 Cấu trúc thư mục dự án2026_2027_1_1_LTTBDD_N01_Nhom_7/
├── lib/                    # Mã nguồn chính của ứng dụng Flutter
│   ├── screens/            # Các màn hình giao diện (Home, Lobby, Game...)
│   ├── services/           # Các dịch vụ xử lý logic (Table, Online, Stats...)
│   ├── widgets/            # Các thành phần UI tái sử dụng
│   └── main.dart           # Điểm khởi chạy ứng dụng
├── server/                 # Thành phần xử lý kết nối máy chủ nội bộ (RelayServer)
├── test/                   # Các kịch bản kiểm thử tự động
├── Bao_cao_di_dong_23010452.docx  # Báo cáo chi tiết bài tập lớn (Word)
├── Bao_cao_di_dong_23010452.pdf   # Báo cáo chi tiết bài tập lớn (PDF)
└── pubspec.yaml            # Khai báo thư viện và cấu hình dự án
🚀 Hướng dẫn cài đặt và chạy thử1. Yêu cầu môi trườngĐã cài đặt Flutter SDK (>= 3.47.5) và Dart.Đối với macOS/iOS: Cần cài đặt Xcode và bật Developer Mode trên thiết bị iPhone/iPad thật.2. Các bước chạy ứng dụng# Bước 1: Clone repository về máy
git clone https://github.com/chucngook/2026_2027_1_1_LTTBDD_N01_Nhom_7.git

# Bước 2: Di chuyển vào thư mục dự án
cd 2026_2027_1_1_LTTBDD_N01_Nhom_7

# Bước 3: Cài đặt các thư viện phụ thuộc
flutter pub get

# Bước 4: Kiểm tra thiết bị kết nối và chạy ứng dụng
flutter devices
flutter run
3. Thử nghiệm chơi 2 người qua Wi-FiKết nối cả hai thiết bị vào cùng một mạng Wi-Fi.Trên thiết bị 1 (Host): Chọn Mở bàn để tạo phòng và lấy Mã bàn / Mã QR.Trên thiết bị 2 (Client): Chọn Vào bàn $\rightarrow$ Nhập mã bàn (hoặc quét QR) để kết nối và bắt đầu trò chơi.© 2026 Nhóm 7 – Trường Công nghệ Thông tin, Đại học Phenikaa.
