# 🚀 KENHLIVE iOS v1.6.3 (Build 135) — ĐẠI TU TOÀN DIỆN MỤC PHIM & NÂNG CẤP TRÌNH PHÁT CINEMA PLAYLIST

### 🎬 1. Khắc Phục Triệt Để Toàn Bộ Lỗi Phần Phim (`EpisodePickerSheet.swift`)
- **Xóa bỏ hoàn toàn Mini Player 220pt chạy ngầm**:
  - Loại bỏ hoàn toàn trình phát thu nhỏ inline gây lỗi phát trùng 2 nguồn âm thanh (audio double/echo) và xung đột điều hướng.
  - Khi người dùng bấm **"XEM PHIM NGAY"**, **"XEM TIẾP"** hoặc bấm vào **bất kỳ tập phim nào trong lưới**, app sẽ **phóng thẳng vào Cinema Player Toàn Màn Hình** (`HLSPlayerView`).
- **Tự động khóa xoay ngang màn hình chuẩn điện ảnh**:
  - Tích hợp `OrientationManager.lockLandscape()` tự động xoay ngang thiết bị (`UIWindowScene.requestGeometryUpdate`), mang lại trải nghiệm xem phim Netflix chuẩn rạp.
  - Khi bấm đóng player hoặc vuốt xuống, app tự động trả lại màn hình dọc gọn gàng.
- **Hỗ trợ chọn Server & Nhóm Tập mượt mà**:
  - Đổi server Vietsub, Thuyết Minh, Lồng Tiếng dễ dàng.
  - Phân nhóm 30 tập/tab cho các bộ phim dài (Conan, One Piece, v.v.).
  - Đánh dấu tập đã xem với biểu tượng tích xanh `✓` chuẩn xác.

---

### 📺 2. Trình Phát Hỗ Trợ Đổi Tập Trực Tiếp Trong Player (`HLSPlayerView.swift`)
- **Nút "Tập Kế Tiếp ▶" và "◀ Tập Trước"**:
  - Người dùng có thể chuyển tập nhanh chóng ngay trên thanh điều khiển OSD mà không cần phải thoát ra menu ngoài.
- **Ngăn Kéo Danh Sách Tập (In-Player Episode Drawer)**:
  - Bấm vào nút `TẬP (x/y)` ở góc trên để mở danh sách toàn bộ các tập ngay khi đang xem ở chế độ ngang.
- **Tự động chuyển tập tiếp theo**:
  - Khi xem hết một tập, trình phát tự động nhận diện `AVPlayerItemDidPlayToEndTime` và chuyển tiếp sang tập kế tiếp.

---

### 🔍 3. Tối Ưu Tìm Kiếm & Nạp Luồng Phim Chuẩn RFC 3986 (`PhimService.swift`)
- Chuẩn hóa URL mã hóa bằng `URLComponents`, khắc phục triệt để lỗi tìm kiếm các phim có khoảng trắng hoặc dấu tiếng Việt như *"One Piece"*, *"Lật Mặt"*, *"Tây Du Ký"*.
- Thêm cơ chế tự động bóc tách link `.m3u8` trực tiếp từ link embed nếu server chưa trả về direct stream.
- Cơ chế fallback an toàn giữa `thumb_url` và `poster_url`, không còn hiện tượng trắng ảnh poster.
- Giới hạn thời gian chờ request (timeout 10s) chống treo giật giao diện khi mạng kém.

---

### 📦 Cài Đặt (iPhone / iPad — iOS 16.0+):
- Tải file `KenhLive-iOS.ipa` bên dưới và cài đặt qua **TrollStore**, **ESign**, **Scarlet**, **Feather**, **Sideloadly** hoặc **AltStore**.