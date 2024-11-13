//
//  NewMessageView.swift
//  diploma
//
//  Created by Максим Купрейчук on 19.04.2023.
//

import SwiftUI
import SDWebImageSwiftUI

class NewMessageViewViewModel: ObservableObject{
    
    @Published var users = [ChatUser]()
    
    init(){
        fetchAllUsers()
    }
    
    private func fetchAllUsers(){
        FireBaseManager.shared.firestore.collection("users").getDocuments{
            documentsSnapshot, error in
            if let error = error{
                print("Ошибка считывания пользователей \(error)")
                return
            }
            
            documentsSnapshot?.documents.forEach({snapshot in
                let data = snapshot.data()
                let user = ChatUser(data: data)
                if user.uid != FireBaseManager.shared.auth.currentUser?.uid{
                    self.users.append(.init(data: data))
                }
            })
        }
    }
}

struct NewMessageView: View {
    
    @State var userSearh = ""
    @State var filteredArr = [ChatUser]()
    
    let didSelectNewUser: (ChatUser) -> ()
    
    @Environment(\.presentationMode) var presentationMode
    
    @ObservedObject var vm = NewMessageViewViewModel()
    
    var body: some View {
        NavigationView{
            ScrollView{
                HStack{
                    TextField("Введите имя для поиска", text: $userSearh)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onChange(of: userSearh){
                            _ in
                            filterArr()
                        }
                    Image(systemName: "magnifyingglass")
                }.padding()
                ForEach(filteredArr, id: \.id){
                    user in
                    Button{
                        presentationMode.wrappedValue.dismiss()
                        didSelectNewUser(user)
                    }label: {
                        HStack(spacing: 16){
                            WebImage(url: URL(string: user.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .cornerRadius(50)
                                .overlay(RoundedRectangle(cornerRadius: 50).stroke())
                            Text(user.email)
                                .fontWeight(.bold)
                                .foregroundColor(Color.blue)
                            Spacer()
                        }.padding(.horizontal)
                            .padding(.vertical, 8)
                    }
                    Divider()
                }
            }.navigationTitle("Новое сообщение")
                .toolbar{
                    ToolbarItemGroup(placement: .navigationBarLeading){
                        Button{
                            presentationMode.wrappedValue.dismiss()
                        } label:{
                            Text("Назад")
                        }
                    }
                }
        }.onAppear{
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0){
                filterArr()
            }
        }
    }
    
    func filterArr(){
        if userSearh.isEmpty {
                filteredArr = vm.users
            } else {
                filteredArr = vm.users.filter { item in
                    item.email.localizedCaseInsensitiveContains(userSearh)
                }
            }
            filteredArr.sort { $0.email < $1.email }
    }
}

struct NewMessageView_Previews: PreviewProvider {
    static var previews: some View {
        NewMessageView(didSelectNewUser: {_ in })
    }
}
