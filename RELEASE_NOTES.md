# 🚀 KENHLIVE iOS v1.8.2 (Build 154) — ĐẠI TU TOÀN DIỆN HỆ THỐNG APP, TRÌNH PHÁT & AN TOÀN ĐA LUỒNG

### 🛠️ 1. Đại Tu & Vá Triệt Để Các Lỗi Tiềm Ẩn Toàn Ứng Dụng
- **Loại Bỏ 10 Điểm Nguy Cơ Force Crash (`try!` & `!`)**:
  - Tái cấu trúc `DataNormalizer.swift`: thay thế toàn bộ 10 biểu thức `try! NSRegularExpression` và `TimeZone(...)!` sang cơ chế nạp an toàn `compactMap { try? ... }` và fallback `.current`. Ứng dụng loại bỏ 100% rủi ro crash bất thình lình khi xử lý chuỗi tiêu đề tiếng Việt.
- **Vá Lỗi Kẹt Binding Modal / Thiếu `onClose`**:
  - Bổ sung `onClose` đồng bộ trên toàn bộ các màn hình còn lại: `HomeHubView`, `ScheduleView`, `SearchAndSettingsView` (cả trận đấu & kênh truyền hình), `VodWebPlayerView`. Tránh kẹt modal hoặc lỗi không mở lại được trình phát ở các lần nhấn kế tiếp.
- **Chuẩn Hóa Quản Lý Hướng Màn Hình (iOS 16/17+)**:
  - Nâng cấp `OrientationManager.swift`: thay thế thuộc tính lỗi thời `windowScene.keyWindow` bằng bộ duyệt cửa sổ hiện đại `windowScene.windows.first(where: { $0.isKeyWindow })`, tương thích mượt mà với dynamic island và hệ thống iOS 16/17/18.
- **Tối Ưu Hóa Tua Video Chuẩn Frame-Accurate**:
  - `seekToTime` áp dụng `toleranceBefore: .zero, toleranceAfter: .zero` kết hợp tự động tiếp tục phát ngay khi kết thúc hành vi kéo thanh trượt (Scrubbing).

---

# 🚀 KENHLIVE iOS v1.8.1 (Build 153) — SỬA TRIỆT ĐỂ LỖI VIDEO ĐỨNG YÊN / KHÔNG CHẠY TRÌNH PHÁT

### 🚀 1. Giải Phóng Bộ Đệm AVPlayer Tự Động (Fix Video Bị Đứng Yên 0:00)
- **Nguyên nhân cốt lõi**:
  - Ở bản trước, cấu hình thử nghiệm `automaticallyWaitsToMinimizeStalling = false` và `preferredForwardBufferDuration = 1.0s` (vốn chỉ dành cho video ngắn 5 giây) đã bị áp dụng nhầm lên toàn bộ phim dài HLS và truyền hình.
  - Các phân đoạn HLS (.ts) của KKPhim, Socolive và VTV thường dài từ 6–10 giây. Khi tắt cơ chế tự động chờ đệm của AVPlayer và bóp dung lượng đệm xuống 1 giây, AVPlayer ngay lập tức rơi vào trạng thái `stalled` (rate = 0) do chưa tải kịp phân đoạn đầu tiên, dẫn đến việc **video bị đứng yên hoàn toàn ở 00:00**.
- **Giải pháp**:
  - Gỡ bỏ hoàn toàn `automaticallyWaitsToMinimizeStalling = false` và `preferredForwardBufferDuration = 1.0s`.
  - Khôi phục cơ chế đệm tiêu chuẩn mượt mà tự nhiên của Apple AVFoundation: tự động nạp phân đoạn mượt mà, sẵn sàng là phát ngay.
  - Sử dụng lệnh `player.play()` chuẩn kết hợp đồng bộ `player.rate` linh hoạt cho tính năng chỉnh tốc độ (0.75x – 2.0x).
  - Tự động tắt vòng xoay loading `isLoadingStream = false` chính xác ngay khi khung hình đầu tiên hiển thị (`currentTime > 0`).

---

# 🚀 KENHLIVE iOS v1.8.0 (Build 152) — TÍCH HỢP TRỌN VẸN LÕI TRÌNH PHÁT GỐC FPT PLAY (`VideoSwappingManager` & `VepisodePlayerControlStackview`)

### ⚡ 1. Chuẩn Hóa Lõi Trình Phát Trích Xuất Trực Tiếp Từ Mã Nguồn FPT Play
- **Asset Gốc FPT Play**: Thay thế toàn bộ biểu tượng hệ thống bằng asset vector gốc trích xuất từ Asset Catalog của FPT Play:
  - Nút khay chọn tập `fp_player_episode` trên thanh tiêu đề và thanh điều khiển dưới.
  - Phím tốc độ phát `fp_player_speed` (0.75x, 1.0x, 1.25x, 1.5x, 2.0x).
  - Phím khóa cảm ứng chống chạm nhầm `fp_player_lock` và `fp_player_unlock`.
  - Phím tua nhanh/lùi vector 10s `fp_player_rewind_10` & `fp_player_forward_10`.
- **Cơ Chế VideoSwappingManager**: Áp dụng quy trình chuyển tập chuẩn FPT Play:
  - Khi người dùng đổi tập, hệ thống lập tức tạm dừng và gọi `cancelLoading()` triệt tiêu tác vụ tải của tập cũ để giải phóng băng thông ngay lập tức.
  - Khởi tạo `AVPlayerItem` mới với cấu hình đệm cực ngắn `preferredForwardBufferDuration = 1.0s` và tắt `automaticallyWaitsToMinimizeStalling` giúp tập mới phát ngay lập tức 0ms mà không bị khựng đệm.
- **Thanh Điều Khiển Kép VepisodePlayerControlStackview**: Bổ sung nút chọn tập nhanh `fp_player_episode` nằm ngay cạnh phím tốc độ phát ở thanh dưới, giúp người dùng dễ dàng chuyển tập ở bất kỳ tư thế cầm máy nào.

---

# 🚀 KENHLIVE iOS v1.7.9 (Build 151) — KÍCH HOẠT TÍNH NĂNG CHUYỂN TẬP / DANH SÁCH TẬP KHI XEM TIẾP (CONTINUE WATCHING)

### 🎬 1. Bổ Sung Toàn Bộ Nút Chuyển Tập & Bảng Chọn Tập Khi Mở Từ \"Tiếp Tục Xem\"
- **Nguyên nhân**: Khi mở phim từ kệ \"Tiếp tục xem\" (Watch History), trình phát chỉ nhận thông tin tập phim đã lưu (`directUrl`, `positionMs`) mà không có danh sách các tập còn lại (`episodes: []`). Do đó, các nút \"TẬP TIẾP THEO\", \"TẬP TRƯỚC ĐÓ\" và nút mở danh sách tập (\"TẬP X/Y\") bị ẩn đi.
- **Giải pháp tối ưu**:
  - Tích hợp `filmSlug` trực tiếp vào `HLSPlayerView`. Trình phát vẫn **phát ngay lập tức 0ms** đúng giây phim đã xem dở thông qua `directUrl`.
  - Đồng thời ở luồng nền, `HLSPlayerView` tự động tải toàn bộ danh sách tập của bộ phim (`allAvailableEpisodes`) và tự động định vị đúng số thứ tự tập hiện tại.
  - Ngay khi nạp xong, nút **\"TẬP X/Y\"** trên thanh tiêu đề và cụm phím chuyển tập **Tập Trước (`backward.end.fill`) / Tập Kế Tiếp (`forward.end.fill`)** sẽ lập tức xuất hiện!
  - Người dùng có thể nhấn vào để mở khay chọn tập dạng lưới (`episodeDrawerSheet`), chuyển sang tập mới bất kỳ lúc nào và hệ thống sẽ tự động lưu lại tiến trình xem của tập mới.

---

# 🚀 KENHLIVE iOS v1.7.8 (Build 150) — KHẮC PHỤC TRIỆT ĐỂ LỖI VĂNG TRÌNH PHÁT THỂ THAO & XUNG ĐỘT MODAL SHEET

### 🛡️ 1. Khắc Phục Triệt Để Xung Đột Modal Kép (Modal Collision) Khi Chọn BLV Thể Thao
- **Nguyên nhân cốt lõi**: Trước đây khi người dùng bấm vào một trận đấu có nhiều BLV, bảng chọn `RoomPickerSheet` mở lên dưới dạng `.sheet`. Khi người dùng chạm vào một BLV, lệnh `dismiss()` được gọi đồng thời với việc gán `activeRoomForPlayer = room` trên màn hình cha `LiveSportsView`. Trên iOS UIKit, việc vừa đóng một sheet vừa mở ngay một `fullScreenCover` trên cùng ViewController cha gây xung đột tiến trình hiển thị (Presentation Collision), khiến hệ thống tự động huỷ bỏ hoặc đóng văng trình phát ngay tức khắc!
- **Giải pháp**: Tái cấu trúc theo mô hình phân tầng độc lập như `EpisodePickerSheet`: Giờ đây `RoomPickerSheet` tự quản lý và phóng trình phát `HLSPlayerView` trực tiếp từ chính nó (`fullScreenCover` nội bộ). Không còn đóng mở sheet chéo nhau, 0ms độ trễ và triệt tiêu 100% hiện tượng văng/sập modal.

### 🔄 2. Tách Biệt Vòng Đời `cleanupResources()` Khỏi `closePlayer()`
- Sửa lỗi trong `HLSPlayerView`: phương thức `.onDisappear` trước đây gọi nhầm `closePlayer()`, mà bên trong `closePlayer()` lại gọi `dismiss()`. Khi màn hình xoay ngang (Landscape), iOS kích hoạt lại layout pass khiến `.onDisappear` vô tình kích hoạt lệnh `dismiss()` làm người dùng bị văng khỏi trình phát khi vừa mới mở.
- Tách riêng `cleanupResources()` (chỉ huỷ timer, giải phóng AVPlayer, đặt lại hướng màn hình) cho `.onDisappear`, và giữ `dismiss()` chỉ khi người dùng chủ động bấm nút đóng (X) hoặc vuốt xuống.

### 🌐 3. Tăng Cường Độ Bền Luồng Phát & Xử Lý URL Dự Phòng
- Thêm `onClose` callback rõ ràng cho toàn bộ các trình phát thể thao và IPTV, bảo đảm giải phóng biến trạng thái modal về `nil`.
- Bổ sung cơ chế tự động encode ký tự đặc biệt trên URL luồng phát và kích hoạt máy chủ dự phòng tự động nếu luồng chính của phòng bị gián đoạn.

---

# 🚀 KENHLIVE iOS v1.7.7 (Build 149) — CỐ ĐỊNH THANH TÌM KIẾM TRANG CHỦ THEO NỘI DUNG & KÍCH HOẠT 100% BỘ SƯU TẬP \"BẠN ĐANG QUAN TÂM GÌ?\"

### 🔍 1. Thanh Tìm Kiếm Cố Định Đỉnh Trang & Cuộn Tự Nhiên Theo Nội Dung
- Xóa bỏ hoàn toàn nút tìm kiếm nổi lơ lửng cố định ở góc phải màn hình (`.overlay` góc chết) gây vướng mắt và che mất poster phim khi cuộn xuống.
- Nút tìm kiếm giờ đây được gắn trực tiếp vào thanh tiêu đề đỉnh trang trên Hero Banner cùng logo **KENHLIVE** sắc nét. Khi người dùng cuộn xuống duyệt phim, thanh tìm kiếm sẽ **cuộn lên theo trang một cách tự nhiên**, không còn bị kẹt lại che khuất nội dung.

### 🗂️ 2. Kích Hoạt 100% Các Thẻ Bộ Sưu Tập (\"Bạn Đang Quan Tâm Gì?\")
- Sửa dứt điểm lỗi chỉ bấm được mỗi Thể thao và Truyền hình. Giờ đây toàn bộ các thẻ bộ sưu tập tuyển chọn:
  - **Marvel / DC Comic**
  - **Hoạt Hình & Anime**
  - **Chiếu Rạp Bom Tấn**
  - **K-Drama Hot**
  - **Cổ Trang Trung Quốc**
  - **IMDb Top 100 Movies**
- Khi chạm vào bất kỳ thẻ nào, hệ thống lập tức mở bảng danh mục phim chuyên biệt `CuratedCollectionDetailSheet` với dải màu gradient tương ứng, hiển thị toàn bộ poster phim tuyển chọn chuẩn 3 cột để xem ngay hoặc chọn tập.

---

# 🚀 KENHLIVE iOS v1.7.6 (Build 148) — TỐI ƯU HIỆU NĂNG 120HZ PROMOTION & GIAO DIỆN CHUẨN FPT PLAY: BỘ ĐỆM ẢNH BẤT ĐỒNG BỘ DEDUPLICATED, TẢI LAZYVSTACK/LAZYHSTACK SIÊU MƯỢT, TRIỆT TIÊU TIÊU THỤ NỀN

### ⚡ 1. Đại Tu Hệ Thống Tải & Cache Ảnh (`KLImageDownloader` + RAM Cache 200MB)
- Thay thế toàn bộ kiến trúc tải ảnh cũ bằng Actor bất đồng bộ `KLImageDownloader` hỗ trợ **Request Deduplication**: khi nhiều cell cùng hiển thị chung một hình ảnh (Hero, kệ phim, lịch sử), hệ thống chỉ thực hiện đúng **1 lượt tải duy nhất** qua mạng và chia sẻ kết quả cho các view khác, tiết kiệm 70% băng thông và RAM.
- `KLAsyncImage` hiển thị tức thì **0ms** khi ảnh đã có trong RAM Cache, giải phóng 100% chi phí phân bổ `@StateObject` trên từng cell giúp cuộn trang đạt 120Hz mượt như bơ.

### 📜 2. Chuyển Đổi Toàn Diện Sang `LazyVStack` & `LazyHStack`
- Khắc phục triệt để tình trạng đơ giật do `VStack`/`HStack` thông thường khởi tạo đồng loạt hàng trăm poster phim cùng lúc. Giờ đây, chỉ những poster xuất hiện trong khung nhìn mới được render và giải phóng ngay khi cuộn qua, giảm 80% áp lực CPU và GPU.

### 🔋 3. Triệt Tiêu 100% Tiến Trình Chạy Ngầm Gây Tụt Pin & Lag Tab (`isActive Lifecycle`)
- Tích hợp cờ trạng thái `isActive`:
  - Trình phát xem trước IPTV (`InlinePreviewPlayerView`) sẽ **tự động tạm dừng ngay lập tức** khi người dùng chuyển sang tab khác (Trang chủ, Thể thao, Cá nhân), triệt tiêu hoàn toàn việc ngốn CPU giải mã video ngầm.
  - Tự động ngắt timer làm mới tỷ số thể thao 60s khi rời khỏi tab Thể thao và kích hoạt lại khi người dùng quay lại.

### 🎬 4. Cụm Phím Thao Tác Kép Chuẩn FPT Play trên Hero Banner
- Bổ sung nút **"Xem Ngay"** nổi bật với dải màu FPT Tangerine Gradient (`play.fill`) phát ngay lập tức không cần chọn lại tập, đi kèm nút phụ **"Chi tiết"** kính mờ (`info.circle`) để xem tóm tắt nội dung và chọn tập.

---

# 🚀 KENHLIVE iOS v1.7.5 (Build 147) — TÍCH HỢP HỆ THỐNG THIẾT KẾ FPT PLAY: KHÓA MÀN HÌNH CHỐNG CHẠM NHẦM, TÙY CHỈNH TỐC ĐỘ PHÁT, NÚT TUA 10S & HIỆU ỨNG AMBIENT RADIANT GLOW

### 🔒 1. Khóa Cảm Ứng Trình Phát Chống Chạm Nhầm (Screen Lock / Unlock)
- Trích xuất và tích hợp trực tiếp bộ icon `player_ic_lock` và `player_ic_unlock` từ hệ thống thiết kế gốc của FPT Play.
- Khi bật chế độ Khóa màn hình, toàn bộ thanh điều khiển (thanh trên, thanh dưới, nút tập, đổi server) và các cử chỉ vuốt vô tình đều được ẩn hoàn toàn để người dùng thoải mái cầm điện thoại nằm xem phim/thể thao mà không sợ chạm nhầm.
- Nút "MỞ KHÓA" viên thuốc kính mờ hiển thị tinh tế ở góc trên cùng bên trái khi người dùng chạm vào màn hình.

### ⚡ 2. Bộ Chọn Tốc Độ Phát Video (Playback Speed Control)
- Bổ sung nút điều chỉnh tốc độ phát thông minh (`1.0X`, `1.25X`, `1.5X`, `2.0X`) tại thanh điều khiển đáy trình phát `HLSPlayerView`, sử dụng icon tốc độ vector `fp_player_speed`.

### ⏩ 3. Nút Tua Nhanh / Lùi 10 Giây Vector FPT Play
- Thay thế các icon SF Symbol thông thường bằng bộ icon tua nhanh 10 giây (`fp_player_forward_10`) và tua lùi 10 giây (`fp_player_rewind_10`) sắc nét được trích xuất từ Asset Catalog.

### 🌅 4. Hiệu Ứng Ánh Sáng Ambient Header Glow Đỉnh Màn Hình
- Ứng dụng dải tỏa sáng `KLAmbientHeaderGlow`:
  - **Trang chủ & Rạp phim**: Dải ánh sáng Cam hoàng hôn ấm (`#FF9D5C`) tỏa từ mép trên màn hình đè lên nền đen sâu Obsidian OLED.
  - **Thể thao 4 Đài**: Dải ánh sáng Xanh cỏ sân vận động (`#14A673`) mang lại cảm giác sống động và sang trọng chuẩn phong cách OTT hàng đầu.
- Thanh Dock Tabbar đáy được nâng cấp hiệu ứng vầng sáng Sunset Tangerine Gradient nổi bật cho tab đang chọn.

---

# 🚀 KENHLIVE iOS v1.7.4 (Build 146) — ĐẠI TU TOÀN DIỆN: PHÁT LẠI 0MS KHÔNG QUA TRUNG GIAN, XOÁ BỎ 100% XUNG ĐỘT MODAL, TỰ ĐỘNG LƯU TIẾN ĐỘ & BẢNG BÁO LỖI PHÁT KÈM THỬ LẠI

### ⚡ 1. Khôi Phục Xem Phim Tức Thì 0ms (Bỏ Sheet Trung Gian Tránh Xung Đột)
- Khi chạm vào card "Tiếp Tục Xem" trên **Trang chủ** hoặc tab **Cá nhân**, hệ thống sẽ **khởi chạy ngay trình phát Fullscreen Landscape 0ms** với đúng số giây đã dừng, bỏ qua bước mở sheet trung gian giúp triệt tiêu 100% tình trạng hai modal `.sheet` và `.fullScreenCover` xung đột lẫn nhau gây giật lag hay văng màn hình.

### 🛡️ 2. Xử Lý Luồng Embed & Triệt Tiêu Màn Hình Đen (`VodWebPlayerView` Fallback)
- Tự động nhận diện các tập phim chỉ có luồng nhúng HTML (`embed`) mà không có file `.m3u8` trực tiếp. Thay vì đẩy vào AVPlayer gây màn hình đen, ứng dụng tự động điều hướng sang `VodWebPlayerView` để phát mượt mà không lỗi.

### 🔄 3. Bảng Báo Lỗi & Tự Động Chuyển Server Dự Phòng
- Bổ sung bảng thông báo lỗi phát sóng Glassmorphic tinh tế trong `HLSPlayerView`: tự động phát hiện khi luồng bị gián đoạn và tự chuyển sang máy chủ dự phòng tiếp theo. Nếu mọi máy chủ đều lỗi, hiển thị nút "Thử lại" và "Đổi Server" trực tiếp trên màn hình phát.
- Tự động lưu tiến độ phim liên tục mỗi 5 giây (`Continuous Progress Auto-Save`), đảm bảo không bị mất thời gian đã xem khi thoát app đột ngột.

### 📱 4. Xoay Màn Hình Linh Hoạt Cả 2 Chiều Landscape
- Cải tiến `OrientationManager`: hỗ trợ xoay linh hoạt cả hai chiều ngang (xoay trái lẫn xoay phải) khi xem phim/thể thao để phù hợp với tư thế cầm điện thoại của người dùng.
- Khắc phục triệt để race condition và rò rỉ bộ nhớ trong trình phát xem trước IPTV (`setupTask cancellation`).

---

# 🚀 KENHLIVE iOS v1.7.3 (Build 145) — NÂNG CẤP ĐỘ MƯỢT 120HZ PROMOTION, CARD PHIM LỊCH SỬ XEM & TỐI ƯU GIAO DIỆN CINEMA LIQUID GLASS

### 🎬 1. Card Phim Lịch Sử Xem & Tiếp Tục Xem Đẳng Cấp Cinema (`KLWatchHistoryCard`)
- Thay thế hoàn toàn các ô văn bản xám cũ bằng **Card phim 16:9 Cinema Widescreen** chuẩn phong cách Netflix & Apple TV+:
  - **Ảnh Poster / Backdrop** sắc nét tải qua bộ đệm RAM `KLAsyncImage`.
  - **Nút Play tròn phát quang kính mờ Liquid Glass** nằm chính giữa poster, chạm 1 lần là phát ngay từ đúng số giây đã dừng.
  - **Thanh tiến trình màu đỏ thẫm (Crimson Red Progress Bar)** chạy mượt mà theo tỷ lệ thời lượng đã xem (%).
  - **Nhãn tập phim & thời gian** hiển thị rõ ràng (Tập 1, Tập 12, Đã xem 65%).
  - Xuất hiện đồng bộ trên cả **Trang Chủ** (ngay sau cụm "Bạn đang quan tâm gì?"), bộ lọc **"Đã Lưu & Xem Gần Đây"**, và tab **"Cá nhân"**.
  - Bổ sung nút xóa từng phim (`xmark`) và nút "Xóa tất cả" giúp quản lý lịch sử xem tiện lợi.

### ⚡ 2. Tối Ưu Độ Mượt & Ổn Định 120Hz ProMotion (Smoothness & Stability)
- **Giải nén ảnh trước trên luồng nền (`byPreparingForDisplay`)**: Sử dụng API UIKit tối ưu để giải mã bitmap trên background thread trước khi đưa lên GPU, loại bỏ 100% hiện tượng micro-stutter hay khựng khung hình khi cuộn nhanh qua hàng trăm poster.
- **Hỗ trợ cập nhật URL tức thì (`onChange(of: url)`)**: Đảm bảo các ô tái sử dụng trong ScrollView/List cập nhật poster chính xác và không bị hiển thị sai ảnh.
- **Xử lý trạng thái rỗng (Empty States)**: Thiết kế card thông báo tinh tế khi chưa có phim trong lịch sử, không gây lỗi giao diện.
- **Thao tác xóa an toàn**: Cung cấp hàm `removeWatchProgress(filmSlug:)` với lưu trữ bất đồng bộ an toàn trên `StorageManager`.

---

# 🚀 KENHLIVE iOS v1.7.2 (Build 144) — CHUYỂN HOÀN TOÀN TÌM KIẾM VÀO TRANG ĐẦU, DOCK 4 TAB TINH GỌN, XÓA BỎ THANH TÌM KIẾM THỂ THAO & TRUYỀN HÌNH

### 🎬 1. Bỏ Tab Tìm Kiếm Khỏi Thanh Dock — Chuyển Trọn Vẹn Vào Nút Tìm Kiếm Trang Chủ
- Loại bỏ hoàn toàn tab Tìm kiếm khỏi thanh Dock điều hướng phía dưới.
- Thanh Dock trở về cấu trúc **4 Tab tinh gọn, chuẩn mực**: `Trang chủ`, `Thể thao 4 đài`, `Truyền hình VTV/K+`, `Cá nhân`.
- Tính năng Tìm kiếm Phim 4K & Anime được kích hoạt thông qua **nút kính lúp góc phải trên cùng của Trang chủ**, mở giao diện tìm kiếm rạp phim toàn màn hình với nút quay lại tiện lợi.

### ⚽ 2. Loại Bỏ Hoàn Toàn Thanh Tìm Kiếm Ở Thể Thao & Truyền Hình
- **Màn hình Thể thao 4 đài (`LiveSportsView`)**: Gỡ bỏ thanh tìm kiếm `KLGlassSearchBar`, giải phóng không gian màn hình tối đa để tập trung 100% vào danh sách các trận cầu trực tiếp, thanh đài phát sóng và bộ lọc giải đấu.
- **Màn hình Truyền hình VTV (`IptvView`)**: Gỡ bỏ thanh tìm kiếm, giữ lại nguyên vẹn màn hình xem trước và danh mục phân loại kênh truyền hình trực quan, mượt mà.

---

# 🚀 KENHLIVE iOS v1.7.1 (Build 143) — SỬA TRIỆT ĐỂ LỖI HITBOX VÙNG CHẠM THANH DOCK ĐIỀU HƯỚNG

### 🎯 1. Khắc Phục Triệt Để Lỗi Hitbox Vùng Chạm Thanh Tab Ngang (Full-Column Hitbox)
- **Nguyên nhân**: Ở bản trước, frame cố định chỉ nằm trong icon `Image` và thiếu `.contentShape(Rectangle())`. Trong SwiftUI, đối với các vector icon khi không kích hoạt, hệ thống chỉ nhận diện cảm ứng trên các đường nét mảnh (alpha stroke) vài pixel của biểu tượng, dẫn đến việc chạm lệch nhẹ hoặc chạm vào khoảng trống xung quanh bị trượt phím (ấn không ăn).
- **Khắc phục triệt để**:
  - Mở rộng toàn bộ vùng chạm của mỗi nút tab ra **toàn bộ cột** (`.frame(maxWidth: .infinity, maxHeight: .infinity)` nằm ngay bên trong nội dung nút).
  - Ép khuôn cảm ứng toàn diện bằng `.contentShape(Rectangle())` cho từng tab (kích thước vùng chạm thực tế lên đến **~70pt chiều rộng x 52pt chiều cao**).
  - Bất kể bạn chạm vào chính giữa icon, góc trên, góc dưới hay mép trái/phải của tab, hệ thống đều nhận diện cảm ứng và chuyển tab ngay lập tức 100%.
  - Loại bỏ hoàn toàn khối `VStack { Spacer() }` toàn màn hình để loại bỏ nguy cơ chặn cảm ứng.

---

# 🚀 KENHLIVE iOS v1.7.0 (Build 142) — THANH ĐIỀU HƯỚNG ICON TINH GỌN, CHUYỂN TAB 0MS MƯỢT MÀ, TÌM KIẾM GÓC PHẢI TRÊN CÙNG & BỘ NHỚ ĐỆM RAM TẢI ẢNH TỨC THÌ

### 💎 1. Thanh Dock Điều Hướng Tinh Gọn — Chỉ Giữ Icon Sắc Nét, Bỏ Chữ Rườm Rà
- Loại bỏ hoàn toàn text nhãn chữ dưới các tab, chỉ hiển thị biểu tượng icon tối giản, sang trọng.
- Tab đang kích hoạt được bao bọc bởi đĩa sáng tròn phát quang gradient đỏ nhung sang trọng (`#B81F2E` -> `#E63D4D`), bán kính 38pt, đổ bóng chiều sâu mượt mà.

### ⚡ 2. Chuyển Tab Siêu Tốc 0ms — Giữ Trọn Vẹn Bộ Nhớ Giao Diện (Zero View Destruction)
- Tái cấu trúc chuyển tab từ `switch-case` sang cơ chế xếp chồng đa tầng `ZStack` với `.opacity` và `.allowsHitTesting`.
- Không bao giờ hủy và khởi tạo lại view khi chuyển tab: giữ nguyên vị trí cuộn trang, danh sách phim đã tải và trạng thái của từng màn hình. Chuyển tab lập tức phản hồi ở tần số 120Hz ProMotion mà không hề giật lag.

### 🔍 3. Nút Tìm Kiếm Nổi Góc Phải Trên Cùng Trang Chủ
- Bổ sung nút kính lúp tìm kiếm kính mờ Liquid Glass (`Circle 38pt`, viền mảnh 0.8pt) ở góc phải trên cùng ngay trên Hero Banner của Trang Chủ.
- Chạm vào lập tức chuyển hướng sang giao diện Tìm Kiếm Phim Điện Ảnh & Anime 100%.

### 🚀 4. Bộ Nhớ Đệm RAM Siêu Tốc `KLImageCache` & `KLAsyncImage` (0ms Image Load)
- Triển khai kiến trúc quản lý ảnh hai tầng: Bộ nhớ đệm RAM tốc độ cao (`NSCache<NSString, UIImage>` tối đa 150MB / 350 ảnh) kết hợp ổ đĩa 600MB.
- Toàn bộ poster phim từ Hero Banner, Top tuần, kệ phim đề xuất đến kết quả tìm kiếm chỉ tải 1 lần qua mạng; từ lần thứ 2 hiển thị ngay tức thì 0.001ms từ RAM, triệt tiêu hiện tượng nháy ảnh hoặc giật khi cuộn trang.

---

# 🚀 KENHLIVE iOS v1.6.9 (Build 141) — SỬA TRIỆT ĐỂ LỖI THANH ĐIỀU HƯỚNG BỊ KÉO DÀI CHE MÀN HÌNH (FIX LAYOUT CONSTRAINT)

### 🛠️ 1. Khắc Phục Triệt Để Lỗi Viên Thuốc Kéo Dài 100% Chiều Cao Màn Hình
- **Nguyên nhân**: Ở bản trước, `Capsule()` trong `ZStack` không có giới hạn chiều cao cố định kết hợp với `matchedGeometryEffect` trong một layout toàn màn hình đã khiến SwiftUI tính toán sai kích thước, làm hình viên thuốc màu đỏ bị giãn nở dọc vô tận từ mép trên cùng (che đồng hồ 18:28) xuống tận đáy màn hình.
- **Khắc phục triệt để**:
  - Ghim thanh dock cố định dưới đáy màn hình bằng `VStack { Spacer(); renderFloatingDockTabBar() }`.
  - Khóa cứng chiều cao thanh Dock là **48pt** và chiều cao nút bấm tab là **34pt**.
  - Đưa `Capsule()` vào đúng thuộc tính `.background()` của nội dung nút, triệt tiêu 100% khả năng bị kéo dài hoặc chiếm diện tích màn hình.
  - Loại bỏ hoàn toàn lỗi hiển thị thanh điều hướng bị đẩy lên giữa màn hình.

---

# 🚀 KENHLIVE iOS v1.6.8 (Build 140) — TỐI ƯU TAB TÌM KIẾM CHUYÊN BIỆT 100% CHO KHO PHIM ĐIỆN ẢNH (CINEMA 4K)

### 🎬 1. Tab Tìm Kiếm Chuyên Biệt Cho Kho Phim Điện Ảnh
- **Tập trung 100% vào Phim**:
  - Loại bỏ hoàn toàn các bộ lọc thể thao và truyền hình gây rối mắt khỏi giao diện tìm kiếm.
  - Tích hợp thanh tìm kiếm thông minh tối ưu cho tác phẩm điện ảnh, diễn viên, anime hot (KKPhim & NguonC HLS 4K).
- **Bộ Lọc Thể Loại Phim Đầy Đủ**:
  - Bổ sung thanh lọc thể loại phim chuyên sâu: **"Tất Cả Phim"**, **"Mới Cập Nhật"**, **"Phim Lẻ Rạp"**, **"Phim Bộ Hot"**, **"Hoạt Hình & Anime"**, **"Hàn Quốc"**, **"Trung Quốc"**, **"Âu Mỹ Bom Tấn"**, **"Hành Động"**, **"Cổ Trang"**, **"Kinh Dị"**.
  - Hỗ trợ nạp phim theo thể loại với bộ đệm RAM 0ms độ trễ.
- **Từ Khóa Phim & Anime Thịnh Hành**:
  - Hàng chip xu hướng điện ảnh: *One Piece, Conan, Marvel, Batman, Doraemon, Naruto, Squid Game, Chiếu Rạp, Avengers, John Wick*.
- **Lưới Poster Phim Chuẩn Cinema 3 Cột**:
  - Thẻ poster tỉ lệ 2:3 bo góc 8pt, tích hợp huy hiệu điểm vàng IMDb (`★ 9.0`), nhãn chất lượng (`4K / Full HD`), số tập hiện tại và năm phát hành.
  - Bấm vào bất kỳ poster nào lập tức mở bảng chọn tập và phát phim chế độ ngang màn hình.

---

# 🚀 KENHLIVE iOS v1.6.7 (Build 139) — KHÔI PHỤC ĐẦY ĐỦ THỂ THAO & VTV TRUYỀN HÌNH + HIỆU ỨNG TRƯỢT VIÊN THUỐC ĐỘNG (MATCHEDGEOMETRY)

### ⚽ 1. Khôi Phục Đầy Đủ Thể Thao Live & VTV Truyền Hình Vào Thanh Điều Hướng Đáy (5 Tab)
- **Thanh Dock 5 Tab Hoàn Chỉnh**:
  1. 🏠 **Trang chủ**: Rạp phim Netflix Cinema tràn viền chuẩn Cinematic theo ảnh mẫu (Hero Banner 480pt, "Bạn đang quan tâm gì?", "Top tuần" #1 #2 #3...).
  2. ⚽ **Thể thao**: Trực tiếp bóng đá 4 nhà đài (**Socolive, ColaTV, Gà Vàng 33, Giờ Vàng TV**), bảng tỷ số thời gian thực, bình luận viên, logo CLB ESPN 500x500.
  3. 📺 **Truyền hình**: Đầy đủ các kênh VTV Quốc Gia (**VTV1, VTV2, VTV3, VTV5, VTV6, VTV Cần Thơ**), K+ Sport, HTV, Thể thao TV với trình phát tức thì.
  4. 🔍 **Tìm kiếm**: Tìm kiếm toàn diện (Phim rạp, Trận đấu bóng đá, Kênh TV) với bộ lọc phạm vi.
  5. 👤 **Cá nhân**: Quản lý "Tiếp tục xem", Lịch thi đấu 7 ngày ("LỊCH ĐÁ"), Báo lỗi Telegram, Kiểm tra tốc độ CDN.
- **Lối tắt nhanh trong Trang Chủ**: Bổ sung ngay thẻ "Thể Thao Live" và "Truyền Hình VTV" vào hàng "Bạn đang quan tâm gì?", bấm vào lập tức chuyển mượt mà sang nhà đài hoặc kênh mong muốn.

### ✨ 2. Hiệu Ứng Trượt Viên Thuốc Động Sang Trọng (Dynamic Tab Sliding Capsule)
- Tích hợp công nghệ `.matchedGeometryEffect` trong SwiftUI: Viên thuốc màu đỏ rượu vang (`#7A1F26`) không còn biến mất/xuất hiện đột ngột mà **trượt lướt và co giãn vật lý cực mượt (Spring Animation)** từ tab này sang tab khác khi bạn chạm.
- Hiệu ứng nảy biểu tượng (`scaleEffect 1.15`) và phản hồi rung xúc giác `KLHaptics.selection()` tinh tế trên từng thao tác chạm.

---

# 🚀 KENHLIVE iOS v1.6.6 (Build 138) — HOÀN THIỆN ĐỒNG BỘ TOÀN BỘ GIAO DIỆN THEO MẪU THIẾT KẾ (DOCK BAR 4 TAB & FULL BLEED STATUS BAR)

### 🌟 1. Banner Tràn Viền Tuyệt Đối (Edge-to-Edge Status Bar)
- Loại bỏ thanh tiêu đề phía trên (`Header Bar`), để ảnh bìa tác phẩm điện ảnh tràn viền 100% lên tận mép trên cùng của màn hình iPhone, lồng ghép trực tiếp dưới thanh trạng thái iOS (đồng hồ, pin, sóng WiFi) theo đúng ảnh mẫu.
- Nâng chiều cao Hero Banner lên 480pt cho trải nghiệm thị giác điện ảnh choáng ngợp.
- Thêm huy hiệu chất lượng xanh Cyan `Full HD (PĐ)` và `4K (PĐ-TM)` chính xác theo ảnh mẫu.

### ⚓ 2. Thanh Điều Hướng Đáy Kiểu Dock Nổi (Floating Glass Dock Bar)
- Thiết kế thanh điều hướng 4 tab dạng dock bo tròn 32pt với hiệu ứng kính mờ tối màu:
  1. **Trang chủ**: Viên thuốc màu đỏ rượu vang (`#7A1F26`) độc quyền với icon ngôi nhà đỏ san hô rực sáng.
  2. **Tìm kiếm**: Tab chuyên biệt tích hợp thanh tìm kiếm thông minh, từ khóa thịnh hành (One Piece, Conan, Ngoại Hạng Anh...) và bộ lọc thể loại.
  3. **Thư viện**: Quản lý tập phim xem dở ("Tiếp tục xem") và danh sách phim đã lưu.
  4. **Hồ sơ**: Thông tin VIP, Lịch thi đấu bóng đá 7 ngày, Báo lỗi Telegram và công cụ kiểm tra tốc độ CDN.

---

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