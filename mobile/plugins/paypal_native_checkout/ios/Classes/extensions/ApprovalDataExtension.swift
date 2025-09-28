import PayPalCheckout

extension ApprovalData {
    func toDictionary() -> [String: Any?] {
        var dataMap: [String: Any?] = [
            "orderId": ecToken,
            "payerId": payerID,
            "intent": intent.stringValue,
        ]

        if let buyer2 = buyer {
            dataMap["payer"] = buyer2.toDictionary()
        }

        if let cart2 = cart {
            dataMap["cart"] = cart2.toDictionary()
        }
        return dataMap
    }
}
