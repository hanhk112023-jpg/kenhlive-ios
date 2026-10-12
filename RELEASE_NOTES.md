# 🚀 KENHLIVE iOS v1.4.2 (Build 122) — SỬA TRIỆT ĐỂ LỆCH TIÊU ĐỀ & ỔN ĐỊNH 4 NHÀ ĐÀI

### ⚽ 1. Khắc Phục Triệt Để Lỗi Lệch Tiêu Đề Trận Đấu & Phòng Live Gà Vàng 33
- **Căn nguyên**: Gà Vàng 33 API trả về 57 trận, nhưng chỉ có **4 trận đang đá trực tiếp** (`matchStatus == "live"`), còn lại 53 trận là lịch thi đấu sắp tới (`scheduled`). Các BLV của Gà Vàng dùng link kênh stream cá nhân cố định và được gán cho nhiều trận. Khi ứng dụng nạp các trận tương lai (như 00:00 hoặc ngày mai), người dùng bấm vào thì stream lại đang phát trận đấu mà BLV đang bình luận trực tiếp hiện tại, dẫn đến tiêu đề một đằng nhưng phát một nẻo.
- **Khắc phục**:
  - Lọc nghiêm ngặt: Chỉ lấy các trận **`matchStatus == "live"`** vào danh mục phát trực tiếp.
  - Mỗi phòng phát đúng link stream của BLV trận đó từ hạ tầng `zktsva.app` `.m3u8`, lọc bỏ tên miền lỗi chứng chỉ SSL `gvvsb.com`.
  - Khớp 100% giữa tiêu đề trận đấu, logo 2 đội và nội dung video trên sân.

---

### 🥤 2. Khắc Phục Hoàn Toàn Đài ColaTV
- **Căn nguyên**: Nguồn M3U của ColaTV chứa 3 luồng cho mỗi trận: `[flv]`, `[hls]` (`zhwpg.app` sống, tốc độ cao) và `[hls 2]` (`miekgo.app` chết/timeout). Trước đây app nạp cả tên miền chết và các trận chưa đá (không có chấm xanh `🟢`), khiến nhiều trận khi bấm vào bị treo xoay tròn hoặc không tải được luồng.
- **Khắc phục**:
  - Viết parser chuyên dụng cho ColaTV: Lọc nghiêm ngặt các trận có chấm xanh **`🟢` (Đang phát sóng trực tiếp)**.
  - Chỉ nhận luồng HLS `.m3u8` từ máy chủ sống `zhwpg.app`, loại bỏ 100% tên miền chết `miekgo.app` và định dạng `.flv`.
  - Trích xuất tự động tên 2 đội bóng, logo giải đấu và tên BLV Cola (`BLV 7UP`, `BLV FANTA`, `BLV ROCKSTAR`, `BLV SODA`, `BLV PEPSI`).

---

### ⏰ 3. Tối Ưu Hóa & Ổn Định Đài Giờ Vàng TV
- **Căn nguyên**: Trước đây app chỉ nạp danh sách trận từ `live.json` và để trống link stream, đợi người dùng bấm vào mới gọi tiếp API phân giải. Nếu mạng chậm hoặc API phản hồi trễ, player bị trống link và báo lỗi.
- **Khắc phục**:
  - Dùng **Swift TaskGroup** nạp song song chi tiết tất cả các trận đang live ngay lúc mở tab (chỉ mất ~0.5s).
  - Gán sẵn link trực tiếp HLS `.m3u8` từ hạ tầng VCDN Cloud (`vcdn.cloud`) và tên BLV chuẩn (`BLV Chồn`, `BLV Trĩ`, `BLV Tôm`...) vào từng phòng đấu.
  - Bấm vào là phát tức thì trong 0.05s, không còn độ trễ.

---

### 📺 4. Tăng Cường Trình Phát HLS (`HLSPlayerView`)
- Thêm giao diện thông báo lỗi trực quan và nút **"THỬ KẾT NỐI LẠI"** khi luồng phát bị gián đoạn mạng.
- Tự động dọn dẹp bộ nhớ và giải phóng tài nguyên AVPlayer khi đóng trình phát.

---

### 📦 Cài Đặt (iPhone / iPad — iOS 16.0+):
- Tải file `KenhLive-iOS.ipa` bên dưới và cài đặt qua **TrollStore**, **ESign**, **Scarlet**, **Feather**, **Sideloadly** hoặc **AltStore**.
