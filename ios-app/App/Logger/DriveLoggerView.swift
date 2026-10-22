import SwiftUI
import TeslaBLE
import UIKit

/// Small button on the main screen that opens the logger page. Launch with
/// `-DriveLoggerOpen YES` to open the page at once (screenshots).
struct DriveLoggerEntryButton: View {
    let logger: DriveLogger
    @State private var isPresented = UserDefaults.standard.bool(forKey: "DriveLoggerOpen")

    var body: some View {
        Button {
            isPresented = true
        } label: {
            Label("行車紀錄", systemImage: "record.circle")
                .font(.footnote.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.white.opacity(0.12), in: Capsule())
        }
        .foregroundStyle(.white.opacity(0.85))
        .padding(12)
        .fullScreenCover(isPresented: $isPresented) {
            DriveLoggerView(logger: logger)
        }
    }
}

/// "行車紀錄(測試)": the guided steps for the first real-car trip.
struct DriveLoggerView: View {
    @Bindable var logger: DriveLogger
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    private var locked: Bool { logger.isRecording || logger.busy != nil }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    safetyNote
                    statusLine
                    vinCard
                    connectCard
                    keyCard.id("key")
                    readCard.id("read")
                    recordCard.id("record")
                    exportCard
                    routeCard.id("route")
                    recentCard
                }
                .frame(maxWidth: 760)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity)
            }
            .onAppear {
                #if DEBUG
                // Screenshots: `-DriveLoggerDemo YES -DriveLoggerScrollTo read`.
                if UserDefaults.standard.bool(forKey: "DriveLoggerDemo") { logger.loadDemoState() }
                if let target = UserDefaults.standard.string(forKey: "DriveLoggerScrollTo") {
                    Task {
                        try? await Task.sleep(for: .milliseconds(500))
                        proxy.scrollTo(target, anchor: .top)
                    }
                }
                #endif
            }
        }
        .background(Color(white: 0.04).ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) { _, phase in logger.scenePhaseChanged(phase) }
        .sheet(item: $logger.shareItems) { items in
            ShareSheet(items: items.urls)
        }
    }

    // MARK: Sections

    private var header: some View {
        HStack {
            Text("行車紀錄(測試)").font(.title2.bold())
            Spacer()
            Button("關閉") { dismiss() }
                .disabled(logger.isRecording)
        }
    }

    private var safetyNote: some View {
        Label("請在停車時操作,開車時不要碰手機", systemImage: "exclamationmark.triangle.fill")
            .font(.title3.bold())
            .foregroundStyle(.black)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.yellow, in: RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var statusLine: some View {
        if let busy = logger.busy {
            HStack(spacing: 8) {
                ProgressView()
                Text(busy)
            }
        }
        if let error = logger.lastError {
            Text(error).foregroundStyle(.red).font(.callout)
        }
    }

    private var vinCard: some View {
        StepCard(number: 1, title: "輸入車身號碼(VIN)") {
            TextField("17 碼,例如 5YJ3E1EA0KF000000", text: $logger.vin)
                .font(.system(.title3, design: .monospaced))
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)
                .disabled(locked)
            Text("目前 \(logger.normalizedVIN.count)/17 碼。可以在車子螢幕「控制 > 軟體」或行照上找到。只存在這支手機裡。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var connectCard: some View {
        StepCard(number: 2, title: "連線") {
            Button("連線") { Task { await logger.connect() } }
                .buttonStyle(.borderedProminent)
                .disabled(locked || !logger.isVINValid)
            Text(linkText).font(.callout)
        }
    }

    private var keyCard: some View {
        StepCard(number: 3, title: "加入鑰匙(只需要做一次)") {
            Button("加入鑰匙") { Task { await logger.enrollKey() } }
                .buttonStyle(.borderedProminent)
                .disabled(locked || logger.linkStatus != .connected)
            if let hint = logger.keyHint {
                Text(hint).font(.callout)
            }
            enrollmentMessage
        }
    }

    @ViewBuilder
    private var enrollmentMessage: some View {
        switch logger.enrollment {
        case nil:
            Text("按下後,照畫面上的指示把實體鑰匙卡放到感應區。")
                .font(.footnote).foregroundStyle(.secondary)
        case .checking?:
            Text("正在確認這支手機是不是已經是車子的鑰匙…").font(.callout)
        case .awaitingKeyCardTap?:
            VStack(alignment: .leading, spacing: 6) {
                Text("請把實體鑰匙卡放在中控台手機架後方的感應區")
                    .font(.title2.bold())
                Text("放好後等幾秒鐘,要在 60 秒內完成。")
                    .font(.callout)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.blue.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
        case .waitingForSync?:
            Text("已感應到鑰匙卡,正在同步到車機,請稍等…").font(.callout.bold())
        case .enrolled?:
            Text("完成!這支手機已經是車子的鑰匙。").font(.callout.bold()).foregroundStyle(.green)
        case .timedOut?:
            Text("時間到,沒有感應到鑰匙卡。請再按一次「加入鑰匙」,並在 60 秒內把卡放好。")
                .font(.callout).foregroundStyle(.orange)
        case .rejected(let reason)?:
            Text("車子拒絕加入鑰匙(\(reason))。如果車上的鑰匙已經滿了,請先在車子螢幕刪除不用的鑰匙再試。")
                .font(.callout).foregroundStyle(.orange)
        }
    }

    private var readCard: some View {
        StepCard(number: 4, title: "讀一次") {
            Button("讀一次") { Task { await logger.readOnce() } }
                .buttonStyle(.borderedProminent)
                .disabled(locked || logger.linkStatus != .connected)
            if let sample = logger.lastSample {
                ReadingGrid(sample: sample)
            } else {
                Text("讀到的每一個數值都會列在這裡。空白代表車子沒有給這個值。")
                    .font(.footnote).foregroundStyle(.secondary)
            }
        }
    }

    private var recordCard: some View {
        StepCard(number: 5, title: "紀錄") {
            HStack(spacing: 12) {
                Button("開始紀錄") { logger.startRecording() }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(locked || logger.linkStatus != .connected)
                Button(logger.isStopping ? "停止中…" : "停止紀錄") { Task { await logger.stopRecording() } }
                    .buttonStyle(.bordered)
                    .disabled(!logger.isRecording || logger.isStopping)
            }
            if logger.isRecording, let start = logger.recordingStartedAt {
                TimelineView(.periodic(from: start, by: 1)) { context in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("紀錄中 \(Self.elapsed(from: start, to: context.date))")
                            .font(.title3.bold()).foregroundStyle(.red)
                        Text("已紀錄 \(logger.sampleCount) 筆,其中錯誤 \(logger.errorCount) 筆")
                        Text("手機 GPS 速度:\(gpsText)")
                    }
                }
            }
            Text("紀錄時螢幕會一直亮著。請不要按側邊鍵鎖住手機,鎖住或切到別的 App 時紀錄會暫停。")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var exportCard: some View {
        StepCard(number: 6, title: "匯出") {
            Button("匯出") { logger.export() }
                .buttonStyle(.borderedProminent)
                .disabled(locked || logger.lastFolder == nil)
            if let folder = logger.lastFolder {
                Text("最近一次紀錄:\(folder.lastPathComponent)").font(.callout)
            }
            Text("會打包成一個 zip 檔,用 LINE、AirDrop 或 Email 傳給我們就可以。")
                .font(.footnote).foregroundStyle(.secondary)
        }
    }

    private var routeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("開車路線").font(.headline)
            ForEach(Array(Self.route.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(index + 1).").monospacedDigit().foregroundStyle(.secondary)
                    Text(step)
                }
                .font(.callout)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("最近事件").font(.headline)
            if logger.recent.isEmpty {
                Text("還沒有事件。").font(.footnote).foregroundStyle(.secondary)
            }
            ForEach(Array(logger.recent.suffix(15).reversed().enumerated()), id: \.offset) { _, line in
                Text(line).font(.system(.caption2, design: .monospaced)).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: Text

    /// The drive script, also in ios-app/README.md.
    static let route = [
        "停在 P 檔,人坐在車上、腳踩煞車,讓車子保持醒著。(車子在睡覺的話,先開一下車門或踩煞車。)",
        "按「讀一次」,確認有讀到資料。",
        "按「開始紀錄」,把手機放上手機架,之後就不要再碰手機。",
        "打 R 檔,倒車幾公尺後停下。",
        "打 D 檔,慢慢滑行 1–2 分鐘。",
        "正常開 10 分鐘。",
        "可以的話,開過隧道或進地下停車場。",
        "停好打 P 檔,等 2 分鐘。",
        "停好車後才拿手機,按「停止紀錄」。",
        "按「匯出」,把檔案傳給我們。",
    ]

    private var linkText: String {
        switch logger.linkStatus {
        case .idle: "還沒連線。"
        case .connecting: "正在找車子並連線…"
        case .connected: "已連上 \(logger.maskedVIN)"
        case .reconnecting: "連線中斷,正在自動重新連線…"
        case .failed(let message): "連線失敗:\(message)"
        case .disconnected(let reason): "連線中斷了\(reason.isEmpty ? "" : "(\(reason))"),請再按「連線」。"
        }
    }

    private var gpsText: String {
        guard let fix = logger.latestFix else { return "等待中" }
        let speed = fix.speed.map { String(format: "%.1f 公里/時", $0 * 3.6) } ?? "無效"
        let accuracy = fix.speedAccuracy.map { String(format: "(誤差 %.1f 公尺/秒)", $0) } ?? ""
        return speed + accuracy
    }

    private static func elapsed(from start: Date, to now: Date) -> String {
        let seconds = max(0, Int(now.timeIntervalSince(start)))
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
}

/// One numbered step.
private struct StepCard<Content: View>: View {
    let number: Int
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("步驟 \(number)  \(title)").font(.headline)
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

/// Every `samples.csv` column of one sample, labelled.
private struct ReadingGrid: View {
    let sample: Sample

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220), alignment: .leading)], alignment: .leading, spacing: 6) {
            ForEach(SampleCSV.columns, id: \.key) { column in
                let value = column.value(sample)
                VStack(alignment: .leading, spacing: 1) {
                    Text(column.label).font(.caption2).foregroundStyle(.secondary)
                    Text(value.isEmpty ? "—" : value)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(column.key == "error" && !value.isEmpty ? .red : .primary)
                }
            }
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [URL]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
