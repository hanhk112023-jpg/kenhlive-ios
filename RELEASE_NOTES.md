# 🚀 KENHLIVE iOS v1.6.4 (Build 136) — SỬA TRIỆT ĐỂ LỖI BẤM TAB DANH MỤC PHIM (HOẠT HÌNH, PHIM BỘ, PHIM LẺ...)

### 🎯 1. Khắc Phục Triệt Để Lỗi Bấm Tab Thể Loại Phim (`Theme.swift` & `PhimView.swift`)
- **Khắc phục lỗi nuốt cử chỉ chạm (Gesture Cancellation)**:
  - Trước đây thanh lọc danh mục (`KLFilterStrip`) sử dụng `KLScaleButtonStyle` với hiệu ứng co giãn nút, dẫn đến việc cử chỉ cuộn ngang của `ScrollView` trên iOS chặn và nuốt mất lệnh bấm của người dùng khi ngón tay xê dịch nhẹ.
  - **Khắc phục**: Chuyển style nút bấm sang `.buttonStyle(.plain)` và tích hợp callback điều hướng trực tiếp `onSelect`, giúp mọi thao tác bấm tab như **"Hoạt Hình & Anime"**, **"Phim Bộ"**, **"Phim Lẻ"**, **"Hàn Quốc"**, **"Trung Quốc"**, **"Âu Mỹ"**, v.v. phản hồi 100% tức thì ngay khi chạm.
- **Nạp bộ nhớ đệm 0ms (Instant Cache Hit)**:
  - Khi mở ứng dụng, toàn bộ danh mục thể loại (bao gồm Hoạt Hình & Anime) được tự động nạp sẵn vào RAM (`cachedCategoryFilms`). Khi người dùng bấm chuyển tab, danh sách phim hiển thị ngay lập tức với độ trễ 0ms.
- **Hiệu ứng Skeleton Loading trực quan**:
  - Khi nạp dữ liệu mới, hiển thị lưới 12 khung hình Skeleton xám nhấp nháy tạo phản hồi thị giác tức thời, không còn tình trạng đứng yên hay trống màn hình.

---

### 🎬 2. Trình Phát Toàn Màn Hình Tự Động Khóa Xoay Ngang Chuẩn Netflix (`HLSPlayerView.swift`)
- Bấm vào bất kỳ tập phim nào sẽ phóng thẳng vào chế độ toàn màn hình và tự động xoay ngang thiết bị (`OrientationManager.lockLandscape()`).
- Tích hợp cụm nút chuyển tập **"◀ Tập Trước"** và **"Tập Kế Tiếp ▶"** ngay trong trình phát.
- Ngăn kéo chọn tập nhanh `TẬP (x/y)` cho phép chuyển tập mượt mà mà không cần thoát ra ngoài.
- Tự động chuyển tập kế tiếp khi xem hết một tập.

---

### 📦 Cài Đặt (iPhone / iPad — iOS 16.0+):
- Tải file `KenhLive-iOS.ipa` bên dưới và cài đặt qua **TrollStore**, **ESign**, **Scarlet**, **Feather**, **Sideloadly** hoặc **AltStore**.