//
//  TaskViewController.swift
//  TaskList
//
//  Created by Matvei Khlestov on 03.12.2022.
//

import UIKit
import CoreData

class TaskViewController: UIViewController {
    var delegate: TaskViewControllerDelegate?
    
    private let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    private lazy var newTaskTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "New Task"
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    private lazy var saveButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(
            red: 21/255,
            green: 101/255,
            blue: 192/255,
            alpha: 194/255
        )
        
        button.setTitle("Save Task", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector(save), for: .touchUpInside)
        return button
    }()
    
    private lazy var cancelButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor(
            red: 150/255,
            green: 50/255,
            blue: 50/255,
            alpha: 190/255
        )
        
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 4
        button.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        setupSubviews(newTaskTextField, saveButton, cancelButton)
        setupConstraints()
    }
    
    private func setupSubviews(_ subwiews: UIView...) {
        subwiews.forEach { subview in
            view.addSubview(subview)
        }
    }
    
    private func setupConstraints() {
        newTaskTextField.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            newTaskTextField.topAnchor.constraint(equalTo: view.topAnchor, constant: 88),
            newTaskTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            newTaskTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            saveButton.topAnchor.constraint(equalTo: newTaskTextField.bottomAnchor, constant: 20),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
        
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cancelButton.topAnchor.constraint(equalTo: saveButton.bottomAnchor, constant: 20),
            cancelButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            cancelButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }
    
    @objc private func save() {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Task", in: context) else { return }
        guard let task = NSManagedObject(entity: entityDescription, insertInto: context) as? Task else { return }
        task.title = newTaskTextField.text
        
        if context.hasChanges {
            do {
                try context.save()
            } catch let error {
                print(error)
            }
        }
        
        delegate?.reloadData()
        dismiss(animated: true)
    }
    
    @objc private func cancel() {
        dismiss(animated: true)
    }
}
