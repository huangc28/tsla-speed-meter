import Foundation
import SwiftProtobuf
import Testing
@testable import TeslaBLE

// Port of test/ble/tesla_reading_mapper_test.dart (feature/goal-2-ble), plus
// gear, TPMS, range and nil-handling cases.
@Suite("VehicleReading mapper")
struct VehicleReadingTests {
    func reading(
        drive: CarServer_DriveState? = nil,
        charge: CarServer_ChargeState? = nil,
        tires: CarServer_TirePressureState? = nil
    ) -> VehicleReading {
        var data = CarServer_VehicleData()
        if let drive { data.driveState = drive }
        if let charge { data.chargeState = charge }
        if let tires { data.tirePressureState = tires }
        return VehicleReading(vehicleData: data)
    }

    @Test("maps a moving, charged vehicle (mph -> m/s)")
    func movingVehicle() {
        var drive = CarServer_DriveState()
        drive.speedFloat = 60.0
        drive.power = 45
        drive.shiftState.d = CarServer_Void()
        var charge = CarServer_ChargeState()
        charge.batteryLevel = 72
        charge.batteryRange = 211.5

        let r = reading(drive: drive, charge: charge)
        // 60 mph == 26.8224 m/s.
        #expect(abs(r.speedMetersPerSecond! - 26.8224) < 1e-4)
        #expect(r.speedFloat == 60.0)
        #expect(r.gear == .drive)
        #expect(r.drivePower == 45)
        #expect(r.batteryLevel == 72)
        #expect(r.batteryRangeMiles == 211.5)
        #expect(abs(r.batteryRangeKilometers! - 340.376256) < 1e-6)
    }

    @Test("uses integer speed when speed_float is absent")
    func integerSpeed() {
        var drive = CarServer_DriveState()
        drive.speed = 30
        let r = reading(drive: drive)
        #expect(r.speed == 30)
        #expect(r.speedFloat == nil)
        #expect(abs(r.speedMetersPerSecond! - 13.4112) < 1e-4)
    }

    @Test("keeps the sign of a negative speed_float")
    func negativeSpeed() {
        var drive = CarServer_DriveState()
        drive.speedFloat = -3.5
        let r = reading(drive: drive)
        #expect(r.speedFloat == -3.5)
        #expect(abs(r.speedMetersPerSecond! - (-1.56464)) < 1e-6)
    }

    @Test("maps each gear; Invalid, SNA and absent are unknown")
    func gears() {
        func gear(_ set: ((inout CarServer_ShiftState) -> Void)?) -> Gear {
            var drive = CarServer_DriveState()
            if let set { set(&drive.shiftState) }
            return reading(drive: drive).gear
        }
        #expect(gear { $0.p = CarServer_Void() } == .park)
        #expect(gear { $0.r = CarServer_Void() } == .reverse)
        #expect(gear { $0.n = CarServer_Void() } == .neutral)
        #expect(gear { $0.d = CarServer_Void() } == .drive)
        #expect(gear { $0.invalid = CarServer_Void() } == .unknown)
        #expect(gear { $0.sna = CarServer_Void() } == .unknown)
        #expect(gear(nil) == .unknown)
        #expect(reading().gear == .unknown)

        var drive = CarServer_DriveState()
        drive.shiftState.r = CarServer_Void()
        #expect(reading(drive: drive).shiftState?.type == .r(CarServer_Void()))
    }

    @Test("leaves fields nil when the vehicle omits them")
    func nilWhenAbsent() {
        let empty = reading(drive: CarServer_DriveState(), charge: CarServer_ChargeState(), tires: CarServer_TirePressureState())
        let none = reading()
        for r in [empty, none] {
            #expect(r.speed == nil)
            #expect(r.speedFloat == nil)
            #expect(r.speedMetersPerSecond == nil)
            #expect(r.shiftState == nil)
            #expect(r.drivePower == nil)
            #expect(r.driveStateTimestamp == nil)
            #expect(r.batteryLevel == nil)
            #expect(r.batteryRangeMiles == nil)
            #expect(r.batteryRangeKilometers == nil)
            #expect(r.estBatteryRangeMiles == nil)
            #expect(r.idealBatteryRangeMiles == nil)
            #expect(r.chargingStateRaw == nil)
            #expect(r.chargingState == nil)
            #expect(r.chargerPower == nil)
            #expect(r.chargeStateTimestamp == nil)
            #expect(r.tirePressureFrontLeft == nil)
            #expect(r.tirePressureFrontRight == nil)
            #expect(r.tirePressureRearLeft == nil)
            #expect(r.tirePressureRearRight == nil)
            #expect(r.tpmsLastSeenPressureTimeFrontLeft == nil)
            #expect(r.tpmsLastSeenPressureTimeRearRight == nil)
            #expect(r.tirePressureStateTimestamp == nil)
        }
    }

    @Test("keeps explicit zeros distinct from absent values")
    func zeroIsNotNil() {
        var drive = CarServer_DriveState()
        drive.speed = 0
        drive.power = 0
        var charge = CarServer_ChargeState()
        charge.chargerPower = 0
        charge.batteryLevel = 0
        var tires = CarServer_TirePressureState()
        tires.tpmsPressureFl = 0

        let r = reading(drive: drive, charge: charge, tires: tires)
        #expect(r.speed == 0)
        #expect(r.speedMetersPerSecond == 0)
        #expect(r.drivePower == 0)
        #expect(r.chargerPower == 0)
        #expect(r.batteryLevel == 0)
        #expect(r.tirePressureFrontLeft?.bar == 0)
    }

    @Test("maps charge state, ranges and charger power")
    func chargeState() {
        var charge = CarServer_ChargeState()
        charge.chargingState.charging = CarServer_Void()
        charge.chargerPower = 11
        charge.estBatteryRange = 180.25
        charge.idealBatteryRange = 230
        charge.timestamp = Google_Protobuf_Timestamp(seconds: 1_767_225_600)

        let r = reading(charge: charge)
        #expect(r.chargingState == .charging)
        #expect(r.chargingStateRaw?.type == .charging(CarServer_Void()))
        #expect(r.chargerPower == 11)
        #expect(r.estBatteryRangeMiles == 180.25)
        #expect(abs(r.estBatteryRangeKilometers! - 290.084256) < 1e-6)
        #expect(r.idealBatteryRangeMiles == 230)
        #expect(abs(r.idealBatteryRangeKilometers! - 370.14912) < 1e-4)
        #expect(r.chargeStateTimestamp == Date(timeIntervalSince1970: 1_767_225_600))

        func state(_ set: (inout CarServer_ChargeState.ChargingState) -> Void) -> ChargingState? {
            var c = CarServer_ChargeState()
            set(&c.chargingState)
            return reading(charge: c).chargingState
        }
        #expect(state { $0.unknown = CarServer_Void() } == .unknown)
        #expect(state { $0.disconnected = CarServer_Void() } == .disconnected)
        #expect(state { $0.noPower = CarServer_Void() } == .noPower)
        #expect(state { $0.starting = CarServer_Void() } == .starting)
        #expect(state { $0.complete = CarServer_Void() } == .complete)
        #expect(state { $0.stopped = CarServer_Void() } == .stopped)
        #expect(state { $0.calibrating = CarServer_Void() } == .calibrating)
    }

    @Test("converts TPMS bar to psi and rounds only after converting")
    func tirePressure() {
        var tires = CarServer_TirePressureState()
        tires.tpmsPressureFl = 2.86
        tires.tpmsPressureFr = 2.9
        tires.tpmsPressureRr = 3.0
        tires.tpmsLastSeenPressureTimeFl = Google_Protobuf_Timestamp(seconds: 1_767_225_000)
        tires.tpmsLastSeenPressureTimeRl = Google_Protobuf_Timestamp(seconds: 1_767_224_000)
        tires.timestamp = Google_Protobuf_Timestamp(seconds: 1_767_225_600)

        let r = reading(tires: tires)
        let fl = r.tirePressureFrontLeft!
        #expect(fl.bar == 2.86)
        #expect(abs(fl.psi - Double(Float(2.86)) * 14.5037738) < 1e-12)
        // 2.86 bar = 41.48 psi -> 41. Rounding bar to 2.9 first would give 42.
        #expect(fl.psiRounded == 41)
        #expect(fl.lastSeen == Date(timeIntervalSince1970: 1_767_225_000))
        #expect(r.tirePressureFrontRight?.psiRounded == 42)
        #expect(r.tirePressureFrontRight?.lastSeen == nil)
        #expect(abs(r.tirePressureRearRight!.psi - 43.5113214) < 1e-6)

        // A last-seen time without a pressure is still reported.
        #expect(r.tirePressureRearLeft == nil)
        #expect(r.tpmsLastSeenPressureTimeRearLeft == Date(timeIntervalSince1970: 1_767_224_000))
        #expect(r.tpmsLastSeenPressureTimeFrontLeft == Date(timeIntervalSince1970: 1_767_225_000))
        #expect(r.tpmsLastSeenPressureTimeFrontRight == nil)
        #expect(r.tirePressureStateTimestamp == Date(timeIntervalSince1970: 1_767_225_600))
    }

    @Test("parses a CarServer.Response and rejects errors or missing data")
    func responseParsing() throws {
        var ok = CarServer_Response()
        ok.vehicleData.driveState.speed = 12
        #expect(try VehicleReading(responsePlaintext: ok.serializedData()).speed == 12)

        var failed = CarServer_Response()
        failed.actionStatus.result = .rror // OPERATIONSTATUS_ERROR
        failed.actionStatus.resultReason.plainText = "vehicle asleep"
        #expect(throws: VehicleReadingError.actionFailed("vehicle asleep")) {
            try VehicleReading(responsePlaintext: failed.serializedData())
        }

        var ping = CarServer_Response()
        ping.ping = CarServer_Ping()
        #expect(throws: VehicleReadingError.missingVehicleData) {
            try VehicleReading(responsePlaintext: ping.serializedData())
        }
    }
}
