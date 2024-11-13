//
//  geopoints.swift
//  diploma
//
//  Created by Максим Купрейчук on 16.05.2023.
//

import Foundation

struct pointInfo: Identifiable{
    var id: String
    
    var pointName: String
    var pointDesc: String
    var pointImage: String
    
    init(id: String, pointName: String, pointDesc: String, pointImage: String) {
        self.id = id
        self.pointName = pointName
        self.pointDesc = pointDesc
        self.pointImage = pointImage
    }
}

class GeoPointModel: ObservableObject{
    @Published var pointsArray = [pointInfo]()
    
    init(){
    }
    
    func checkAllPoints(family: String) {
        FireBaseManager.shared.firestore.collection("points")
            .document(family)
            .collection("points")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print(error)
                    return
                }
                
                guard let snapshot = querySnapshot else {
                    if let error = error {
                        print("Error fetching tasks: \(error)")
                    }
                    return
                }
                
                self.pointsArray.removeAll()
                
                for document in snapshot.documents {
                        let docId = document.documentID
                        let pointName = document.data()["pointName"] as? String ?? ""
                        let pointDesc = document.data()["pointDesc"] as? String ?? ""
                        let pointImage = document.data()["pointImage"] as? String ?? ""
                        self.pointsArray.append(.init(id: docId, pointName: pointName, pointDesc: pointDesc, pointImage: pointImage))
                }
            }
    }
    
    func deleteGeoPoint(documentId: String, familyName: String){
        FireBaseManager.shared.firestore.collection("points")
            .document(familyName)
            .collection("points")
            .document(documentId)
            .delete(){
                error in
                if let error = error{
                    print(error)
                    return
                }
            }
        self.checkAllPoints(family: familyName)
    }
}


