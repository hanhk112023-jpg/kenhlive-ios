# 🚀 KENHLIVE iOS v1.6.2 (Build 134) — TỰ ĐỘNG KHÓA XOAY NGANG KHI XEM & LÀM LẠI TOÀN DIỆN TRÌNH PHÁT CINEMA

### 🔄 1. Tự Động Khóa Xoay Ngang Màn Hình Khi Xem (`OrientationManager.swift` & `HLSPlayerView.swift`)
- **Tự động chuyển xoay ngang (Landscape Auto-Lock)**:
  - Khi người dùng nhấn xem trận đấu, kênh TV hay tập phim ở chế độ toàn màn hình, ứng dụng tự động xoay ngang thiết bị (`UIInterfaceOrientationMask.landscape`) qua `UIWindowScene.requestGeometryUpdate` chuẩn iOS 16+.
  - Khi đóng trình phát (nhấn nút X hoặc vuốt xuống), màn hình lập tức tự động xoay dọc trở lại (`UIInterfaceOrientationMask.portrait`) mượt mà, không cần người dùng phải xoay tay hay mở Control Center.
- **Nút chuyển đổi hướng xoay trên thanh điều khiển OSD**:
  - Tích hợp nút **"XOAY DỌC" / "XOAY NGANG"** ngay góc phải thanh OSD với phản hồi xúc giác rung nhẹ (`KLHaptics.selection()`), cho phép người dùng tùy ý chuyển đổi nhanh chóng.

---

### 🛡️ 2. Làm Lại Trình Phát Cinema AVPlayer Metal 100% Crash-Proof (`HLSPlayerView.swift`)
- **Tối ưu vùng an toàn (Safe Area Insets)**:
  - Tự động bù lề ngang (`36pt`) cho Dynamic Island và tai thỏ camera trên các dòng iPhone mới nhất, đảm bảo nút Đóng (X), tên trận đấu, menu chọn Server và các nút chức năng không bao giờ bị che khuất.
- **Safe Seek mượt mà**:
  - Chuẩn hóa lệnh tua `player.seek(to: targetTime)` tương thích hoàn toàn với AVFoundation.
  - Cử chỉ chạm 2 lần tua ±10s hiển thị ripple hiệu ứng nổi bật.
  - Chạm 1 lần ẩn/hiện OSD thông minh sau 3.8s.
  - Cử chỉ chụm mở 2 ngón (Pinch-to-zoom) chuyển đổi tức thì giữa tỉ lệ chuẩn 16:9 và chế độ Tràn Viền.

---

### 📅 3. Lịch Thi Đấu EPG 7 Ngày Tự Động (`ScheduleView.swift` & `SportsService.swift`)
- Tự động tính toán 7 ngày kế tiếp (Hôm nay, Ngày mai, và các ngày trong tuần tiếp theo).
- Tải dữ liệu lịch thi đấu thực tế từ API nhà đài thể thao cho bất kỳ ngày nào được chọn.
- Bộ nhớ đệm thông minh (`scheduleCache`) chuyển đổi giữa các ngày tức thì.

---

### 📦 Cài Đặt (iPhone / iPad — iOS 16.0+):
- Tải file `KenhLive-iOS.ipa` bên dưới và cài đặt qua **TrollStore**, **ESign**, **Scarlet**, **Feather**, **Sideloadly** hoặc **AltStore**.