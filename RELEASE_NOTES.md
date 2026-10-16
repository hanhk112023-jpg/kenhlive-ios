# 🚀 KENHLIVE iOS v1.6.1 (Build 133) — ĐỘT PHÁ LỊCH THI ĐẤU EPG 7 NGÀY & NÂNG CẤP PHÒNG BÌNH LUẬN LIQUID GLASS

### 💎 1. Đột Phá Lịch Thi Đấu EPG 7 Ngày Tự Động (`ScheduleView.swift` & `SportsService.swift`)
- **Tích hợp lịch động theo thời gian thực (GMT+7)**:
  - Tự động tính toán 7 ngày kế tiếp (Hôm nay, Ngày mai, và các ngày trong tuần tiếp theo).
  - Tải dữ liệu lịch thi đấu thực tế từ API nhà đài thể thao cho bất kỳ ngày nào được chọn.
  - Bộ nhớ đệm thông minh (`scheduleCache: [Int: [ScheduleItem]]`) chuyển đổi giữa các ngày tức thì không cần tải lại.
  - Ô tìm kiếm trận đấu, câu lạc bộ hoặc giải đấu tức thì trên lịch thi đấu.
  - Nhấn 1 chạm vào trận đang đá để khởi chạy ngay trình phát Native Cinema Player.

---

### 🎙️ 2. Nâng Cấp Bảng Chọn Phòng Bình Luận Liquid Glass (`RoomPickerSheet.swift`)
- **Thiết kế Liquid Glass Neo-Dark Cinema**:
  - Avatar đại diện BLV với viền phát sáng thương hiệu (Socolive, ColaTV, Gà Vàng 33, Giờ Vàng TV).
  - Nhịp đèn trực tiếp `KLLivePulseBadge` và số lượng khán giả đang theo dõi.
  - Phản hồi xúc giác cơ học `KLHaptics.selection()` khi chọn phòng.

---

### 🎬 3. Bóc Tách Luồng Direct M3U8 Siêu Tốc (`VodWebPlayerView.swift`)
- **Tự động trích xuất luồng `.m3u8` trực tiếp**:
  - Tự động bóc tách link HLS từ các URL nhúng iframe (`embed?url=...`), ưu tiên 100% trình phát Native `AVPlayerViewController` Metal thay vì mở qua webview.
  - Lưu tiến trình xem dở chuẩn xác theo giây.

---

### 🛡️ 4. Trình Phát Cinema AVPlayer Metal 100% Crash-Proof (`HLSPlayerView.swift`)
- Kế thừa `AVPlayerViewController` với `showsPlaybackControls = false`, hoàn toàn loại bỏ lỗi ép kiểu `CALayer` gây sập ứng dụng.
- Kẹp biên an toàn cho thanh tua thời gian `0...safeDuration` với `duration.isFinite`.
- Cử chỉ chạm kép tua ±10s, pinch zoom fit/fill, vuốt xuống đóng mượt mà.

---

### 📦 Cài Đặt (iPhone / iPad — iOS 16.0+):
- Tải file `KenhLive-iOS.ipa` bên dưới và cài đặt qua **TrollStore**, **ESign**, **Scarlet**, **Feather**, **Sideloadly** hoặc **AltStore**.