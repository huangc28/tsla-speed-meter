import Foundation
import SwiftProtobuf

/// Gear from the vehicle's shift state.
public enum Gear: Sendable, Equatable {
    case park, reverse, neutral, drive, unknown
}

/// Charging state from `ChargeState.charging_state`.
public enum ChargingState: Sendable, Equatable {
    case unknown, disconnected, noPower, starting, charging, complete, stopped, calibrating
}

/// One tire's pressure. The proto unit is bar (vehicle.proto
/// `TirePressureState`: "tpms pressure values in bar").
public struct TirePressure: Sendable, Equatable {
    public static let psiPerBar = 14.5037738

    /// As reported, in bar.
    public let bar: Float
    /// Vehicle time the sensor last reported, if given.
    public let lastSeen: Date?

    /// Converted from the raw bar value, unrounded.
    public var psi: Double { Double(bar) * Self.psiPerBar }
    /// Whole psi, rounded only after converting (rounding bar first can be
    /// off by one psi).
    public var psiRounded: Int { Int(psi.rounded()) }
}

/// Decoded vehicle data, raw values next to converted ones. Every field is
/// nil when the vehicle did not send it; nothing defaults to 0.
public struct VehicleReading: Sendable, Equatable {
    public static let metersPerSecondPerMph = 0.44704
    public static let kilometersPerMile = 1.609344

    // MARK: Drive state

    /// `DriveState.speed_float` as reported, sign kept. vehicle.proto states
    /// no unit; mph per Tesla's vehicle_data docs and the Dart port.
    public let speedFloat: Float?
    /// `DriveState.speed` (uint32) as reported, same unit.
    public let speed: UInt32?
    /// Speed in m/s, from `speedFloat` when present, else `speed`.
    public var speedMetersPerSecond: Double? {
        if let speedFloat { return Double(speedFloat) * Self.metersPerSecondPerMph }
        if let speed { return Double(speed) * Self.metersPerSecondPerMph }
        return nil
    }

    /// `DriveState.shift_state` as reported.
    public let shiftState: CarServer_ShiftState?
    /// P/R/N/D; Invalid, SNA and absent map to `.unknown`.
    public let gear: Gear

    /// `DriveState.power` as reported (kW per Tesla's vehicle_data docs).
    public let drivePower: Int32?
    public let driveStateTimestamp: Date?

    // MARK: Charge state

    /// `ChargeState.battery_level`, percent.
    public let batteryLevel: Int32?
    /// `ChargeState.battery_range` as reported, in miles.
    public let batteryRangeMiles: Float?
    /// `ChargeState.est_battery_range`, miles.
    public let estBatteryRangeMiles: Float?
    /// `ChargeState.ideal_battery_range`, miles.
    public let idealBatteryRangeMiles: Float?
    public var batteryRangeKilometers: Double? { batteryRangeMiles.map { Double($0) * Self.kilometersPerMile } }
    public var estBatteryRangeKilometers: Double? { estBatteryRangeMiles.map { Double($0) * Self.kilometersPerMile } }
    public var idealBatteryRangeKilometers: Double? { idealBatteryRangeMiles.map { Double($0) * Self.kilometersPerMile } }

    /// `ChargeState.charging_state` as reported.
    public let chargingStateRaw: CarServer_ChargeState.ChargingState?
    /// Nil when absent or of an unrecognized type.
    public let chargingState: ChargingState?
    /// `ChargeState.charger_power` as reported (kW per Tesla's vehicle_data docs).
    public let chargerPower: Int32?
    public let chargeStateTimestamp: Date?

    // MARK: Tire pressure state

    public let tirePressureFrontLeft: TirePressure?
    public let tirePressureFrontRight: TirePressure?
    public let tirePressureRearLeft: TirePressure?
    public let tirePressureRearRight: TirePressure?
    /// `TirePressureState.tpms_last_seen_pressure_time_*`, also kept per wheel
    /// even when that wheel's pressure is absent.
    public let tpmsLastSeenPressureTimeFrontLeft: Date?
    public let tpmsLastSeenPressureTimeFrontRight: Date?
    public let tpmsLastSeenPressureTimeRearLeft: Date?
    public let tpmsLastSeenPressureTimeRearRight: Date?
    public let tirePressureStateTimestamp: Date?
}

extension VehicleReading {
    /// Maps decoded CarServer vehicle data. Pure: no BLE or I/O. Sub-states
    /// the vehicle did not send leave their fields nil.
    public init(vehicleData data: CarServer_VehicleData) {
        let drive: CarServer_DriveState? = data.hasDriveState ? data.driveState : nil
        let charge: CarServer_ChargeState? = data.hasChargeState ? data.chargeState : nil
        let tires: CarServer_TirePressureState? = data.hasTirePressureState ? data.tirePressureState : nil

        if case .speedFloat(let v)? = drive?.optionalSpeedFloat { speedFloat = v } else { speedFloat = nil }
        if case .speed(let v)? = drive?.optionalSpeed { speed = v } else { speed = nil }
        shiftState = (drive?.hasShiftState ?? false) ? drive?.shiftState : nil
        gear = Self.gear(shiftState)
        if case .power(let v)? = drive?.optionalPower { drivePower = v } else { drivePower = nil }
        driveStateTimestamp = Self.date(drive?.hasTimestamp, drive?.timestamp)

        if case .batteryLevel(let v)? = charge?.optionalBatteryLevel { batteryLevel = v } else { batteryLevel = nil }
        if case .batteryRange(let v)? = charge?.optionalBatteryRange { batteryRangeMiles = v } else { batteryRangeMiles = nil }
        if case .estBatteryRange(let v)? = charge?.optionalEstBatteryRange { estBatteryRangeMiles = v } else { estBatteryRangeMiles = nil }
        if case .idealBatteryRange(let v)? = charge?.optionalIdealBatteryRange { idealBatteryRangeMiles = v } else { idealBatteryRangeMiles = nil }
        chargingStateRaw = (charge?.hasChargingState ?? false) ? charge?.chargingState : nil
        chargingState = Self.chargingState(chargingStateRaw)
        if case .chargerPower(let v)? = charge?.optionalChargerPower { chargerPower = v } else { chargerPower = nil }
        chargeStateTimestamp = Self.date(charge?.hasTimestamp, charge?.timestamp)

        tpmsLastSeenPressureTimeFrontLeft = Self.date(tires?.hasTpmsLastSeenPressureTimeFl, tires?.tpmsLastSeenPressureTimeFl)
        tpmsLastSeenPressureTimeFrontRight = Self.date(tires?.hasTpmsLastSeenPressureTimeFr, tires?.tpmsLastSeenPressureTimeFr)
        tpmsLastSeenPressureTimeRearLeft = Self.date(tires?.hasTpmsLastSeenPressureTimeRl, tires?.tpmsLastSeenPressureTimeRl)
        tpmsLastSeenPressureTimeRearRight = Self.date(tires?.hasTpmsLastSeenPressureTimeRr, tires?.tpmsLastSeenPressureTimeRr)
        if case .tpmsPressureFl(let v)? = tires?.optionalTpmsPressureFl {
            tirePressureFrontLeft = TirePressure(bar: v, lastSeen: tpmsLastSeenPressureTimeFrontLeft)
        } else { tirePressureFrontLeft = nil }
        if case .tpmsPressureFr(let v)? = tires?.optionalTpmsPressureFr {
            tirePressureFrontRight = TirePressure(bar: v, lastSeen: tpmsLastSeenPressureTimeFrontRight)
        } else { tirePressureFrontRight = nil }
        if case .tpmsPressureRl(let v)? = tires?.optionalTpmsPressureRl {
            tirePressureRearLeft = TirePressure(bar: v, lastSeen: tpmsLastSeenPressureTimeRearLeft)
        } else { tirePressureRearLeft = nil }
        if case .tpmsPressureRr(let v)? = tires?.optionalTpmsPressureRr {
            tirePressureRearRight = TirePressure(bar: v, lastSeen: tpmsLastSeenPressureTimeRearRight)
        } else { tirePressureRearRight = nil }
        tirePressureStateTimestamp = Self.date(tires?.hasTimestamp, tires?.timestamp)
    }

    /// Parses a decrypted infotainment reply (`CarServer.Response`) and maps
    /// its vehicle data.
    public init(responsePlaintext: Data) throws {
        self.init(vehicleData: try Self.vehicleData(responsePlaintext: responsePlaintext))
    }

    /// Parses a decrypted reply to a one-category request and maps only
    /// that category's sub-state, so a reply never fills another
    /// category's fields.
    public init(responsePlaintext: Data, category: VehicleDataCategory) throws {
        let data = try Self.vehicleData(responsePlaintext: responsePlaintext)
        var only = CarServer_VehicleData()
        switch category {
        case .drive: if data.hasDriveState { only.driveState = data.driveState }
        case .charge: if data.hasChargeState { only.chargeState = data.chargeState }
        case .tirePressure: if data.hasTirePressureState { only.tirePressureState = data.tirePressureState }
        }
        self.init(vehicleData: only)
    }

    /// One reading from per-category readings: drive-state fields from
    /// `drive`, charge-state fields from `charge`, tire-pressure fields from
    /// `tirePressure`. A missing category leaves its fields nil.
    public init(drive: VehicleReading?, charge: VehicleReading?, tirePressure: VehicleReading?) {
        self.init(
            speedFloat: drive?.speedFloat,
            speed: drive?.speed,
            shiftState: drive?.shiftState,
            gear: drive?.gear ?? .unknown,
            drivePower: drive?.drivePower,
            driveStateTimestamp: drive?.driveStateTimestamp,
            batteryLevel: charge?.batteryLevel,
            batteryRangeMiles: charge?.batteryRangeMiles,
            estBatteryRangeMiles: charge?.estBatteryRangeMiles,
            idealBatteryRangeMiles: charge?.idealBatteryRangeMiles,
            chargingStateRaw: charge?.chargingStateRaw,
            chargingState: charge?.chargingState,
            chargerPower: charge?.chargerPower,
            chargeStateTimestamp: charge?.chargeStateTimestamp,
            tirePressureFrontLeft: tirePressure?.tirePressureFrontLeft,
            tirePressureFrontRight: tirePressure?.tirePressureFrontRight,
            tirePressureRearLeft: tirePressure?.tirePressureRearLeft,
            tirePressureRearRight: tirePressure?.tirePressureRearRight,
            tpmsLastSeenPressureTimeFrontLeft: tirePressure?.tpmsLastSeenPressureTimeFrontLeft,
            tpmsLastSeenPressureTimeFrontRight: tirePressure?.tpmsLastSeenPressureTimeFrontRight,
            tpmsLastSeenPressureTimeRearLeft: tirePressure?.tpmsLastSeenPressureTimeRearLeft,
            tpmsLastSeenPressureTimeRearRight: tirePressure?.tpmsLastSeenPressureTimeRearRight,
            tirePressureStateTimestamp: tirePressure?.tirePressureStateTimestamp
        )
    }

    static func vehicleData(responsePlaintext: Data) throws -> CarServer_VehicleData {
        let response = try CarServer_Response(serializedBytes: responsePlaintext)
        if response.actionStatus.result != .operationstatusOk {
            throw VehicleReadingError.actionFailed(response.actionStatus.resultReason.plainText)
        }
        guard case .vehicleData(let data)? = response.responseMsg else {
            throw VehicleReadingError.missingVehicleData
        }
        return data
    }

    static func gear(_ shiftState: CarServer_ShiftState?) -> Gear {
        switch shiftState?.type {
        case .p?: .park
        case .r?: .reverse
        case .n?: .neutral
        case .d?: .drive
        case .invalid?, .sna?, nil: .unknown
        }
    }

    static func chargingState(_ raw: CarServer_ChargeState.ChargingState?) -> ChargingState? {
        switch raw?.type {
        case .unknown?: .unknown
        case .disconnected?: .disconnected
        case .noPower?: .noPower
        case .starting?: .starting
        case .charging?: .charging
        case .complete?: .complete
        case .stopped?: .stopped
        case .calibrating?: .calibrating
        case nil: nil
        }
    }

    static func date(_ has: Bool?, _ timestamp: Google_Protobuf_Timestamp?) -> Date? {
        guard has == true, let timestamp else { return nil }
        return timestamp.date
    }
}

public enum VehicleReadingError: Error, Equatable {
    /// `Response.actionStatus.result` was an error; carries the vehicle's reason.
    case actionFailed(String)
    /// The response carried no `vehicleData`.
    case missingVehicleData
}
