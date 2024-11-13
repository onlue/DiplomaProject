//
//  TaskManager.swift
//  diploma
//
//  Created by Максим Купрейчук on 07.05.2023.
//

import Foundation
import Firebase
import SwiftUI

extension String {
    var color: Color {
        let arr = ["green": Color.green, "red": Color.red, "blue": Color.blue, "gray": Color.gray, "yellow": Color.yellow, "cyan": Color.cyan, "orange": Color.orange, "pink": Color.pink, "brown": Color.brown, "indigo": Color.indigo]
        return arr[self] ?? Color.black
    }
}

class TaskStruct: Identifiable, ObservableObject{
    var id: String {documentId}
    var documentId: String
    var taskName: String
    var taskDate: Date
    var taskColor: String
    @Published var taskChecked = false
    
    init(data: [String: Any], documentId: String) {
        self.documentId = documentId
        self.taskName = data["taskName"] as? String ?? ""
        self.taskColor = data["taskColor"] as? String ?? "black"
        
        let timestamp = data["taskDate"] as? Timestamp ?? Timestamp()
        self.taskDate = timestamp.dateValue()

        if let isTaskChecked = data["taskChecked"] as? Bool {
            self.taskChecked = isTaskChecked
        }
    }
    
    func toggleTaskChecked(taskManager: TaskManager, family: String) {
            taskManager.changeStatus(taskObject: self, family: family)
        }
}

class TaskManager: ObservableObject{
    @Published var tasksArray = [TaskStruct]()
    
    public func addTask(taskN: String, taskD: Date, taskC: String, taskF: String){
        if(taskF.count <= 3){
            print("Создайте/присоединитесь к семье, для добавления в список дел!")
            return
        }
        
        if taskN.isEmpty{
            print("Введите название дела!")
            return
        }
        
        let document = FireBaseManager.shared.firestore.collection(FireBaseConstants.taskCollection)
            .document(taskF)
            .collection("tasks")
            .document()
        
        let taskData = ["taskName": taskN, "taskDate": taskD, "taskColor": taskC, "taskChecked": false] as [String : Any]
        
        document.setData(taskData){
            error in
            if let error = error{
                print("\(error)")
                return
            }
        }
    }
    
    public func changeStatus(taskObject: TaskStruct, family: String){
        let tempStatus = taskObject.taskChecked == true ? false : true
        let tempObject = ["taskChecked": tempStatus, "taskColor": taskObject.taskColor.description, "taskDate": taskObject.taskDate, "taskName": taskObject.taskName] as [String : Any]
        let document = FireBaseManager.shared.firestore.collection(FireBaseConstants.taskCollection)
            .document(family)
            .collection("tasks")
            .document(taskObject.documentId)
        print(tempObject)
        document.setData(tempObject){
            error in
            if let error = error{
                print("\(error)")
                return
            }
        }
    }
    
    public func printArr(){
        print(tasksArray)
    }
    
    public func fetchTasks(family: String){
        if family.isEmpty {
            print("Please join a family")
            return
        }
        FireBaseManager.shared.firestore
            .collection(FireBaseConstants.taskCollection)
            .document(family)
            .collection("tasks")
            .order(by: "taskColor")
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    if let error = error {
                        print("Error fetching tasks: \(error)")
                    }
                    return
                }
                self.tasksArray.removeAll()
                for document in snapshot.documents {
                    self.tasksArray.append(.init(data: document.data(), documentId: document.documentID))
                }
            }
    }

}
