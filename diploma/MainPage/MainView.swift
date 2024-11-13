//
//  MainView.swift
//  diploma
//
//  Created by Максим Купрейчук on 16.04.2023.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import MapKit

struct MainView: View {
    @State var shouldNavigateToChatLog = false
    @State var chatUser: ChatUser?
    @State var shouldShowLogOutOptions = false
    @State var isHaveFamily = false
    @State var familyName = "1"
    @State var shouldShowNewMessageScreen = false
    @State var shouldShowJoinFamilyScreen = false
    @State var familyCode = ""
    @State var isProfileEditMode = false
    @State var createNewTask = false
    
    var curruser = FireBaseManager.shared.auth.currentUser?.uid ?? "-1"
    
    @ObservedObject var geoPointsModel = GeoPointModel()
    @ObservedObject var familyModel = MyFamilyModel()
    @ObservedObject var vm = MainMessagesViewModel()
    @ObservedObject var taskModel = TaskManager()
    
    @State var taskName = ""
    @State var taskDate: Date = Date()
    @State var taskColor: Color = .black
    @State var taskComplete = false
    
    @State var userName = "UserName"
    @State var userMail = "UserMail"
    @State var userChangePassword = ""
    @State var userPassword = ""
    @State var editName = false
    @State var editMail = false
    @State var editMailChange = false
    @State var editPassword = false
    @State var isShouldShowAlert = false
    @State var editLocationStatus = false
    
    @State var tempString = ""
    @State var userChangeError = ""
    
    @State var showDeleteUserAlert = false
    @State var passwordField = false
    
    @State var shouldShowImagePicker = false
    @State var image: UIImage?
    @State var isProfileImageChanged = false
    
    @State var shouldNavigateToFamilyChat = false
    
    @State var shouldUpdateNavigation = false
    @State var canSeeRecentMessages = false
    @State var updateRecentStatus = false
    
    
    @State var shouldupdatetext = ""
    @State private var selectedColorIndex = 0
    let defaultColor = [Color.blue, Color.red, Color.gray, Color.yellow, Color.green, Color.cyan, Color.orange, Color.pink, Color.brown, Color.indigo] as [Color]
    
    private var customNavBar: some View{
        HStack(spacing: 16) {
            WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                .resizable()
                .scaledToFill()
                .frame(width: 50, height: 50)
                .clipped()
                .cornerRadius(50)
                .overlay(RoundedRectangle(cornerRadius: 44)
                    .stroke(Color(.label), lineWidth: 1)
                )
                .shadow(radius: 5)
                .onTapGesture {
                    isProfileEditMode.toggle()
                    checkUserData()
                }
            
            VStack(alignment: .leading, spacing: 4) {
                let email = vm.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                Text(email)
                    .font(.system(size: 24, weight: .bold))
                
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("В сети")
                        .font(.system(size: 12))
                        .foregroundColor(Color(.lightGray))
                }
                
            }
            
            Spacer()
            Button {
                shouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.red))
            }
        }
        .padding()
        .actionSheet(isPresented: $shouldShowLogOutOptions) {
            .init(title: Text("Настройки"), message: Text("Хотите выйти?"), buttons: [
                .destructive(Text("Выйти"), action: {
                    print("handle sign out")
                    vm.handleSignOut()
                    UserDefaults.standard.set(false, forKey: "loginStatus")
                    UserDefaults.standard.synchronize()
                }),
                .cancel()
            ])
        }.fullScreenCover(isPresented: $vm.isUserCurrentlyLoggedOut, onDismiss: nil){
            ContentView(didCompleteLoginProcess: {
                self.vm.isUserCurrentlyLoggedOut = false
                self.vm.fetchCurrentUser()
                self.vm.fetchRecentMessages()
            })
        }
        .fullScreenCover(isPresented: $isProfileEditMode, onDismiss: nil){
            NavigationView{
                VStack{
                    Divider()
                    Button{
                        shouldShowImagePicker.toggle()
                        isProfileImageChanged = true
                    }label:{
                        WebImage(url: URL(string: vm.chatUser?.profileImageUrl ?? ""))
                            .resizable()
                            .scaledToFill()
                            .frame(width: UIScreen.main.bounds.width / 2, height: UIScreen.main.bounds.width / 2)
                            .clipped()
                            .cornerRadius(UIScreen.main.bounds.width / 2)
                            .shadow(radius: 5)
                            .padding(.bottom, 35)
                    }
                    if isProfileImageChanged{
                        Button{
                            putUpdatedUmageToStorage()
                        }label:{
                            Text("Сохранить изображение")
                        }
                    }
                    HStack{
                        TextField("Имя", text: $userName)
                            .disabled(!editName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button{
                            if editName{
                                changeUserName()
                                familyModel.familyUsersArray.removeAll()
                                familyModel.getUsers()
                                editName.toggle()
                            }
                            else{
                                editName.toggle()
                                tempString = userName
                            }
                        }label:{
                            Image(systemName: !editName ? "pencil.circle" : "checkmark.circle")
                                .foregroundColor(.blue)
                        }
                        if editName{
                            Button{
                                editName.toggle()
                                userName = tempString
                            }label:{
                                Image(systemName: "clear")
                                    .foregroundColor(.blue)
                            }
                        }
                    }.padding()
                    HStack{
                        TextField("Почта", text: $userMail)
                            .disabled(!editMail)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button{
                            if editMail{
                                changeUserMail()
                                editMail.toggle()
                            }
                            else{
                                editMail.toggle()
                                tempString = userMail
                            }
                        }label:{
                            Image(systemName: !editMail ? "pencil.circle" : "checkmark.circle")
                                .foregroundColor(.blue)
                        }
                        // Подтверждение пароля
                        .sheet(isPresented: $isShouldShowAlert){
                            PasswordAlert
                        }
                        if editMail{
                            Button{
                                editMail.toggle()
                                userMail = tempString
                            }label:{
                                Image(systemName: "clear")
                                    .foregroundColor(.blue)
                            }
                        }
                    }.padding()
                    HStack{
                        if !editPassword{
                            SecureField("Новый пароль", text: $userChangePassword)
                                .disabled(!editPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }else{
                            TextField("Новый пароль", text: $userChangePassword)
                                .disabled(!editPassword)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        Button{
                            if editPassword{
                                isShouldShowAlert = true
                                editPassword = true
                            }
                            else{
                                editPassword.toggle()
                            }
                        }label:{
                            Image(systemName: !editPassword ? "pencil.circle" : "checkmark.circle")
                                .foregroundColor(.blue)
                        }
                        // Подтверждение пароля
                        .sheet(isPresented: $isShouldShowAlert){
                            PasswordAlert
                        }
                        if editPassword{
                            Button{
                                editPassword.toggle()
                            }label:{
                                Image(systemName: "clear")
                                    .foregroundColor(.blue)
                            }
                        }
                    }.padding()
                    HStack{
                        Toggle(isOn: $shouldUpdateNavigation){
                            Text("Включить обновление позиции?")
                        }.onChange(of: shouldUpdateNavigation){
                            _ in
                            changeUpdateLocation()
                            shouldupdatetext = "Для применения настроек перезапустите приложение!"
                        }
                    }
                    .padding()
                    HStack{
                        Toggle(isOn: $canSeeRecentMessages, label: {Text("Включить общий чат?")})
                            .onChange(of: canSeeRecentMessages){
                                item in
                                if item{
                                    updateRecentStatus.toggle()
                                    isShouldShowAlert.toggle()
                                }
                                else{
                                    FireBaseManager.shared.firestore.collection("users")
                                        .document(curruser)
                                        .updateData(["canAccessChat": canSeeRecentMessages])
                                }
                            }
                    }
                    .padding()
                    Text(shouldupdatetext)
                        .foregroundColor(.red)
                    Spacer()
                }.navigationTitle("Профиль")
                    .toolbar{
                        ToolbarItemGroup(placement: .navigationBarLeading){
                            Button{
                                isProfileEditMode.toggle()
                                isProfileImageChanged = false
                            } label: {
                                Text("Назад")
                            }
                        }
                    }
            }.fullScreenCover(isPresented: $shouldShowImagePicker, onDismiss: nil){
                ImagePicker(image: $image)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            TabView{
                if canSeeRecentMessages{
                    VStack {
                        customNavBar
                        messagesView
                        NavigationLink("", isActive: $shouldNavigateToChatLog){
                            ChatLogView(chatUser: self.chatUser)
                        }
                    }
                    .tabItem{
                        Image(systemName: "message")
                        Text("Сообщения")
                    }
                    .overlay(
                        newMessageButton, alignment: .bottom)
                    .navigationBarHidden(true)
                    .padding(.bottom, 10)
                }
                else{
                    VStack {
                        customNavBar
                        Spacer()
                        Image(systemName: "hand.raised")
                            .resizable()
                            .frame(width: UIScreen.main.bounds.width / 4, height: UIScreen.main.bounds.width / 3.3)
                            .scaledToFit()
                            .foregroundColor(Color.red)
                            
                        Text("Отображене общего чата выключено")
                        Button{
                            vm.fetchCurrentUser()
                            checkFamily()
                        }label: {
                            Text("Обновить?")
                        }
                        Spacer()
                    }
                    .tabItem{
                        Image(systemName: "message")
                        Text("Сообщения")
                    }
                }
                VStack{
                    if !isHaveFamily{
                        Button{
                            createFamily()
                            checkFamily()
                        }label: {
                            Spacer()
                            Text("Создать семью")
                            Spacer()
                        }.foregroundColor(.white)
                            .padding(.vertical)
                            .background(Color.blue)
                            .cornerRadius(32)
                            .padding(.horizontal)
                            .shadow(radius: 15)
                        
                        Button{
                            shouldShowJoinFamilyScreen.toggle()
                        }label: {
                            Spacer()
                            Text("Присоединиться к семье")
                            Spacer()
                        }.foregroundColor(.white)
                            .padding(.vertical)
                            .background(Color.blue)
                            .cornerRadius(32)
                            .padding(.horizontal)
                            .shadow(radius: 15)
                    }
                    else{
                        VStack{
                            HStack{
                                NavigationLink("", isActive: $shouldNavigateToFamilyChat){
                                    FamilyChatView(familyName: familyName)
                                }
                                Text("Код: \(familyName)")
                                    .font(Font.custom("", size: 15))
                                Button{
                                    UIPasteboard.general.string = familyName
                                }label:{
                                    Image(systemName: "doc.on.doc")
                                }
                            }
                            .padding(.horizontal)
                            Button{
                                shouldNavigateToFamilyChat.toggle()
                            }label: {
                                HStack {
                                    Spacer()
                                    Text("Семейный чат")
                                        .font(.system(size: 16, weight: .bold))
                                    Spacer()
                                }
                                .foregroundColor(.white)
                                .padding(.vertical)
                                .background(Color.blue)
                                .cornerRadius(32)
                                .padding(.horizontal)
                                .shadow(radius: 15)
                            }
                            ScrollView{
                                ForEach(familyModel.familyUsersArray){item in
                                    HStack(spacing: 16){
                                        WebImage(url: URL(string: item.image))
                                            .resizable()
                                            .scaledToFill()
                                            .frame(width: 50, height: 50)
                                            .clipped()
                                            .cornerRadius(50)
                                            .overlay(RoundedRectangle(cornerRadius: 44)
                                                .stroke(Color(.label), lineWidth: 1)
                                            )
                                            .shadow(radius: 5)
                                        VStack{
                                            HStack{
                                                Text(item.name)
                                                    .font(.system(size: 16, weight: .bold))
                                                if item.id == familyName {
                                                    Image(systemName: "crown.fill")
                                                        .foregroundColor(Color.yellow)
                                                }
                                                Spacer()
                                            }
                                            HStack{
                                                Text(item.login)
                                                    .font(.system(size: 14))
                                                    .foregroundColor(Color(.lightGray))
                                                Spacer()
                                            }
                                        }
                                        Spacer()
                                        if item.id != familyName && curruser == familyName{
                                            Button{
                                                showDeleteUserAlert.toggle()
                                            }label:{
                                                Image(systemName: "trash")
                                                    .foregroundColor(Color.red)
                                            }.alert(isPresented: $showDeleteUserAlert) {
                                                Alert(
                                                    title: Text("Подтверждение"),
                                                    message: Text("Вы уверены, что хотите удалить пользователя?"),
                                                    primaryButton: .destructive(Text("Выполнить")) {
                                                        deleteFamilyUser(userId: item.id)
                                                        checkFamily()
                                                    },
                                                    secondaryButton: .cancel(Text("Отменить"))
                                                )
                                            }
                                        }
                                    }.padding()
                                    Divider()
                                }
                            }.padding()
                        }
                    }
                }.tabItem{
                    Image(systemName: "person.2")
                    Text("Моя семья")
                }
                .sheet(isPresented: $shouldShowJoinFamilyScreen){
                    VStack{
                        Text("Присоединиться к семье")
                            .padding(.vertical, 20)
                            .fontWeight(.bold)
                        TextField("Введите код семьи", text: $familyCode)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                        Button{
                            joinFamily(familyId: familyCode)
                        }label:{
                            HStack{
                                Spacer()
                                Text("Подтвердить")
                                    .foregroundColor(Color.white)
                                Spacer()
                            }
                        }.foregroundColor(.white)
                            .padding(.vertical)
                            .background(Color.blue)
                            .cornerRadius(32)
                            .padding(.horizontal)
                            .shadow(radius: 15)
                    }
                    Spacer()
                }
                
                VStack{
                    MapViewWrapper(familyName: familyName, canUpdateLocation: shouldUpdateNavigation)
                        .ignoresSafeArea(.all, edges: .top)
                }.tabItem{
                    Image(systemName: "map")
                    Text("Карта")
                }
                VStack{
                    ScrollView{
                        ForEach(geoPointsModel.pointsArray){
                            pointItem in
                            HStack{
                                Image(systemName: pointItem.pointImage)
                                        .resizable()
                                        .frame(width: 15, height: 15)
                                        .padding()
                                        .background(Color.blue)
                                        .cornerRadius(10)
                                        .foregroundColor(Color.white)
                                    VStack{
                                        HStack{
                                            Text("Место: \(pointItem.pointName)")
                                                .font(.title2)
                                            Spacer()
                                        }
                                        HStack{
                                            Text("Описание \(pointItem.pointDesc)")
                                            Spacer()
                                        }
                                    }
                                    Spacer()
                                    Button{
                                        geoPointsModel.deleteGeoPoint(documentId: pointItem.id, familyName: familyName)
                                    }label:{
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                            }
                            .padding()
                            Divider()
                        }
                    }
                }.tabItem{
                    Image(systemName: "signpost.left")
                    Text("Список мест")
                }
                VStack{
                    HStack{
                        Spacer()
                    }
                    ScrollView{
                        ForEach(taskModel.tasksArray){taskItem in
                            VStack{
                                HStack{
                                    Text(taskItem.taskName)
                                        .padding(.leading, 5)
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(taskItem.taskColor.color)
                                    Spacer()
                                    Text("Дата: \(getFormattedDate(inputDate: taskItem.taskDate))")
                                        .padding(.leading, 5)
                                    Image(systemName: taskItem.taskChecked ? "checkmark.square.fill" : "square")
                                        .resizable()
                                        .frame(width: UIScreen.main.bounds.width/11, height: UIScreen.main.bounds.width/11)
                                        .foregroundColor(Color.blue)
                                        .padding(.trailing, 5)
                                        .onTapGesture {
                                            taskItem.toggleTaskChecked(taskManager: taskModel, family: familyName)
                                        }
                                }
                            }
                            .padding()
                            Divider()
                        }
                    }
                }
                .overlay(newTaskButton, alignment: .bottom)
                .tabItem{
                    Image(systemName: "list.bullet.clipboard")
                    Text("Список дел")
                }
                .padding(.bottom, 10)
                .sheet(isPresented: $createNewTask){
                    NavigationView{
                        VStack{
                            TextField("Название задачи", text: $taskName)
                                .padding(10)
                                .overlay(RoundedRectangle(cornerRadius: 32)
                                    .stroke(Color(.label), lineWidth: 0.4)
                                ).padding(10)
                            ScrollView(.horizontal, showsIndicators: false){
                                HStack{
                                    ForEach(defaultColor, id: \.self) { color in
                                        Button(action: {
                                            self.taskColor = color
                                        }) {
                                            color.frame(width: 40, height: 40)
                                                .cornerRadius(20)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 20)
                                                        .strokeBorder(Color.black, lineWidth: 0.1)
                                                )
                                        }
                                    }
                                }
                            }
                            DatePicker("Когда нужно закончить?", selection: $taskDate, displayedComponents: .date)
                                .padding(10)
                            Button{
                                taskModel.addTask(taskN: taskName, taskD: taskDate, taskC: taskColor.description, taskF: familyName)
                                createNewTask.toggle()
                            }label:{
                                HStack{
                                    Spacer()
                                    Text("Добавить").font(.system(size: 16, weight: .bold))
                                    Spacer()
                                }.foregroundColor(.white)
                                    .padding(.vertical)
                                    .background(Color.blue)
                                    .cornerRadius(32)
                                    .padding(.horizontal)
                                    .shadow(radius: 15)
                            }
                            Spacer()
                        }.navigationTitle("Новоя задача")
                            .toolbar{
                                ToolbarItemGroup(placement: .navigationBarLeading){
                                    Button{
                                        createNewTask.toggle()
                                    } label: {
                                        Text("Назад")
                                    }
                                }
                            }
                    }
                }
            }
        }
        .onAppear{
            checkStatus()
            checkFamily()
        }
    }
    
    func checkStatus(){
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5){
            shouldUpdateNavigation = FireBaseManager.shared.currentUser?.updateLocation ?? false
            canSeeRecentMessages = FireBaseManager.shared.currentUser?.canAccessChat ?? false
        }
    }
    
    private func joinFamily(familyId: String){
        guard let userId = FireBaseManager.shared.auth.currentUser?.uid
        else {return}
        
        FireBaseManager.shared.firestore.collection(FireBaseConstants.familyCollection).document(familyId).getDocument{
            snapshot, error in
            
            if let error = error{
                print("Ошибка проверки \(error)")
                return
            }
            
            guard let data = snapshot?.data() else {return}
            
            let newFamilyUser = [FireBaseConstants.familyUser: userId, FireBaseConstants.familyid: familyId, "timestamp": Timestamp()] as [String: Any]
            
            if !data.isEmpty{
                FireBaseManager.shared.firestore.collection(FireBaseConstants.familyCollection)
                    .document(userId)
                    .setData(newFamilyUser)
                print("Пользователь (\(userId) присоединияется к семье(\(familyId)")
                checkFamily()
                shouldShowJoinFamilyScreen.toggle()
            }
            else{
                print("Пользователь уже в семье")
            }
        }
    }
    
    private func checkFamily(){
        print(curruser)
        guard let userId = FireBaseManager.shared.auth.currentUser?.uid
        else{ return }

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
                
                if !data.isEmpty{
                    familyModel.familyUsersArray.removeAll()
                    familyModel.getUsers()
                    isHaveFamily = true
                    familyName = data["familyid"] as? String ?? ""
                    taskModel.fetchTasks(family: familyName)
                    geoPointsModel.checkAllPoints(family: familyName)
                }
            }
    }
    
    private func createFamily(){
        guard let userId = FireBaseManager.shared.auth.currentUser?.uid
        else {return}
        
        let familyData = [FireBaseConstants.familyid: userId, "timestamp": Timestamp(), FireBaseConstants.familyUser: userId] as [String : Any]
        
        FireBaseManager.shared.firestore
            .collection(FireBaseConstants.familyCollection)
            .document(userId)
            .setData(familyData){
                error in
                if let error = error{
                    print("Ошибка! \(error)")
                    return
                }
            }
        isHaveFamily = true
    }
    
    public func changeUserMail(){
        func isValidEmail(email: String) -> Bool {
            return email.isValidEmail()
        }
        
        if !isValidEmail(email: userMail) {
            return
        }
        isShouldShowAlert.toggle()
        editMailChange = true
    }
    
    public func changeMail(){
        guard let user = FireBaseManager.shared.auth.currentUser else {return}
        
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "-1", password: userPassword)
        user.reauthenticate(with: credential) { (authResult, error) in
            if let error = error {
                print("\(error)")
                return
            }
            user.updateEmail(to: userMail){
                error in
                if let error = error{
                    print("\(error)")
                    //Добавить ошибку для текста
                    return
                }
            }
            isShouldShowAlert.toggle()
            userPassword = ""
            FireBaseManager.shared.firestore.collection("users")
                .document(user.uid)
                .updateData(["email": userMail]){
                    error in
                    if let error = error{
                        print("\(error)")
                        return
                    }
                }
            shouldupdatetext = "Обновлено!"
            editMailChange = false
            vm.fetchCurrentUser()
        }
    }
    
    public func changeUserName(){
        if userName.isEmpty || userName.count <= 2{
            print("Несоответсвие имени!")
            return
        }
        
        guard let user = FireBaseManager.shared.auth.currentUser?.uid else {return}
        
        FireBaseManager.shared.firestore.collection("users")
            .document(user)
            .updateData(["fullName": userName]){error in
                if let error = error{
                    print("\(error)")
                    return
                }
            }
    }
    
    public func checkUserData(){
        guard let curruser = FireBaseManager.shared.auth.currentUser?.uid else {return}
        
        FireBaseManager.shared.firestore.collection("users")
            .document(curruser)
            .getDocument{
                mydata, error in
                if let error = error{
                    print("\(error)")
                    return
                }
                let data = mydata?.data()
                userName = data?["fullName"] as! String
                userMail = data?["email"] as! String
            }
    }
    
    private var messagesView: some View {
        ScrollView {
            ForEach(vm.recentMessages) { recentMessage in
                VStack{
                    Button{
                        let uid = FireBaseManager.shared.auth.currentUser?.uid == recentMessage.fromid ? recentMessage.toid : recentMessage.fromid
                        
                        let data = ["uid": uid, "email": recentMessage.email, "profileImageUrl": recentMessage.image, FireBaseConstants.familyid: familyName]
                        
                        self.chatUser = .init(data: data)
                        self.shouldNavigateToChatLog.toggle()
                    } label:{
                        HStack(spacing: 16) {
                            WebImage(url: URL(string: recentMessage.image))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 64, height: 64)
                                .cornerRadius(64)
                                .overlay(RoundedRectangle(cornerRadius: 64).stroke(Color.blue, lineWidth: 2)).shadow(radius: 5)
                            
                            
                            VStack(alignment: .leading) {
                                Text(recentMessage.email.replacingOccurrences(of: "@gmail.com", with: ""))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color.blue)
                                Text(recentMessage.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.lightGray))
                                    .lineLimit(1)
                            }
                            Spacer()
                            
                            Text(recentMessage.timeAgo.replacingOccurrences(of: "-", with: ""))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color.blue)
                        }
                    }.foregroundColor(Color.black)
                    
                    Divider()
                        .padding(8)
                }.padding()
                
            }.padding(.bottom, 50)
        }
    }
    
    private var newTaskButton: some View{
        Button{
            createNewTask.toggle()
        }label:{
            HStack {
                Spacer()
                Spacer()
                Text("Добавить")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
    }
    
    private var newMessageButton: some View {
        Button {
            shouldShowNewMessageScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ Новое сообщение")
                    .font(.system(size: 16, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(32)
            .padding(.horizontal)
            .shadow(radius: 15)
        }
        .fullScreenCover(isPresented: $shouldShowNewMessageScreen){
            NewMessageView(didSelectNewUser: {
                user in
                print(user.email)
                self.shouldNavigateToChatLog.toggle()
                self.chatUser = user
            })
        }
    }
    
    private var PasswordAlert: some View{
        NavigationView{
            VStack{
                HStack{
                    if passwordField{
                        TextField("Пароль", text: $userPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    }
                    else{
                        SecureField("Пароль", text: $userPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .padding()
                    }
                    Button{
                        passwordField.toggle()
                    }label:{
                        Image(systemName: "eye")
                            .padding()
                    }
                }
                Text(userChangeError)
                Button{
                    if editPassword{
                        changeUserPassword()
                    }
                    if editMailChange{
                        changeMail()
                    }
                    if updateRecentStatus{
                        changeMessagesStatus()
                    }
                }label:{
                    HStack{
                        Spacer()
                        Text("Отправить")
                            .foregroundColor(Color.white)
                            .padding(.vertical, 10)
                        Spacer()
                    }
                }
                .background(Color.blue)
                .cornerRadius(10)
                .padding()
                Spacer()
            }.navigationTitle("Подтвердите пароль")
        }
    }
    
    func changeMessagesStatus(){
        
        guard let user = FireBaseManager.shared.auth.currentUser else {return}
        
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "-1", password: userPassword)
        user.reauthenticate(with: credential) { (authResult, error) in
            if let error = error {
                print("\(error)")
                return
            }
            FireBaseManager.shared.firestore.collection("users")
                .document(curruser)
                .updateData(["canAccessChat": canSeeRecentMessages])
            isShouldShowAlert.toggle()
            userPassword = ""
            print("обновлен?")
            editPassword = false
        }
    }
    
    func changeUserPassword(){
        print("here")
        guard let user = FireBaseManager.shared.auth.currentUser else {return}
        
        let credential = EmailAuthProvider.credential(withEmail: user.email ?? "-1", password: userPassword)
        user.reauthenticate(with: credential) { (authResult, error) in
            if let error = error {
                print("\(error)")
                return
            }
            user.updatePassword(to: userChangePassword){
                error in
                if let error = error{
                    print("\(error)")
                    return
                }
            }
            vm.handleSignOut()
            isShouldShowAlert.toggle()
            userPassword = ""
            print("обновлен?")
            editPassword = false
            UserDefaults.standard.set(false, forKey: "StringloginStatus")
        }
        
        UserDefaults.standard.set(false, forKey: "loginStatus")
        UserDefaults.standard.synchronize()
    }
    
    func changeUpdateLocation(){
        FireBaseManager.shared.firestore
            .collection("users")
            .document(curruser)
            .updateData(["canUpdateLocation": shouldUpdateNavigation])
    }
    
    func putUpdatedUmageToStorage(){
        guard let uid = FireBaseManager.shared.auth.currentUser?.uid
        else{ return }
        
        let ref = FireBaseManager.shared.storage.reference(withPath: uid)
        guard let imageData = self.image?.jpegData(compressionQuality: 0.5) else{return}
        ref.putData(imageData, metadata: nil){
            metadata, err in
            if let error = err{
                print("\(error)")
                return
            }
            
            ref.downloadURL{url, err in
                if let err = err{
                    print("\(err)")
                    return
                }
                guard let url = url else {return}
                FireBaseManager.shared.firestore.collection("users")
                    .document(FireBaseManager.shared.auth.currentUser?.uid ?? "")
                    .updateData(["profileImageUrl": url.absoluteString]){
                        error in
                        if let error = error{
                            print(error)
                            return
                        }
                    }
                vm.fetchCurrentUser()
            }
        }
    }
    
}


struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
