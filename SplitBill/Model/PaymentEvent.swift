import Foundation
import Firebase

struct PaymentEvent: Equatable
{
    let FIRDocID: String
    let eventName: String
    let dateCreated: Double
    let participants: [String]
    let price: Double
    let eventDate: String
    let isOwner: Bool
}

