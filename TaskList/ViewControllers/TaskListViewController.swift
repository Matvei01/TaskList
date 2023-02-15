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
    private var tasks: [Task] = []
    private var filteredTasks: [Task] = []
    private let searchController = UISearchController(searchResultsController: nil)
    private var searchBarIsEmty: Bool {
        guard let text = searchController.searchBar.text else { return false }
        return text.isEmpty
    }
    
    private var isFiltering: Bool {
        searchController.isActive && !searchBarIsEmty
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
        
        navigationController?.navigationBar.tintColor = .white
        navigationController?.navigationBar.standardAppearance = navBarAppearance
        navigationController?.navigationBar.scrollEdgeAppearance = navBarAppearance
    }
    
    @objc private func addNewTask() {
        showAlert()
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
}

// MARK: - Alert Controllers
extension TaskListViewController {
    private func showAlert(task: Task? = nil, completion: (() -> Void)? = nil) {
        let title = task != nil ? "Update Task" : "New Task"
        let alert = UIAlertController.createAlertController(withTitle: title)
        
        alert.action(task: task) { taskName in
            if let task = task, let completion = completion {
                StorageManager.shared.updateTask(task: task, newTaskName: taskName)
                completion()
            } else {
                self.save(taskName)
            }
        }
        
        present(alert, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController {
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int) -> Int {
        
        isFiltering ? filteredTasks.count : tasks.count
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
        
        showAlert(task: task) {
            tableView.reloadRows(at: [indexPath], with: .automatic)
        }
    }
}

// MARK: - UISearchResultsUpdating
extension TaskListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        fetchSearchData(searchController.searchBar.text ?? "")
    }
}









