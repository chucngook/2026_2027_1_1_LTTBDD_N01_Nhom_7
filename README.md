# 🎮 Playtime – Ứng dụng trò chơi và kết nối bạn bè

**Playtime – Giờ ra chơi** là ứng dụng giải trí di động được xây dựng bằng Flutter, mang đến không gian thư giãn nhẹ nhàng, vui nhộn và kết nối bạn bè thông qua các trò chơi mini (minigame) trực tiếp trên mạng nội bộ.

---

## 📋 Mục lục
- [Thông tin nhóm thực hiện](#-thông-tin-nhóm-thực-hiện)
- [Giới thiệu dự án](#-giới-thiệu-dự-án)
- [Tính năng nổi bật](#-tính-năng-nổi-bật)
- [Danh sách Minigame](#-danh-sách-minigame)
- [Kiến trúc & Công nghệ sử dụng](#-kiến-trúc--công-nghệ-sử-dụng)
- [Cấu trúc thư mục dự án](#-cấu-trúc-thư-mục-dự-án)
- [Hướng dẫn cài đặt và chạy thử](#-hướng-dẫn-cài-đặt-và-chạy-thử)

---

## 👥 Thông tin nhóm thực hiện

- **Trường:** Đại học Phenikaa – Trường Công nghệ Thông tin
- **Học phần:** Lập trình thiết bị di động (`2026_2027_1_1_LTTBDD_N01`)
- **Giảng viên hướng dẫn:** ThS. Nguyễn Xuân Quế
- **Nhóm thực hiện:** Nhóm 7

### Danh sách thành viên
| STT | Họ và tên | Mã sinh viên | Vai trò / Công việc phụ trách | Đóng góp |
| :---: | :--- | :---: | :--- | :---: |
| 1 | **Nguyễn Xuân Chức** | `23010452` | Phân tích yêu cầu, thiết kế hệ thống, lập trình Flutter, kiểm thử và viết báo cáo | 100% |

---

## 📖 Giới thiệu dự án

Trong môi trường học đường, nhu cầu giải trí và tương tác trực tiếp với bạn bè trong những giờ nghỉ giải lao rất cao, nhưng phần lớn các trò chơi hiện nay lại mang tính cạnh tranh gay gắt hoặc yêu cầu kết nối Internet phức tạp. 

**Playtime** ra đời nhằm giải quyết vấn đề đó:
- **Giải trí lành mạnh:** Các trò chơi có luật chơi đơn giản, ván đấu nhanh, giúp xả stress hiệu quả sau giờ học.
- **Gắn kết bạn bè:** Hỗ trợ chế độ chơi nhiều người qua mạng Wi-Fi/LAN nội bộ mà không cần máy chủ đám mây phức tạp.
- **Cá nhân hóa trải nghiệm:** Cho phép tùy chỉnh tên nhân vật, ảnh đại diện (avatar), cỡ chữ, ngôn ngữ và giao diện chủ đề (Đại dương...).

---

## ✨ Tính năng nổi bật

- **Chế độ chơi đa dạng:**
  - *Chơi một mình (Offline):* Thử sức với máy (AI) ở các mức độ Dễ, Trung bình, Khó.
  - *Chơi cùng bạn trên 1 máy:* Hai người cùng thao tác luân phiên trên một thiết bị.
  - *Chơi qua mạng Wi-Fi (Host & Client):* Một thiết bị mở bàn (Host) và thiết bị khác tham gia (Client) thông qua địa chỉ IP, Mã bàn hoặc quét mã QR.
- **Phòng chờ & Trò chuyện (Lobby & Chat):** Tích hợp tính năng nhắn tin trực tiếp trong bàn chơi trước và trong khi bắt đầu ván đấu.
- **Quản lý hồ sơ & Thống kê:** Lưu trữ lịch sử số ván đã chơi, danh sách bạn bè và cài đặt cá nhân cục bộ trên thiết bị.

---

## 🕹️ Danh sách Minigame

Ứng dụng tích hợp nhiều trò chơi dân gian và trí tuệ kinh điển:
1. **Ô ăn quan:** Trò chơi dân gian Việt Nam rải quân và ăn quan tính điểm.
2. **Cờ ca-rô (Gomoku):** Đấu trí xếp 5 quân liên tiếp trên bàn cờ.
3. **Bắn máy bay:** Trò chơi chiến thuật đoán tọa độ.
4. **Cờ vua:** Đấu cờ trí tuệ cổ điển.
5. *Và các minigame mở rộng khác...*

---

## 🛠️ Kiến trúc & Công nghệ sử dụng

Ứng dụng được thiết kế theo mô hình phân tầng rõ ràng:
- **Tầng Giao diện (Presentation):** Flutter UI (`SplashScreen`, `HomeScreen`, `ModeSelectScreen`, `OnlineLobbyScreen`, `GameScaffold`...).
- **Tầng Nghiệp vụ (Business Logic):** `TableService`, `OnlineService`, `PlayerService`, `FriendService`, `StatsService`, `SettingsService`.
- **Tầng Kết nối (Network):** `RelayServer` sử dụng Socket (`dart:io`) truyền tải dữ liệu thời gian thực qua mạng LAN/Wi-Fi.
- **Tầng Dữ liệu (Data):** Lưu trữ dữ liệu cục bộ bằng SQLite (`sqflite`) và cài đặt người dùng.

| Công nghệ / Thư viện | Phiên bản | Vai trò |
| :--- | :---: | :--- |
| **Flutter SDK** | `3.47.5` | Framework phát triển giao diện đa nền tảng |
| **Dart** | `3.13.4` | Ngôn ngữ lập trình chính |
| **sqflite & path** | Latest | Quản lý cơ sở dữ liệu SQLite cục bộ |
| **Xcode** | Latest | Công cụ biên dịch và triển khai trên iOS / iPadOS |

---

## 📂 Cấu trúc thư mục dự án

```text
2026_2027_1_1_LTTBDD_N01_Nhom_7/
├── lib/                    # Mã nguồn chính của ứng dụng Flutter
│   ├── screens/            # Các màn hình giao diện (Home, Lobby, Game...)
│   ├── services/           # Các dịch vụ xử lý logic, kết nối mạng, database
│   ├── models/             # Các mô hình dữ liệu (OnlineSession, MatchConfig...)
│   └── widgets/            # Các thành phần giao diện tái sử dụng
├── server/                 # Xử lý máy chủ chuyển tiếp nội bộ (RelayServer)
├── ios/ & macos/           # Cấu hình nền tảng Apple
├── test/                   # Mã nguồn kiểm thử
└── pubspec.yaml            # Khai báo thư viện và tài nguyên dự án
