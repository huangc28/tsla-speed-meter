import Foundation
import TeslaBLE

/// One poll cycle: one request per vehicle-data category, with the latest
/// phone GPS fix at that moment.
struct Sample: Sendable {
    let phoneTime: Date
    /// Milliseconds since the recording started (monotonic clock).
    let monotonicMs: Int
    /// The whole cycle (the `response_ms` … `retried` columns): the merged
    /// reading of the categories that came back, their round trips and send
    /// waits added up, encrypted when all of them were, retried when any was.
    /// Nil when nothing came back.
    let response: VehicleDataResponse?
    /// The first error of the cycle (raw), nil when every category asked for came back.
    let error: String?
    let gps: GPSFix?
    /// Each category's own result; a category not asked for this cycle has none.
    var poll: VehicleDataPoll?

    /// Drive state did not come back: it failed, or was skipped after a link
    /// failure. Counted in `error_count`; a row without a poll counts any error.
    var driveFailed: Bool {
        guard let poll else { return error != nil }
        return poll.error(for: .drive) != nil || poll.skipped.contains(.drive)
    }

    /// Drive state came back, but charge state, tire pressure or closures did not.
    /// Counted in `category_error_count`.
    var categoryFailed: Bool {
        error != nil && !driveFailed
    }
}

extension Sample {
    init(poll: VehicleDataPoll, phoneTime: Date, monotonicMs: Int, gps: GPSFix?) {
        let responses = poll.entries.compactMap { entry -> VehicleDataResponse? in
            if case .success(let response) = entry.result { response } else { nil }
        }
        self.init(
            phoneTime: phoneTime,
            monotonicMs: monotonicMs,
            response: poll.reading.map { reading in
                VehicleDataResponse(
                    reading: reading,
                    isEncrypted: responses.allSatisfy(\.isEncrypted),
                    roundTripMs: responses.reduce(0) { $0 + $1.roundTripMs },
                    sendWaitMs: responses.reduce(0) { $0 + $1.sendWaitMs },
                    retried: responses.contains(where: \.retried)
                )
            },
            error: poll.firstError.map { "\($0)" },
            gps: gps,
            poll: poll
        )
    }
}

/// `samples.csv` columns. The same list labels the "讀一次" screen, so
/// every logged field is also visible there.
enum SampleCSV {
    struct Column {
        let key: String
        /// Plain Chinese label for the screen.
        let label: String
        let value: @Sendable (Sample) -> String
    }

    private static func reading(_ body: @escaping @Sendable (VehicleReading) -> String) -> @Sendable (Sample) -> String {
        { sample in sample.response.map { body($0.reading) } ?? "" }
    }

    /// Round trip and error of one category's request; both empty when it
    /// was not asked for this cycle, and the error `skipped` when an earlier
    /// category's link failure left it unasked.
    private static func category(_ category: VehicleDataCategory, key: String, label: String) -> [Column] {
        [
            Column(key: "\(key)_response_ms", label: "\(label) 回應時間(毫秒)") {
                LogFormat.int($0.poll?.response(for: category)?.roundTripMs)
            },
            Column(key: "\(key)_error", label: "\(label) 錯誤") { sample in
                if let error = sample.poll?.error(for: category) { return "\(error)" }
                return sample.poll?.skipped.contains(category) == true ? "skipped" : ""
            },
        ]
    }

    static let columns: [Column] = [
        Column(key: "phone_time", label: "手機時間") { LogFormat.iso($0.phoneTime) },
        Column(key: "monotonic_ms", label: "紀錄經過(毫秒)") { "\($0.monotonicMs)" },
        Column(key: "response_ms", label: "回應時間(毫秒)") { LogFormat.int($0.response?.roundTripMs) },
        Column(key: "send_wait_ms", label: "等待送出(毫秒)") { LogFormat.int($0.response?.sendWaitMs) },
        Column(key: "encrypted", label: "回應有加密") { LogFormat.bool($0.response?.isEncrypted) },
        Column(key: "retried", label: "重試過") { LogFormat.bool($0.response?.retried) },
        Column(key: "error", label: "錯誤") { $0.error ?? "" },
    ]
        + category(.drive, key: "drive", label: "行駛資料")
        + category(.charge, key: "charge", label: "充電資料")
        + category(.tirePressure, key: "tire_pressure", label: "胎壓資料")
        + [
        Column(key: "speed_float_raw", label: "速度 speed_float(原始)", value: reading { LogFormat.raw($0.speedFloat) }),
        Column(key: "speed_raw", label: "速度 speed(原始)", value: reading { LogFormat.int($0.speed) }),
        Column(key: "speed_mps", label: "速度(公尺/秒)", value: reading { LogFormat.decimal($0.speedMetersPerSecond, places: 3) }),
        Column(key: "speed_kmh", label: "速度(公里/時)", value: reading { LogFormat.decimal($0.speedMetersPerSecond.map { $0 * 3.6 }, places: 2) }),
        Column(key: "shift_state_raw", label: "排檔(原始)", value: reading { shiftRaw($0.shiftState) }),
        Column(key: "gear", label: "排檔", value: reading { gear($0.gear, present: $0.shiftState != nil) }),
        Column(key: "drive_power_kw", label: "行駛功率(kW)", value: reading { LogFormat.int($0.drivePower) }),
        Column(key: "drive_state_time", label: "行駛資料時間(車)", value: reading { LogFormat.iso($0.driveStateTimestamp) }),

        Column(key: "battery_level_pct", label: "電量(%)", value: reading { LogFormat.int($0.batteryLevel) }),
        Column(key: "battery_range_mi", label: "續航 battery_range(英里,原始)", value: reading { LogFormat.raw($0.batteryRangeMiles) }),
        Column(key: "battery_range_km", label: "續航(公里)", value: reading { LogFormat.decimal($0.batteryRangeKilometers, places: 1) }),
        Column(key: "est_battery_range_mi", label: "預估續航(英里,原始)", value: reading { LogFormat.raw($0.estBatteryRangeMiles) }),
        Column(key: "est_battery_range_km", label: "預估續航(公里)", value: reading { LogFormat.decimal($0.estBatteryRangeKilometers, places: 1) }),
        Column(key: "ideal_battery_range_mi", label: "理想續航(英里,原始)", value: reading { LogFormat.raw($0.idealBatteryRangeMiles) }),
        Column(key: "ideal_battery_range_km", label: "理想續航(公里)", value: reading { LogFormat.decimal($0.idealBatteryRangeKilometers, places: 1) }),
        Column(key: "charging_state_raw", label: "充電狀態(原始)", value: reading { chargingRaw($0.chargingStateRaw) }),
        Column(key: "charging_state", label: "充電狀態", value: reading { $0.chargingState.map { "\($0)" } ?? "" }),
        Column(key: "charger_power_kw", label: "充電功率(kW)", value: reading { LogFormat.int($0.chargerPower) }),
        Column(key: "charge_state_time", label: "充電資料時間(車)", value: reading { LogFormat.iso($0.chargeStateTimestamp) }),

        Column(key: "tpms_fl_bar", label: "胎壓 左前(bar)", value: reading { LogFormat.raw($0.tirePressureFrontLeft?.bar) }),
        Column(key: "tpms_fr_bar", label: "胎壓 右前(bar)", value: reading { LogFormat.raw($0.tirePressureFrontRight?.bar) }),
        Column(key: "tpms_rl_bar", label: "胎壓 左後(bar)", value: reading { LogFormat.raw($0.tirePressureRearLeft?.bar) }),
        Column(key: "tpms_rr_bar", label: "胎壓 右後(bar)", value: reading { LogFormat.raw($0.tirePressureRearRight?.bar) }),
        Column(key: "tpms_fl_psi", label: "胎壓 左前(psi)", value: reading { LogFormat.decimal($0.tirePressureFrontLeft?.psi, places: 2) }),
        Column(key: "tpms_fr_psi", label: "胎壓 右前(psi)", value: reading { LogFormat.decimal($0.tirePressureFrontRight?.psi, places: 2) }),
        Column(key: "tpms_rl_psi", label: "胎壓 左後(psi)", value: reading { LogFormat.decimal($0.tirePressureRearLeft?.psi, places: 2) }),
        Column(key: "tpms_rr_psi", label: "胎壓 右後(psi)", value: reading { LogFormat.decimal($0.tirePressureRearRight?.psi, places: 2) }),
        Column(key: "tpms_fl_last_seen", label: "胎壓 左前 最後更新", value: reading { LogFormat.iso($0.tpmsLastSeenPressureTimeFrontLeft) }),
        Column(key: "tpms_fr_last_seen", label: "胎壓 右前 最後更新", value: reading { LogFormat.iso($0.tpmsLastSeenPressureTimeFrontRight) }),
        Column(key: "tpms_rl_last_seen", label: "胎壓 左後 最後更新", value: reading { LogFormat.iso($0.tpmsLastSeenPressureTimeRearLeft) }),
        Column(key: "tpms_rr_last_seen", label: "胎壓 右後 最後更新", value: reading { LogFormat.iso($0.tpmsLastSeenPressureTimeRearRight) }),
        Column(key: "tpms_state_time", label: "胎壓資料時間(車)", value: reading { LogFormat.iso($0.tirePressureStateTimestamp) }),

        Column(key: "gps_speed_mps", label: "手機 GPS 速度(公尺/秒)") { LogFormat.decimal($0.gps?.speed, places: 3) },
        Column(key: "gps_speed_kmh", label: "手機 GPS 速度(公里/時)") { LogFormat.decimal($0.gps?.speed.map { $0 * 3.6 }, places: 2) },
        Column(key: "gps_speed_accuracy_mps", label: "GPS 速度誤差(公尺/秒)") { LogFormat.decimal($0.gps?.speedAccuracy, places: 3) },
        Column(key: "gps_horizontal_accuracy_m", label: "GPS 位置誤差(公尺)") { LogFormat.decimal($0.gps?.horizontalAccuracy, places: 1) },
        Column(key: "gps_fix_age_ms", label: "GPS 資料年齡(毫秒)") { sample in LogFormat.int(sample.gps?.ageMs(at: sample.phoneTime)) },
    ]
        // #78: closures came later, so its columns are added at the end and the earlier ones keep their places.
        + category(.closures, key: "closures", label: "車門資料")
        + [
        Column(key: "door_df_open", label: "車門 駕駛側前 開著", value: reading { LogFormat.bool($0.doorOpenDriverFront) }),
        Column(key: "door_dr_open", label: "車門 駕駛側後 開著", value: reading { LogFormat.bool($0.doorOpenDriverRear) }),
        Column(key: "door_pf_open", label: "車門 副駕側前 開著", value: reading { LogFormat.bool($0.doorOpenPassengerFront) }),
        Column(key: "door_pr_open", label: "車門 副駕側後 開著", value: reading { LogFormat.bool($0.doorOpenPassengerRear) }),
        Column(key: "trunk_front_open", label: "前車廂 開著", value: reading { LogFormat.bool($0.trunkFrontOpen) }),
        Column(key: "trunk_rear_open", label: "後車廂 開著", value: reading { LogFormat.bool($0.trunkRearOpen) }),
        Column(key: "closures_state_time", label: "車門資料時間(車)", value: reading { LogFormat.iso($0.closuresStateTimestamp) }),
    ]

    static let header = LogFormat.csvLine(columns.map(\.key))

    static func row(_ sample: Sample) -> String {
        LogFormat.csvLine(columns.map { $0.value(sample) })
    }

    /// The oneof case the vehicle sent; empty when the field is absent,
    /// "unset" when present without a value.
    static func shiftRaw(_ state: CarServer_ShiftState?) -> String {
        guard let state else { return "" }
        switch state.type {
        case .invalid?: return "Invalid"
        case .p?: return "P"
        case .r?: return "R"
        case .n?: return "N"
        case .d?: return "D"
        case .sna?: return "SNA"
        case nil: return "unset"
        }
    }

    static func gear(_ gear: Gear, present: Bool) -> String {
        guard present else { return "" }
        switch gear {
        case .park: return "P"
        case .reverse: return "R"
        case .neutral: return "N"
        case .drive: return "D"
        case .unknown: return "unknown"
        }
    }

    static func chargingRaw(_ state: CarServer_ChargeState.ChargingState?) -> String {
        guard let state else { return "" }
        switch state.type {
        case .unknown?: return "Unknown"
        case .disconnected?: return "Disconnected"
        case .noPower?: return "NoPower"
        case .starting?: return "Starting"
        case .charging?: return "Charging"
        case .complete?: return "Complete"
        case .stopped?: return "Stopped"
        case .calibrating?: return "Calibrating"
        case nil: return "unset"
        }
    }
}
