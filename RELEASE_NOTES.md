# 🚀 KENHLIVE iOS v1.5.2 (Build 130) — TỐI ƯU TỐC ĐỘ NẠP KHO PHIM, LƯU & XEM TIẾP CHÍNH XÁC TỪNG GIÂY VÀ TRÌNH PHÁT INLINE 16:9

### ⚡ 1. Tối Ưu Tốc Độ Nạp Kho Phim Tức Thì (Instant Cache & Progressive Load)
- **Bộ nhớ đệm siêu tốc (In-Memory Cache)**: Kho phim giờ đây mở trong **0.00 giây** nếu đã truy cập trước đó nhờ lớp cache bộ nhớ an toàn đa luồng.
- **Tải dần thông minh (Progressive Staged Loading)**:
  - Khi mở tab Phim lần đầu, ứng dụng lập tức tải trước 2 hàng phim quan trọng nhất (*Phim Mới Cập Nhật* và *Phim Bộ Đặc Sắc*) trong **~0.2 giây** để hiển thị giao diện ngay lập tức mà không để người dùng phải chờ đợi.
  - Các hàng phim tiếp theo (*Phim Lẻ, Anime, Hàn Quốc, Cổ Trang...*) được nạp ngầm bất đồng bộ và tự động chèn vào danh sách cực kỳ mượt mà.
- **Giới hạn thời gian kết nối (Fast Timeout)**: Không còn hiện tượng xoay tròn vô tận khi mạng chập chờn.

---

### ⏱️ 2. Lưu & Xem Tiếp Phim Chuẩn Xác Từng Giây (Real-Time Resume & Episode Tracking)
- **Tua đúng vị trí đã xem khi bấm "Xem Tiếp"**:
  - Truyền trực tiếp thời gian dừng chính xác (`initialTimeSeconds`) vào trình phát AVPlayer gốc để video nhảy ngay đến đúng phân cảnh đang xem dở, **chấm dứt hoàn toàn lỗi phát lại từ đầu 00:00**.
- **Lưu tiến trình thời gian thực (Live Progress Sync)**:
  - Tự động ghi nhận vị trí xem thực tế từ trình phát mỗi 0.5 giây và ngay trước khi đóng màn hình, lưu trọn vẹn số tập và thời lượng vào `StorageManager`.
- **Thẻ "Tiếp Tục Xem" thông minh**:
  - Khi mở bất kỳ bộ phim nào đã từng xem, ứng dụng hiển thị ngay thẻ nhắc nhở nổi bật: *"Đang xem dở tập X - Dừng tại mm:ss"* kèm nút **"XEM TIẾP"** bấm 1 phát là vào xem ngay.

---

### 📱 3. Trình Phát Inline 16:9 Linh Hoạt — Không Còn Ép Buộc Toàn Màn Hình
- **Xem phim dạng Inline 16:9 tại trang chi tiết (Chuẩn YouTube / Netflix Mobile)**:
  - Khi bấm chọn tập hoặc "Phát ngay", video sẽ phát mượt mà tại **khung 16:9 ở phần trên cùng của trang chi tiết**.
  - Phần bên dưới vẫn hiển thị đầy đủ thông tin phim, mô tả nội dung, máy chủ Vietsub/Thuyết minh và **toàn bộ danh sách tập**.
  - Người dùng có thể vừa xem tập 1 vừa cuộn xem danh sách tập khác, hoặc bấm chuyển sang tập 2, tập 3 ngay lập tức mà không bị ngắt quãng.
  - Tập đang phát được làm nổi bật với viền cam phát sáng và biểu tượng sóng nhạc chuyển động `waveform`.
- **Nút Phóng Toàn Màn Hình (Expand to Fullscreen `⛶`) Chủ Động**:
  - Khi muốn xem đắm chìm toàn màn hình, người dùng chỉ cần bấm nút góc phải dưới trình phát để mở toàn màn hình (kèm đầy đủ cử chỉ tua ±10s, pinch zoom tràn viền, vuốt xuống để đóng).
  - Bấm thu nhỏ sẽ trở lại ngay trang chi tiết mà không làm gián đoạn luồng phát.

---

### 📦 Cài Đặt (iPhone / iPad — iOS 16.0+):
- Tải file `KenhLive-iOS.ipa` bên dưới và cài đặt qua **TrollStore**, **ESign**, **Scarlet**, **Feather**, **Sideloadly** hoặc **AltStore**.
