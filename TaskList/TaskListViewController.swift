//
//  TaskListViewController.swift
//  TaskList
//
//  Created by Matvei Khlestov on 02.12.2022.
//  Copyright © 2022 Matvei Khlestov. All rights reserved.
//

import UIKit
import CoreData

final class TaskListViewController: UITableViewController {
    
    // MARK: - Private Properties
    private let cellID = "task"
    private let context = StorageManager.shared.context
    private var tasks: [Task] = []
    private var filteredTasks: [Task] = []
    private let searchController = UISearchController(searchResultsController: nil)
    private var searchBarIsEmty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    
    private var isFiltering: Bool {
        return searchController.isActive && !searchBarIsEmty
    }
    
    // MARK: - Override Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(
            UITableViewCell.self,
            forCellReuseIdentifier: cellID
        )
        setUpNavigationBar()
        setupSearchController()
        fetchData()
    }
}

// MARK: - Private Methods
extension TaskListViewController {
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.barTintColor = .brown
        navigationItem.searchController = searchController
        definesPresentationContext = true
        
        setupTextField()
    }
    
    private func setupTextField() {
        if let textField = searchController.searchBar.value(forKey: "searchField") as? UITextField {
            
            textField.font = UIFont.systemFont(ofSize: 18)
            textField.textColor = .white
            textField.autocapitalizationType = .none
            textField.attributedPlaceholder = NSAttributedString(
                string: "Search",
                attributes: [
                    NSAttributedString.Key.foregroundColor: UIColor(
                        white: 1.1,
                        alpha: 0.5
                    )
                ]
            )
        }
    }
    
    private func setUpNavigationBar() {
        title = "Task List"
        navigationController?.navigationBar.prefersLargeTitles = true
        
        let navBarAppearance = UINavigationBarAppearance()
        navBarAppearance.backgroundColor = UIColor(
            red: 120/255,
            green: 200/255,
            blue: 95/255,
            alpha: 215/255
        )
        navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addNewTask)
        )
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .trash,
            target: self,
            action: #selector(deleteAllTasks)
        )
        
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
    }
    
    @objc private func addNewTask() {
        showSaveAlert()
    }
    
    @objc private func deleteAllTasks() {
        showDeleteAlert()
    }
    
    private func fetchData() {
        StorageManager.shared.fetchData { result in
            switch result {
            case .success(let tasks):
                self.tasks = tasks
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func fetchSearchData(_ searchText: String) {
        StorageManager.shared.fetchSearchData(searchText) { result in
            switch result {
            case .success(let filteredTasks):
                self.filteredTasks = filteredTasks
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    private func save(_ taskName: String) {
        StorageManager.shared.save(taskName: taskName) { task in
            self.tasks.append(task)
            self.tableView.insertRows(
                at: [IndexPath(row: tasks.count - 1, section: 0)],
                with: .automatic
            )
        }
    }
    
    private func showSaveAlert() {
        let alert = UIAlertController(
            title: "New Task",
            message: "What do you want to do?",
            preferredStyle: .alert
        )
        let saveAction = UIAlertAction(title: "Save", style: .default) {_ in
            guard let task = alert.textFields?.first?.text, !task.isEmpty else { return }
            self.save(task)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) {_ in }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextField { textField in
            textField.placeholder = "New Task"
            textField.font = UIFont.systemFont(ofSize: 17)
            textField.translatesAutoresizingMaskIntoConstraints = false
        }
        
        present(alert, animated: true)
    }
    
    private func showDeleteAlert() {
        let alertController = UIAlertController(
            title: "Deleting all tasks",
            message: "Do you really wan't to delete all the tasks?",
            preferredStyle: .alert
        )
        let deleteAction = UIAlertAction(title: "Delete", style: .default) {_ in
            self.tasks.removeAll()
            StorageManager.shared.deleteTasks()
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) {_ in }
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController {
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        if isFiltering {
            return filteredTasks.count
        }
        
        return tasks.count
    }
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath)
        var task: Task
        
        if isFiltering {
            task = filteredTasks[indexPath.row]
        } else {
            task = tasks[indexPath.row]
        }
        
        var content = cell.defaultContentConfiguration()
        content.text = task.title
        cell.contentConfiguration = content
        return cell
    }
}

// MARK: - UITableViewDelegate
extension TaskListViewController {
    override func tableView(_ tableView: UITableView,
                            editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    
    override func tableView(_ tableView: UITableView,
                            commit editingStyle: UITableViewCell.EditingStyle,
                            forRowAt indexPath: IndexPath) {
        var task: Task
        
        if editingStyle == .delete {
            if isFiltering {
                task = filteredTasks[indexPath.row]
                
                filteredTasks.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                StorageManager.shared.delete(task: task)
            } else {
                task = tasks[indexPath.row]
                
                tasks.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                StorageManager.shared.delete(task: task)
            }
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        var task: Task
        
        if isFiltering {
            task = filteredTasks[indexPath.row]
        } else {
            task = tasks[indexPath.row]
        }
        
        let alert = UIAlertController(
            title: "Update",
            message: "What do you want to do?",
            preferredStyle: .alert
        )
        let saveAction = UIAlertAction(title: "Save", style: .default) { _ in
            guard let newValue = alert.textFields?.first?.text, !newValue.isEmpty else { return }
            let newTaskName = newValue
            StorageManager.shared.updateTask(task: task, newTaskName: newTaskName)
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive) {_ in }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        alert.addTextField { textField in
            textField.placeholder = "Task"
            textField.text = task.title
            textField.font = UIFont.systemFont(ofSize: 17)
        }
        
        present(alert, animated: true)
    }
}

// MARK: - UISearchResultsUpdating
extension TaskListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        fetchSearchData(searchController.searchBar.text ?? "")
    }
}








