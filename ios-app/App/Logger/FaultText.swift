import TeslaBLE

/// Plain Chinese for the protocol faults the car reports, for the page and
/// `events.jsonl`. Uncommon codes show their number.
enum FaultText {
    static func name(_ fault: UniversalMessage_MessageFault_E) -> String {
        switch fault {
        case .rrorBusy: "車子忙碌中"
        case .rrorTimeout: "車子處理逾時"
        case .rrorUnknownKeyID: "不認得這把鑰匙"
        case .rrorInactiveKey: "鑰匙已停用"
        case .rrorInvalidSignature: "簽章不對"
        case .rrorInvalidTokenOrCounter: "計數不對"
        case .rrorInsufficientPrivileges: "鑰匙權限不夠"
        case .rrorInvalidCommand: "車子不懂這個指令"
        case .rrorInternal: "車子內部錯誤"
        case .rrorIncorrectEpoch: "加密連線過期"
        case .rrorTimeExpired: "請求過期"
        case .rrorTimeToLiveTooLong: "請求有效時間太長"
        case .rrorRemoteAccessDisabled: "車子關閉了遠端存取"
        case .rrorRequestMtuExceeded: "請求太大"
        case .rrorResponseMtuExceeded: "回應太大"
        default: "錯誤碼 \(fault.rawValue)"
        }
    }

    /// A fault whose reply authenticated: 「車子回報:回應太大」.
    static func verified(_ fault: UniversalMessage_MessageFault_E) -> String {
        "車子回報:\(name(fault))"
    }

    /// A fault claimed by a reply whose tag failed: 「車子回報:回應太大(未驗證)」.
    static func unverified(_ fault: UniversalMessage_MessageFault_E) -> String {
        "車子回報:\(name(fault))(未驗證)"
    }
}
