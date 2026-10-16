# 🚀 KENHLIVE iOS v1.6.5 (Build 137) — GIAO DIỆN CINEMA NETFLIX CHUẨN ĐIỆN ẢNH THEO MẪU THIẾT KẾ MỚI

### 🌟 1. Billboard Hero Tràn Viền Chuẩn Cinematic (410pt)
- **Banner lớn nổi bật**: Áp dụng hiệu ứng chuyển dốc bóng mờ điện ảnh đa tầng (`Multi-Layer Cinema Scrim Gradient`), hình ảnh phim bao phủ toàn bộ phần đỉnh màn hình.
- **Typography & Huy hiệu thông tin**:
  - Tiêu đề phim chữ đậm bo tròn chuẩn rạp chiếu phim (`size: 26, weight: heavy`).
  - Phụ đề tên gốc tiếng Anh thanh lịch.
  - Hàng huy hiệu viên thuốc: **Năm phát hành**, **Huy hiệu vàng IMDb**, và **Huy hiệu 4K (PĐ-TM)**.
- **Nút bấm "Xem chi tiết"**: Nút con nhộng màu trắng sang trọng mở ngay bảng danh sách tập phim và thông tin phát.
- **Cụm 7 chấm phân trang (Carousel Dots)**: Tự động cuộn và cho phép vuốt chạm chuyển đổi giữa các tác phẩm điện ảnh hot nhất.

---

### 🎨 2. Khối Bộ Sưu Tập Vũ Trụ "Bạn đang quan tâm gì?"
- Thiết kế thẻ ngang bo góc 18pt với gradient rực rỡ riêng biệt:
  - **Marvel** (Tím huyền bí · 32 phim)
  - **IMDb Top 100 Movies** (Cam đỏ · 52 phim)
  - **DC Comic** (Xanh cobalt · 39 phim)
  - **Hoạt Hình & Anime** (Xanh ngọc · 48 phim)
  - **Chiếu Rạp Bom Tấn** (Hổ phách · 48 phim)
  - **K-Drama Hot** (Hồng neon · 48 phim)
  - **Cổ Trang Trung Quốc** (Đỏ rượu vang · 48 phim)
- Nút mũi tên tròn `>` cho phép truy cập nhanh toàn bộ kho phim.

---

### 🏆 3. Kệ Xếp Hạng "Top tuần" (Weekly Leaderboard)
- **Số thứ tự khổng lồ (#1, #2, #3...)**: Phông chữ siêu đậm bóng đổ chìm phong cách bảng xếp hạng điện ảnh quốc tế.
- **Poster dọc tỷ lệ vàng 2:3**: Tích hợp thời lượng phim (⏱ 120), nhãn chất lượng Full HD / 4K, năm phát hành, điểm đánh giá sao và huy hiệu vàng IMDb.

---

### 🎬 4. Các Kệ Phim Chuyên Mục & Hệ Thống Đã Kiểm Chứng
- Duy trì 100% tính năng cốt lõi: Tự động khóa xoay ngang chuẩn Netflix, không trùng âm thanh, chuyển tập tức thì trực tiếp trên player, cache 0ms cho tất cả danh mục thể loại.

---

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