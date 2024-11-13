//
//  FamilyView.swift
//  diploma
//
//  Created by Максим Купрейчук on 19.05.2023.
//

import SwiftUI
import SDWebImageSwiftUI

struct FamilyChatView: View {
    
    var familyName: String
    @ObservedObject var groupChatModel: GroupChat
    
    init(familyName: String) {
        self.familyName = familyName
        self.groupChatModel = GroupChat(family: familyName)
    }
    
    var body: some View {
        VStack{
            if #available(iOS 15.0, *) {
                ScrollView{
                    ScrollViewReader{scrollViewProxy in
                        VStack{
                            ForEach(groupChatModel.messagesArray){ message in
                                GroupMessageView(message: message)
                            }
                            HStack{ Spacer() }
                                .id("Empty")
                        }.onReceive(groupChatModel.$count) {_ in
                            withAnimation(.easeOut(duration: 0.5)){
                                scrollViewProxy.scrollTo("Empty", anchor: .bottom)
                            }
                        }
                    }
                }.background(Color(.init(white: 0.96, alpha: 1)))
                    .padding(.top, 20)
                HStack{
                    TextField("Введите сообщение", text: $groupChatModel.chatMessage)
                    Button{
                        groupChatModel.handleSend()
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
        }
    }
}

struct GroupMessageView: View{
    
    let message: GroupChatMessage
    
    var body: some View{
        VStack{
            if message.senderId == FireBaseManager.shared.auth.currentUser?.uid{
                HStack{
                    Spacer()
                    Text(message.sender.replacingOccurrences(of: "@gmail.com", with: ""))
                        .padding(.vertical, -3)
                        .padding(.horizontal, 2)
                }
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
                    .padding(6)
                    .background(Color.blue)
                    .cornerRadius(8)
                    WebImage(url: URL(string: message.image))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(50)
                        .padding(.horizontal, 2)
                }.padding(.horizontal, 4)
            }
            else{
                HStack{
                    Text(message.sender.replacingOccurrences(of: "@gmail.com", with: ""))
                        .padding(.vertical, -3)
                        .padding(.horizontal, 2)
                    Spacer()
                }
                HStack{
                    WebImage(url: URL(string: message.image))
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipped()
                        .cornerRadius(50)
                        .padding(.horizontal, 2)
                    HStack{
                        Button{
                            UIPasteboard.general.string = message.text
                        }label: {
                            Text(message.text)
                                .foregroundColor(.white)
                        }
                    }
                    .padding(6)
                    .background(Color(.init(white: 0.81, alpha: 1)))
                    .cornerRadius(8)
                    Spacer()
                }.padding(.horizontal, 4)
            }
        }
    }
}

struct FamilyView_Previews: PreviewProvider {
    static var previews: some View {
        FamilyChatView(familyName: "")
    }
}
