//
//  ContentView.swift
//  diploma
//
//  Created by Максим Купрейчук on 15.04.2023.
//

import SwiftUI


struct ContentView: View {
    
    let didCompleteLoginProcess: () -> ()
    
    @State var changeView = false

    @State private var isLogin = false
    @State private var shouldShowImagePicker = false
    @State private var userEmail = ""
    @State private var userPassword = ""
    @State private var registrationStatus = ""
    @State private var image: UIImage?
    @State private var isImageLoaded = false
    
    var body: some View {
        NavigationView{
            VStack{
                Picker(selection: $isLogin, label: Text("Picker")) {
                    Text("Регистрация").tag(false)
                    Text("Вход").tag(true)
                }.pickerStyle(SegmentedPickerStyle())
                
                if !isLogin{
                    Button{
                        shouldShowImagePicker.toggle()
                    } label: {
                        
                        VStack{
                            if let image = self.image{
                                Image(uiImage: image)
                                    .resizable()
                                    .frame(width: 128, height: 128)
                                    .scaledToFit()
                                    .cornerRadius(64)
                                    .padding(.top, 20)
                            }
                            else{
                                Image(systemName: "person.fill")
                                    .font(.system(size: 64))
                                    .padding(.top, 20)
                            }
                        }
                    }
                }
                
                TextField("Email", text: $userEmail).textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .padding(.top, 20)
                SecureField("Password", text: $userPassword).textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding([.bottom, .top], 20)
                
                Button{
                    userMode()
                } label:{
                    HStack{
                        Spacer()
                        Text(isLogin ? "Войти" : "Зарегистрироваться")
                            .padding(13)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                        Spacer()
                    }.background(Color.blue)
                }
                Spacer()
            }.padding(10)
                .navigationTitle(!isLogin ? "Регистрация" : "Вход")
                .fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil){
                    ImagePicker(image: $image)
                }
            
        }.fullScreenCover(isPresented: $changeView, onDismiss: nil){
            MainView()
        }
        .onAppear{
            isUserLogIn()
        }
        Text(self.registrationStatus)
    }
    
    private func putImageToStorage(){
        guard let uid = FireBaseManager.shared.auth.currentUser?.uid
        else{ return }
        
        let ref = FireBaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else{return}
        ref.putData(imageData, metadata: nil){
            metadata, err in
            if let err = err{
                self.registrationStatus = "Ошибка загрузки изображения!\(err)"
                return
            }
            
            ref.downloadURL{url, err in
                if let err = err{
                    self.registrationStatus = "Ошибка получения изображения!"
                    print("\(err)")
                    return
                }
                guard let url = url else {return}
                self.storeUserInformation(profileURL: url)
            }
        }
    }
    
    private func userMode(){
        if isLogin{
            loginUser()
        }
        else{
            createNewAccount()
        }
    }
    
    private func loginUser(){
        FireBaseManager.shared.auth.signIn(withEmail: userEmail, password: userPassword){
            result, err in
            if let err = err{
                print("Ошибка регистрации",err)
                registrationStatus = "Ошибка входа"
                return
            }
            
            registrationStatus = "Вход выполнен!"
            
            self.didCompleteLoginProcess()
            changeView.toggle()
            UserDefaults.standard.set(true, forKey: "loginStatus")
            UserDefaults.standard.synchronize()
        }
    }
    
    private func createNewAccount(){
        if self.image == nil{
            registrationStatus = "Загрузите изображение!"
            return
        }
        FireBaseManager.shared.auth.createUser(withEmail: userEmail, password: userPassword){ result, err in
            if let err = err{
                print("Ошибка создания аккаунта", err)
                registrationStatus = "Ошибка регистрации"
                return
            }
            
            registrationStatus = "Регистрация выполнена!"
            
            putImageToStorage()
        }
    }
    
    private func storeUserInformation(profileURL: URL){
        guard let uid = FireBaseManager.shared.auth.currentUser?.uid else{
            return
        }
        let userData = ["email": self.userEmail, "uid": uid, "profileImageUrl": profileURL.absoluteString, FireBaseConstants.familyid: "", FireBaseConstants.userFullName: "", FireBaseConstants.bday: "", "canAccessChat": false] as [String : Any]
        
        FireBaseManager.shared.firestore.collection("users")
            .document(uid).setData(userData){
                err in
                if let err = err{
                    print(err)
                    return
                }
            }
    }
    
    func isUserLogIn(){
        let status = UserDefaults.standard.bool(forKey: "loginStatus")
        print(status)
        if status{
            changeView.toggle()
        }
    }
    
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(didCompleteLoginProcess: {
        })
    }
}
