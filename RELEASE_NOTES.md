# 🚀 KENHLIVE iOS v1.5.1 (Build 129) — KHẮC PHỤC TRIỆT ĐỂ TIẾNG PREVIEW & RA MẮT TRÌNH XEM CINEMA NATIVE CHUẨN IOS

### 🔇 1. Khắc Phục Triệt Để Lỗi Trùng Tiếng Xem Trước Tại Tab Truyền Hình
- **Tắt tiếng mặc định (Default Muted) cho Preview**: Khung xem trước kênh truyền hình giờ đây tự động tắt tiếng (`isMuted = true`) chuẩn trải nghiệm iOS (như YouTube/App Store), không còn bất ngờ phát tiếng khi người dùng duyệt danh sách kênh.
- **Nút bật/tắt tiếng nhanh**: Bổ sung nút loa tròn tiện lợi ở góc phải khung xem trước để người dùng chủ động nghe thử nếu muốn.
- **Tự động ngắt tiếng & tạm dừng ngay lập tức**:
  - Khi người dùng bấm vào xem bất kỳ kênh nào toàn màn hình (`activeChannelForPlayer != nil`), trình xem trước sẽ **ngay lập tức tạm dừng và tắt tiếng 100%**, loại bỏ hoàn toàn hiện tượng vang/chồng chéo 2 luồng âm thanh cùng lúc.
  - Khi chuyển sang tab khác hoặc đóng ứng dụng, trình xem trước tự động dọn dẹp bộ nhớ và giải phóng tài nguyên.

---

### 🎬 2. Tái Cấu Trúc Toàn Diện Trình Xem Video Cinema Native Cho iOS
- **Loại bỏ xung đột giao diện**: Gỡ bỏ hoàn toàn thanh top bar đen tĩnh che khuất video, chuyển sang kiến trúc OSD (On-Screen Display) tự động ẩn sau 3.8 giây.
- **Thao tác chạm & cử chỉ chuẩn iOS (Cinema Gestures)**:
  - **Chạm 1 lần**: Ẩn/hiện bộ điều khiển OSD mượt mà.
  - **Chạm 2 lần (Double Tap)**:
    - Chạm nửa bên trái: Tua lùi 10s (`<< 10s`) kèm hiệu ứng ripple phát sáng và rung phản hồi `KLHaptics`.
    - Chạm nửa bên phải: Tua tới 10s (`10s >>`) kèm hiệu ứng ripple phát sáng.
  - **Kéo vuốt xuống (Swipe down to dismiss)**: Kéo nhẹ ngón tay từ trên xuống dưới để đóng trình phát ngay lập tức, đúng chuẩn tương tác iOS.
  - **Thu phóng hai ngón tay (Pinch to Zoom)**: Thu phóng giữa tỉ lệ **Gốc 16:9** (không bị crop) và **Tràn viền (Aspect Fill)** lấp đầy màn hình iPhone tai thỏ / Dynamic Island.
- **Bộ điều khiển trung tâm & Thanh thời gian (Scrubber)**:
  - Nút Play/Pause lớn nổi bật ở giữa với hiệu ứng kính mờ glassmorphism.
  - Đối với Phim VOD: Thanh kéo thời gian trực quan, hiển thị chi tiết thời lượng đã xem và thời gian còn lại.
  - Đối với Thể Thao & Truyền Hình: Huy hiệu `● TRỰC TIẾP` đỏ rực rỡ, nút chuyển đổi tỉ lệ màn hình và nút tắt/bật âm thanh.
- **Menu Đổi Server Chuẩn Native iOS**:
  - Tích hợp menu xổ xuống của iOS kèm dấu tích `✓` trên server đang phát, thao tác chuyển server mượt mà không dừng luồng.
- **Hỗ trợ AirPlay & Âm Thanh Chế Độ Im Lặng**:
  - Tích hợp sẵn nút phát **AirPlay** lên Apple TV / Smart TV.
  - Cấu hình chuẩn `AVAudioSession .playback` giúp video vẫn phát tiếng đầy đủ ngay cả khi iPhone đang gạt nút Rung / Im Lặng.

---

### 📦 Cài Đặt (iPhone / iPad — iOS 16.0+):
- Tải file `KenhLive-iOS.ipa` bên dưới và cài đặt qua **TrollStore**, **ESign**, **Scarlet**, **Feather**, **Sideloadly** hoặc **AltStore**.
