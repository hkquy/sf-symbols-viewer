import SwiftUI

enum AppInformation {
    private static let metadata: [String: Any] = {
        guard let url = Bundle.main.url(forResource: "AppMetadata", withExtension: "plist")
                ?? Bundle.module.url(forResource: "AppMetadata", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let values = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else { return [:] }
        return values
    }()

    static let name = metadata["CFBundleDisplayName"] as? String ?? "SF Symbols Viewer"
    static let version = metadata["CFBundleShortVersionString"] as? String ?? "—"
    static let build = metadata["CFBundleVersion"] as? String ?? "—"
    static let description = metadata["AppDescription"] as? String ?? ""
    static var license: String {
        guard let url = Bundle.main.url(forResource: "SFSafeSymbols-LICENSE", withExtension: "txt")
                ?? Bundle.module.url(forResource: "SFSafeSymbols-LICENSE", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8)
        else { return "Không thể đọc giấy phép. Hãy kiểm tra tài nguyên ứng dụng." }
        return text
    }
}

struct AppInformationView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable().frame(width: 80, height: 80)
                .accessibilityHidden(true)
            Text(AppInformation.name).font(.title.bold())
            Text("Phiên bản \(AppInformation.version) (\(AppInformation.build))")
                .foregroundStyle(.secondary)
            Text(AppInformation.description).multilineTextAlignment(.center)
            TabView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Quyền riêng tư").font(.headline)
                    Text("Ứng dụng hoạt động offline, không yêu cầu tài khoản, không có quảng cáo hay tích hợp phân tích sử dụng.")
                    Text("Danh sách yêu thích được lưu trong cài đặt ứng dụng trên máy này. Nội dung chỉ được ghi vào clipboard khi bạn chọn sao chép.")
                    Text("Yêu cầu: macOS 13 trở lên. Số lượng biểu tượng hiển thị phụ thuộc phiên bản macOS đang dùng.")
                    Spacer()
                }.padding().tabItem { Text("Thông tin") }
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Nguồn danh mục").font(.headline)
                        Text("Tên biểu tượng được trích từ SFSafeSymbols. Hình biểu tượng được hệ thống macOS hiển thị, không đóng gói trong ứng dụng.")
                        Text("SF Symbols là tài nguyên của Apple. Ứng dụng này là công cụ độc lập, không phải sản phẩm chính thức của Apple.")
                        Text("SFSafeSymbols · Giấy phép MIT").font(.headline)
                        Text(AppInformation.license).font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }.frame(maxWidth: .infinity, alignment: .leading).padding()
                }.tabItem { Text("Nguồn & giấy phép") }
            }.frame(height: 250)
        }.padding(24).frame(width: 540)
    }
}

struct AppHelpView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Hướng dẫn sử dụng").font(.title2.bold())
            help("1. Tìm biểu tượng", "Nhập tên tiếng Anh, ví dụ arrow circle hoặc heart.fill. Các từ tìm kiếm được kết hợp để thu hẹp kết quả. Nhấn ⌘F để đến ô tìm kiếm.")
            help("2. Lọc và lưu yêu thích", "Chọn nhóm ở thanh bên. Nhấn ngôi sao trong bảng xem trước hoặc dùng menu chuột phải để lưu biểu tượng vào Yêu thích.")
            help("3. Tùy chỉnh xem trước", "Chọn biểu tượng, sau đó chỉnh kích thước, độ đậm, màu và chế độ hiển thị ở bảng bên phải. Thanh trượt phía trên lưới điều chỉnh kích thước ô biểu tượng.")
            help("4. Sao chép để sử dụng", "Nhấn Sao chép tên (⇧⌘C) hoặc nút sao chép ở mục SWIFTUI để lấy đoạn mã theo tùy chỉnh hiện tại.")
            Divider()
            Text("Các nhóm chủ đề được lọc theo từ khóa. Chọn Tất cả biểu tượng nếu chưa tìm thấy kết quả. Màu sắc và biểu tượng khả dụng phụ thuộc hỗ trợ của macOS.")
                .font(.callout).foregroundStyle(.secondary)
        }.padding(28).frame(width: 540)
    }

    private func help(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.headline)
            Text(text).fixedSize(horizontal: false, vertical: true)
        }
    }
}
