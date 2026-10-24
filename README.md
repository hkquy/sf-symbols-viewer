# SF Symbols Viewer

Ứng dụng macOS bằng SwiftUI để tra cứu SF Symbols, hoạt động offline. Yêu cầu macOS 13 trở lên và Swift 5.9 trở lên để build. Không có thư viện phụ thuộc bên ngoài.

## Thông tin ứng dụng

- Tên: **SF Symbols Viewer**.
- Phiên bản: **1.0.0**, build **1**.
- Nền tảng: macOS 13 trở lên; giao diện tiếng Việt.
- Nhóm ứng dụng: Công cụ lập trình.
- Quyền riêng tư: hoạt động offline, không tài khoản, quảng cáo hay SDK phân tích; yêu thích được lưu cục bộ. Clipboard chỉ được ghi khi người dùng chọn sao chép.
- Menu ứng dụng → **Giới thiệu SF Symbols Viewer**: phiên bản, quyền riêng tư, nguồn và giấy phép danh mục.
- Menu Help → **Hướng dẫn SF Symbols Viewer** (`⌘?`): cách tìm, tùy chỉnh và sao chép biểu tượng.

Metadata được quản lý tại `Sources/SymbolViewer/Resources/AppMetadata.plist`, dùng chung cho giao diện giới thiệu và `Info.plist` của bản đóng gói. Bundle ID hiện tại `dev.local.sfsymbolsviewer` dành cho bản dùng cục bộ; cần thay bằng ID của chủ sở hữu khi phát hành.

## Chạy

```sh
swift run SymbolViewer
```

Hoặc mở `Package.swift` bằng Xcode và chạy target `SymbolViewer`.

Tạo ứng dụng mở được từ Finder:

```sh
./scripts/build-app.sh
open "dist/SF Symbols Viewer.app"
```

Bản `.app` được ký ad-hoc để dùng cục bộ. Phân phối công khai cần ký Developer ID và notarize.

## Tính năng

- Danh mục đóng gói gồm 7.752 tên biểu tượng; chỉ hiển thị tên được macOS hiện tại hỗ trợ.
- Tìm kiếm tiếng Anh theo tên, hỗ trợ nhiều từ, ví dụ `arrow circle`.
- Nhóm chủ đề dựa theo tên, mục yêu thích lưu qua các lần khởi động.
- Lưới có thể đổi kích thước, bảng xem trước với 9 độ đậm, màu và 4 chế độ hiển thị.
- Sao chép tên, mã SwiftUI hoặc dùng menu chuột phải.
- `⌘F`: tìm kiếm; `⇧⌘C`: sao chép tên đang chọn.
- Theo giao diện sáng/tối của hệ thống.

Bộ lọc chủ đề dùng từ khóa, không phải phân nhóm chính thức của Apple. Tìm theo nhóm “Tất cả biểu tượng” để tra cứu toàn bộ danh mục. Các chế độ màu phụ thuộc từng biểu tượng.

## Danh mục

Tên biểu tượng được trích từ [SFSafeSymbols](https://github.com/SFSafeSymbols/SFSafeSymbols), giấy phép MIT được đóng gói trong Resources. Không sao chép hình ảnh SF Symbols. Ứng dụng render bằng `Image(systemName:)` của hệ thống. Việc sử dụng SF Symbols trong sản phẩm cần tuân thủ điều khoản của Apple.

Để cập nhật danh mục (cần mạng, Python 3):

```sh
python3 scripts/update-catalog.py
```
