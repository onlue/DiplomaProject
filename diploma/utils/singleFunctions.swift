//
//  singleFunctions.swift
//  diploma
//
//  Created by Максим Купрейчук on 16.05.2023.
//

import Foundation

public func getFormattedDate(inputDate: Date) -> String{
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd.MM.yyyy"
    let formattedDate = dateFormatter.string(from: inputDate)
    return formattedDate
}

public func deleteFamilyUser(userId: String){
    FireBaseManager.shared.firestore.collection(FireBaseConstants.familyCollection)
        .document(userId)
        .delete()
}


extension String {
    func isValidEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
    }
}
