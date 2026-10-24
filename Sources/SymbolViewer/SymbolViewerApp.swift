import SwiftUI
import AppKit

@main
struct SymbolViewerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 960, minHeight: 640)
                .onAppear {
                    NSApp.setActivationPolicy(.regular)
                    NSApp.activate(ignoringOtherApps: true)
                    if let iconUrl = Bundle.main.url(forResource: "AppIcon", withExtension: "icns")
                        ?? Bundle.module.url(forResource: "AppIcon", withExtension: "icns"),
                       let image = NSImage(contentsOf: iconUrl) {
                        NSApp.applicationIconImage = image
                    }
                }
        }
        .defaultSize(width: 1240, height: 800)
        .commands { AppCommands() }
        Window("Giới thiệu SF Symbols Viewer", id: "app-info") {
            AppInformationView()
        }
        .windowResizability(.contentSize)
        Window("Hướng dẫn sử dụng", id: "app-help") {
            AppHelpView()
        }
        .windowResizability(.contentSize)
    }
}

// Resolve scene actions from the commands environment, rather than the App value.
struct AppCommands: Commands {
    @Environment(\.openWindow) private var openWindow

    var body: some Commands {
        CommandGroup(replacing: .appInfo) {
            Button("Giới thiệu SF Symbols Viewer") { openWindow(id: "app-info") }
        }
        CommandGroup(replacing: .help) {
            Button("Hướng dẫn SF Symbols Viewer") { openWindow(id: "app-help") }
                .keyboardShortcut("/", modifiers: [.command, .shift])
        }
    }
}

struct SymbolGroup: Identifiable {
    let id: String
    let icon: String
    let keywords: [String]
    static let all: [SymbolGroup] = [
        .init(id: "Tất cả biểu tượng", icon: "square.grid.2x2", keywords: []),
        .init(id: "Yêu thích", icon: "star", keywords: []),
        .init(id: "Giao tiếp", icon: "bubble.left.and.bubble.right", keywords: ["message", "bubble", "phone", "envelope", "video", "mic"]),
        .init(id: "Thời tiết", icon: "cloud.sun", keywords: ["sun", "moon", "cloud", "snow", "wind", "thermometer", "rain", "humidity"]),
        .init(id: "Thiết bị", icon: "desktopcomputer", keywords: ["iphone", "ipad", "mac", "computer", "keyboard", "display", "airpod", "watch", "printer"]),
        .init(id: "Điều hướng", icon: "arrow.triangle.turn.up.right.diamond", keywords: ["arrow", "chevron", "location", "map", "compass"]),
        .init(id: "Đa phương tiện", icon: "play.rectangle", keywords: ["play", "pause", "music", "speaker", "photo", "camera", "film", "backward", "forward"]),
        .init(id: "Con người", icon: "person.2", keywords: ["person", "figure", "hand", "face", "eye", "ear", "brain", "heart"]),
        .init(id: "Đồ vật & thiên nhiên", icon: "leaf", keywords: ["leaf", "tree", "flower", "bird", "dog", "cat", "fish", "bag", "house", "book", "car", "bicycle"])
    ]
}

@MainActor
final class SymbolStore: ObservableObject {
    @Published var names: [String] = []
    @Published var loading = true
    @Published var error: String?
    @Published var favorites: Set<String> {
        didSet { UserDefaults.standard.set(favorites.sorted(), forKey: "favoriteSymbols") }
    }
    init() {
        favorites = Set(UserDefaults.standard.stringArray(forKey: "favoriteSymbols") ?? [])
    }
    func load() async {
        guard loading else { return }
        guard let url = Bundle.main.url(forResource: "symbols", withExtension: "txt")
                ?? Bundle.module.url(forResource: "symbols", withExtension: "txt"),
              let text = try? String(contentsOf: url, encoding: .utf8) else {
            error = "Không thể đọc danh mục biểu tượng. Hãy build lại ứng dụng."
            loading = false
            return
        }
        let candidates = text.split(separator: "\n").map(String.init)
        // Yield between batches so the window remains responsive while AppKit checks availability.
        var supported: [String] = []
        for start in stride(from: 0, to: candidates.count, by: 150) {
            supported += candidates[start..<min(start + 150, candidates.count)].filter {
                NSImage(systemSymbolName: $0, accessibilityDescription: nil) != nil
            }
            await Task.yield()
        }
        names = supported
        loading = false
    }
    func toggle(_ name: String) {
        if favorites.contains(name) { favorites.remove(name) } else { favorites.insert(name) }
    }
}

enum RenderStyle: String, CaseIterable {
    case monochrome = "Đơn sắc", hierarchical = "Phân cấp", palette = "Bảng màu", multicolor = "Đa sắc"
    var mode: SymbolRenderingMode {
        switch self {
        case .monochrome: return .monochrome
        case .hierarchical: return .hierarchical
        case .palette: return .palette
        case .multicolor: return .multicolor
        }
    }
    var code: String {
        switch self {
        case .monochrome: return "monochrome"
        case .hierarchical: return "hierarchical"
        case .palette: return "palette"
        case .multicolor: return "multicolor"
        }
    }
}

enum SymbolWeight: String, CaseIterable {
    case ultralight, thin, light, regular, medium, semibold, bold, heavy, black
    var fontWeight: Font.Weight {
        switch self {
        case .ultralight: return .ultraLight
        case .thin: return .thin
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
    var code: String { self == .ultralight ? "ultraLight" : rawValue }
}

struct ContentView: View {
    @StateObject private var store = SymbolStore()
    @State private var group = SymbolGroup.all[0].id
    @State private var query = ""
    @State private var selected: String? = "star.fill"
    @State private var size = 80.0
    @State private var weight = SymbolWeight.regular
    @State private var rendering = RenderStyle.hierarchical
    @State private var tint = Color.white
    @State private var gridSize = 48.0
    @State private var copied: String?
    @FocusState private var searchFocused: Bool

    private var results: [String] {
        let category = SymbolGroup.all.first { $0.id == group } ?? SymbolGroup.all[0]
        let words = query.lowercased().split(whereSeparator: { $0.isWhitespace || $0 == "." })
        return store.names.filter { name in
            (group != "Yêu thích" || store.favorites.contains(name)) &&
            (category.keywords.isEmpty || category.keywords.contains { name.contains($0) }) &&
            words.allSatisfy { name.contains($0) }
        }
    }

    var body: some View {
        NavigationSplitView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text("SYMBOLS").font(.system(size: 24, weight: .bold, design: .rounded))
                    Text("Thư viện biểu tượng macOS").font(.caption).foregroundStyle(.secondary)
                }.padding(.horizontal, 18).padding(.top, 24)
                List(selection: $group) {
                    Section("THƯ VIỆN") {
                        ForEach(SymbolGroup.all) { item in
                            Label(item.id, systemImage: item.icon).tag(item.id).padding(.vertical, 5)
                        }
                    }
                }.listStyle(.sidebar)
                Text("SF Symbols • Offline\n\(store.names.count.formatted()) biểu tượng khả dụng")
                    .font(.caption).foregroundStyle(.secondary).padding(18)
            }
            .navigationSplitViewColumnWidth(min: 205, ideal: 230, max: 270)
        } detail: {
            HStack(spacing: 0) {
                library.frame(maxWidth: .infinity, maxHeight: .infinity)
                Divider()
                inspector.frame(width: 300)
            }
        }
        .task { await store.load() }
        .task(id: copied) {
            guard copied != nil else { return }
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { copied = nil }
        }
        .toolbar {
            ToolbarItem {
                Button { searchFocused = true } label: { Label("Tìm kiếm", systemImage: "magnifyingglass") }
                    .keyboardShortcut("f", modifiers: .command)
            }
        }
        .navigationTitle("SF Symbols Viewer")
    }

    private var library: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Tìm tên biểu tượng, ví dụ: arrow, heart, wifi…", text: $query)
                    .textFieldStyle(.plain).focused($searchFocused)
                if !query.isEmpty {
                    Button { query = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.plain).help("Xóa tìm kiếm")
                }
            }.padding(12).background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 10)).padding(20)
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(group).font(.title2.bold())
                    Text("\(results.count.formatted()) biểu tượng").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "square.grid.3x3").foregroundStyle(.secondary)
                Slider(value: $gridSize, in: 28...64).frame(width: 90).help("Kích thước lưới")
            }.padding(.horizontal, 22).padding(.bottom, 18)
            Divider()
            if store.loading {
                Spacer()
                ProgressView("Đang tải biểu tượng…").frame(maxWidth: .infinity)
                Spacer()
            } else if let error = store.error {
                emptyState(icon: "exclamationmark.triangle", title: "Không thể tải danh mục", message: error)
            } else if results.isEmpty {
                emptyState(icon: group == "Yêu thích" ? "star" : "magnifyingglass", title: "Chưa có biểu tượng", message: group == "Yêu thích" ? "Nhấn ngôi sao ở bảng chi tiết để lưu biểu tượng." : "Thử tên tiếng Anh khác hoặc chọn nhóm Tất cả biểu tượng.")
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: gridSize + 65), spacing: 12)], spacing: 12) {
                        ForEach(results, id: \.self) { name in
                            Button { selected = name } label: {
                                VStack(spacing: 12) {
                                    Image(systemName: name)
                                        .symbolRenderingMode(rendering.mode)
                                        .foregroundStyle(tint, tint.opacity(0.45), Color.orange)
                                        .font(.system(size: gridSize, weight: weight.fontWeight))
                                        .frame(height: gridSize + 12)
                                    Text(name).font(.system(size: 10, design: .monospaced))
                                        .lineLimit(2).multilineTextAlignment(.center)
                                        .foregroundStyle(selected == name ? Color.accentColor : .secondary)
                                        .frame(height: 28)
                                }
                                .frame(maxWidth: .infinity).padding(.vertical, 14).padding(.horizontal, 5)
                                .background(selected == name ? tint.opacity(0.12) : Color.primary.opacity(0.025), in: RoundedRectangle(cornerRadius: 12))
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected == name ? tint.opacity(0.7) : .clear))
                                .overlay(alignment: .topTrailing) {
                                    if store.favorites.contains(name) {
                                        Image(systemName: "star.fill").font(.caption2).foregroundStyle(.orange).padding(8)
                                    }
                                }
                            }
                            .buttonStyle(.plain).help(name)
                            .accessibilityLabel(name)
                            .contextMenu {
                                Button("Sao chép tên") { copy(name, label: "Đã sao chép tên") }
                                Button(store.favorites.contains(name) ? "Bỏ yêu thích" : "Thêm yêu thích") { store.toggle(name) }
                            }
                        }
                    }.padding(20)
                }
            }
        }
    }

    private var inspector: some View {
        ScrollView {
            if let name = selected {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Text("XEM TRƯỚC").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        Spacer()
                        Button { store.toggle(name) } label: {
                            Image(systemName: store.favorites.contains(name) ? "star.fill" : "star")
                                .foregroundStyle(store.favorites.contains(name) ? .orange : .secondary)
                        }.buttonStyle(.plain).help("Bật/tắt yêu thích")
                    }
                    Image(systemName: name)
                        .symbolRenderingMode(rendering.mode)
                        .foregroundStyle(tint, tint.opacity(0.45), Color.orange)
                        .font(.system(size: size, weight: weight.fontWeight))
                        .frame(maxWidth: .infinity).frame(height: 180)
                        .background(tint.opacity(0.06), in: RoundedRectangle(cornerRadius: 18))
                    Text(name).font(.system(.title3, design: .monospaced).weight(.semibold)).textSelection(.enabled)
                    Button { copy(name, label: "Đã sao chép tên") } label: {
                        Label("Sao chép tên", systemImage: "doc.on.doc").frame(maxWidth: .infinity)
                    }.controlSize(.large).keyboardShortcut("c", modifiers: [.command, .shift])
                    Divider()
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Kích thước")
                            Spacer()
                            Text("\(Int(size)) pt").foregroundStyle(.secondary).monospacedDigit()
                        }
                        Slider(value: $size, in: 24...128, step: 1)
                        Picker("Độ đậm", selection: $weight) {
                            ForEach(SymbolWeight.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                        }
                        Picker("Hiển thị", selection: $rendering) {
                            ForEach(RenderStyle.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        ColorPicker("Màu biểu tượng", selection: $tint, supportsOpacity: false)
                    }.font(.callout)
                    Divider()
                    HStack {
                        Text("SWIFTUI").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                        Spacer()
                        Button { copy(code(for: name), label: "Đã sao chép mã SwiftUI") } label: {
                            Image(systemName: "doc.on.doc")
                        }.buttonStyle(.plain).help("Sao chép mã SwiftUI")
                    }
                    Text(code(for: name)).font(.system(size: 11, design: .monospaced))
                        .textSelection(.enabled).padding(12).frame(maxWidth: .infinity, alignment: .leading)
                        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 8))
                    if let copied {
                        Label(copied, systemImage: "checkmark.circle.fill").font(.caption).foregroundStyle(.green)
                    }
                    Text("Màu sắc phụ thuộc vào các lớp màu mà từng biểu tượng hỗ trợ.")
                        .font(.caption).foregroundStyle(.secondary)
                }.padding(22)
            }
        }.background(.regularMaterial)
    }

    private func emptyState(icon: String, title: String, message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 42)).foregroundStyle(.tertiary)
            Text(title).font(.title3.bold())
            Text(message).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }.padding(40).frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func code(for name: String) -> String {
        let color = NSColor(tint).usingColorSpace(.deviceRGB) ?? .white
        let rgb = String(format: "Color(red: %.3f, green: %.3f, blue: %.3f)", color.redComponent, color.greenComponent, color.blueComponent)
        return "Image(systemName: \"\(name)\")\n    .font(.system(size: \(Int(size)),\n                  weight: .\(weight.code)))\n    .symbolRenderingMode(.\(rendering.code))\n    .foregroundStyle(\n        \(rgb),\n        \(rgb).opacity(0.45),\n        Color.orange\n    )"
    }
    private func copy(_ value: String, label: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
        copied = label
    }
}
