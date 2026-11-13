# Playtime (PT)

Ứng dụng mini game cho hai người viết bằng Flutter: **chơi với máy** (Dễ / Trung bình / Khó), **chơi chung một máy**, hoặc **chơi online** giữa hai điện thoại.
Hỗ trợ **Tiếng Việt** và **English**, nhiều màu nền, nhạc nền, nhắn tin trong bàn và kết bạn bằng mã QR.

> Môn: Lập trình thiết bị di động – Mã lớp: `2026_2027_1_1_LTTBDD_N0x_Nhom_`
> Thông tin thành viên: sửa trong `lib/constants/team_info.dart` (hiển thị ở **Tôi → Giới thiệu nhóm**).

## Chức năng
| Nhóm | Nội dung |
|---|---|
| Game 2 người | Ô ăn quan, Cờ ca-rô (5 quân), Bắn máy bay, Cờ vua (đủ luật) – mỗi game có 3 cách chơi |
| Game 1 người | Rắn, 2048, Chim bay, Lật hình, Hứng táo, Toán nhanh, Bingo, Triệu phú |
| Tab **Chơi** | Danh sách game, nút **Vào bàn**, thẻ tên vui tự cấp, sắp xếp / ghim yêu thích |
| Tab **Nhắn** | Mở bàn / nhập mã bàn, nhắn tin trong bàn, chọn game để cả hai cùng chơi, mời bạn bè |
| Tab **Tôi** | Hồ sơ, ván đã chơi, bạn bè, mã QR, Dễ nhìn (cỡ chữ, ngôn ngữ, màu nền), Âm thanh, Cảm giác, Trò chuyện, Nhắc chơi, Giới thiệu nhóm |
| Âm thanh | Nhạc nền menu luôn phát; vào game đổi sang nhạc game; hiệu ứng âm thanh; bật/tắt từng loại |

Không cần đăng nhập: lần đầu mở app sẽ tự cấp một tên vui (ví dụ *Hổ Vằn Bão Tố*) và có thể đổi.

## Chạy ứng dụng
```
flutter create --platforms=ios,android --project-name playtime .   # lần đầu: tạo thư mục ios/ android/
rm -rf test
./setup_platforms.sh        # thêm quyền Camera, Internet, Mạng cục bộ
flutter pub get
flutter run
```
**Font tròn (tùy chọn):** tải *Baloo 2* từ Google Fonts, chép vào `assets/fonts/` rồi bỏ dấu `#` khối `fonts:` trong `pubspec.yaml`.

## Chơi online
### Cách 1 – Qua Wi-Fi, KHÔNG cần máy chủ (mặc định)
Một điện thoại tự làm "chủ bàn" ngay trong app.
1. Hai máy cùng một mạng Wi-Fi (hoặc một máy phát điểm truy cập cá nhân, máy kia kết nối vào).
2. Máy A: tab **Nhắn → Mở bàn** → app hiện **địa chỉ IP**, **mã bàn** và **mã QR**. Giữ app mở.
3. Máy B: **Vào bàn** (hoặc **Nhắn → Nhập mã bàn**) → nhập IP + mã bàn, hoặc bấm **Quét mã QR**.
4. Hai máy nhắn tin được ngay; một người bấm **Chơi**, chọn game thì cả hai cùng vào ván.

### Cách 2 – Qua Internet với máy chủ riêng
```
dart server/server.dart          # cổng 8080 (đổi cổng: dart server/server.dart 9000)
```
Trong app: **Tôi → Kết nối online**, nhập địa chỉ máy chủ (`192.168.1.5:8080` hoặc `wss://ten-mien.com`).
Khi đã cài máy chủ, chỉ cần nhập **mã bàn** và có thêm tính năng mời bạn bè. Có thể deploy bằng `server/Dockerfile`
(build từ thư mục gốc: `docker build -f server/Dockerfile -t playtime .`).

## Cơ sở dữ liệu (SQLite – `playtime.db`)
```
matches(id PK, game_id, mode, result, opponent, played_at)   -- lịch sử ván đã chơi
scores(game_id PK, best)                                      -- điểm cao các game 1 người
friends(id PK, name, emoji, added_at)                         -- bạn bè (kết bạn bằng QR)
```
Cài đặt (ngôn ngữ, màu nền, âm thanh...) lưu bằng `SharedPreferences`.

## Cấu trúc thư mục
```
lib/
  main.dart                  khởi động, theme, điều hướng, nhạc nền
  constants/                 danh mục game, thông tin nhóm
  data/                      SQLite (app_database.dart), game_service.dart
  services/                  settings, lang (song ngữ), music, fx (âm thanh/rung),
                             player, stats, friend, online_service, table_service
  widgets/                   thành phần giao diện dùng chung (Text dịch tự động, thẻ, nút...)
  screens/                   home, play_tab, messages_tab, me_tab, about, friends, history...
  screens/games/             caro, chess, oanquan, planes + 8 game một người
server/                      server.dart (máy chủ độc lập), Dockerfile  (logic dùng chung: lib/services/relay_server.dart)
assets/                      images, sounds, music
```
