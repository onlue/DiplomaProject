//
//  RecentMessages.swift
//  diploma
//
//  Created by Максим Купрейчук on 04.05.2023.
//

import Foundation
import Firebase

struct RecentMessage: Identifiable{
    var id: String {documentId}
    
    let documentId: String
    let text, fromid, toid: String
    let email, image: String
    let timestamp: Timestamp
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.text = data["text"] as? String ?? ""
        self.fromid = data["fromId"] as? String ?? ""
        self.toid = data["toId"] as? String ?? ""
        self.email = data["email"] as? String ?? ""
        self.image = data["profileImage"] as? String ?? ""
        self.timestamp = data["timestamp"] as? Timestamp ?? Timestamp.init(date: Date())
    }
    
    var timeAgo: String{
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp.seconds))
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
