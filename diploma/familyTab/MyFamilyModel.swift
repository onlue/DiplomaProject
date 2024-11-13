//
//  MyFamilyModel.swift
//  diploma
//
//  Created by Максим Купрейчук on 28.04.2023.
//

import Foundation

struct FamilyUser: Identifiable{
    var id: String
    
    let image, name, login: String
    
    init(image: String, name: String, login: String, id: String) {
        self.image = image
        self.name = name
        self.login = login
        self.id = id
    }
}

class MyFamilyModel: ObservableObject{
    @Published var familyUsersArray = [FamilyUser]()
    
    init(){
//        getUsers()
    }
    
    func getUsers(){
        guard let userId = FireBaseManager.shared.auth.currentUser?.uid
        else{ return }
        
        var familyName = "-1"
        
        FireBaseManager.shared.firestore.collection(FireBaseConstants.familyCollection)
            .document(userId)
            .getDocument{
                snapshot, error  in

                if let error = error{
                    print("Ошибка \(error)")
                    return
                }

                guard let data = snapshot?.data() else{
                    print("Данные об семье не найдены")
                    return
                }
                
                familyName = data["familyid"] as? String ?? "no"
                
                FireBaseManager.shared.firestore.collection(FireBaseConstants.familyCollection).whereField(FireBaseConstants.familyid, isEqualTo: familyName)
                    .addSnapshotListener{
                        snapshot, error in
                        if let error = error{
                            print("error \(error)")
                            return
                        }
                        
                        snapshot?.documentChanges.forEach{ document in
                            if document.type == .added{
                                var userPic = ""
                                var userMail = ""
                                var userName = ""
                                var userId = ""
                                
                                let temp = document.document.data()[FireBaseConstants.familyUser]
                                
                                FireBaseManager.shared.firestore.collection("users")
                                    .document(temp as? String ?? "-1").getDocument{
                                        local, error in
                                        if let error = error{
                                            print("error \(error)")
                                            return
                                        }
                                        
                                        let data = local?.data()
                                        userPic = data?["profileImageUrl"] as? String ?? ""
                                        userMail = data?["email"] as? String ?? ""
                                        userName = data?["fullName"] as? String ?? ""
                                        userName = userName.isEmpty ? "Имя не указано" : userName
                                        userId = data?["uid"] as? String ?? ""
                                        self.familyUsersArray.append(.init(image: userPic, name: userName, login: userMail, id: userId))
                                    }
                            }
                        }
                    }
            }
    }
}
