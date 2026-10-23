package authentication

// Emits the request/response vector in Tests/TeslaBLETests/ResponseDecryptTests.swift
// (UpstreamResponseVector) using vehicle-command's own Signer and Verifier.
// Not built by SwiftPM. To regenerate (nonce and epoch are random, so the hex
// changes on every run):
//
//	git clone https://github.com/teslamotors/vehicle-command   # fc5a191 was used
//	cp zz_emit_vector_test.go vehicle-command/internal/authentication/
//	cd vehicle-command && go test ./internal/authentication -run TestZZEmitResponseVector -v
//
// TestZZEmitEmptyFaultVector adds one more reply to the committed request
// (run it with -run TestZZEmitEmptyFaultVector); it does not change the
// committed hex above.

import (
	"bytes"
	"encoding/hex"
	"fmt"
	"testing"
	"time"

	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/teslamotors/vehicle-command/pkg/protocol/protobuf/carserver"
	"github.com/teslamotors/vehicle-command/pkg/protocol/protobuf/signatures"
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

// The committed UpstreamResponseVector values this reply is sealed against.
const (
	committedSessionInfo = "1241041431dc57c892b8dcc87ba59159031e12046b6febcdfb88f7b9c9e2a0fc2b7a1e323a4bd5a5696f103845bd1c4b9dd104d0fe87a3721314a03a7550406445705b1a10fd913356a5f5ffaa5b43942191b56afc"
	committedRequest     = "320208033a121210a1a1a1a1a1a1a1a1a1a1a1a1a1a1a1a19a0310b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2b2a00302520a5e8d1ac6783033869b846a80010a430a4104b2b6bc68c2da0665ce656815594996c62394edd8bea905fe781a754fe6a845a714330902f225e9269d466e05b349981fda9d85cc23c6fb444aa73b629105dc6e2a390a10fd913356a5f5ffaa5b43942191b56afc120cfb76afe5272f582bd90d3b4f1801253c0000002a1007406afa108eaeaebd57a37419f6b2d9"
)

// A third reply to the committed request, shaped like the replies a real car
// sent on 2026-10-23: operation status ERROR, fault RESPONSE_MTU_EXCEEDED, no
// flags, its own uuid, AES-GCM response data, and no payload field at all.
// Response metadata has no epoch, so a fresh Verifier with the same keys seals
// a reply the committed session opens.
func TestZZEmitEmptyFaultVector(t *testing.T) {
	clientScalar, _ := hex.DecodeString("2538cdc29a97c19c1e99a637d6cf4f8c970c118b56ede1e6323e6d162c4b30db")
	vehicleScalar, _ := hex.DecodeString("9d9c5e86d5a83057965ca94b5faeff116c275d08ca91e839bd2dea59c2229b81")
	vin := []byte("5YJ30123456789ABC")
	client := UnmarshalECDHPrivateKey(clientScalar)
	vehicle := UnmarshalECDHPrivateKey(vehicleScalar)

	encodedInfo, _ := hex.DecodeString(committedSessionInfo)
	var info signatures.SessionInfo
	if err := proto.Unmarshal(encodedInfo, &info); err != nil {
		t.Fatal(err)
	}
	encodedRequest, _ := hex.DecodeString(committedRequest)
	var request universal.RoutableMessage
	if err := proto.Unmarshal(encodedRequest, &request); err != nil {
		t.Fatal(err)
	}
	id := RequestID(&request)

	verifier, err := NewVerifier(vehicle, vin, universal.Domain_DOMAIN_INFOTAINMENT, client.PublicBytes())
	if err != nil {
		t.Fatal(err)
	}
	response := &universal.RoutableMessage{
		ToDestination: &universal.Destination{
			SubDestination: &universal.Destination_RoutingAddress{RoutingAddress: request.GetFromDestination().GetRoutingAddress()},
		},
		FromDestination: &universal.Destination{
			SubDestination: &universal.Destination_Domain{Domain: universal.Domain_DOMAIN_INFOTAINMENT},
		},
		RequestUuid: request.Uuid,
		Uuid:        bytes.Repeat([]byte{0xc3}, 16),
		SignedMessageStatus: &universal.MessageStatus{
			OperationStatus:    universal.OperationStatus_E_OPERATIONSTATUS_ERROR,
			SignedMessageFault: universal.MessageFault_E_MESSAGEFAULT_ERROR_RESPONSE_MTU_EXCEEDED,
		},
	}
	if err := verifier.Encrypt(response, id, 3); err != nil {
		t.Fatal(err)
	}
	if len(response.GetProtobufMessageAsBytes()) != 0 {
		t.Fatal("expected an empty ciphertext")
	}
	// protobuf-go writes a zero-length oneof field; the car omits it.
	response.Payload = nil
	encodedResponse, _ := proto.Marshal(response)

	// Sanity: upstream Signer, built from the committed session info, opens it.
	signer, err := NewSigner(client, vin, &info)
	if err != nil {
		t.Fatal(err)
	}
	var check universal.RoutableMessage
	_ = proto.Unmarshal(encodedResponse, &check)
	if check.Payload != nil {
		t.Fatal("payload field present")
	}
	if counter, err := signer.Decrypt(&check, id); err != nil || counter != 3 || len(check.GetProtobufMessageAsBytes()) != 0 {
		t.Fatalf("self-check failed: %v", err)
	}

	fmt.Printf("REQUEST_ID=%x\n", id)
	fmt.Printf("EMPTY_FAULT_RESPONSE=%x\n", encodedResponse)
}
