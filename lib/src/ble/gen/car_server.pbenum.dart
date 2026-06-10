// This is a generated file - do not edit.
//
// Generated from car_server.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_relative_imports

import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

class OperationStatus_E extends $pb.ProtobufEnum {
  static const OperationStatus_E OPERATIONSTATUS_OK =
      OperationStatus_E._(0, _omitEnumNames ? '' : 'OPERATIONSTATUS_OK');
  static const OperationStatus_E OPERATIONSTATUS_ERROR =
      OperationStatus_E._(1, _omitEnumNames ? '' : 'OPERATIONSTATUS_ERROR');

  static const $core.List<OperationStatus_E> values = <OperationStatus_E>[
    OPERATIONSTATUS_OK,
    OPERATIONSTATUS_ERROR,
  ];

  static final $core.List<OperationStatus_E?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 1);
  static OperationStatus_E? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const OperationStatus_E._(super.value, super.name);
}

class HvacSeatCoolerActions_HvacSeatCoolerLevel_E extends $pb.ProtobufEnum {
  static const HvacSeatCoolerActions_HvacSeatCoolerLevel_E
      HvacSeatCoolerLevel_Unknown =
      HvacSeatCoolerActions_HvacSeatCoolerLevel_E._(
          0, _omitEnumNames ? '' : 'HvacSeatCoolerLevel_Unknown');
  static const HvacSeatCoolerActions_HvacSeatCoolerLevel_E
      HvacSeatCoolerLevel_Off = HvacSeatCoolerActions_HvacSeatCoolerLevel_E._(
          1, _omitEnumNames ? '' : 'HvacSeatCoolerLevel_Off');
  static const HvacSeatCoolerActions_HvacSeatCoolerLevel_E
      HvacSeatCoolerLevel_Low = HvacSeatCoolerActions_HvacSeatCoolerLevel_E._(
          2, _omitEnumNames ? '' : 'HvacSeatCoolerLevel_Low');
  static const HvacSeatCoolerActions_HvacSeatCoolerLevel_E
      HvacSeatCoolerLevel_Med = HvacSeatCoolerActions_HvacSeatCoolerLevel_E._(
          3, _omitEnumNames ? '' : 'HvacSeatCoolerLevel_Med');
  static const HvacSeatCoolerActions_HvacSeatCoolerLevel_E
      HvacSeatCoolerLevel_High = HvacSeatCoolerActions_HvacSeatCoolerLevel_E._(
          4, _omitEnumNames ? '' : 'HvacSeatCoolerLevel_High');

  static const $core.List<HvacSeatCoolerActions_HvacSeatCoolerLevel_E> values =
      <HvacSeatCoolerActions_HvacSeatCoolerLevel_E>[
    HvacSeatCoolerLevel_Unknown,
    HvacSeatCoolerLevel_Off,
    HvacSeatCoolerLevel_Low,
    HvacSeatCoolerLevel_Med,
    HvacSeatCoolerLevel_High,
  ];

  static final $core.List<HvacSeatCoolerActions_HvacSeatCoolerLevel_E?>
      _byValue = $pb.ProtobufEnum.$_initByValueList(values, 4);
  static HvacSeatCoolerActions_HvacSeatCoolerLevel_E? valueOf(
          $core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const HvacSeatCoolerActions_HvacSeatCoolerLevel_E._(super.value, super.name);
}

class HvacSeatCoolerActions_HvacSeatCoolerPosition_E extends $pb.ProtobufEnum {
  static const HvacSeatCoolerActions_HvacSeatCoolerPosition_E
      HvacSeatCoolerPosition_Unknown =
      HvacSeatCoolerActions_HvacSeatCoolerPosition_E._(
          0, _omitEnumNames ? '' : 'HvacSeatCoolerPosition_Unknown');
  static const HvacSeatCoolerActions_HvacSeatCoolerPosition_E
      HvacSeatCoolerPosition_FrontLeft =
      HvacSeatCoolerActions_HvacSeatCoolerPosition_E._(
          1, _omitEnumNames ? '' : 'HvacSeatCoolerPosition_FrontLeft');
  static const HvacSeatCoolerActions_HvacSeatCoolerPosition_E
      HvacSeatCoolerPosition_FrontRight =
      HvacSeatCoolerActions_HvacSeatCoolerPosition_E._(
          2, _omitEnumNames ? '' : 'HvacSeatCoolerPosition_FrontRight');

  static const $core.List<HvacSeatCoolerActions_HvacSeatCoolerPosition_E>
      values = <HvacSeatCoolerActions_HvacSeatCoolerPosition_E>[
    HvacSeatCoolerPosition_Unknown,
    HvacSeatCoolerPosition_FrontLeft,
    HvacSeatCoolerPosition_FrontRight,
  ];

  static final $core.List<HvacSeatCoolerActions_HvacSeatCoolerPosition_E?>
      _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static HvacSeatCoolerActions_HvacSeatCoolerPosition_E? valueOf(
          $core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const HvacSeatCoolerActions_HvacSeatCoolerPosition_E._(
      super.value, super.name);
}

class HvacSetPreconditioningMaxAction_ManualOverrideMode_E
    extends $pb.ProtobufEnum {
  static const HvacSetPreconditioningMaxAction_ManualOverrideMode_E DogMode =
      HvacSetPreconditioningMaxAction_ManualOverrideMode_E._(
          0, _omitEnumNames ? '' : 'DogMode');
  static const HvacSetPreconditioningMaxAction_ManualOverrideMode_E Soc =
      HvacSetPreconditioningMaxAction_ManualOverrideMode_E._(
          1, _omitEnumNames ? '' : 'Soc');
  static const HvacSetPreconditioningMaxAction_ManualOverrideMode_E Doors =
      HvacSetPreconditioningMaxAction_ManualOverrideMode_E._(
          2, _omitEnumNames ? '' : 'Doors');

  static const $core.List<HvacSetPreconditioningMaxAction_ManualOverrideMode_E>
      values = <HvacSetPreconditioningMaxAction_ManualOverrideMode_E>[
    DogMode,
    Soc,
    Doors,
  ];

  static final $core.List<HvacSetPreconditioningMaxAction_ManualOverrideMode_E?>
      _byValue = $pb.ProtobufEnum.$_initByValueList(values, 2);
  static HvacSetPreconditioningMaxAction_ManualOverrideMode_E? valueOf(
          $core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const HvacSetPreconditioningMaxAction_ManualOverrideMode_E._(
      super.value, super.name);
}

class AutoSeatClimateAction_AutoSeatPosition_E extends $pb.ProtobufEnum {
  static const AutoSeatClimateAction_AutoSeatPosition_E
      AutoSeatPosition_Unknown = AutoSeatClimateAction_AutoSeatPosition_E._(
          0, _omitEnumNames ? '' : 'AutoSeatPosition_Unknown');
  static const AutoSeatClimateAction_AutoSeatPosition_E
      AutoSeatPosition_FrontLeft = AutoSeatClimateAction_AutoSeatPosition_E._(
          1, _omitEnumNames ? '' : 'AutoSeatPosition_FrontLeft');
  static const AutoSeatClimateAction_AutoSeatPosition_E
      AutoSeatPosition_FrontRight = AutoSeatClimateAction_AutoSeatPosition_E._(
          2, _omitEnumNames ? '' : 'AutoSeatPosition_FrontRight');

  static const $core.List<AutoSeatClimateAction_AutoSeatPosition_E> values =
      <AutoSeatClimateAction_AutoSeatPosition_E>[
    AutoSeatPosition_Unknown,
    AutoSeatPosition_FrontLeft,
    AutoSeatPosition_FrontRight,
  ];

  static final $core.List<AutoSeatClimateAction_AutoSeatPosition_E?> _byValue =
      $pb.ProtobufEnum.$_initByValueList(values, 2);
  static AutoSeatClimateAction_AutoSeatPosition_E? valueOf($core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const AutoSeatClimateAction_AutoSeatPosition_E._(super.value, super.name);
}

class HvacClimateKeeperAction_ClimateKeeperAction_E extends $pb.ProtobufEnum {
  static const HvacClimateKeeperAction_ClimateKeeperAction_E
      ClimateKeeperAction_Off = HvacClimateKeeperAction_ClimateKeeperAction_E._(
          0, _omitEnumNames ? '' : 'ClimateKeeperAction_Off');
  static const HvacClimateKeeperAction_ClimateKeeperAction_E
      ClimateKeeperAction_On = HvacClimateKeeperAction_ClimateKeeperAction_E._(
          1, _omitEnumNames ? '' : 'ClimateKeeperAction_On');
  static const HvacClimateKeeperAction_ClimateKeeperAction_E
      ClimateKeeperAction_Dog = HvacClimateKeeperAction_ClimateKeeperAction_E._(
          2, _omitEnumNames ? '' : 'ClimateKeeperAction_Dog');
  static const HvacClimateKeeperAction_ClimateKeeperAction_E
      ClimateKeeperAction_Camp =
      HvacClimateKeeperAction_ClimateKeeperAction_E._(
          3, _omitEnumNames ? '' : 'ClimateKeeperAction_Camp');

  static const $core.List<HvacClimateKeeperAction_ClimateKeeperAction_E>
      values = <HvacClimateKeeperAction_ClimateKeeperAction_E>[
    ClimateKeeperAction_Off,
    ClimateKeeperAction_On,
    ClimateKeeperAction_Dog,
    ClimateKeeperAction_Camp,
  ];

  static final $core.List<HvacClimateKeeperAction_ClimateKeeperAction_E?>
      _byValue = $pb.ProtobufEnum.$_initByValueList(values, 3);
  static HvacClimateKeeperAction_ClimateKeeperAction_E? valueOf(
          $core.int value) =>
      value < 0 || value >= _byValue.length ? null : _byValue[value];

  const HvacClimateKeeperAction_ClimateKeeperAction_E._(
      super.value, super.name);
}

const $core.bool _omitEnumNames =
    $core.bool.fromEnvironment('protobuf.omit_enum_names');
