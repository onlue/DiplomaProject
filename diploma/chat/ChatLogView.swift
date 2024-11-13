//
//  ChatLogView.swift
//  diploma
//
//  Created by Максим Купрейчук on 19.04.2023.
//

import SwiftUI
import Firebase

struct ChatMessage: Identifiable{
    var id = UUID()
    let fromId, toId, text: String
    
    init(data: [String: Any]){
        self.fromId = data[FireBaseConstants.fromId] as? String ?? ""
        self.toId = data[FireBaseConstants.toId] as? String ?? ""
        self.text = data[FireBaseConstants.text] as? String ?? ""
    }
}

class ChatLogViewModel: ObservableObject{
    
    @Published var count = 0
    @Published var chatMessage = ""
    @Published var chatMessages = [ChatMessage]()
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?){
        self.chatUser = chatUser
        
        fetchMessages()
    }
    
    func fetchMessages(){
        guard let fromId = FireBaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = chatUser?.uid else {return}
        
        FireBaseManager.shared.firestore.collection("messages").document(fromId)
            .collection(toId)
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
                        self.chatMessages.append(.init(data: data))
                        self.count += 1
                    }
                })
            }
    }
    
    func handleSend(){
        guard let fromId = FireBaseManager.shared.auth.currentUser?.uid else {return}
        guard let toId = chatUser?.uid else {return}
        let document = FireBaseManager.shared.firestore.collection("messages")
            .document(fromId)
            .collection(toId)
            .document()
        
        let messageData = ["fromId": fromId, "toId": toId, "text": self.chatMessage, "timestamp": Timestamp()] as [String: Any]
        
        document.setData(messageData){error in
            if let error = error{
                print("Невозможно сохранить сообщение \(error)")
                return
            }
        }
        
        let recipientMessageDocument = FireBaseManager.shared.firestore.collection("messages")
            .document(toId)
            .collection(fromId)
            .document()
        
        recipientMessageDocument.setData(messageData){error in
            if let error = error{
                print("Невозможно сохранить сообщение \(error)")
                return
            }
        }
        
        persistRecentMessage()
        
        self.chatMessage = ""
        self.count += 1
    }
    
    func persistRecentMessage(){
        guard let chatUser = chatUser else { return }
        
        guard let uid = FireBaseManager.shared.auth.currentUser?.uid else { return }
        guard let toId = self.chatUser?.uid else { return }
        
        let document = FireBaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(toId)
        
        
        let data = [
            "timestamp": Timestamp(),
            "text": self.chatMessage,
            "fromId":  uid,
            "toId": toId,
            "profileImage": chatUser.profileImageUrl,
            "email": chatUser.email
            
        ] as [String : Any]
        
        document.setData(data) { error in
            if let error = error {
                print("Failed to save recent message: \(error)")
                return
            }
        }
        
        guard let currentUser = FireBaseManager.shared.currentUser else { return }
        
        let recipientRecentMessageDictionary = [
            "timestamp": Timestamp(),
            "text": self.chatMessage,
            "fromId": uid,
            "toId": toId,
            "profileImage": currentUser.profileImageUrl,
            "email": currentUser.email
        ] as [String : Any]
        
        FireBaseManager.shared.firestore
            .collection("recent_messages")
            .document(toId)
            .collection("messages")
            .document(currentUser.uid)
            .setData(recipientRecentMessageDictionary) { error in
                if let error = error {
                    print("Failed to save recipient recent message: \(error)")
                    return
                }
            }
    }
}
    struct ChatLogView: View{
    
        let chatUser: ChatUser?
        
        init(chatUser : ChatUser?){
            self.chatUser = chatUser
            self.vm = .init(chatUser: chatUser)
        }
        
        @ObservedObject var vm: ChatLogViewModel
        
        var body: some View{
            VStack{
                if #available(iOS 15.0, *) {
                    ScrollView{
                        ScrollViewReader{scrollViewProxy in
                            VStack{
                                ForEach(vm.chatMessages){ message in
                                    MessageView(message: message)
                                }
                                
                                HStack{ Spacer() }
                                    .id("Empty")
                            }.onReceive(vm.$count) {_ in
                                withAnimation(.easeOut(duration: 0.5)){
                                    scrollViewProxy.scrollTo("Empty", anchor: .bottom)
                                }
                            }
                        }
                    }.background(Color(.init(white: 0.96, alpha: 1)))
                        .padding(.top, 20)
                    HStack{
                        TextField("Введите сообщение", text: $vm.chatMessage)
                        Button{
                            vm.handleSend()
                        }label:{
                            Text("Отправить")
                                .foregroundColor(Color.white)
                        }
                        .padding(8)
                        .background(Color.blue)
                        .cornerRadius(8)
                        
                    }
                    .padding(8)
                }
            }.navigationTitle(chatUser?.email ?? "")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    struct MessageView: View{
        
        let message: ChatMessage
        
        var body: some View{
            VStack{
                if message.fromId == FireBaseManager.shared.auth.currentUser?.uid{
                    HStack{
                        Spacer()
                        HStack{
                            Button{
                                UIPasteboard.general.string = message.text
                            }label: {
                                Text(message.text)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(8)
                    }.padding(.horizontal, 4)
                }
                else{
                    HStack{
                        HStack{
                            Button{
                                UIPasteboard.general.string = message.text
                            }label: {
                                Text(message.text)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding()
                        .background(Color(.init(white: 0.87, alpha: 1)))
                        .cornerRadius(8)
                        Spacer()
                    }.padding(.horizontal, 4)
                }
            }
        }
    }
    
    struct ChatLogView_Previews: PreviewProvider {
        static var previews: some View {
            NavigationView{
                ChatLogView(chatUser: nil)
            }
        }
    }
