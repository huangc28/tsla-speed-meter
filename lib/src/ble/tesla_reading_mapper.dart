import '../data/reading.dart';
import 'gen/vehicle.pb.dart';

/// 1 mph in metres per second — keeps BLE speed unit-consistent with GPS.
const double _mphToMs = 0.44704;

/// Maps decoded Tesla vehicle data (CarServer protobuf) into the seam's
/// unified [Reading]. Pure: no BLE or I/O. Absent optional fields stay null.
class TeslaReadingMapper {
  static Reading fromVehicleData({
    required DateTime timestamp,
    required DriveState drive,
    ChargeState? charge,
  }) {
    return Reading(
      timestamp: timestamp,
      speedMs: _speedMs(drive),
      powerKw: drive.hasPower() ? drive.power : null,
      gear: _gear(drive),
      batteryPercent:
          (charge?.hasBatteryLevel() ?? false) ? charge!.batteryLevel : null,
      rangeMiles:
          (charge?.hasBatteryRange() ?? false) ? charge!.batteryRange : null,
    );
  }

  static double? _speedMs(DriveState drive) {
    if (drive.hasSpeedFloat()) return drive.speedFloat * _mphToMs;
    if (drive.hasSpeed()) return drive.speed * _mphToMs;
    return null;
  }

  static Gear _gear(DriveState drive) {
    if (!drive.hasShiftState()) return Gear.unknown;
    switch (drive.shiftState.whichType()) {
      case ShiftState_Type.p:
        return Gear.park;
      case ShiftState_Type.r:
        return Gear.reverse;
      case ShiftState_Type.n:
        return Gear.neutral;
      case ShiftState_Type.d:
        return Gear.drive;
      default:
        return Gear.unknown;
    }
  }
}
