//
//  customAlert.swift
//  diploma
//
//  Created by Максим Купрейчук on 11.05.2023.
//

import SwiftUI

class InputAlertController: UIAlertController {
    
    private var inputTextField: UITextField?
    
    func addInputField(placeholder: String? = nil) {
        addTextField { textField in
            textField.placeholder = placeholder
            self.inputTextField = textField
        }
    }
    
    func getInputText() -> String? {
        return inputTextField?.text
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addAction(UIAlertAction(title: "Отмена", style: .cancel, handler: nil))
        addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            // Handle OK button action
        }))
    }
}

struct InputAlert: UIViewControllerRepresentable {
    @Binding var inputText: String
    var title: String

    func makeUIViewController(context: Context) -> UIAlertController {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)

        alertController.addTextField { textField in
            textField.placeholder = "Введите сообщение"
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.inputText = alertController.textFields?[0].text ?? ""
        }))

        return alertController
    }

    func updateUIViewController(_ uiViewController: UIAlertController, context: Context) {
        // Ничего не нужно обновлять
    }
}


