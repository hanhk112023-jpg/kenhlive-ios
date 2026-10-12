# 🚀 KENHLIVE iOS v1.4.1 (Build 121) — TỐI ƯU GIAO DIỆN ĐIỆN THOẠI & SỬA LỖI VĂNG APP

### 🛠️ 1. Khắc Phục Triệt Để Lỗi Văng App (Crash Fix)
- **Sửa lỗi `String index out of bounds`** trong bộ phân tích luồng M3U thể thao (`SportsService.parseTitleAndBLV`) khi tách tên BLV ở cuối dòng tiêu đề.
- **Loại bỏ xung đột ID trùng lặp** trên `LazyVGrid` và `ForEach` của danh sách kênh IPTV (`IptvChannel`), lịch thi đấu (`ScheduleItem`) và danh sách tập phim (`EpisodeItem`).
- **Tối ưu tốc độ nạp Giờ Vàng TV**: Tách luồng phân giải VCDN Cloud sang thời điểm bấm phát, giúp danh sách trận đấu nạp tức thì trong `0.1s` thay vì phải chờ tuần tự.
- **Chuyển sang thanh điều hướng `TabView` gốc của iOS**: Giữ nguyên trạng thái bộ nhớ của từng phân khu khi chuyển tab, chống giải phóng bộ nhớ đột ngột và tương thích hoàn toàn với thanh Home Bar trên iPhone.

---

### 📱 2. Thiết Kế Lại Giao Diện Chuẩn Điện Thoại (Mobile-First UI)
- **Thanh Tab Bar Chuẩn Apple HIG (5 Tab Có Biểu Tượng SF Symbols)**:
  - 🏠 **Trang Chủ**: Cổng chọn gọn gàng với 3 phân khu (Thể Thao, Truyền Hình, Kho Phim), dải *Trận Cầu Tâm Điểm* và *Phim Thịnh Hành* ngay trên màn hình chính.
  - ⚽ **Thể Thao**: 4 nhà đài độc lập (*Socolive · Gà Vàng 33 · ColaTV · Giờ Vàng TV*).
  - 📺 **Truyền Hình**: Kênh VTV, HTV, THVL, Thể thao FHD với màn hình xem thử trực tiếp.
  - 🎬 **Kho Phim**: Giao diện **Netflix Cinema** với Billboard Hero, nhãn `TOP 10`, `98% Phù Hợp`, nút Play trắng và poster tỷ lệ 2:3.
  - ⚙️ **Hệ Thống**: Tìm kiếm nhanh, chỉnh chất lượng video, dọn bộ nhớ đệm và liên hệ Telegram.
- **Thanh Header Gọn Nhẹ**: Nút mở nhanh **2 Màn Hình** và **Báo Lỗi Telegram (`@T990512S`)** kèm mã QR sắc nét.

---

### 📦 Cài Đặt (iPhone / iPad — iOS 16.0+):
- Tải file `KenhLive-iOS.ipa` bên dưới và cài đặt qua **TrollStore**, **ESign**, **Scarlet**, **Feather**, **Sideloadly** hoặc **AltStore**.
