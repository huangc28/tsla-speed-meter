import Foundation
import SwiftProtobuf
import Testing
@testable import TeslaBLE
import TeslaBLETestSupport

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
            #expect(r.activeRouteDestination == nil)
            #expect(r.activeRouteMinutesToArrival == nil)
            #expect(r.activeRouteMilesToArrival == nil)
            #expect(r.activeRouteKilometersToArrival == nil)
            #expect(r.activeRouteEnergyAtArrival == nil)
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

    /// A drive reply as the car sends it while driving in D, with or without a route set (#77).
    func drivingState(route: Bool) -> CarServer_DriveState {
        var drive = CarServer_DriveState()
        drive.speedFloat = 69.6
        drive.speed = 70
        drive.power = 38
        drive.shiftState.d = CarServer_Void()
        drive.odometerInHundredthsOfAMile = 1_234_567
        drive.timestamp = Google_Protobuf_Timestamp(seconds: 1_767_225_600)
        if route {
            drive.activeRouteDestination = "台北車站"
            drive.activeRouteMinutesToArrival = 17.6
            drive.activeRouteMilesToArrival = 7.46
            drive.activeRouteTrafficMinutesDelay = 0
            drive.activeRouteEnergyAtArrival = 64.3
            drive.activeRouteCoordinates.latitude = 25.0478
            drive.activeRouteCoordinates.longitude = 121.517
        }
        return drive
    }

    @Test("maps the active route of a drive reply, and none without one")
    func activeRoute() {
        let r = reading(drive: drivingState(route: true))
        #expect(r.gear == .drive)
        #expect(r.speedFloat == 69.6)
        #expect(r.activeRouteDestination == "台北車站")
        #expect(r.activeRouteMinutesToArrival == 17.6)
        #expect(r.activeRouteMilesToArrival == 7.46)
        #expect(abs(r.activeRouteKilometersToArrival! - Double(Float(7.46)) * 1.609344) < 1e-9)
        #expect(r.activeRouteEnergyAtArrival == 64.3)

        let none = reading(drive: drivingState(route: false))
        #expect(none.gear == .drive)
        #expect(none.driveStateTimestamp == Date(timeIntervalSince1970: 1_767_225_600))
        #expect(none.activeRouteDestination == nil)
        #expect(none.activeRouteMinutesToArrival == nil)
        #expect(none.activeRouteMilesToArrival == nil)
        #expect(none.activeRouteEnergyAtArrival == nil)

        // Presence comes from the oneof: an empty destination and zeros are still a route.
        var zeros = drivingState(route: false)
        zeros.activeRouteDestination = ""
        zeros.activeRouteMinutesToArrival = 0
        zeros.activeRouteEnergyAtArrival = 0
        let z = reading(drive: zeros)
        #expect(z.activeRouteDestination == "")
        #expect(z.activeRouteMinutesToArrival == 0)
        #expect(z.activeRouteMilesToArrival == nil)
        #expect(z.activeRouteEnergyAtArrival == 0)

        // The route is drive state: a drive-only merge keeps it, a charge-only one does not.
        #expect(VehicleReading(drive: r, charge: nil, tirePressure: nil) == r)
        #expect(VehicleReading(drive: nil, charge: r, tirePressure: nil).activeRouteDestination == nil)
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

    // #78: a closures reply shaped like the car's (doors, trunks, windows, lock, sentry, its own
    // time), with some door and trunk fields left out. Absent is nil, never closed.
    @Test("closures keep presence: false is closed, absent is unknown")
    func closuresWithFieldsMissing() throws {
        var closures = CarServer_ClosuresState()
        closures.doorOpenDriverFront = true
        closures.doorOpenDriverRear = false
        closures.doorOpenPassengerFront = false
        closures.doorOpenTrunkRear = true
        closures.windowOpenDriverFront = false
        closures.windowOpenPassengerFront = false
        closures.windowOpenDriverRear = true
        closures.locked = false
        closures.isUserPresent = true
        closures.sentryModeState.off = CarServer_Void()
        closures.timestamp = .init(date: Date(timeIntervalSince1970: 1_767_225_600))
        var response = CarServer_Response()
        response.actionStatus.result = .operationstatusOk
        response.vehicleData.closuresState = closures
        response.vehicleData.driveState.speedFloat = 30

        let r = try VehicleReading(responsePlaintext: response.serializedData(), category: .closures)
        #expect(r.doorOpenDriverFront == true)
        #expect(r.doorOpenDriverRear == false)
        #expect(r.doorOpenPassengerFront == false)
        #expect(r.doorOpenPassengerRear == nil)
        #expect(r.trunkFrontOpen == nil)
        #expect(r.trunkRearOpen == true)
        #expect(r.closuresStateTimestamp == Date(timeIntervalSince1970: 1_767_225_600))
        // #79: the windows keep presence like the doors.
        #expect(r.windowOpenDriverFront == false && r.windowOpenPassengerFront == false)
        #expect(r.windowOpenDriverRear == true && r.windowOpenPassengerRear == nil)
        // Only the closures category: the drive state in the same reply is left out.
        #expect(r.speedFloat == nil)

        // An empty closures state, and a reply without one: every field nil.
        var empty = CarServer_Response()
        empty.vehicleData.closuresState = CarServer_ClosuresState()
        for plaintext in [try empty.serializedData(), try CarServer_Response.with { $0.vehicleData = .init() }.serializedData()] {
            let none = try VehicleReading(responsePlaintext: plaintext, category: .closures)
            #expect([none.doorOpenDriverFront, none.doorOpenDriverRear, none.doorOpenPassengerFront,
                     none.doorOpenPassengerRear, none.trunkFrontOpen, none.trunkRearOpen, none.windowOpenDriverFront,
                     none.windowOpenDriverRear, none.windowOpenPassengerFront, none.windowOpenPassengerRear].allSatisfy { $0 == nil })
            #expect(none.closuresStateTimestamp == nil)
        }

        // Merged per category, closures come only from the closures reading.
        let merged = VehicleReading(drive: nil, charge: nil, tirePressure: nil, closures: r)
        #expect(merged.trunkRearOpen == true && merged.doorOpenPassengerRear == nil && merged.windowOpenDriverRear == true)
        #expect(VehicleReading(drive: r, charge: r, tirePressure: r).trunkRearOpen == nil)
    }

    // #79: the 車況 card's temperatures, from a climate reply shaped like the car's (with the climate
    // settings around them); absent is nil, and 0 °C stays 0.
    @Test("climate state: outside and inside temperature, presence kept")
    func climate() throws {
        var climate = CarServer_ClimateState()
        climate.outsideTempCelsius = 23.5
        climate.insideTempCelsius = 0
        climate.driverTempSetting = 21
        climate.isClimateOn = false
        climate.timestamp = .init(date: Date(timeIntervalSince1970: 1_767_225_600))
        var response = CarServer_Response()
        response.actionStatus.result = .operationstatusOk
        response.vehicleData.climateState = climate
        response.vehicleData.driveState.speedFloat = 30

        let r = try VehicleReading(responsePlaintext: response.serializedData(), category: .climate)
        #expect(r.outsideTempCelsius == 23.5)
        #expect(r.insideTempCelsius == 0)
        #expect(r.climateStateTimestamp == Date(timeIntervalSince1970: 1_767_225_600))
        #expect(r.speedFloat == nil)

        var outsideOnly = CarServer_Response()
        outsideOnly.vehicleData.climateState.outsideTempCelsius = -4
        let partial = try VehicleReading(responsePlaintext: outsideOnly.serializedData(), category: .climate)
        #expect(partial.outsideTempCelsius == -4 && partial.insideTempCelsius == nil && partial.climateStateTimestamp == nil)

        // Merged per category, the temperatures come only from the climate reading.
        #expect(VehicleReading(drive: nil, charge: nil, tirePressure: nil, climate: r).outsideTempCelsius == 23.5)
        #expect(VehicleReading(drive: r, charge: r, tirePressure: r, closures: r).outsideTempCelsius == nil)
        // The request asks for climate state alone.
        let action = TeslaRequests.getVehicleDataAction(.climate)
        #expect(action.vehicleAction.getVehicleData.hasGetClimateState)
        #expect(!action.vehicleAction.getVehicleData.hasGetDriveState)
    }

    // #79: the odometer is in the drive reply already polled; hundredths of a mile, converted to km.
    @Test("odometer from drive state, in km")
    func odometer() throws {
        var drive = CarServer_DriveState()
        drive.odometerInHundredthsOfAMile = 767_100
        drive.shiftState.p = CarServer_Void()
        let r = reading(drive: drive)
        #expect(r.odometerInHundredthsOfAMile == 767_100)
        // 7,671 mi = 12,345.3 km (07 §5's pair).
        #expect(abs(r.odometerKilometers! - 12_345.27) < 0.01)
        #expect(reading(drive: CarServer_DriveState()).odometerKilometers == nil)
        #expect(VehicleReading(drive: r, charge: nil, tirePressure: nil).odometerInHundredthsOfAMile == 767_100)
        #expect(VehicleReading(drive: nil, charge: r, tirePressure: r).odometerInHundredthsOfAMile == nil)
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

    @Test("a one-category reply fills only that category, and readings merge per category")
    func categories() throws {
        let plaintext = UpstreamResponseVector.responsePlaintext
        let drive = try VehicleReading(responsePlaintext: plaintext, category: .drive)
        let charge = try VehicleReading(responsePlaintext: plaintext, category: .charge)
        let tires = try VehicleReading(responsePlaintext: plaintext, category: .tirePressure)
        #expect(drive.speedFloat == 60.5 && drive.batteryLevel == nil && drive.tirePressureFrontLeft == nil)
        #expect(charge.batteryLevel == 72 && charge.speedFloat == nil && charge.gear == .unknown && charge.tirePressureFrontLeft == nil)
        #expect(tires.tirePressureFrontLeft?.bar == 2.9 && tires.speedFloat == nil && tires.batteryLevel == nil)

        let full = try VehicleReading(responsePlaintext: plaintext)
        #expect(VehicleReading(drive: drive, charge: charge, tirePressure: tires) == full)
        // Each source contributes only its own category, even a full reading.
        let driveOnly = VehicleReading(drive: full, charge: nil, tirePressure: nil)
        #expect(driveOnly == drive)
    }
}
