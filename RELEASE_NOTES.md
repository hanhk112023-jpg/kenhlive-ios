# 🚀 KENHLIVE iOS v1.5.3 (Build 131) — KHẮC PHỤC TRIỆT ĐỂ LỖI CRASH KHI VÀO TRÌNH PHÁT (100% CRASH-PROOF CINEMA PLAYER)

### 🛡️ 1. Khắc Phục Triệt Để Lỗi Crash Khi Mở Trình Phát (Root Cause Fixes)
- **Chuẩn hóa lớp hiển thị AVPlayerViewController**:
  - Loại bỏ hoàn toàn lớp `PlayerUIView` tự định nghĩa với `CALayer as! AVPlayerLayer` (nguyên nhân gây lỗi sập ứng dụng `EXC_BREAKPOINT` trên một số phiên bản iOS do lỗi tra cứu động `layerClass` của Swift private struct).
  - Thay thế bằng `NativeCinemaPlayerRepresentable` kế thừa trực tiếp từ `AVPlayerViewController` của Apple với cờ `showsPlaybackControls = false`. Đảm bảo độ ổn định tuyệt đối 100%, render mượt mà bằng phần cứng Apple Metal, hỗ trợ Picture-in-Picture (PiP) và chuyển đổi tỷ lệ khung hình Fit / Fill tràn viền native.
- **Sửa cấu hình âm thanh AVAudioSession**:
  - Loại bỏ các tùy chọn `.allowAirPlay` và `.allowBluetooth` bị xung đột với danh mục `.playback` (trên iOS thực tế, các cờ này chỉ được phép dùng với danh mục `.playAndRecord`, việc truyền vào `.playback` gây lỗi hệ thống `AVAudioSessionErrorCodeIncompatibleCategory`).
- **Khắc phục lỗi vòng lặp Render tái phát (Re-entrant Render Loop Crash)**:
  - Tách biệt cơ chế quan sát `StorageManager`: gỡ bỏ `@ObservedObject` khỏi `EpisodePickerSheet` để việc lưu tiến trình xem phim không kích hoạt re-render liên tục trên luồng chính khi video đang chạy.
  - Chuyển `onProgressUpdate` sang chỉ kích hoạt khi người dùng tạm dừng, tua thời gian hoặc đóng trình phát, triệt tiêu hoàn toàn tình trạng nghẽn Main Thread.
- **Bảo vệ thanh trượt thời gian (Slider Bound Guard)**:
  - Bổ sung hàm kẹp biên an toàn `safeDuration` và `safeValue`, ngăn chặn tuyệt đối lỗi văng ứng dụng `Fatal error: Slider value out of bounds` khi luồng HLS trả về `duration` là `NaN` hoặc `Infinity`.
- **Hỗ trợ tự động bóc tách link M3U8 từ web player embed**:
  - Tự động nhận diện và trích xuất luồng m3u8 sạch từ các đường dẫn dạng `embed?url=...` để AVPlayer giải mã trực tiếp mà không gặp lỗi phân giải trang web.

---

### 📦 Cài Đặt (iPhone / iPad — iOS 16.0+):
- Tải file `KenhLive-iOS.ipa` bên dưới và cài đặt qua **TrollStore**, **ESign**, **Scarlet**, **Feather**, **Sideloadly** hoặc **AltStore**.