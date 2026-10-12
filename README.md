# KenhLive iOS — Trực Tiếp Thể Thao, IPTV & Kho Phim Cho iPhone

Ứng dụng OTT đa năng thuần Native Swift/SwiftUI dành riêng cho iPhone, kế thừa trọn vẹn 6 phân hệ cốt lõi từ KenhLive TV với phong cách thiết kế **Apple Glassmorphism tối giản, typography-driven (ít dùng icon)**.

---

### 🌟 Tính Năng Nổi Bật

1. **Trực Tiếp Thể Thao (Live Sports):**
   - 4 đường ray tách biệt hoàn toàn: **Socolive, ColaTV, Gà Vàng, Khán Đài**.
   - Hero Spotlight trận cầu tâm điểm với nút chuyển trận trực tiếp.
   - Chọn phòng bình luận viên (BLV), hiển thị cấp độ và lượt xem trực tiếp.
   - Tự động lọc sạch các nội dung quảng cáo nhóm VIP / Zalo từ nguồn phát.
2. **Lịch Thi Đấu (Schedule EPG):**
   - Lịch thi đấu 7 ngày liên tục với bộ lọc ngày mượt mà.
   - Cập nhật tỷ số trực tiếp, trạng thái trận đấu (*Đang đá, Sắp đá, Kết thúc*).
3. **Truyền Hình Kênh TV (IPTV):**
   - Đầy đủ kênh VTV, HTV, VTC, kênh thể thao, giải trí và tin tức.
   - Khung phát thử trực tiếp (Inline Live Preview) ngay đầu trang.
   - Nhấn giữ để lưu/bỏ lưu kênh yêu thích.
4. **Kho Phim Điện Ảnh (Cinema VOD Hub):**
   - Hơn 33.400+ đầu phim Nguồn C & Anime vietsub/thuyết minh.
   - Hero Spotlight tỷ lệ 16:9 kèm điểm IMDb vàng hổ phách (`★ 9.0 IMDb`).
   - Nút `Đổi Phim` chuyển đổi 8 phim nổi bật tại chỗ.
   - Hàng *Tiếp Tục Xem* ghi nhớ tiến độ chính xác từng giây.
   - Bảng chọn tập phim mượt mà.
5. **Đa Màn Hình (MultiView):**
   - Xem đồng thời 2 trận đấu / 2 kênh truyền hình cùng lúc trên iPhone.
   - Tự động xếp dọc khi cầm máy dọc, chia đôi ngang khi xoay máy ngang.
   - Chạm vào ô nào để bật tiếng ô đó.
6. **Tìm Kiếm & Cài Đặt:**
   - Tìm kiếm tức thì đồng thời trận đấu, kênh TV và phim ảnh.
   - Tùy chỉnh chất lượng phát (`Tự động FHD`, `1080p`, `720p`).
   - Xóa bộ nhớ đệm và liên hệ hỗ trợ Telegram `@T990512S`.

---

### 📲 Hướng Dẫn Cài Đặt File `.ipa`

File `.ipa` của KenhLive iOS được đóng gói chuẩn không khóa chứng chỉ, bạn có thể cài đặt dễ dàng qua các công cụ phổ biến:

* **Sideloadly (Khuyên dùng qua PC/Mac):** Kéo thả file `KenhLive-iOS.ipa` vào Sideloadly, nhập Apple ID để ký chứng chỉ 7 ngày miễn phí.
* **TrollStore (iOS 14.0 - 16.6.1 & 17.0):** Cài trực tiếp vĩnh viễn không cần gia hạn chứng chỉ.
* **AltStore / Scarlet / ESign:** Mở file `.ipa` trực tiếp trong ứng dụng để cài đặt.

---

### 🛠️ Xây Dựng Dự Án (Build from Source)

```bash
# Cài đặt XcodeGen
brew install xcodegen

# Tạo file .xcodeproj
xcodegen generate

# Mở dự án trong Xcode
open KenhLive.xcodeproj
```
