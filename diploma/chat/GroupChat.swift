//
//  GroupChat.swift
//  diploma
//
//  Created by Максим Купрейчук on 19.05.2023.
//

import Foundation
import Firebase

struct GroupChatMessage: Identifiable{
    var id = UUID()
    
    var sender: String
    var senderId: String
    var text: String
    var image: String
    
    init(text: String, image: String, sender: String, senderId: String) {
        self.text = text
        self.image = image
        self.sender = sender
        self.senderId = senderId
    }
}

class GroupChat: ObservableObject{
    @Published var messagesArray = [GroupChatMessage]()
    @Published var count = 0
    @Published var chatMessage = ""
    var family: String
    
    init(family: String){
        self.family = family
        fetchMessages()
    }
    
    func handleSend(){
        let document = FireBaseManager.shared.firestore.collection("group_messages")
            .document(family)
            .collection("messages")
            .document()
        
        guard let currentUserImage = FireBaseManager.shared.currentUser?.profileImageUrl else {return}
        guard let currentUserName = FireBaseManager.shared.currentUser?.email else {return}
        guard let senderId = FireBaseManager.shared.currentUser?.uid else {return}
        
        let data = ["sender": currentUserName, "senderId": senderId, "image": currentUserImage, "text": self.chatMessage, "timestamp": Timestamp()] as [String: Any]
        
        document.setData(data)
        count += 1
        chatMessage = ""
    }
    
    func fetchMessages(){
        FireBaseManager.shared.firestore.collection("group_messages")
            .document(family)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener{
                querySnapshot, error in
                if let error = error {
                    print("Невозможно считать сообщения \(error)")
                    return
                }
                
                querySnapshot?.documentChanges.forEach({change in
                    if change.type == .added{
                        let data = change.document.data()
                        let text = data["text"] as? String ?? ""
                        let image = data["image"] as? String ?? ""
                        let sender = data["sender"] as? String ?? ""
                        let senderId = data["senderId"] as? String ?? ""
                        self.messagesArray.append(.init(text: text, image: image, sender: sender, senderId: senderId))
                        self.count += 1
                    }
                })
            }
    }
}
