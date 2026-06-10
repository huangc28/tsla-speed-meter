// This is a generated file - do not edit.
//
// Generated from car_server.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports
// ignore_for_file: unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use operationStatus_EDescriptor instead')
const OperationStatus_E$json = {
  '1': 'OperationStatus_E',
  '2': [
    {'1': 'OPERATIONSTATUS_OK', '2': 0},
    {'1': 'OPERATIONSTATUS_ERROR', '2': 1},
  ],
};

/// Descriptor for `OperationStatus_E`. Decode as a `google.protobuf.EnumDescriptorProto`.
final $typed_data.Uint8List operationStatus_EDescriptor = $convert.base64Decode(
    'ChFPcGVyYXRpb25TdGF0dXNfRRIWChJPUEVSQVRJT05TVEFUVVNfT0sQABIZChVPUEVSQVRJT0'
    '5TVEFUVVNfRVJST1IQAQ==');

@$core.Deprecated('Use actionDescriptor instead')
const Action$json = {
  '1': 'Action',
  '2': [
    {
      '1': 'vehicleAction',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleAction',
      '9': 0,
      '10': 'vehicleAction'
    },
  ],
  '8': [
    {'1': 'action_msg'},
  ],
  '9': [
    {'1': 3, '2': 6},
  ],
};

/// Descriptor for `Action`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List actionDescriptor = $convert.base64Decode(
    'CgZBY3Rpb24SQAoNdmVoaWNsZUFjdGlvbhgCIAEoCzIYLkNhclNlcnZlci5WZWhpY2xlQWN0aW'
    '9uSABSDXZlaGljbGVBY3Rpb25CDAoKYWN0aW9uX21zZ0oECAMQBg==');

@$core.Deprecated('Use vehicleActionDescriptor instead')
const VehicleAction$json = {
  '1': 'VehicleAction',
  '2': [
    {
      '1': 'getVehicleData',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetVehicleData',
      '9': 0,
      '10': 'getVehicleData'
    },
    {
      '1': 'chargingSetLimitAction',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.CarServer.ChargingSetLimitAction',
      '9': 0,
      '10': 'chargingSetLimitAction'
    },
    {
      '1': 'chargingStartStopAction',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.CarServer.ChargingStartStopAction',
      '9': 0,
      '10': 'chargingStartStopAction'
    },
    {
      '1': 'drivingClearSpeedLimitPinAction',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.CarServer.DrivingClearSpeedLimitPinAction',
      '9': 0,
      '10': 'drivingClearSpeedLimitPinAction'
    },
    {
      '1': 'drivingSetSpeedLimitAction',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.CarServer.DrivingSetSpeedLimitAction',
      '9': 0,
      '10': 'drivingSetSpeedLimitAction'
    },
    {
      '1': 'drivingSpeedLimitAction',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.CarServer.DrivingSpeedLimitAction',
      '9': 0,
      '10': 'drivingSpeedLimitAction'
    },
    {
      '1': 'hvacAutoAction',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.CarServer.HvacAutoAction',
      '9': 0,
      '10': 'hvacAutoAction'
    },
    {
      '1': 'hvacSetPreconditioningMaxAction',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.CarServer.HvacSetPreconditioningMaxAction',
      '9': 0,
      '10': 'hvacSetPreconditioningMaxAction'
    },
    {
      '1': 'hvacSteeringWheelHeaterAction',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.CarServer.HvacSteeringWheelHeaterAction',
      '9': 0,
      '10': 'hvacSteeringWheelHeaterAction'
    },
    {
      '1': 'hvacTemperatureAdjustmentAction',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.CarServer.HvacTemperatureAdjustmentAction',
      '9': 0,
      '10': 'hvacTemperatureAdjustmentAction'
    },
    {
      '1': 'mediaPlayAction',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.CarServer.MediaPlayAction',
      '9': 0,
      '10': 'mediaPlayAction'
    },
    {
      '1': 'mediaUpdateVolume',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.CarServer.MediaUpdateVolume',
      '9': 0,
      '10': 'mediaUpdateVolume'
    },
    {
      '1': 'mediaNextFavorite',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.CarServer.MediaNextFavorite',
      '9': 0,
      '10': 'mediaNextFavorite'
    },
    {
      '1': 'mediaPreviousFavorite',
      '3': 18,
      '4': 1,
      '5': 11,
      '6': '.CarServer.MediaPreviousFavorite',
      '9': 0,
      '10': 'mediaPreviousFavorite'
    },
    {
      '1': 'mediaNextTrack',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.CarServer.MediaNextTrack',
      '9': 0,
      '10': 'mediaNextTrack'
    },
    {
      '1': 'mediaPreviousTrack',
      '3': 20,
      '4': 1,
      '5': 11,
      '6': '.CarServer.MediaPreviousTrack',
      '9': 0,
      '10': 'mediaPreviousTrack'
    },
    {
      '1': 'getNearbyChargingSites',
      '3': 23,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetNearbyChargingSites',
      '9': 0,
      '10': 'getNearbyChargingSites'
    },
    {
      '1': 'vehicleControlCancelSoftwareUpdateAction',
      '3': 25,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleControlCancelSoftwareUpdateAction',
      '9': 0,
      '10': 'vehicleControlCancelSoftwareUpdateAction'
    },
    {
      '1': 'vehicleControlFlashLightsAction',
      '3': 26,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleControlFlashLightsAction',
      '9': 0,
      '10': 'vehicleControlFlashLightsAction'
    },
    {
      '1': 'vehicleControlHonkHornAction',
      '3': 27,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleControlHonkHornAction',
      '9': 0,
      '10': 'vehicleControlHonkHornAction'
    },
    {
      '1': 'vehicleControlResetValetPinAction',
      '3': 28,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleControlResetValetPinAction',
      '9': 0,
      '10': 'vehicleControlResetValetPinAction'
    },
    {
      '1': 'vehicleControlScheduleSoftwareUpdateAction',
      '3': 29,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleControlScheduleSoftwareUpdateAction',
      '9': 0,
      '10': 'vehicleControlScheduleSoftwareUpdateAction'
    },
    {
      '1': 'vehicleControlSetSentryModeAction',
      '3': 30,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleControlSetSentryModeAction',
      '9': 0,
      '10': 'vehicleControlSetSentryModeAction'
    },
    {
      '1': 'vehicleControlSetValetModeAction',
      '3': 31,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleControlSetValetModeAction',
      '9': 0,
      '10': 'vehicleControlSetValetModeAction'
    },
    {
      '1': 'vehicleControlSunroofOpenCloseAction',
      '3': 32,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleControlSunroofOpenCloseAction',
      '9': 0,
      '10': 'vehicleControlSunroofOpenCloseAction'
    },
    {
      '1': 'vehicleControlTriggerHomelinkAction',
      '3': 33,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleControlTriggerHomelinkAction',
      '9': 0,
      '10': 'vehicleControlTriggerHomelinkAction'
    },
    {
      '1': 'vehicleControlWindowAction',
      '3': 34,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleControlWindowAction',
      '9': 0,
      '10': 'vehicleControlWindowAction'
    },
    {
      '1': 'hvacBioweaponModeAction',
      '3': 35,
      '4': 1,
      '5': 11,
      '6': '.CarServer.HvacBioweaponModeAction',
      '9': 0,
      '10': 'hvacBioweaponModeAction'
    },
    {
      '1': 'hvacSeatHeaterActions',
      '3': 36,
      '4': 1,
      '5': 11,
      '6': '.CarServer.HvacSeatHeaterActions',
      '9': 0,
      '10': 'hvacSeatHeaterActions'
    },
    {
      '1': 'scheduledChargingAction',
      '3': 41,
      '4': 1,
      '5': 11,
      '6': '.CarServer.ScheduledChargingAction',
      '9': 0,
      '10': 'scheduledChargingAction'
    },
    {
      '1': 'scheduledDepartureAction',
      '3': 42,
      '4': 1,
      '5': 11,
      '6': '.CarServer.ScheduledDepartureAction',
      '9': 0,
      '10': 'scheduledDepartureAction'
    },
    {
      '1': 'setChargingAmpsAction',
      '3': 43,
      '4': 1,
      '5': 11,
      '6': '.CarServer.SetChargingAmpsAction',
      '9': 0,
      '10': 'setChargingAmpsAction'
    },
    {
      '1': 'hvacClimateKeeperAction',
      '3': 44,
      '4': 1,
      '5': 11,
      '6': '.CarServer.HvacClimateKeeperAction',
      '9': 0,
      '10': 'hvacClimateKeeperAction'
    },
    {
      '1': 'ping',
      '3': 46,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Ping',
      '9': 0,
      '10': 'ping'
    },
    {
      '1': 'autoSeatClimateAction',
      '3': 48,
      '4': 1,
      '5': 11,
      '6': '.CarServer.AutoSeatClimateAction',
      '9': 0,
      '10': 'autoSeatClimateAction'
    },
    {
      '1': 'hvacSeatCoolerActions',
      '3': 49,
      '4': 1,
      '5': 11,
      '6': '.CarServer.HvacSeatCoolerActions',
      '9': 0,
      '10': 'hvacSeatCoolerActions'
    },
    {
      '1': 'setCabinOverheatProtectionAction',
      '3': 50,
      '4': 1,
      '5': 11,
      '6': '.CarServer.SetCabinOverheatProtectionAction',
      '9': 0,
      '10': 'setCabinOverheatProtectionAction'
    },
    {
      '1': 'setVehicleNameAction',
      '3': 54,
      '4': 1,
      '5': 11,
      '6': '.CarServer.SetVehicleNameAction',
      '9': 0,
      '10': 'setVehicleNameAction'
    },
    {
      '1': 'chargePortDoorClose',
      '3': 61,
      '4': 1,
      '5': 11,
      '6': '.CarServer.ChargePortDoorClose',
      '9': 0,
      '10': 'chargePortDoorClose'
    },
    {
      '1': 'chargePortDoorOpen',
      '3': 62,
      '4': 1,
      '5': 11,
      '6': '.CarServer.ChargePortDoorOpen',
      '9': 0,
      '10': 'chargePortDoorOpen'
    },
    {
      '1': 'guestModeAction',
      '3': 65,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleState.GuestMode',
      '9': 0,
      '10': 'guestModeAction'
    },
    {
      '1': 'setCopTempAction',
      '3': 66,
      '4': 1,
      '5': 11,
      '6': '.CarServer.SetCopTempAction',
      '9': 0,
      '10': 'setCopTempAction'
    },
    {
      '1': 'eraseUserDataAction',
      '3': 72,
      '4': 1,
      '5': 11,
      '6': '.CarServer.EraseUserDataAction',
      '9': 0,
      '10': 'eraseUserDataAction'
    },
    {
      '1': 'vehicleControlSetPinToDriveAction',
      '3': 77,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleControlSetPinToDriveAction',
      '9': 0,
      '10': 'vehicleControlSetPinToDriveAction'
    },
    {
      '1': 'vehicleControlResetPinToDriveAction',
      '3': 78,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleControlResetPinToDriveAction',
      '9': 0,
      '10': 'vehicleControlResetPinToDriveAction'
    },
    {
      '1': 'drivingClearSpeedLimitPinAdminAction',
      '3': 79,
      '4': 1,
      '5': 11,
      '6': '.CarServer.DrivingClearSpeedLimitPinAdminAction',
      '9': 0,
      '10': 'drivingClearSpeedLimitPinAdminAction'
    },
    {
      '1': 'vehicleControlResetPinToDriveAdminAction',
      '3': 89,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleControlResetPinToDriveAdminAction',
      '9': 0,
      '10': 'vehicleControlResetPinToDriveAdminAction'
    },
    {
      '1': 'addChargeScheduleAction',
      '3': 97,
      '4': 1,
      '5': 11,
      '6': '.CarServer.ChargeSchedule',
      '9': 0,
      '10': 'addChargeScheduleAction'
    },
    {
      '1': 'removeChargeScheduleAction',
      '3': 98,
      '4': 1,
      '5': 11,
      '6': '.CarServer.RemoveChargeScheduleAction',
      '9': 0,
      '10': 'removeChargeScheduleAction'
    },
    {
      '1': 'addPreconditionScheduleAction',
      '3': 99,
      '4': 1,
      '5': 11,
      '6': '.CarServer.PreconditionSchedule',
      '9': 0,
      '10': 'addPreconditionScheduleAction'
    },
    {
      '1': 'removePreconditionScheduleAction',
      '3': 100,
      '4': 1,
      '5': 11,
      '6': '.CarServer.RemovePreconditionScheduleAction',
      '9': 0,
      '10': 'removePreconditionScheduleAction'
    },
    {
      '1': 'batchRemovePreconditionSchedulesAction',
      '3': 107,
      '4': 1,
      '5': 11,
      '6': '.CarServer.BatchRemovePreconditionSchedulesAction',
      '9': 0,
      '10': 'batchRemovePreconditionSchedulesAction'
    },
    {
      '1': 'batchRemoveChargeSchedulesAction',
      '3': 108,
      '4': 1,
      '5': 11,
      '6': '.CarServer.BatchRemoveChargeSchedulesAction',
      '9': 0,
      '10': 'batchRemoveChargeSchedulesAction'
    },
    {
      '1': 'setLowPowerModeAction',
      '3': 130,
      '4': 1,
      '5': 11,
      '6': '.CarServer.SetLowPowerModeAction',
      '9': 0,
      '10': 'setLowPowerModeAction'
    },
    {
      '1': 'setKeepAccessoryPowerModeAction',
      '3': 138,
      '4': 1,
      '5': 11,
      '6': '.CarServer.SetKeepAccessoryPowerModeAction',
      '9': 0,
      '10': 'setKeepAccessoryPowerModeAction'
    },
  ],
  '8': [
    {'1': 'vehicle_action_msg'},
  ],
  '9': [
    {'1': 11, '2': 12},
    {'1': 60, '2': 61},
    {'1': 76, '2': 77},
  ],
};

/// Descriptor for `VehicleAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleActionDescriptor = $convert.base64Decode(
    'Cg1WZWhpY2xlQWN0aW9uEkMKDmdldFZlaGljbGVEYXRhGAEgASgLMhkuQ2FyU2VydmVyLkdldF'
    'ZlaGljbGVEYXRhSABSDmdldFZlaGljbGVEYXRhElsKFmNoYXJnaW5nU2V0TGltaXRBY3Rpb24Y'
    'BSABKAsyIS5DYXJTZXJ2ZXIuQ2hhcmdpbmdTZXRMaW1pdEFjdGlvbkgAUhZjaGFyZ2luZ1NldE'
    'xpbWl0QWN0aW9uEl4KF2NoYXJnaW5nU3RhcnRTdG9wQWN0aW9uGAYgASgLMiIuQ2FyU2VydmVy'
    'LkNoYXJnaW5nU3RhcnRTdG9wQWN0aW9uSABSF2NoYXJnaW5nU3RhcnRTdG9wQWN0aW9uEnYKH2'
    'RyaXZpbmdDbGVhclNwZWVkTGltaXRQaW5BY3Rpb24YByABKAsyKi5DYXJTZXJ2ZXIuRHJpdmlu'
    'Z0NsZWFyU3BlZWRMaW1pdFBpbkFjdGlvbkgAUh9kcml2aW5nQ2xlYXJTcGVlZExpbWl0UGluQW'
    'N0aW9uEmcKGmRyaXZpbmdTZXRTcGVlZExpbWl0QWN0aW9uGAggASgLMiUuQ2FyU2VydmVyLkRy'
    'aXZpbmdTZXRTcGVlZExpbWl0QWN0aW9uSABSGmRyaXZpbmdTZXRTcGVlZExpbWl0QWN0aW9uEl'
    '4KF2RyaXZpbmdTcGVlZExpbWl0QWN0aW9uGAkgASgLMiIuQ2FyU2VydmVyLkRyaXZpbmdTcGVl'
    'ZExpbWl0QWN0aW9uSABSF2RyaXZpbmdTcGVlZExpbWl0QWN0aW9uEkMKDmh2YWNBdXRvQWN0aW'
    '9uGAogASgLMhkuQ2FyU2VydmVyLkh2YWNBdXRvQWN0aW9uSABSDmh2YWNBdXRvQWN0aW9uEnYK'
    'H2h2YWNTZXRQcmVjb25kaXRpb25pbmdNYXhBY3Rpb24YDCABKAsyKi5DYXJTZXJ2ZXIuSHZhY1'
    'NldFByZWNvbmRpdGlvbmluZ01heEFjdGlvbkgAUh9odmFjU2V0UHJlY29uZGl0aW9uaW5nTWF4'
    'QWN0aW9uEnAKHWh2YWNTdGVlcmluZ1doZWVsSGVhdGVyQWN0aW9uGA0gASgLMiguQ2FyU2Vydm'
    'VyLkh2YWNTdGVlcmluZ1doZWVsSGVhdGVyQWN0aW9uSABSHWh2YWNTdGVlcmluZ1doZWVsSGVh'
    'dGVyQWN0aW9uEnYKH2h2YWNUZW1wZXJhdHVyZUFkanVzdG1lbnRBY3Rpb24YDiABKAsyKi5DYX'
    'JTZXJ2ZXIuSHZhY1RlbXBlcmF0dXJlQWRqdXN0bWVudEFjdGlvbkgAUh9odmFjVGVtcGVyYXR1'
    'cmVBZGp1c3RtZW50QWN0aW9uEkYKD21lZGlhUGxheUFjdGlvbhgPIAEoCzIaLkNhclNlcnZlci'
    '5NZWRpYVBsYXlBY3Rpb25IAFIPbWVkaWFQbGF5QWN0aW9uEkwKEW1lZGlhVXBkYXRlVm9sdW1l'
    'GBAgASgLMhwuQ2FyU2VydmVyLk1lZGlhVXBkYXRlVm9sdW1lSABSEW1lZGlhVXBkYXRlVm9sdW'
    '1lEkwKEW1lZGlhTmV4dEZhdm9yaXRlGBEgASgLMhwuQ2FyU2VydmVyLk1lZGlhTmV4dEZhdm9y'
    'aXRlSABSEW1lZGlhTmV4dEZhdm9yaXRlElgKFW1lZGlhUHJldmlvdXNGYXZvcml0ZRgSIAEoCz'
    'IgLkNhclNlcnZlci5NZWRpYVByZXZpb3VzRmF2b3JpdGVIAFIVbWVkaWFQcmV2aW91c0Zhdm9y'
    'aXRlEkMKDm1lZGlhTmV4dFRyYWNrGBMgASgLMhkuQ2FyU2VydmVyLk1lZGlhTmV4dFRyYWNrSA'
    'BSDm1lZGlhTmV4dFRyYWNrEk8KEm1lZGlhUHJldmlvdXNUcmFjaxgUIAEoCzIdLkNhclNlcnZl'
    'ci5NZWRpYVByZXZpb3VzVHJhY2tIAFISbWVkaWFQcmV2aW91c1RyYWNrElsKFmdldE5lYXJieU'
    'NoYXJnaW5nU2l0ZXMYFyABKAsyIS5DYXJTZXJ2ZXIuR2V0TmVhcmJ5Q2hhcmdpbmdTaXRlc0gA'
    'UhZnZXROZWFyYnlDaGFyZ2luZ1NpdGVzEpEBCih2ZWhpY2xlQ29udHJvbENhbmNlbFNvZnR3YX'
    'JlVXBkYXRlQWN0aW9uGBkgASgLMjMuQ2FyU2VydmVyLlZlaGljbGVDb250cm9sQ2FuY2VsU29m'
    'dHdhcmVVcGRhdGVBY3Rpb25IAFIodmVoaWNsZUNvbnRyb2xDYW5jZWxTb2Z0d2FyZVVwZGF0ZU'
    'FjdGlvbhJ2Ch92ZWhpY2xlQ29udHJvbEZsYXNoTGlnaHRzQWN0aW9uGBogASgLMiouQ2FyU2Vy'
    'dmVyLlZlaGljbGVDb250cm9sRmxhc2hMaWdodHNBY3Rpb25IAFIfdmVoaWNsZUNvbnRyb2xGbG'
    'FzaExpZ2h0c0FjdGlvbhJtChx2ZWhpY2xlQ29udHJvbEhvbmtIb3JuQWN0aW9uGBsgASgLMicu'
    'Q2FyU2VydmVyLlZlaGljbGVDb250cm9sSG9ua0hvcm5BY3Rpb25IAFIcdmVoaWNsZUNvbnRyb2'
    'xIb25rSG9ybkFjdGlvbhJ8CiF2ZWhpY2xlQ29udHJvbFJlc2V0VmFsZXRQaW5BY3Rpb24YHCAB'
    'KAsyLC5DYXJTZXJ2ZXIuVmVoaWNsZUNvbnRyb2xSZXNldFZhbGV0UGluQWN0aW9uSABSIXZlaG'
    'ljbGVDb250cm9sUmVzZXRWYWxldFBpbkFjdGlvbhKXAQoqdmVoaWNsZUNvbnRyb2xTY2hlZHVs'
    'ZVNvZnR3YXJlVXBkYXRlQWN0aW9uGB0gASgLMjUuQ2FyU2VydmVyLlZlaGljbGVDb250cm9sU2'
    'NoZWR1bGVTb2Z0d2FyZVVwZGF0ZUFjdGlvbkgAUip2ZWhpY2xlQ29udHJvbFNjaGVkdWxlU29m'
    'dHdhcmVVcGRhdGVBY3Rpb24SfAohdmVoaWNsZUNvbnRyb2xTZXRTZW50cnlNb2RlQWN0aW9uGB'
    '4gASgLMiwuQ2FyU2VydmVyLlZlaGljbGVDb250cm9sU2V0U2VudHJ5TW9kZUFjdGlvbkgAUiF2'
    'ZWhpY2xlQ29udHJvbFNldFNlbnRyeU1vZGVBY3Rpb24SeQogdmVoaWNsZUNvbnRyb2xTZXRWYW'
    'xldE1vZGVBY3Rpb24YHyABKAsyKy5DYXJTZXJ2ZXIuVmVoaWNsZUNvbnRyb2xTZXRWYWxldE1v'
    'ZGVBY3Rpb25IAFIgdmVoaWNsZUNvbnRyb2xTZXRWYWxldE1vZGVBY3Rpb24ShQEKJHZlaGljbG'
    'VDb250cm9sU3Vucm9vZk9wZW5DbG9zZUFjdGlvbhggIAEoCzIvLkNhclNlcnZlci5WZWhpY2xl'
    'Q29udHJvbFN1bnJvb2ZPcGVuQ2xvc2VBY3Rpb25IAFIkdmVoaWNsZUNvbnRyb2xTdW5yb29mT3'
    'BlbkNsb3NlQWN0aW9uEoIBCiN2ZWhpY2xlQ29udHJvbFRyaWdnZXJIb21lbGlua0FjdGlvbhgh'
    'IAEoCzIuLkNhclNlcnZlci5WZWhpY2xlQ29udHJvbFRyaWdnZXJIb21lbGlua0FjdGlvbkgAUi'
    'N2ZWhpY2xlQ29udHJvbFRyaWdnZXJIb21lbGlua0FjdGlvbhJnChp2ZWhpY2xlQ29udHJvbFdp'
    'bmRvd0FjdGlvbhgiIAEoCzIlLkNhclNlcnZlci5WZWhpY2xlQ29udHJvbFdpbmRvd0FjdGlvbk'
    'gAUhp2ZWhpY2xlQ29udHJvbFdpbmRvd0FjdGlvbhJeChdodmFjQmlvd2VhcG9uTW9kZUFjdGlv'
    'bhgjIAEoCzIiLkNhclNlcnZlci5IdmFjQmlvd2VhcG9uTW9kZUFjdGlvbkgAUhdodmFjQmlvd2'
    'VhcG9uTW9kZUFjdGlvbhJYChVodmFjU2VhdEhlYXRlckFjdGlvbnMYJCABKAsyIC5DYXJTZXJ2'
    'ZXIuSHZhY1NlYXRIZWF0ZXJBY3Rpb25zSABSFWh2YWNTZWF0SGVhdGVyQWN0aW9ucxJeChdzY2'
    'hlZHVsZWRDaGFyZ2luZ0FjdGlvbhgpIAEoCzIiLkNhclNlcnZlci5TY2hlZHVsZWRDaGFyZ2lu'
    'Z0FjdGlvbkgAUhdzY2hlZHVsZWRDaGFyZ2luZ0FjdGlvbhJhChhzY2hlZHVsZWREZXBhcnR1cm'
    'VBY3Rpb24YKiABKAsyIy5DYXJTZXJ2ZXIuU2NoZWR1bGVkRGVwYXJ0dXJlQWN0aW9uSABSGHNj'
    'aGVkdWxlZERlcGFydHVyZUFjdGlvbhJYChVzZXRDaGFyZ2luZ0FtcHNBY3Rpb24YKyABKAsyIC'
    '5DYXJTZXJ2ZXIuU2V0Q2hhcmdpbmdBbXBzQWN0aW9uSABSFXNldENoYXJnaW5nQW1wc0FjdGlv'
    'bhJeChdodmFjQ2xpbWF0ZUtlZXBlckFjdGlvbhgsIAEoCzIiLkNhclNlcnZlci5IdmFjQ2xpbW'
    'F0ZUtlZXBlckFjdGlvbkgAUhdodmFjQ2xpbWF0ZUtlZXBlckFjdGlvbhIlCgRwaW5nGC4gASgL'
    'Mg8uQ2FyU2VydmVyLlBpbmdIAFIEcGluZxJYChVhdXRvU2VhdENsaW1hdGVBY3Rpb24YMCABKA'
    'syIC5DYXJTZXJ2ZXIuQXV0b1NlYXRDbGltYXRlQWN0aW9uSABSFWF1dG9TZWF0Q2xpbWF0ZUFj'
    'dGlvbhJYChVodmFjU2VhdENvb2xlckFjdGlvbnMYMSABKAsyIC5DYXJTZXJ2ZXIuSHZhY1NlYX'
    'RDb29sZXJBY3Rpb25zSABSFWh2YWNTZWF0Q29vbGVyQWN0aW9ucxJ5CiBzZXRDYWJpbk92ZXJo'
    'ZWF0UHJvdGVjdGlvbkFjdGlvbhgyIAEoCzIrLkNhclNlcnZlci5TZXRDYWJpbk92ZXJoZWF0UH'
    'JvdGVjdGlvbkFjdGlvbkgAUiBzZXRDYWJpbk92ZXJoZWF0UHJvdGVjdGlvbkFjdGlvbhJVChRz'
    'ZXRWZWhpY2xlTmFtZUFjdGlvbhg2IAEoCzIfLkNhclNlcnZlci5TZXRWZWhpY2xlTmFtZUFjdG'
    'lvbkgAUhRzZXRWZWhpY2xlTmFtZUFjdGlvbhJSChNjaGFyZ2VQb3J0RG9vckNsb3NlGD0gASgL'
    'Mh4uQ2FyU2VydmVyLkNoYXJnZVBvcnREb29yQ2xvc2VIAFITY2hhcmdlUG9ydERvb3JDbG9zZR'
    'JPChJjaGFyZ2VQb3J0RG9vck9wZW4YPiABKAsyHS5DYXJTZXJ2ZXIuQ2hhcmdlUG9ydERvb3JP'
    'cGVuSABSEmNoYXJnZVBvcnREb29yT3BlbhJNCg9ndWVzdE1vZGVBY3Rpb24YQSABKAsyIS5DYX'
    'JTZXJ2ZXIuVmVoaWNsZVN0YXRlLkd1ZXN0TW9kZUgAUg9ndWVzdE1vZGVBY3Rpb24SSQoQc2V0'
    'Q29wVGVtcEFjdGlvbhhCIAEoCzIbLkNhclNlcnZlci5TZXRDb3BUZW1wQWN0aW9uSABSEHNldE'
    'NvcFRlbXBBY3Rpb24SUgoTZXJhc2VVc2VyRGF0YUFjdGlvbhhIIAEoCzIeLkNhclNlcnZlci5F'
    'cmFzZVVzZXJEYXRhQWN0aW9uSABSE2VyYXNlVXNlckRhdGFBY3Rpb24SfAohdmVoaWNsZUNvbn'
    'Ryb2xTZXRQaW5Ub0RyaXZlQWN0aW9uGE0gASgLMiwuQ2FyU2VydmVyLlZlaGljbGVDb250cm9s'
    'U2V0UGluVG9Ecml2ZUFjdGlvbkgAUiF2ZWhpY2xlQ29udHJvbFNldFBpblRvRHJpdmVBY3Rpb2'
    '4SggEKI3ZlaGljbGVDb250cm9sUmVzZXRQaW5Ub0RyaXZlQWN0aW9uGE4gASgLMi4uQ2FyU2Vy'
    'dmVyLlZlaGljbGVDb250cm9sUmVzZXRQaW5Ub0RyaXZlQWN0aW9uSABSI3ZlaGljbGVDb250cm'
    '9sUmVzZXRQaW5Ub0RyaXZlQWN0aW9uEoUBCiRkcml2aW5nQ2xlYXJTcGVlZExpbWl0UGluQWRt'
    'aW5BY3Rpb24YTyABKAsyLy5DYXJTZXJ2ZXIuRHJpdmluZ0NsZWFyU3BlZWRMaW1pdFBpbkFkbW'
    'luQWN0aW9uSABSJGRyaXZpbmdDbGVhclNwZWVkTGltaXRQaW5BZG1pbkFjdGlvbhKRAQoodmVo'
    'aWNsZUNvbnRyb2xSZXNldFBpblRvRHJpdmVBZG1pbkFjdGlvbhhZIAEoCzIzLkNhclNlcnZlci'
    '5WZWhpY2xlQ29udHJvbFJlc2V0UGluVG9Ecml2ZUFkbWluQWN0aW9uSABSKHZlaGljbGVDb250'
    'cm9sUmVzZXRQaW5Ub0RyaXZlQWRtaW5BY3Rpb24SVQoXYWRkQ2hhcmdlU2NoZWR1bGVBY3Rpb2'
    '4YYSABKAsyGS5DYXJTZXJ2ZXIuQ2hhcmdlU2NoZWR1bGVIAFIXYWRkQ2hhcmdlU2NoZWR1bGVB'
    'Y3Rpb24SZwoacmVtb3ZlQ2hhcmdlU2NoZWR1bGVBY3Rpb24YYiABKAsyJS5DYXJTZXJ2ZXIuUm'
    'Vtb3ZlQ2hhcmdlU2NoZWR1bGVBY3Rpb25IAFIacmVtb3ZlQ2hhcmdlU2NoZWR1bGVBY3Rpb24S'
    'ZwodYWRkUHJlY29uZGl0aW9uU2NoZWR1bGVBY3Rpb24YYyABKAsyHy5DYXJTZXJ2ZXIuUHJlY2'
    '9uZGl0aW9uU2NoZWR1bGVIAFIdYWRkUHJlY29uZGl0aW9uU2NoZWR1bGVBY3Rpb24SeQogcmVt'
    'b3ZlUHJlY29uZGl0aW9uU2NoZWR1bGVBY3Rpb24YZCABKAsyKy5DYXJTZXJ2ZXIuUmVtb3ZlUH'
    'JlY29uZGl0aW9uU2NoZWR1bGVBY3Rpb25IAFIgcmVtb3ZlUHJlY29uZGl0aW9uU2NoZWR1bGVB'
    'Y3Rpb24SiwEKJmJhdGNoUmVtb3ZlUHJlY29uZGl0aW9uU2NoZWR1bGVzQWN0aW9uGGsgASgLMj'
    'EuQ2FyU2VydmVyLkJhdGNoUmVtb3ZlUHJlY29uZGl0aW9uU2NoZWR1bGVzQWN0aW9uSABSJmJh'
    'dGNoUmVtb3ZlUHJlY29uZGl0aW9uU2NoZWR1bGVzQWN0aW9uEnkKIGJhdGNoUmVtb3ZlQ2hhcm'
    'dlU2NoZWR1bGVzQWN0aW9uGGwgASgLMisuQ2FyU2VydmVyLkJhdGNoUmVtb3ZlQ2hhcmdlU2No'
    'ZWR1bGVzQWN0aW9uSABSIGJhdGNoUmVtb3ZlQ2hhcmdlU2NoZWR1bGVzQWN0aW9uElkKFXNldE'
    'xvd1Bvd2VyTW9kZUFjdGlvbhiCASABKAsyIC5DYXJTZXJ2ZXIuU2V0TG93UG93ZXJNb2RlQWN0'
    'aW9uSABSFXNldExvd1Bvd2VyTW9kZUFjdGlvbhJ3Ch9zZXRLZWVwQWNjZXNzb3J5UG93ZXJNb2'
    'RlQWN0aW9uGIoBIAEoCzIqLkNhclNlcnZlci5TZXRLZWVwQWNjZXNzb3J5UG93ZXJNb2RlQWN0'
    'aW9uSABSH3NldEtlZXBBY2Nlc3NvcnlQb3dlck1vZGVBY3Rpb25CFAoSdmVoaWNsZV9hY3Rpb2'
    '5fbXNnSgQICxAMSgQIPBA9SgQITBBN');

@$core.Deprecated('Use getVehicleDataDescriptor instead')
const GetVehicleData$json = {
  '1': 'GetVehicleData',
  '2': [
    {
      '1': 'getChargeState',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetChargeState',
      '10': 'getChargeState'
    },
    {
      '1': 'getClimateState',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetClimateState',
      '10': 'getClimateState'
    },
    {
      '1': 'getDriveState',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetDriveState',
      '10': 'getDriveState'
    },
    {
      '1': 'getLocationState',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetLocationState',
      '10': 'getLocationState'
    },
    {
      '1': 'getClosuresState',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetClosuresState',
      '10': 'getClosuresState'
    },
    {
      '1': 'getChargeScheduleState',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetChargeScheduleState',
      '10': 'getChargeScheduleState'
    },
    {
      '1': 'getPreconditioningScheduleState',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetPreconditioningScheduleState',
      '10': 'getPreconditioningScheduleState'
    },
    {
      '1': 'getTirePressureState',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetTirePressureState',
      '10': 'getTirePressureState'
    },
    {
      '1': 'getMediaState',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetMediaState',
      '10': 'getMediaState'
    },
    {
      '1': 'getMediaDetailState',
      '3': 16,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetMediaDetailState',
      '10': 'getMediaDetailState'
    },
    {
      '1': 'getSoftwareUpdateState',
      '3': 17,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetSoftwareUpdateState',
      '10': 'getSoftwareUpdateState'
    },
    {
      '1': 'getParentalControlsState',
      '3': 19,
      '4': 1,
      '5': 11,
      '6': '.CarServer.GetParentalControlsState',
      '10': 'getParentalControlsState'
    },
  ],
  '9': [
    {'1': 5, '2': 6},
    {'1': 6, '2': 7},
    {'1': 12, '2': 13},
    {'1': 13, '2': 14},
  ],
};

/// Descriptor for `GetVehicleData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getVehicleDataDescriptor = $convert.base64Decode(
    'Cg5HZXRWZWhpY2xlRGF0YRJBCg5nZXRDaGFyZ2VTdGF0ZRgCIAEoCzIZLkNhclNlcnZlci5HZX'
    'RDaGFyZ2VTdGF0ZVIOZ2V0Q2hhcmdlU3RhdGUSRAoPZ2V0Q2xpbWF0ZVN0YXRlGAMgASgLMhou'
    'Q2FyU2VydmVyLkdldENsaW1hdGVTdGF0ZVIPZ2V0Q2xpbWF0ZVN0YXRlEj4KDWdldERyaXZlU3'
    'RhdGUYBCABKAsyGC5DYXJTZXJ2ZXIuR2V0RHJpdmVTdGF0ZVINZ2V0RHJpdmVTdGF0ZRJHChBn'
    'ZXRMb2NhdGlvblN0YXRlGAcgASgLMhsuQ2FyU2VydmVyLkdldExvY2F0aW9uU3RhdGVSEGdldE'
    'xvY2F0aW9uU3RhdGUSRwoQZ2V0Q2xvc3VyZXNTdGF0ZRgIIAEoCzIbLkNhclNlcnZlci5HZXRD'
    'bG9zdXJlc1N0YXRlUhBnZXRDbG9zdXJlc1N0YXRlElkKFmdldENoYXJnZVNjaGVkdWxlU3RhdG'
    'UYCiABKAsyIS5DYXJTZXJ2ZXIuR2V0Q2hhcmdlU2NoZWR1bGVTdGF0ZVIWZ2V0Q2hhcmdlU2No'
    'ZWR1bGVTdGF0ZRJ0Ch9nZXRQcmVjb25kaXRpb25pbmdTY2hlZHVsZVN0YXRlGAsgASgLMiouQ2'
    'FyU2VydmVyLkdldFByZWNvbmRpdGlvbmluZ1NjaGVkdWxlU3RhdGVSH2dldFByZWNvbmRpdGlv'
    'bmluZ1NjaGVkdWxlU3RhdGUSUwoUZ2V0VGlyZVByZXNzdXJlU3RhdGUYDiABKAsyHy5DYXJTZX'
    'J2ZXIuR2V0VGlyZVByZXNzdXJlU3RhdGVSFGdldFRpcmVQcmVzc3VyZVN0YXRlEj4KDWdldE1l'
    'ZGlhU3RhdGUYDyABKAsyGC5DYXJTZXJ2ZXIuR2V0TWVkaWFTdGF0ZVINZ2V0TWVkaWFTdGF0ZR'
    'JQChNnZXRNZWRpYURldGFpbFN0YXRlGBAgASgLMh4uQ2FyU2VydmVyLkdldE1lZGlhRGV0YWls'
    'U3RhdGVSE2dldE1lZGlhRGV0YWlsU3RhdGUSWQoWZ2V0U29mdHdhcmVVcGRhdGVTdGF0ZRgRIA'
    'EoCzIhLkNhclNlcnZlci5HZXRTb2Z0d2FyZVVwZGF0ZVN0YXRlUhZnZXRTb2Z0d2FyZVVwZGF0'
    'ZVN0YXRlEl8KGGdldFBhcmVudGFsQ29udHJvbHNTdGF0ZRgTIAEoCzIjLkNhclNlcnZlci5HZX'
    'RQYXJlbnRhbENvbnRyb2xzU3RhdGVSGGdldFBhcmVudGFsQ29udHJvbHNTdGF0ZUoECAUQBkoE'
    'CAYQB0oECAwQDUoECA0QDg==');

@$core.Deprecated('Use getTirePressureStateDescriptor instead')
const GetTirePressureState$json = {
  '1': 'GetTirePressureState',
};

/// Descriptor for `GetTirePressureState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getTirePressureStateDescriptor =
    $convert.base64Decode('ChRHZXRUaXJlUHJlc3N1cmVTdGF0ZQ==');

@$core.Deprecated('Use getMediaStateDescriptor instead')
const GetMediaState$json = {
  '1': 'GetMediaState',
};

/// Descriptor for `GetMediaState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMediaStateDescriptor =
    $convert.base64Decode('Cg1HZXRNZWRpYVN0YXRl');

@$core.Deprecated('Use getMediaDetailStateDescriptor instead')
const GetMediaDetailState$json = {
  '1': 'GetMediaDetailState',
};

/// Descriptor for `GetMediaDetailState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getMediaDetailStateDescriptor =
    $convert.base64Decode('ChNHZXRNZWRpYURldGFpbFN0YXRl');

@$core.Deprecated('Use getSoftwareUpdateStateDescriptor instead')
const GetSoftwareUpdateState$json = {
  '1': 'GetSoftwareUpdateState',
};

/// Descriptor for `GetSoftwareUpdateState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getSoftwareUpdateStateDescriptor =
    $convert.base64Decode('ChZHZXRTb2Z0d2FyZVVwZGF0ZVN0YXRl');

@$core.Deprecated('Use getChargeStateDescriptor instead')
const GetChargeState$json = {
  '1': 'GetChargeState',
};

/// Descriptor for `GetChargeState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getChargeStateDescriptor =
    $convert.base64Decode('Cg5HZXRDaGFyZ2VTdGF0ZQ==');

@$core.Deprecated('Use getClimateStateDescriptor instead')
const GetClimateState$json = {
  '1': 'GetClimateState',
};

/// Descriptor for `GetClimateState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getClimateStateDescriptor =
    $convert.base64Decode('Cg9HZXRDbGltYXRlU3RhdGU=');

@$core.Deprecated('Use getDriveStateDescriptor instead')
const GetDriveState$json = {
  '1': 'GetDriveState',
};

/// Descriptor for `GetDriveState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getDriveStateDescriptor =
    $convert.base64Decode('Cg1HZXREcml2ZVN0YXRl');

@$core.Deprecated('Use getLocationStateDescriptor instead')
const GetLocationState$json = {
  '1': 'GetLocationState',
};

/// Descriptor for `GetLocationState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getLocationStateDescriptor =
    $convert.base64Decode('ChBHZXRMb2NhdGlvblN0YXRl');

@$core.Deprecated('Use getClosuresStateDescriptor instead')
const GetClosuresState$json = {
  '1': 'GetClosuresState',
};

/// Descriptor for `GetClosuresState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getClosuresStateDescriptor =
    $convert.base64Decode('ChBHZXRDbG9zdXJlc1N0YXRl');

@$core.Deprecated('Use getChargeScheduleStateDescriptor instead')
const GetChargeScheduleState$json = {
  '1': 'GetChargeScheduleState',
};

/// Descriptor for `GetChargeScheduleState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getChargeScheduleStateDescriptor =
    $convert.base64Decode('ChZHZXRDaGFyZ2VTY2hlZHVsZVN0YXRl');

@$core.Deprecated('Use getPreconditioningScheduleStateDescriptor instead')
const GetPreconditioningScheduleState$json = {
  '1': 'GetPreconditioningScheduleState',
};

/// Descriptor for `GetPreconditioningScheduleState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getPreconditioningScheduleStateDescriptor =
    $convert.base64Decode('Ch9HZXRQcmVjb25kaXRpb25pbmdTY2hlZHVsZVN0YXRl');

@$core.Deprecated('Use getParentalControlsStateDescriptor instead')
const GetParentalControlsState$json = {
  '1': 'GetParentalControlsState',
};

/// Descriptor for `GetParentalControlsState`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getParentalControlsStateDescriptor =
    $convert.base64Decode('ChhHZXRQYXJlbnRhbENvbnRyb2xzU3RhdGU=');

@$core.Deprecated('Use eraseUserDataActionDescriptor instead')
const EraseUserDataAction$json = {
  '1': 'EraseUserDataAction',
  '2': [
    {'1': 'reason', '3': 1, '4': 1, '5': 9, '10': 'reason'},
  ],
};

/// Descriptor for `EraseUserDataAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List eraseUserDataActionDescriptor =
    $convert.base64Decode(
        'ChNFcmFzZVVzZXJEYXRhQWN0aW9uEhYKBnJlYXNvbhgBIAEoCVIGcmVhc29u');

@$core.Deprecated('Use responseDescriptor instead')
const Response$json = {
  '1': 'Response',
  '2': [
    {
      '1': 'actionStatus',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.CarServer.ActionStatus',
      '10': 'actionStatus'
    },
    {
      '1': 'vehicleData',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.CarServer.VehicleData',
      '9': 0,
      '10': 'vehicleData'
    },
    {
      '1': 'getSessionInfoResponse',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.Signatures.SessionInfo',
      '9': 0,
      '10': 'getSessionInfoResponse'
    },
    {
      '1': 'getNearbyChargingSites',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.CarServer.NearbyChargingSites',
      '9': 0,
      '10': 'getNearbyChargingSites'
    },
    {
      '1': 'ping',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Ping',
      '9': 0,
      '10': 'ping'
    },
  ],
  '8': [
    {'1': 'response_msg'},
  ],
};

/// Descriptor for `Response`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List responseDescriptor = $convert.base64Decode(
    'CghSZXNwb25zZRI7CgxhY3Rpb25TdGF0dXMYASABKAsyFy5DYXJTZXJ2ZXIuQWN0aW9uU3RhdH'
    'VzUgxhY3Rpb25TdGF0dXMSOgoLdmVoaWNsZURhdGEYAiABKAsyFi5DYXJTZXJ2ZXIuVmVoaWNs'
    'ZURhdGFIAFILdmVoaWNsZURhdGESUQoWZ2V0U2Vzc2lvbkluZm9SZXNwb25zZRgDIAEoCzIXLl'
    'NpZ25hdHVyZXMuU2Vzc2lvbkluZm9IAFIWZ2V0U2Vzc2lvbkluZm9SZXNwb25zZRJYChZnZXRO'
    'ZWFyYnlDaGFyZ2luZ1NpdGVzGAUgASgLMh4uQ2FyU2VydmVyLk5lYXJieUNoYXJnaW5nU2l0ZX'
    'NIAFIWZ2V0TmVhcmJ5Q2hhcmdpbmdTaXRlcxIlCgRwaW5nGAkgASgLMg8uQ2FyU2VydmVyLlBp'
    'bmdIAFIEcGluZ0IOCgxyZXNwb25zZV9tc2c=');

@$core.Deprecated('Use actionStatusDescriptor instead')
const ActionStatus$json = {
  '1': 'ActionStatus',
  '2': [
    {
      '1': 'result',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.CarServer.OperationStatus_E',
      '10': 'result'
    },
    {
      '1': 'result_reason',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.CarServer.ResultReason',
      '10': 'resultReason'
    },
  ],
};

/// Descriptor for `ActionStatus`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List actionStatusDescriptor = $convert.base64Decode(
    'CgxBY3Rpb25TdGF0dXMSNAoGcmVzdWx0GAEgASgOMhwuQ2FyU2VydmVyLk9wZXJhdGlvblN0YX'
    'R1c19FUgZyZXN1bHQSPAoNcmVzdWx0X3JlYXNvbhgCIAEoCzIXLkNhclNlcnZlci5SZXN1bHRS'
    'ZWFzb25SDHJlc3VsdFJlYXNvbg==');

@$core.Deprecated('Use resultReasonDescriptor instead')
const ResultReason$json = {
  '1': 'ResultReason',
  '2': [
    {'1': 'plain_text', '3': 1, '4': 1, '5': 9, '9': 0, '10': 'plainText'},
  ],
  '8': [
    {'1': 'reason'},
  ],
};

/// Descriptor for `ResultReason`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List resultReasonDescriptor = $convert.base64Decode(
    'CgxSZXN1bHRSZWFzb24SHwoKcGxhaW5fdGV4dBgBIAEoCUgAUglwbGFpblRleHRCCAoGcmVhc2'
    '9u');

@$core.Deprecated('Use encryptedDataDescriptor instead')
const EncryptedData$json = {
  '1': 'EncryptedData',
  '2': [
    {'1': 'field_number', '3': 1, '4': 1, '5': 5, '10': 'fieldNumber'},
    {'1': 'ciphertext', '3': 2, '4': 1, '5': 12, '10': 'ciphertext'},
    {'1': 'tag', '3': 3, '4': 1, '5': 12, '10': 'tag'},
  ],
};

/// Descriptor for `EncryptedData`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List encryptedDataDescriptor = $convert.base64Decode(
    'Cg1FbmNyeXB0ZWREYXRhEiEKDGZpZWxkX251bWJlchgBIAEoBVILZmllbGROdW1iZXISHgoKY2'
    'lwaGVydGV4dBgCIAEoDFIKY2lwaGVydGV4dBIQCgN0YWcYAyABKAxSA3RhZw==');

@$core.Deprecated('Use chargingSetLimitActionDescriptor instead')
const ChargingSetLimitAction$json = {
  '1': 'ChargingSetLimitAction',
  '2': [
    {'1': 'percent', '3': 1, '4': 1, '5': 5, '10': 'percent'},
  ],
};

/// Descriptor for `ChargingSetLimitAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chargingSetLimitActionDescriptor =
    $convert.base64Decode(
        'ChZDaGFyZ2luZ1NldExpbWl0QWN0aW9uEhgKB3BlcmNlbnQYASABKAVSB3BlcmNlbnQ=');

@$core.Deprecated('Use chargingStartStopActionDescriptor instead')
const ChargingStartStopAction$json = {
  '1': 'ChargingStartStopAction',
  '2': [
    {
      '1': 'unknown',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'unknown'
    },
    {
      '1': 'start',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'start'
    },
    {
      '1': 'start_standard',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'startStandard'
    },
    {
      '1': 'start_max_range',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'startMaxRange'
    },
    {
      '1': 'stop',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'stop'
    },
  ],
  '8': [
    {'1': 'charging_action'},
  ],
};

/// Descriptor for `ChargingStartStopAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chargingStartStopActionDescriptor = $convert.base64Decode(
    'ChdDaGFyZ2luZ1N0YXJ0U3RvcEFjdGlvbhIrCgd1bmtub3duGAEgASgLMg8uQ2FyU2VydmVyLl'
    'ZvaWRIAFIHdW5rbm93bhInCgVzdGFydBgCIAEoCzIPLkNhclNlcnZlci5Wb2lkSABSBXN0YXJ0'
    'EjgKDnN0YXJ0X3N0YW5kYXJkGAMgASgLMg8uQ2FyU2VydmVyLlZvaWRIAFINc3RhcnRTdGFuZG'
    'FyZBI5Cg9zdGFydF9tYXhfcmFuZ2UYBCABKAsyDy5DYXJTZXJ2ZXIuVm9pZEgAUg1zdGFydE1h'
    'eFJhbmdlEiUKBHN0b3AYBSABKAsyDy5DYXJTZXJ2ZXIuVm9pZEgAUgRzdG9wQhEKD2NoYXJnaW'
    '5nX2FjdGlvbg==');

@$core.Deprecated('Use drivingClearSpeedLimitPinActionDescriptor instead')
const DrivingClearSpeedLimitPinAction$json = {
  '1': 'DrivingClearSpeedLimitPinAction',
  '2': [
    {'1': 'pin', '3': 1, '4': 1, '5': 9, '10': 'pin'},
  ],
};

/// Descriptor for `DrivingClearSpeedLimitPinAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List drivingClearSpeedLimitPinActionDescriptor =
    $convert.base64Decode(
        'Ch9Ecml2aW5nQ2xlYXJTcGVlZExpbWl0UGluQWN0aW9uEhAKA3BpbhgBIAEoCVIDcGlu');

@$core.Deprecated('Use drivingClearSpeedLimitPinAdminActionDescriptor instead')
const DrivingClearSpeedLimitPinAdminAction$json = {
  '1': 'DrivingClearSpeedLimitPinAdminAction',
};

/// Descriptor for `DrivingClearSpeedLimitPinAdminAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List drivingClearSpeedLimitPinAdminActionDescriptor =
    $convert
        .base64Decode('CiREcml2aW5nQ2xlYXJTcGVlZExpbWl0UGluQWRtaW5BY3Rpb24=');

@$core.Deprecated('Use drivingSetSpeedLimitActionDescriptor instead')
const DrivingSetSpeedLimitAction$json = {
  '1': 'DrivingSetSpeedLimitAction',
  '2': [
    {'1': 'limit_mph', '3': 1, '4': 1, '5': 1, '10': 'limitMph'},
  ],
};

/// Descriptor for `DrivingSetSpeedLimitAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List drivingSetSpeedLimitActionDescriptor =
    $convert.base64Decode(
        'ChpEcml2aW5nU2V0U3BlZWRMaW1pdEFjdGlvbhIbCglsaW1pdF9tcGgYASABKAFSCGxpbWl0TX'
        'Bo');

@$core.Deprecated('Use drivingSpeedLimitActionDescriptor instead')
const DrivingSpeedLimitAction$json = {
  '1': 'DrivingSpeedLimitAction',
  '2': [
    {'1': 'activate', '3': 1, '4': 1, '5': 8, '10': 'activate'},
    {'1': 'pin', '3': 2, '4': 1, '5': 9, '10': 'pin'},
  ],
};

/// Descriptor for `DrivingSpeedLimitAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List drivingSpeedLimitActionDescriptor =
    $convert.base64Decode(
        'ChdEcml2aW5nU3BlZWRMaW1pdEFjdGlvbhIaCghhY3RpdmF0ZRgBIAEoCFIIYWN0aXZhdGUSEA'
        'oDcGluGAIgASgJUgNwaW4=');

@$core.Deprecated('Use hvacAutoActionDescriptor instead')
const HvacAutoAction$json = {
  '1': 'HvacAutoAction',
  '2': [
    {'1': 'power_on', '3': 1, '4': 1, '5': 8, '10': 'powerOn'},
    {'1': 'manual_override', '3': 2, '4': 1, '5': 8, '10': 'manualOverride'},
  ],
};

/// Descriptor for `HvacAutoAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hvacAutoActionDescriptor = $convert.base64Decode(
    'Cg5IdmFjQXV0b0FjdGlvbhIZCghwb3dlcl9vbhgBIAEoCFIHcG93ZXJPbhInCg9tYW51YWxfb3'
    'ZlcnJpZGUYAiABKAhSDm1hbnVhbE92ZXJyaWRl');

@$core.Deprecated('Use hvacSeatHeaterActionsDescriptor instead')
const HvacSeatHeaterActions$json = {
  '1': 'HvacSeatHeaterActions',
  '2': [
    {
      '1': 'hvacSeatHeaterAction',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.CarServer.HvacSeatHeaterActions.HvacSeatHeaterAction',
      '10': 'hvacSeatHeaterAction'
    },
  ],
  '3': [HvacSeatHeaterActions_HvacSeatHeaterAction$json],
};

@$core.Deprecated('Use hvacSeatHeaterActionsDescriptor instead')
const HvacSeatHeaterActions_HvacSeatHeaterAction$json = {
  '1': 'HvacSeatHeaterAction',
  '2': [
    {
      '1': 'SEAT_HEATER_UNKNOWN',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'SEATHEATERUNKNOWN'
    },
    {
      '1': 'SEAT_HEATER_OFF',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'SEATHEATEROFF'
    },
    {
      '1': 'SEAT_HEATER_LOW',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'SEATHEATERLOW'
    },
    {
      '1': 'SEAT_HEATER_MED',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'SEATHEATERMED'
    },
    {
      '1': 'SEAT_HEATER_HIGH',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'SEATHEATERHIGH'
    },
    {
      '1': 'CAR_SEAT_UNKNOWN',
      '3': 6,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 1,
      '10': 'CARSEATUNKNOWN'
    },
    {
      '1': 'CAR_SEAT_FRONT_LEFT',
      '3': 7,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 1,
      '10': 'CARSEATFRONTLEFT'
    },
    {
      '1': 'CAR_SEAT_FRONT_RIGHT',
      '3': 8,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 1,
      '10': 'CARSEATFRONTRIGHT'
    },
    {
      '1': 'CAR_SEAT_REAR_LEFT',
      '3': 9,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 1,
      '10': 'CARSEATREARLEFT'
    },
    {
      '1': 'CAR_SEAT_REAR_LEFT_BACK',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 1,
      '10': 'CARSEATREARLEFTBACK'
    },
    {
      '1': 'CAR_SEAT_REAR_CENTER',
      '3': 11,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 1,
      '10': 'CARSEATREARCENTER'
    },
    {
      '1': 'CAR_SEAT_REAR_RIGHT',
      '3': 12,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 1,
      '10': 'CARSEATREARRIGHT'
    },
    {
      '1': 'CAR_SEAT_REAR_RIGHT_BACK',
      '3': 13,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 1,
      '10': 'CARSEATREARRIGHTBACK'
    },
    {
      '1': 'CAR_SEAT_THIRD_ROW_LEFT',
      '3': 14,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 1,
      '10': 'CARSEATTHIRDROWLEFT'
    },
    {
      '1': 'CAR_SEAT_THIRD_ROW_RIGHT',
      '3': 15,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 1,
      '10': 'CARSEATTHIRDROWRIGHT'
    },
  ],
  '8': [
    {'1': 'seat_heater_level'},
    {'1': 'seat_position'},
  ],
};

/// Descriptor for `HvacSeatHeaterActions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hvacSeatHeaterActionsDescriptor = $convert.base64Decode(
    'ChVIdmFjU2VhdEhlYXRlckFjdGlvbnMSaQoUaHZhY1NlYXRIZWF0ZXJBY3Rpb24YASADKAsyNS'
    '5DYXJTZXJ2ZXIuSHZhY1NlYXRIZWF0ZXJBY3Rpb25zLkh2YWNTZWF0SGVhdGVyQWN0aW9uUhRo'
    'dmFjU2VhdEhlYXRlckFjdGlvbhqeCAoUSHZhY1NlYXRIZWF0ZXJBY3Rpb24SQQoTU0VBVF9IRU'
    'FURVJfVU5LTk9XThgBIAEoCzIPLkNhclNlcnZlci5Wb2lkSABSEVNFQVRIRUFURVJVTktOT1dO'
    'EjkKD1NFQVRfSEVBVEVSX09GRhgCIAEoCzIPLkNhclNlcnZlci5Wb2lkSABSDVNFQVRIRUFURV'
    'JPRkYSOQoPU0VBVF9IRUFURVJfTE9XGAMgASgLMg8uQ2FyU2VydmVyLlZvaWRIAFINU0VBVEhF'
    'QVRFUkxPVxI5Cg9TRUFUX0hFQVRFUl9NRUQYBCABKAsyDy5DYXJTZXJ2ZXIuVm9pZEgAUg1TRU'
    'FUSEVBVEVSTUVEEjsKEFNFQVRfSEVBVEVSX0hJR0gYBSABKAsyDy5DYXJTZXJ2ZXIuVm9pZEgA'
    'Ug5TRUFUSEVBVEVSSElHSBI7ChBDQVJfU0VBVF9VTktOT1dOGAYgASgLMg8uQ2FyU2VydmVyLl'
    'ZvaWRIAVIOQ0FSU0VBVFVOS05PV04SQAoTQ0FSX1NFQVRfRlJPTlRfTEVGVBgHIAEoCzIPLkNh'
    'clNlcnZlci5Wb2lkSAFSEENBUlNFQVRGUk9OVExFRlQSQgoUQ0FSX1NFQVRfRlJPTlRfUklHSF'
    'QYCCABKAsyDy5DYXJTZXJ2ZXIuVm9pZEgBUhFDQVJTRUFURlJPTlRSSUdIVBI+ChJDQVJfU0VB'
    'VF9SRUFSX0xFRlQYCSABKAsyDy5DYXJTZXJ2ZXIuVm9pZEgBUg9DQVJTRUFUUkVBUkxFRlQSRw'
    'oXQ0FSX1NFQVRfUkVBUl9MRUZUX0JBQ0sYCiABKAsyDy5DYXJTZXJ2ZXIuVm9pZEgBUhNDQVJT'
    'RUFUUkVBUkxFRlRCQUNLEkIKFENBUl9TRUFUX1JFQVJfQ0VOVEVSGAsgASgLMg8uQ2FyU2Vydm'
    'VyLlZvaWRIAVIRQ0FSU0VBVFJFQVJDRU5URVISQAoTQ0FSX1NFQVRfUkVBUl9SSUdIVBgMIAEo'
    'CzIPLkNhclNlcnZlci5Wb2lkSAFSEENBUlNFQVRSRUFSUklHSFQSSQoYQ0FSX1NFQVRfUkVBUl'
    '9SSUdIVF9CQUNLGA0gASgLMg8uQ2FyU2VydmVyLlZvaWRIAVIUQ0FSU0VBVFJFQVJSSUdIVEJB'
    'Q0sSRwoXQ0FSX1NFQVRfVEhJUkRfUk9XX0xFRlQYDiABKAsyDy5DYXJTZXJ2ZXIuVm9pZEgBUh'
    'NDQVJTRUFUVEhJUkRST1dMRUZUEkkKGENBUl9TRUFUX1RISVJEX1JPV19SSUdIVBgPIAEoCzIP'
    'LkNhclNlcnZlci5Wb2lkSAFSFENBUlNFQVRUSElSRFJPV1JJR0hUQhMKEXNlYXRfaGVhdGVyX2'
    'xldmVsQg8KDXNlYXRfcG9zaXRpb24=');

@$core.Deprecated('Use hvacSeatCoolerActionsDescriptor instead')
const HvacSeatCoolerActions$json = {
  '1': 'HvacSeatCoolerActions',
  '2': [
    {
      '1': 'hvacSeatCoolerAction',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.CarServer.HvacSeatCoolerActions.HvacSeatCoolerAction',
      '10': 'hvacSeatCoolerAction'
    },
  ],
  '3': [HvacSeatCoolerActions_HvacSeatCoolerAction$json],
  '4': [
    HvacSeatCoolerActions_HvacSeatCoolerLevel_E$json,
    HvacSeatCoolerActions_HvacSeatCoolerPosition_E$json
  ],
};

@$core.Deprecated('Use hvacSeatCoolerActionsDescriptor instead')
const HvacSeatCoolerActions_HvacSeatCoolerAction$json = {
  '1': 'HvacSeatCoolerAction',
  '2': [
    {
      '1': 'seat_cooler_level',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.CarServer.HvacSeatCoolerActions.HvacSeatCoolerLevel_E',
      '10': 'seatCoolerLevel'
    },
    {
      '1': 'seat_position',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.CarServer.HvacSeatCoolerActions.HvacSeatCoolerPosition_E',
      '10': 'seatPosition'
    },
  ],
};

@$core.Deprecated('Use hvacSeatCoolerActionsDescriptor instead')
const HvacSeatCoolerActions_HvacSeatCoolerLevel_E$json = {
  '1': 'HvacSeatCoolerLevel_E',
  '2': [
    {'1': 'HvacSeatCoolerLevel_Unknown', '2': 0},
    {'1': 'HvacSeatCoolerLevel_Off', '2': 1},
    {'1': 'HvacSeatCoolerLevel_Low', '2': 2},
    {'1': 'HvacSeatCoolerLevel_Med', '2': 3},
    {'1': 'HvacSeatCoolerLevel_High', '2': 4},
  ],
};

@$core.Deprecated('Use hvacSeatCoolerActionsDescriptor instead')
const HvacSeatCoolerActions_HvacSeatCoolerPosition_E$json = {
  '1': 'HvacSeatCoolerPosition_E',
  '2': [
    {'1': 'HvacSeatCoolerPosition_Unknown', '2': 0},
    {'1': 'HvacSeatCoolerPosition_FrontLeft', '2': 1},
    {'1': 'HvacSeatCoolerPosition_FrontRight', '2': 2},
  ],
};

/// Descriptor for `HvacSeatCoolerActions`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hvacSeatCoolerActionsDescriptor = $convert.base64Decode(
    'ChVIdmFjU2VhdENvb2xlckFjdGlvbnMSaQoUaHZhY1NlYXRDb29sZXJBY3Rpb24YASADKAsyNS'
    '5DYXJTZXJ2ZXIuSHZhY1NlYXRDb29sZXJBY3Rpb25zLkh2YWNTZWF0Q29vbGVyQWN0aW9uUhRo'
    'dmFjU2VhdENvb2xlckFjdGlvbhraAQoUSHZhY1NlYXRDb29sZXJBY3Rpb24SYgoRc2VhdF9jb2'
    '9sZXJfbGV2ZWwYASABKA4yNi5DYXJTZXJ2ZXIuSHZhY1NlYXRDb29sZXJBY3Rpb25zLkh2YWNT'
    'ZWF0Q29vbGVyTGV2ZWxfRVIPc2VhdENvb2xlckxldmVsEl4KDXNlYXRfcG9zaXRpb24YAiABKA'
    '4yOS5DYXJTZXJ2ZXIuSHZhY1NlYXRDb29sZXJBY3Rpb25zLkh2YWNTZWF0Q29vbGVyUG9zaXRp'
    'b25fRVIMc2VhdFBvc2l0aW9uIq0BChVIdmFjU2VhdENvb2xlckxldmVsX0USHwobSHZhY1NlYX'
    'RDb29sZXJMZXZlbF9Vbmtub3duEAASGwoXSHZhY1NlYXRDb29sZXJMZXZlbF9PZmYQARIbChdI'
    'dmFjU2VhdENvb2xlckxldmVsX0xvdxACEhsKF0h2YWNTZWF0Q29vbGVyTGV2ZWxfTWVkEAMSHA'
    'oYSHZhY1NlYXRDb29sZXJMZXZlbF9IaWdoEAQiiwEKGEh2YWNTZWF0Q29vbGVyUG9zaXRpb25f'
    'RRIiCh5IdmFjU2VhdENvb2xlclBvc2l0aW9uX1Vua25vd24QABIkCiBIdmFjU2VhdENvb2xlcl'
    'Bvc2l0aW9uX0Zyb250TGVmdBABEiUKIUh2YWNTZWF0Q29vbGVyUG9zaXRpb25fRnJvbnRSaWdo'
    'dBAC');

@$core.Deprecated('Use hvacSetPreconditioningMaxActionDescriptor instead')
const HvacSetPreconditioningMaxAction$json = {
  '1': 'HvacSetPreconditioningMaxAction',
  '2': [
    {'1': 'on', '3': 1, '4': 1, '5': 8, '10': 'on'},
    {'1': 'manual_override', '3': 2, '4': 1, '5': 8, '10': 'manualOverride'},
    {
      '1': 'manual_override_mode',
      '3': 3,
      '4': 3,
      '5': 14,
      '6': '.CarServer.HvacSetPreconditioningMaxAction.ManualOverrideMode_E',
      '10': 'manualOverrideMode'
    },
  ],
  '4': [HvacSetPreconditioningMaxAction_ManualOverrideMode_E$json],
};

@$core.Deprecated('Use hvacSetPreconditioningMaxActionDescriptor instead')
const HvacSetPreconditioningMaxAction_ManualOverrideMode_E$json = {
  '1': 'ManualOverrideMode_E',
  '2': [
    {'1': 'DogMode', '2': 0},
    {'1': 'Soc', '2': 1},
    {'1': 'Doors', '2': 2},
  ],
};

/// Descriptor for `HvacSetPreconditioningMaxAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hvacSetPreconditioningMaxActionDescriptor = $convert.base64Decode(
    'Ch9IdmFjU2V0UHJlY29uZGl0aW9uaW5nTWF4QWN0aW9uEg4KAm9uGAEgASgIUgJvbhInCg9tYW'
    '51YWxfb3ZlcnJpZGUYAiABKAhSDm1hbnVhbE92ZXJyaWRlEnEKFG1hbnVhbF9vdmVycmlkZV9t'
    'b2RlGAMgAygOMj8uQ2FyU2VydmVyLkh2YWNTZXRQcmVjb25kaXRpb25pbmdNYXhBY3Rpb24uTW'
    'FudWFsT3ZlcnJpZGVNb2RlX0VSEm1hbnVhbE92ZXJyaWRlTW9kZSI3ChRNYW51YWxPdmVycmlk'
    'ZU1vZGVfRRILCgdEb2dNb2RlEAASBwoDU29jEAESCQoFRG9vcnMQAg==');

@$core.Deprecated('Use hvacSteeringWheelHeaterActionDescriptor instead')
const HvacSteeringWheelHeaterAction$json = {
  '1': 'HvacSteeringWheelHeaterAction',
  '2': [
    {'1': 'power_on', '3': 1, '4': 1, '5': 8, '10': 'powerOn'},
  ],
};

/// Descriptor for `HvacSteeringWheelHeaterAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hvacSteeringWheelHeaterActionDescriptor =
    $convert.base64Decode(
        'Ch1IdmFjU3RlZXJpbmdXaGVlbEhlYXRlckFjdGlvbhIZCghwb3dlcl9vbhgBIAEoCFIHcG93ZX'
        'JPbg==');

@$core.Deprecated('Use hvacTemperatureAdjustmentActionDescriptor instead')
const HvacTemperatureAdjustmentAction$json = {
  '1': 'HvacTemperatureAdjustmentAction',
  '2': [
    {'1': 'delta_celsius', '3': 1, '4': 1, '5': 2, '10': 'deltaCelsius'},
    {'1': 'delta_percent', '3': 2, '4': 1, '5': 17, '10': 'deltaPercent'},
    {'1': 'absolute_celsius', '3': 3, '4': 1, '5': 2, '10': 'absoluteCelsius'},
    {
      '1': 'level',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.CarServer.HvacTemperatureAdjustmentAction.Temperature',
      '10': 'level'
    },
    {
      '1': 'hvac_temperature_zone',
      '3': 4,
      '4': 3,
      '5': 11,
      '6': '.CarServer.HvacTemperatureAdjustmentAction.HvacTemperatureZone',
      '10': 'hvacTemperatureZone'
    },
    {
      '1': 'driver_temp_celsius',
      '3': 6,
      '4': 1,
      '5': 2,
      '10': 'driverTempCelsius'
    },
    {
      '1': 'passenger_temp_celsius',
      '3': 7,
      '4': 1,
      '5': 2,
      '10': 'passengerTempCelsius'
    },
  ],
  '3': [
    HvacTemperatureAdjustmentAction_Temperature$json,
    HvacTemperatureAdjustmentAction_HvacTemperatureZone$json
  ],
};

@$core.Deprecated('Use hvacTemperatureAdjustmentActionDescriptor instead')
const HvacTemperatureAdjustmentAction_Temperature$json = {
  '1': 'Temperature',
  '2': [
    {
      '1': 'TEMP_UNKNOWN',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'TEMPUNKNOWN'
    },
    {
      '1': 'TEMP_MIN',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'TEMPMIN'
    },
    {
      '1': 'TEMP_MAX',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'TEMPMAX'
    },
  ],
  '8': [
    {'1': 'type'},
  ],
};

@$core.Deprecated('Use hvacTemperatureAdjustmentActionDescriptor instead')
const HvacTemperatureAdjustmentAction_HvacTemperatureZone$json = {
  '1': 'HvacTemperatureZone',
  '2': [
    {
      '1': 'TEMP_ZONE_UNKNOWN',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'TEMPZONEUNKNOWN'
    },
    {
      '1': 'TEMP_ZONE_FRONT_LEFT',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'TEMPZONEFRONTLEFT'
    },
    {
      '1': 'TEMP_ZONE_FRONT_RIGHT',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'TEMPZONEFRONTRIGHT'
    },
    {
      '1': 'TEMP_ZONE_REAR',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'TEMPZONEREAR'
    },
  ],
  '8': [
    {'1': 'type'},
  ],
};

/// Descriptor for `HvacTemperatureAdjustmentAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hvacTemperatureAdjustmentActionDescriptor = $convert.base64Decode(
    'Ch9IdmFjVGVtcGVyYXR1cmVBZGp1c3RtZW50QWN0aW9uEiMKDWRlbHRhX2NlbHNpdXMYASABKA'
    'JSDGRlbHRhQ2Vsc2l1cxIjCg1kZWx0YV9wZXJjZW50GAIgASgRUgxkZWx0YVBlcmNlbnQSKQoQ'
    'YWJzb2x1dGVfY2Vsc2l1cxgDIAEoAlIPYWJzb2x1dGVDZWxzaXVzEkwKBWxldmVsGAUgASgLMj'
    'YuQ2FyU2VydmVyLkh2YWNUZW1wZXJhdHVyZUFkanVzdG1lbnRBY3Rpb24uVGVtcGVyYXR1cmVS'
    'BWxldmVsEnIKFWh2YWNfdGVtcGVyYXR1cmVfem9uZRgEIAMoCzI+LkNhclNlcnZlci5IdmFjVG'
    'VtcGVyYXR1cmVBZGp1c3RtZW50QWN0aW9uLkh2YWNUZW1wZXJhdHVyZVpvbmVSE2h2YWNUZW1w'
    'ZXJhdHVyZVpvbmUSLgoTZHJpdmVyX3RlbXBfY2Vsc2l1cxgGIAEoAlIRZHJpdmVyVGVtcENlbH'
    'NpdXMSNAoWcGFzc2VuZ2VyX3RlbXBfY2Vsc2l1cxgHIAEoAlIUcGFzc2VuZ2VyVGVtcENlbHNp'
    'dXMapwEKC1RlbXBlcmF0dXJlEjQKDFRFTVBfVU5LTk9XThgBIAEoCzIPLkNhclNlcnZlci5Wb2'
    'lkSABSC1RFTVBVTktOT1dOEiwKCFRFTVBfTUlOGAIgASgLMg8uQ2FyU2VydmVyLlZvaWRIAFIH'
    'VEVNUE1JThIsCghURU1QX01BWBgDIAEoCzIPLkNhclNlcnZlci5Wb2lkSABSB1RFTVBNQVhCBg'
    'oEdHlwZRqfAgoTSHZhY1RlbXBlcmF0dXJlWm9uZRI9ChFURU1QX1pPTkVfVU5LTk9XThgBIAEo'
    'CzIPLkNhclNlcnZlci5Wb2lkSABSD1RFTVBaT05FVU5LTk9XThJCChRURU1QX1pPTkVfRlJPTl'
    'RfTEVGVBgCIAEoCzIPLkNhclNlcnZlci5Wb2lkSABSEVRFTVBaT05FRlJPTlRMRUZUEkQKFVRF'
    'TVBfWk9ORV9GUk9OVF9SSUdIVBgDIAEoCzIPLkNhclNlcnZlci5Wb2lkSABSElRFTVBaT05FRl'
    'JPTlRSSUdIVBI3Cg5URU1QX1pPTkVfUkVBUhgEIAEoCzIPLkNhclNlcnZlci5Wb2lkSABSDFRF'
    'TVBaT05FUkVBUkIGCgR0eXBl');

@$core.Deprecated('Use getNearbyChargingSitesDescriptor instead')
const GetNearbyChargingSites$json = {
  '1': 'GetNearbyChargingSites',
  '2': [
    {'1': 'include_meta_data', '3': 1, '4': 1, '5': 8, '10': 'includeMetaData'},
    {'1': 'radius', '3': 2, '4': 1, '5': 5, '10': 'radius'},
    {'1': 'count', '3': 3, '4': 1, '5': 5, '10': 'count'},
  ],
};

/// Descriptor for `GetNearbyChargingSites`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List getNearbyChargingSitesDescriptor = $convert.base64Decode(
    'ChZHZXROZWFyYnlDaGFyZ2luZ1NpdGVzEioKEWluY2x1ZGVfbWV0YV9kYXRhGAEgASgIUg9pbm'
    'NsdWRlTWV0YURhdGESFgoGcmFkaXVzGAIgASgFUgZyYWRpdXMSFAoFY291bnQYAyABKAVSBWNv'
    'dW50');

@$core.Deprecated('Use nearbyChargingSitesDescriptor instead')
const NearbyChargingSites$json = {
  '1': 'NearbyChargingSites',
  '2': [
    {
      '1': 'timestamp',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'timestamp'
    },
    {
      '1': 'superchargers',
      '3': 3,
      '4': 3,
      '5': 11,
      '6': '.CarServer.Superchargers',
      '10': 'superchargers'
    },
    {
      '1': 'congestion_sync_time_utc_secs',
      '3': 4,
      '4': 1,
      '5': 3,
      '10': 'congestionSyncTimeUtcSecs'
    },
  ],
};

/// Descriptor for `NearbyChargingSites`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List nearbyChargingSitesDescriptor = $convert.base64Decode(
    'ChNOZWFyYnlDaGFyZ2luZ1NpdGVzEjgKCXRpbWVzdGFtcBgBIAEoCzIaLmdvb2dsZS5wcm90b2'
    'J1Zi5UaW1lc3RhbXBSCXRpbWVzdGFtcBI+Cg1zdXBlcmNoYXJnZXJzGAMgAygLMhguQ2FyU2Vy'
    'dmVyLlN1cGVyY2hhcmdlcnNSDXN1cGVyY2hhcmdlcnMSQAodY29uZ2VzdGlvbl9zeW5jX3RpbW'
    'VfdXRjX3NlY3MYBCABKANSGWNvbmdlc3Rpb25TeW5jVGltZVV0Y1NlY3M=');

@$core.Deprecated('Use superchargersDescriptor instead')
const Superchargers$json = {
  '1': 'Superchargers',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 3, '10': 'id'},
    {'1': 'amenities', '3': 2, '4': 1, '5': 9, '10': 'amenities'},
    {'1': 'available_stalls', '3': 3, '4': 1, '5': 5, '10': 'availableStalls'},
    {'1': 'billing_info', '3': 4, '4': 1, '5': 9, '10': 'billingInfo'},
    {'1': 'billing_time', '3': 5, '4': 1, '5': 9, '10': 'billingTime'},
    {'1': 'city', '3': 6, '4': 1, '5': 9, '10': 'city'},
    {'1': 'country', '3': 7, '4': 1, '5': 9, '10': 'country'},
    {'1': 'distance_miles', '3': 8, '4': 1, '5': 2, '10': 'distanceMiles'},
    {'1': 'district', '3': 9, '4': 1, '5': 9, '10': 'district'},
    {
      '1': 'location',
      '3': 10,
      '4': 1,
      '5': 11,
      '6': '.CarServer.LatLong',
      '10': 'location'
    },
    {'1': 'name', '3': 11, '4': 1, '5': 9, '10': 'name'},
    {'1': 'postal_code', '3': 12, '4': 1, '5': 9, '10': 'postalCode'},
    {'1': 'site_closed', '3': 13, '4': 1, '5': 8, '10': 'siteClosed'},
    {'1': 'state', '3': 14, '4': 1, '5': 9, '10': 'state'},
    {'1': 'street_address', '3': 15, '4': 1, '5': 9, '10': 'streetAddress'},
    {'1': 'total_stalls', '3': 16, '4': 1, '5': 5, '10': 'totalStalls'},
    {'1': 'within_range', '3': 17, '4': 1, '5': 8, '10': 'withinRange'},
    {'1': 'max_power_kw', '3': 18, '4': 1, '5': 5, '10': 'maxPowerKw'},
    {
      '1': 'out_of_order_stalls_number',
      '3': 19,
      '4': 1,
      '5': 5,
      '10': 'outOfOrderStallsNumber'
    },
    {
      '1': 'out_of_order_stalls_names',
      '3': 20,
      '4': 1,
      '5': 9,
      '10': 'outOfOrderStallsNames'
    },
  ],
};

/// Descriptor for `Superchargers`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List superchargersDescriptor = $convert.base64Decode(
    'Cg1TdXBlcmNoYXJnZXJzEg4KAmlkGAEgASgDUgJpZBIcCglhbWVuaXRpZXMYAiABKAlSCWFtZW'
    '5pdGllcxIpChBhdmFpbGFibGVfc3RhbGxzGAMgASgFUg9hdmFpbGFibGVTdGFsbHMSIQoMYmls'
    'bGluZ19pbmZvGAQgASgJUgtiaWxsaW5nSW5mbxIhCgxiaWxsaW5nX3RpbWUYBSABKAlSC2JpbG'
    'xpbmdUaW1lEhIKBGNpdHkYBiABKAlSBGNpdHkSGAoHY291bnRyeRgHIAEoCVIHY291bnRyeRIl'
    'Cg5kaXN0YW5jZV9taWxlcxgIIAEoAlINZGlzdGFuY2VNaWxlcxIaCghkaXN0cmljdBgJIAEoCV'
    'IIZGlzdHJpY3QSLgoIbG9jYXRpb24YCiABKAsyEi5DYXJTZXJ2ZXIuTGF0TG9uZ1IIbG9jYXRp'
    'b24SEgoEbmFtZRgLIAEoCVIEbmFtZRIfCgtwb3N0YWxfY29kZRgMIAEoCVIKcG9zdGFsQ29kZR'
    'IfCgtzaXRlX2Nsb3NlZBgNIAEoCFIKc2l0ZUNsb3NlZBIUCgVzdGF0ZRgOIAEoCVIFc3RhdGUS'
    'JQoOc3RyZWV0X2FkZHJlc3MYDyABKAlSDXN0cmVldEFkZHJlc3MSIQoMdG90YWxfc3RhbGxzGB'
    'AgASgFUgt0b3RhbFN0YWxscxIhCgx3aXRoaW5fcmFuZ2UYESABKAhSC3dpdGhpblJhbmdlEiAK'
    'DG1heF9wb3dlcl9rdxgSIAEoBVIKbWF4UG93ZXJLdxI6ChpvdXRfb2Zfb3JkZXJfc3RhbGxzX2'
    '51bWJlchgTIAEoBVIWb3V0T2ZPcmRlclN0YWxsc051bWJlchI4ChlvdXRfb2Zfb3JkZXJfc3Rh'
    'bGxzX25hbWVzGBQgASgJUhVvdXRPZk9yZGVyU3RhbGxzTmFtZXM=');

@$core.Deprecated('Use mediaPlayActionDescriptor instead')
const MediaPlayAction$json = {
  '1': 'MediaPlayAction',
};

/// Descriptor for `MediaPlayAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaPlayActionDescriptor =
    $convert.base64Decode('Cg9NZWRpYVBsYXlBY3Rpb24=');

@$core.Deprecated('Use mediaUpdateVolumeDescriptor instead')
const MediaUpdateVolume$json = {
  '1': 'MediaUpdateVolume',
  '2': [
    {'1': 'volume_delta', '3': 1, '4': 1, '5': 17, '9': 0, '10': 'volumeDelta'},
    {
      '1': 'volume_absolute_float',
      '3': 3,
      '4': 1,
      '5': 2,
      '9': 0,
      '10': 'volumeAbsoluteFloat'
    },
  ],
  '8': [
    {'1': 'media_volume'},
  ],
  '9': [
    {'1': 2, '2': 3},
  ],
};

/// Descriptor for `MediaUpdateVolume`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaUpdateVolumeDescriptor = $convert.base64Decode(
    'ChFNZWRpYVVwZGF0ZVZvbHVtZRIjCgx2b2x1bWVfZGVsdGEYASABKBFIAFILdm9sdW1lRGVsdG'
    'ESNAoVdm9sdW1lX2Fic29sdXRlX2Zsb2F0GAMgASgCSABSE3ZvbHVtZUFic29sdXRlRmxvYXRC'
    'DgoMbWVkaWFfdm9sdW1lSgQIAhAD');

@$core.Deprecated('Use mediaNextFavoriteDescriptor instead')
const MediaNextFavorite$json = {
  '1': 'MediaNextFavorite',
};

/// Descriptor for `MediaNextFavorite`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaNextFavoriteDescriptor =
    $convert.base64Decode('ChFNZWRpYU5leHRGYXZvcml0ZQ==');

@$core.Deprecated('Use mediaPreviousFavoriteDescriptor instead')
const MediaPreviousFavorite$json = {
  '1': 'MediaPreviousFavorite',
};

/// Descriptor for `MediaPreviousFavorite`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaPreviousFavoriteDescriptor =
    $convert.base64Decode('ChVNZWRpYVByZXZpb3VzRmF2b3JpdGU=');

@$core.Deprecated('Use mediaNextTrackDescriptor instead')
const MediaNextTrack$json = {
  '1': 'MediaNextTrack',
};

/// Descriptor for `MediaNextTrack`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaNextTrackDescriptor =
    $convert.base64Decode('Cg5NZWRpYU5leHRUcmFjaw==');

@$core.Deprecated('Use mediaPreviousTrackDescriptor instead')
const MediaPreviousTrack$json = {
  '1': 'MediaPreviousTrack',
};

/// Descriptor for `MediaPreviousTrack`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List mediaPreviousTrackDescriptor =
    $convert.base64Decode('ChJNZWRpYVByZXZpb3VzVHJhY2s=');

@$core.Deprecated(
    'Use vehicleControlCancelSoftwareUpdateActionDescriptor instead')
const VehicleControlCancelSoftwareUpdateAction$json = {
  '1': 'VehicleControlCancelSoftwareUpdateAction',
};

/// Descriptor for `VehicleControlCancelSoftwareUpdateAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleControlCancelSoftwareUpdateActionDescriptor =
    $convert.base64Decode(
        'CihWZWhpY2xlQ29udHJvbENhbmNlbFNvZnR3YXJlVXBkYXRlQWN0aW9u');

@$core.Deprecated('Use vehicleControlFlashLightsActionDescriptor instead')
const VehicleControlFlashLightsAction$json = {
  '1': 'VehicleControlFlashLightsAction',
};

/// Descriptor for `VehicleControlFlashLightsAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleControlFlashLightsActionDescriptor =
    $convert.base64Decode('Ch9WZWhpY2xlQ29udHJvbEZsYXNoTGlnaHRzQWN0aW9u');

@$core.Deprecated('Use vehicleControlHonkHornActionDescriptor instead')
const VehicleControlHonkHornAction$json = {
  '1': 'VehicleControlHonkHornAction',
};

/// Descriptor for `VehicleControlHonkHornAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleControlHonkHornActionDescriptor =
    $convert.base64Decode('ChxWZWhpY2xlQ29udHJvbEhvbmtIb3JuQWN0aW9u');

@$core.Deprecated('Use vehicleControlResetValetPinActionDescriptor instead')
const VehicleControlResetValetPinAction$json = {
  '1': 'VehicleControlResetValetPinAction',
};

/// Descriptor for `VehicleControlResetValetPinAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleControlResetValetPinActionDescriptor =
    $convert.base64Decode('CiFWZWhpY2xlQ29udHJvbFJlc2V0VmFsZXRQaW5BY3Rpb24=');

@$core.Deprecated(
    'Use vehicleControlScheduleSoftwareUpdateActionDescriptor instead')
const VehicleControlScheduleSoftwareUpdateAction$json = {
  '1': 'VehicleControlScheduleSoftwareUpdateAction',
  '2': [
    {'1': 'offset_sec', '3': 1, '4': 1, '5': 5, '10': 'offsetSec'},
  ],
};

/// Descriptor for `VehicleControlScheduleSoftwareUpdateAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List
    vehicleControlScheduleSoftwareUpdateActionDescriptor =
    $convert.base64Decode(
        'CipWZWhpY2xlQ29udHJvbFNjaGVkdWxlU29mdHdhcmVVcGRhdGVBY3Rpb24SHQoKb2Zmc2V0X3'
        'NlYxgBIAEoBVIJb2Zmc2V0U2Vj');

@$core.Deprecated('Use vehicleControlSetSentryModeActionDescriptor instead')
const VehicleControlSetSentryModeAction$json = {
  '1': 'VehicleControlSetSentryModeAction',
  '2': [
    {'1': 'on', '3': 1, '4': 1, '5': 8, '10': 'on'},
  ],
};

/// Descriptor for `VehicleControlSetSentryModeAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleControlSetSentryModeActionDescriptor =
    $convert.base64Decode(
        'CiFWZWhpY2xlQ29udHJvbFNldFNlbnRyeU1vZGVBY3Rpb24SDgoCb24YASABKAhSAm9u');

@$core.Deprecated('Use vehicleControlSetValetModeActionDescriptor instead')
const VehicleControlSetValetModeAction$json = {
  '1': 'VehicleControlSetValetModeAction',
  '2': [
    {'1': 'on', '3': 1, '4': 1, '5': 8, '10': 'on'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `VehicleControlSetValetModeAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleControlSetValetModeActionDescriptor =
    $convert.base64Decode(
        'CiBWZWhpY2xlQ29udHJvbFNldFZhbGV0TW9kZUFjdGlvbhIOCgJvbhgBIAEoCFICb24SGgoIcG'
        'Fzc3dvcmQYAiABKAlSCHBhc3N3b3Jk');

@$core.Deprecated('Use vehicleControlSunroofOpenCloseActionDescriptor instead')
const VehicleControlSunroofOpenCloseAction$json = {
  '1': 'VehicleControlSunroofOpenCloseAction',
  '2': [
    {
      '1': 'absolute_level',
      '3': 1,
      '4': 1,
      '5': 5,
      '9': 0,
      '10': 'absoluteLevel'
    },
    {'1': 'delta_level', '3': 2, '4': 1, '5': 17, '9': 0, '10': 'deltaLevel'},
    {
      '1': 'vent',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 1,
      '10': 'vent'
    },
    {
      '1': 'close',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 1,
      '10': 'close'
    },
    {
      '1': 'open',
      '3': 5,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 1,
      '10': 'open'
    },
  ],
  '8': [
    {'1': 'sunroof_level'},
    {'1': 'action'},
  ],
};

/// Descriptor for `VehicleControlSunroofOpenCloseAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleControlSunroofOpenCloseActionDescriptor =
    $convert.base64Decode(
        'CiRWZWhpY2xlQ29udHJvbFN1bnJvb2ZPcGVuQ2xvc2VBY3Rpb24SJwoOYWJzb2x1dGVfbGV2ZW'
        'wYASABKAVIAFINYWJzb2x1dGVMZXZlbBIhCgtkZWx0YV9sZXZlbBgCIAEoEUgAUgpkZWx0YUxl'
        'dmVsEiUKBHZlbnQYAyABKAsyDy5DYXJTZXJ2ZXIuVm9pZEgBUgR2ZW50EicKBWNsb3NlGAQgAS'
        'gLMg8uQ2FyU2VydmVyLlZvaWRIAVIFY2xvc2USJQoEb3BlbhgFIAEoCzIPLkNhclNlcnZlci5W'
        'b2lkSAFSBG9wZW5CDwoNc3Vucm9vZl9sZXZlbEIICgZhY3Rpb24=');

@$core.Deprecated('Use vehicleControlTriggerHomelinkActionDescriptor instead')
const VehicleControlTriggerHomelinkAction$json = {
  '1': 'VehicleControlTriggerHomelinkAction',
  '2': [
    {
      '1': 'location',
      '3': 1,
      '4': 1,
      '5': 11,
      '6': '.CarServer.LatLong',
      '10': 'location'
    },
    {'1': 'token', '3': 2, '4': 1, '5': 9, '10': 'token'},
  ],
};

/// Descriptor for `VehicleControlTriggerHomelinkAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleControlTriggerHomelinkActionDescriptor =
    $convert.base64Decode(
        'CiNWZWhpY2xlQ29udHJvbFRyaWdnZXJIb21lbGlua0FjdGlvbhIuCghsb2NhdGlvbhgBIAEoCz'
        'ISLkNhclNlcnZlci5MYXRMb25nUghsb2NhdGlvbhIUCgV0b2tlbhgCIAEoCVIFdG9rZW4=');

@$core.Deprecated('Use vehicleControlWindowActionDescriptor instead')
const VehicleControlWindowAction$json = {
  '1': 'VehicleControlWindowAction',
  '2': [
    {
      '1': 'unknown',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'unknown'
    },
    {
      '1': 'vent',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'vent'
    },
    {
      '1': 'close',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.CarServer.Void',
      '9': 0,
      '10': 'close'
    },
  ],
  '8': [
    {'1': 'action'},
  ],
  '9': [
    {'1': 1, '2': 2},
  ],
};

/// Descriptor for `VehicleControlWindowAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleControlWindowActionDescriptor = $convert.base64Decode(
    'ChpWZWhpY2xlQ29udHJvbFdpbmRvd0FjdGlvbhIrCgd1bmtub3duGAIgASgLMg8uQ2FyU2Vydm'
    'VyLlZvaWRIAFIHdW5rbm93bhIlCgR2ZW50GAMgASgLMg8uQ2FyU2VydmVyLlZvaWRIAFIEdmVu'
    'dBInCgVjbG9zZRgEIAEoCzIPLkNhclNlcnZlci5Wb2lkSABSBWNsb3NlQggKBmFjdGlvbkoECA'
    'EQAg==');

@$core.Deprecated('Use hvacBioweaponModeActionDescriptor instead')
const HvacBioweaponModeAction$json = {
  '1': 'HvacBioweaponModeAction',
  '2': [
    {'1': 'on', '3': 1, '4': 1, '5': 8, '10': 'on'},
    {'1': 'manual_override', '3': 2, '4': 1, '5': 8, '10': 'manualOverride'},
  ],
};

/// Descriptor for `HvacBioweaponModeAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hvacBioweaponModeActionDescriptor =
    $convert.base64Decode(
        'ChdIdmFjQmlvd2VhcG9uTW9kZUFjdGlvbhIOCgJvbhgBIAEoCFICb24SJwoPbWFudWFsX292ZX'
        'JyaWRlGAIgASgIUg5tYW51YWxPdmVycmlkZQ==');

@$core.Deprecated('Use autoSeatClimateActionDescriptor instead')
const AutoSeatClimateAction$json = {
  '1': 'AutoSeatClimateAction',
  '2': [
    {
      '1': 'carseat',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.CarServer.AutoSeatClimateAction.CarSeat',
      '10': 'carseat'
    },
  ],
  '3': [AutoSeatClimateAction_CarSeat$json],
  '4': [AutoSeatClimateAction_AutoSeatPosition_E$json],
};

@$core.Deprecated('Use autoSeatClimateActionDescriptor instead')
const AutoSeatClimateAction_CarSeat$json = {
  '1': 'CarSeat',
  '2': [
    {'1': 'on', '3': 1, '4': 1, '5': 8, '10': 'on'},
    {
      '1': 'seat_position',
      '3': 2,
      '4': 1,
      '5': 14,
      '6': '.CarServer.AutoSeatClimateAction.AutoSeatPosition_E',
      '10': 'seatPosition'
    },
  ],
};

@$core.Deprecated('Use autoSeatClimateActionDescriptor instead')
const AutoSeatClimateAction_AutoSeatPosition_E$json = {
  '1': 'AutoSeatPosition_E',
  '2': [
    {'1': 'AutoSeatPosition_Unknown', '2': 0},
    {'1': 'AutoSeatPosition_FrontLeft', '2': 1},
    {'1': 'AutoSeatPosition_FrontRight', '2': 2},
  ],
};

/// Descriptor for `AutoSeatClimateAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List autoSeatClimateActionDescriptor = $convert.base64Decode(
    'ChVBdXRvU2VhdENsaW1hdGVBY3Rpb24SQgoHY2Fyc2VhdBgBIAMoCzIoLkNhclNlcnZlci5BdX'
    'RvU2VhdENsaW1hdGVBY3Rpb24uQ2FyU2VhdFIHY2Fyc2VhdBpzCgdDYXJTZWF0Eg4KAm9uGAEg'
    'ASgIUgJvbhJYCg1zZWF0X3Bvc2l0aW9uGAIgASgOMjMuQ2FyU2VydmVyLkF1dG9TZWF0Q2xpbW'
    'F0ZUFjdGlvbi5BdXRvU2VhdFBvc2l0aW9uX0VSDHNlYXRQb3NpdGlvbiJzChJBdXRvU2VhdFBv'
    'c2l0aW9uX0USHAoYQXV0b1NlYXRQb3NpdGlvbl9Vbmtub3duEAASHgoaQXV0b1NlYXRQb3NpdG'
    'lvbl9Gcm9udExlZnQQARIfChtBdXRvU2VhdFBvc2l0aW9uX0Zyb250UmlnaHQQAg==');

@$core.Deprecated('Use pingDescriptor instead')
const Ping$json = {
  '1': 'Ping',
  '2': [
    {'1': 'ping_id', '3': 1, '4': 1, '5': 5, '10': 'pingId'},
    {
      '1': 'local_timestamp',
      '3': 2,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'localTimestamp'
    },
    {
      '1': 'last_remote_timestamp',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.google.protobuf.Timestamp',
      '10': 'lastRemoteTimestamp'
    },
  ],
};

/// Descriptor for `Ping`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingDescriptor = $convert.base64Decode(
    'CgRQaW5nEhcKB3BpbmdfaWQYASABKAVSBnBpbmdJZBJDCg9sb2NhbF90aW1lc3RhbXAYAiABKA'
    'syGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUg5sb2NhbFRpbWVzdGFtcBJOChVsYXN0X3Jl'
    'bW90ZV90aW1lc3RhbXAYAyABKAsyGi5nb29nbGUucHJvdG9idWYuVGltZXN0YW1wUhNsYXN0Um'
    'Vtb3RlVGltZXN0YW1w');

@$core.Deprecated('Use scheduledChargingActionDescriptor instead')
const ScheduledChargingAction$json = {
  '1': 'ScheduledChargingAction',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'charging_time', '3': 2, '4': 1, '5': 5, '10': 'chargingTime'},
  ],
};

/// Descriptor for `ScheduledChargingAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scheduledChargingActionDescriptor =
    $convert.base64Decode(
        'ChdTY2hlZHVsZWRDaGFyZ2luZ0FjdGlvbhIYCgdlbmFibGVkGAEgASgIUgdlbmFibGVkEiMKDW'
        'NoYXJnaW5nX3RpbWUYAiABKAVSDGNoYXJnaW5nVGltZQ==');

@$core.Deprecated('Use scheduledDepartureActionDescriptor instead')
const ScheduledDepartureAction$json = {
  '1': 'ScheduledDepartureAction',
  '2': [
    {'1': 'enabled', '3': 1, '4': 1, '5': 8, '10': 'enabled'},
    {'1': 'departure_time', '3': 2, '4': 1, '5': 5, '10': 'departureTime'},
    {
      '1': 'preconditioning_times',
      '3': 3,
      '4': 1,
      '5': 11,
      '6': '.CarServer.PreconditioningTimes',
      '10': 'preconditioningTimes'
    },
    {
      '1': 'off_peak_charging_times',
      '3': 4,
      '4': 1,
      '5': 11,
      '6': '.CarServer.OffPeakChargingTimes',
      '10': 'offPeakChargingTimes'
    },
    {
      '1': 'off_peak_hours_end_time',
      '3': 5,
      '4': 1,
      '5': 5,
      '10': 'offPeakHoursEndTime'
    },
  ],
};

/// Descriptor for `ScheduledDepartureAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List scheduledDepartureActionDescriptor = $convert.base64Decode(
    'ChhTY2hlZHVsZWREZXBhcnR1cmVBY3Rpb24SGAoHZW5hYmxlZBgBIAEoCFIHZW5hYmxlZBIlCg'
    '5kZXBhcnR1cmVfdGltZRgCIAEoBVINZGVwYXJ0dXJlVGltZRJUChVwcmVjb25kaXRpb25pbmdf'
    'dGltZXMYAyABKAsyHy5DYXJTZXJ2ZXIuUHJlY29uZGl0aW9uaW5nVGltZXNSFHByZWNvbmRpdG'
    'lvbmluZ1RpbWVzElYKF29mZl9wZWFrX2NoYXJnaW5nX3RpbWVzGAQgASgLMh8uQ2FyU2VydmVy'
    'Lk9mZlBlYWtDaGFyZ2luZ1RpbWVzUhRvZmZQZWFrQ2hhcmdpbmdUaW1lcxI0ChdvZmZfcGVha1'
    '9ob3Vyc19lbmRfdGltZRgFIAEoBVITb2ZmUGVha0hvdXJzRW5kVGltZQ==');

@$core.Deprecated('Use hvacClimateKeeperActionDescriptor instead')
const HvacClimateKeeperAction$json = {
  '1': 'HvacClimateKeeperAction',
  '2': [
    {
      '1': 'ClimateKeeperAction',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.CarServer.HvacClimateKeeperAction.ClimateKeeperAction_E',
      '10': 'ClimateKeeperAction'
    },
    {'1': 'manual_override', '3': 2, '4': 1, '5': 8, '10': 'manualOverride'},
  ],
  '4': [HvacClimateKeeperAction_ClimateKeeperAction_E$json],
};

@$core.Deprecated('Use hvacClimateKeeperActionDescriptor instead')
const HvacClimateKeeperAction_ClimateKeeperAction_E$json = {
  '1': 'ClimateKeeperAction_E',
  '2': [
    {'1': 'ClimateKeeperAction_Off', '2': 0},
    {'1': 'ClimateKeeperAction_On', '2': 1},
    {'1': 'ClimateKeeperAction_Dog', '2': 2},
    {'1': 'ClimateKeeperAction_Camp', '2': 3},
  ],
};

/// Descriptor for `HvacClimateKeeperAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List hvacClimateKeeperActionDescriptor = $convert.base64Decode(
    'ChdIdmFjQ2xpbWF0ZUtlZXBlckFjdGlvbhJqChNDbGltYXRlS2VlcGVyQWN0aW9uGAEgASgOMj'
    'guQ2FyU2VydmVyLkh2YWNDbGltYXRlS2VlcGVyQWN0aW9uLkNsaW1hdGVLZWVwZXJBY3Rpb25f'
    'RVITQ2xpbWF0ZUtlZXBlckFjdGlvbhInCg9tYW51YWxfb3ZlcnJpZGUYAiABKAhSDm1hbnVhbE'
    '92ZXJyaWRlIosBChVDbGltYXRlS2VlcGVyQWN0aW9uX0USGwoXQ2xpbWF0ZUtlZXBlckFjdGlv'
    'bl9PZmYQABIaChZDbGltYXRlS2VlcGVyQWN0aW9uX09uEAESGwoXQ2xpbWF0ZUtlZXBlckFjdG'
    'lvbl9Eb2cQAhIcChhDbGltYXRlS2VlcGVyQWN0aW9uX0NhbXAQAw==');

@$core.Deprecated('Use setChargingAmpsActionDescriptor instead')
const SetChargingAmpsAction$json = {
  '1': 'SetChargingAmpsAction',
  '2': [
    {'1': 'charging_amps', '3': 1, '4': 1, '5': 5, '10': 'chargingAmps'},
  ],
};

/// Descriptor for `SetChargingAmpsAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setChargingAmpsActionDescriptor = $convert.base64Decode(
    'ChVTZXRDaGFyZ2luZ0FtcHNBY3Rpb24SIwoNY2hhcmdpbmdfYW1wcxgBIAEoBVIMY2hhcmdpbm'
    'dBbXBz');

@$core.Deprecated('Use removeChargeScheduleActionDescriptor instead')
const RemoveChargeScheduleAction$json = {
  '1': 'RemoveChargeScheduleAction',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
  ],
};

/// Descriptor for `RemoveChargeScheduleAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removeChargeScheduleActionDescriptor =
    $convert.base64Decode(
        'ChpSZW1vdmVDaGFyZ2VTY2hlZHVsZUFjdGlvbhIOCgJpZBgBIAEoBFICaWQ=');

@$core.Deprecated('Use batchRemoveChargeSchedulesActionDescriptor instead')
const BatchRemoveChargeSchedulesAction$json = {
  '1': 'BatchRemoveChargeSchedulesAction',
  '2': [
    {'1': 'home', '3': 1, '4': 1, '5': 8, '10': 'home'},
    {'1': 'work', '3': 2, '4': 1, '5': 8, '10': 'work'},
    {'1': 'other', '3': 3, '4': 1, '5': 8, '10': 'other'},
  ],
};

/// Descriptor for `BatchRemoveChargeSchedulesAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchRemoveChargeSchedulesActionDescriptor =
    $convert.base64Decode(
        'CiBCYXRjaFJlbW92ZUNoYXJnZVNjaGVkdWxlc0FjdGlvbhISCgRob21lGAEgASgIUgRob21lEh'
        'IKBHdvcmsYAiABKAhSBHdvcmsSFAoFb3RoZXIYAyABKAhSBW90aGVy');

@$core
    .Deprecated('Use batchRemovePreconditionSchedulesActionDescriptor instead')
const BatchRemovePreconditionSchedulesAction$json = {
  '1': 'BatchRemovePreconditionSchedulesAction',
  '2': [
    {'1': 'home', '3': 1, '4': 1, '5': 8, '10': 'home'},
    {'1': 'work', '3': 2, '4': 1, '5': 8, '10': 'work'},
    {'1': 'other', '3': 3, '4': 1, '5': 8, '10': 'other'},
  ],
};

/// Descriptor for `BatchRemovePreconditionSchedulesAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List batchRemovePreconditionSchedulesActionDescriptor =
    $convert.base64Decode(
        'CiZCYXRjaFJlbW92ZVByZWNvbmRpdGlvblNjaGVkdWxlc0FjdGlvbhISCgRob21lGAEgASgIUg'
        'Rob21lEhIKBHdvcmsYAiABKAhSBHdvcmsSFAoFb3RoZXIYAyABKAhSBW90aGVy');

@$core.Deprecated('Use removePreconditionScheduleActionDescriptor instead')
const RemovePreconditionScheduleAction$json = {
  '1': 'RemovePreconditionScheduleAction',
  '2': [
    {'1': 'id', '3': 1, '4': 1, '5': 4, '10': 'id'},
  ],
};

/// Descriptor for `RemovePreconditionScheduleAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List removePreconditionScheduleActionDescriptor =
    $convert.base64Decode(
        'CiBSZW1vdmVQcmVjb25kaXRpb25TY2hlZHVsZUFjdGlvbhIOCgJpZBgBIAEoBFICaWQ=');

@$core.Deprecated('Use setCabinOverheatProtectionActionDescriptor instead')
const SetCabinOverheatProtectionAction$json = {
  '1': 'SetCabinOverheatProtectionAction',
  '2': [
    {'1': 'on', '3': 1, '4': 1, '5': 8, '10': 'on'},
    {'1': 'fan_only', '3': 2, '4': 1, '5': 8, '10': 'fanOnly'},
  ],
};

/// Descriptor for `SetCabinOverheatProtectionAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setCabinOverheatProtectionActionDescriptor =
    $convert.base64Decode(
        'CiBTZXRDYWJpbk92ZXJoZWF0UHJvdGVjdGlvbkFjdGlvbhIOCgJvbhgBIAEoCFICb24SGQoIZm'
        'FuX29ubHkYAiABKAhSB2Zhbk9ubHk=');

@$core.Deprecated('Use setVehicleNameActionDescriptor instead')
const SetVehicleNameAction$json = {
  '1': 'SetVehicleNameAction',
  '2': [
    {'1': 'vehicleName', '3': 1, '4': 1, '5': 9, '10': 'vehicleName'},
  ],
};

/// Descriptor for `SetVehicleNameAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setVehicleNameActionDescriptor = $convert.base64Decode(
    'ChRTZXRWZWhpY2xlTmFtZUFjdGlvbhIgCgt2ZWhpY2xlTmFtZRgBIAEoCVILdmVoaWNsZU5hbW'
    'U=');

@$core.Deprecated('Use chargePortDoorCloseDescriptor instead')
const ChargePortDoorClose$json = {
  '1': 'ChargePortDoorClose',
};

/// Descriptor for `ChargePortDoorClose`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chargePortDoorCloseDescriptor =
    $convert.base64Decode('ChNDaGFyZ2VQb3J0RG9vckNsb3Nl');

@$core.Deprecated('Use chargePortDoorOpenDescriptor instead')
const ChargePortDoorOpen$json = {
  '1': 'ChargePortDoorOpen',
};

/// Descriptor for `ChargePortDoorOpen`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List chargePortDoorOpenDescriptor =
    $convert.base64Decode('ChJDaGFyZ2VQb3J0RG9vck9wZW4=');

@$core.Deprecated('Use setCopTempActionDescriptor instead')
const SetCopTempAction$json = {
  '1': 'SetCopTempAction',
  '2': [
    {
      '1': 'copActivationTemp',
      '3': 1,
      '4': 1,
      '5': 14,
      '6': '.CarServer.ClimateState.CopActivationTemp',
      '10': 'copActivationTemp'
    },
  ],
};

/// Descriptor for `SetCopTempAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setCopTempActionDescriptor = $convert.base64Decode(
    'ChBTZXRDb3BUZW1wQWN0aW9uElcKEWNvcEFjdGl2YXRpb25UZW1wGAEgASgOMikuQ2FyU2Vydm'
    'VyLkNsaW1hdGVTdGF0ZS5Db3BBY3RpdmF0aW9uVGVtcFIRY29wQWN0aXZhdGlvblRlbXA=');

@$core.Deprecated('Use vehicleControlSetPinToDriveActionDescriptor instead')
const VehicleControlSetPinToDriveAction$json = {
  '1': 'VehicleControlSetPinToDriveAction',
  '2': [
    {'1': 'on', '3': 1, '4': 1, '5': 8, '10': 'on'},
    {'1': 'password', '3': 2, '4': 1, '5': 9, '10': 'password'},
  ],
};

/// Descriptor for `VehicleControlSetPinToDriveAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleControlSetPinToDriveActionDescriptor =
    $convert.base64Decode(
        'CiFWZWhpY2xlQ29udHJvbFNldFBpblRvRHJpdmVBY3Rpb24SDgoCb24YASABKAhSAm9uEhoKCH'
        'Bhc3N3b3JkGAIgASgJUghwYXNzd29yZA==');

@$core.Deprecated('Use vehicleControlResetPinToDriveActionDescriptor instead')
const VehicleControlResetPinToDriveAction$json = {
  '1': 'VehicleControlResetPinToDriveAction',
};

/// Descriptor for `VehicleControlResetPinToDriveAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleControlResetPinToDriveActionDescriptor =
    $convert
        .base64Decode('CiNWZWhpY2xlQ29udHJvbFJlc2V0UGluVG9Ecml2ZUFjdGlvbg==');

@$core.Deprecated(
    'Use vehicleControlResetPinToDriveAdminActionDescriptor instead')
const VehicleControlResetPinToDriveAdminAction$json = {
  '1': 'VehicleControlResetPinToDriveAdminAction',
};

/// Descriptor for `VehicleControlResetPinToDriveAdminAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List vehicleControlResetPinToDriveAdminActionDescriptor =
    $convert.base64Decode(
        'CihWZWhpY2xlQ29udHJvbFJlc2V0UGluVG9Ecml2ZUFkbWluQWN0aW9u');

@$core.Deprecated('Use setLowPowerModeActionDescriptor instead')
const SetLowPowerModeAction$json = {
  '1': 'SetLowPowerModeAction',
  '2': [
    {'1': 'low_power_mode', '3': 1, '4': 1, '5': 8, '10': 'lowPowerMode'},
  ],
};

/// Descriptor for `SetLowPowerModeAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setLowPowerModeActionDescriptor = $convert.base64Decode(
    'ChVTZXRMb3dQb3dlck1vZGVBY3Rpb24SJAoObG93X3Bvd2VyX21vZGUYASABKAhSDGxvd1Bvd2'
    'VyTW9kZQ==');

@$core.Deprecated('Use setKeepAccessoryPowerModeActionDescriptor instead')
const SetKeepAccessoryPowerModeAction$json = {
  '1': 'SetKeepAccessoryPowerModeAction',
  '2': [
    {
      '1': 'keep_accessory_power_mode',
      '3': 1,
      '4': 1,
      '5': 8,
      '10': 'keepAccessoryPowerMode'
    },
  ],
};

/// Descriptor for `SetKeepAccessoryPowerModeAction`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List setKeepAccessoryPowerModeActionDescriptor =
    $convert.base64Decode(
        'Ch9TZXRLZWVwQWNjZXNzb3J5UG93ZXJNb2RlQWN0aW9uEjkKGWtlZXBfYWNjZXNzb3J5X3Bvd2'
        'VyX21vZGUYASABKAhSFmtlZXBBY2Nlc3NvcnlQb3dlck1vZGU=');
