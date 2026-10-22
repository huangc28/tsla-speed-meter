package authentication

// Emits the request/response vector in Tests/TeslaBLETests/ResponseDecryptTests.swift
// (UpstreamResponseVector) using vehicle-command's own Signer and Verifier.
// Not built by SwiftPM. To regenerate (nonce and epoch are random, so the hex
// changes on every run):
//
//	git clone https://github.com/teslamotors/vehicle-command   # fc5a191 was used
//	cp zz_emit_vector_test.go vehicle-command/internal/authentication/
//	cd vehicle-command && go test ./internal/authentication -run TestZZEmitResponseVector -v

import (
	"bytes"
	"encoding/hex"
	"fmt"
	"testing"
	"time"

	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/teslamotors/vehicle-command/pkg/protocol/protobuf/carserver"
	universal "github.com/teslamotors/vehicle-command/pkg/protocol/protobuf/universalmessage"
)

func TestZZEmitResponseVector(t *testing.T) {
	clientScalar, _ := hex.DecodeString("2538cdc29a97c19c1e99a637d6cf4f8c970c118b56ede1e6323e6d162c4b30db")
	vehicleScalar, _ := hex.DecodeString("9d9c5e86d5a83057965ca94b5faeff116c275d08ca91e839bd2dea59c2229b81")
	vin := []byte("5YJ30123456789ABC")

	client := UnmarshalECDHPrivateKey(clientScalar)
	vehicle := UnmarshalECDHPrivateKey(vehicleScalar)

	verifier, err := NewVerifier(vehicle, vin, universal.Domain_DOMAIN_INFOTAINMENT, client.PublicBytes())
	if err != nil {
		t.Fatal(err)
	}
	info, err := verifier.SessionInfo()
	if err != nil {
		t.Fatal(err)
	}
	encodedInfo, _ := proto.Marshal(info)
	signer, err := NewSigner(client, vin, info)
	if err != nil {
		t.Fatal(err)
	}

	action := &carserver.Action{
		ActionMsg: &carserver.Action_VehicleAction{
			VehicleAction: &carserver.VehicleAction{
				VehicleActionMsg: &carserver.VehicleAction_GetVehicleData{
					GetVehicleData: &carserver.GetVehicleData{
						GetChargeState:       &carserver.GetChargeState{},
						GetDriveState:        &carserver.GetDriveState{},
						GetTirePressureState: &carserver.GetTirePressureState{},
					},
				},
			},
		},
	}
	actionBytes, _ := proto.Marshal(action)

	request := &universal.RoutableMessage{
		ToDestination: &universal.Destination{
			SubDestination: &universal.Destination_Domain{Domain: universal.Domain_DOMAIN_INFOTAINMENT},
		},
		FromDestination: &universal.Destination{
			SubDestination: &universal.Destination_RoutingAddress{RoutingAddress: bytes.Repeat([]byte{0xa1}, 16)},
		},
		Payload: &universal.RoutableMessage_ProtobufMessageAsBytes{ProtobufMessageAsBytes: actionBytes},
		Uuid:    bytes.Repeat([]byte{0xb2}, 16),
		Flags:   1 << universal.Flags_FLAG_ENCRYPT_RESPONSE,
	}
	if err := signer.Encrypt(request, time.Minute); err != nil {
		t.Fatal(err)
	}
	encodedRequest, _ := proto.Marshal(request)
	id := RequestID(request)

	// Vehicle side: verify the request, then encrypt the reply.
	var parsed universal.RoutableMessage
	if err := proto.Unmarshal(encodedRequest, &parsed); err != nil {
		t.Fatal(err)
	}
	if pt, err := verifier.Verify(&parsed); err != nil || !bytes.Equal(pt, actionBytes) {
		t.Fatalf("verify failed: %v", err)
	}

	ts := timestamppb.New(time.Unix(1767225600, 0)) // 2026-01-01T00:00:00Z
	seenFL := timestamppb.New(time.Unix(1767225000, 0))
	vehicleData := &carserver.VehicleData{
		DriveState: &carserver.DriveState{
			ShiftState:         &carserver.ShiftState{Type: &carserver.ShiftState_D{D: &carserver.Void{}}},
			OptionalSpeed:      &carserver.DriveState_Speed{Speed: 60},
			OptionalSpeedFloat: &carserver.DriveState_SpeedFloat{SpeedFloat: 60.5},
			OptionalPower:      &carserver.DriveState_Power{Power: -12},
			Timestamp:          ts,
		},
		ChargeState: &carserver.ChargeState{
			ChargingState:             &carserver.ChargeState_ChargingState{Type: &carserver.ChargeState_ChargingState_Disconnected{Disconnected: &carserver.Void{}}},
			OptionalBatteryLevel:      &carserver.ChargeState_BatteryLevel{BatteryLevel: 72},
			OptionalBatteryRange:      &carserver.ChargeState_BatteryRange{BatteryRange: 211.5},
			OptionalEstBatteryRange:   &carserver.ChargeState_EstBatteryRange{EstBatteryRange: 180.25},
			OptionalIdealBatteryRange: &carserver.ChargeState_IdealBatteryRange{IdealBatteryRange: 230},
			OptionalChargerPower:      &carserver.ChargeState_ChargerPower{ChargerPower: 0},
			Timestamp:                 ts,
		},
		TirePressureState: &carserver.TirePressureState{
			Timestamp:                  ts,
			OptionalTpmsPressureFl:     &carserver.TirePressureState_TpmsPressureFl{TpmsPressureFl: 2.9},
			OptionalTpmsPressureFr:     &carserver.TirePressureState_TpmsPressureFr{TpmsPressureFr: 2.875},
			OptionalTpmsPressureRl:     &carserver.TirePressureState_TpmsPressureRl{TpmsPressureRl: 3.0},
			TpmsLastSeenPressureTimeFl: seenFL,
		},
	}
	responsePayload, _ := proto.Marshal(&carserver.Response{
		ResponseMsg: &carserver.Response_VehicleData{VehicleData: vehicleData},
	})

	response := &universal.RoutableMessage{
		ToDestination: &universal.Destination{
			SubDestination: &universal.Destination_RoutingAddress{RoutingAddress: bytes.Repeat([]byte{0xa1}, 16)},
		},
		FromDestination: &universal.Destination{
			SubDestination: &universal.Destination_Domain{Domain: universal.Domain_DOMAIN_INFOTAINMENT},
		},
		Payload:     &universal.RoutableMessage_ProtobufMessageAsBytes{ProtobufMessageAsBytes: responsePayload},
		RequestUuid: request.Uuid,
	}
	if err := verifier.Encrypt(response, id, 1); err != nil {
		t.Fatal(err)
	}
	encodedResponse, _ := proto.Marshal(response)

	// Sanity: upstream Signer decrypts its own vector.
	var check universal.RoutableMessage
	_ = proto.Unmarshal(encodedResponse, &check)
	if counter, err := signer.Decrypt(&check, id); err != nil || counter != 1 || !bytes.Equal(check.GetProtobufMessageAsBytes(), responsePayload) {
		t.Fatalf("self-check failed: %v", err)
	}

	// Second reply to the same request: non-zero flags and a BUSY fault,
	// both of which are authenticated in the response metadata.
	faultPayload, _ := proto.Marshal(&carserver.Response{
		ActionStatus: &carserver.ActionStatus{
			Result:       carserver.OperationStatus_E_OPERATIONSTATUS_ERROR,
			ResultReason: &carserver.ResultReason{Reason: &carserver.ResultReason_PlainText{PlainText: "busy"}},
		},
	})
	faultResponse := &universal.RoutableMessage{
		ToDestination: &universal.Destination{
			SubDestination: &universal.Destination_RoutingAddress{RoutingAddress: bytes.Repeat([]byte{0xa1}, 16)},
		},
		FromDestination: &universal.Destination{
			SubDestination: &universal.Destination_Domain{Domain: universal.Domain_DOMAIN_INFOTAINMENT},
		},
		Payload:             &universal.RoutableMessage_ProtobufMessageAsBytes{ProtobufMessageAsBytes: faultPayload},
		RequestUuid:         request.Uuid,
		Flags:               1 << universal.Flags_FLAG_ENCRYPT_RESPONSE,
		SignedMessageStatus: &universal.MessageStatus{SignedMessageFault: universal.MessageFault_E_MESSAGEFAULT_ERROR_BUSY},
	}
	if err := verifier.Encrypt(faultResponse, id, 2); err != nil {
		t.Fatal(err)
	}
	encodedFaultResponse, _ := proto.Marshal(faultResponse)
	var faultCheck universal.RoutableMessage
	_ = proto.Unmarshal(encodedFaultResponse, &faultCheck)
	if counter, err := signer.Decrypt(&faultCheck, id); err != nil || counter != 2 || !bytes.Equal(faultCheck.GetProtobufMessageAsBytes(), faultPayload) {
		t.Fatalf("fault self-check failed: %v", err)
	}

	fmt.Printf("VEHICLE_PUBLIC=%x\n", vehicle.PublicBytes())
	fmt.Printf("SESSION_INFO=%x\n", encodedInfo)
	fmt.Printf("REQUEST=%x\n", encodedRequest)
	fmt.Printf("REQUEST_ID=%x\n", id)
	fmt.Printf("RESPONSE=%x\n", encodedResponse)
	fmt.Printf("RESPONSE_PLAINTEXT=%x\n", responsePayload)
	fmt.Printf("FAULT_RESPONSE=%x\n", encodedFaultResponse)
	fmt.Printf("FAULT_RESPONSE_PLAINTEXT=%x\n", faultPayload)
}
