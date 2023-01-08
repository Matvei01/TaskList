//
//  StorageManager.swift
//  TaskList
//
//  Created by Matvei Khlestov on 04.12.2022.
//  Copyright © 2022 Matvei Khlestov. All rights reserved.
//

import CoreData

class StorageManager {
    
    static let shared = StorageManager()
    
    // MARK: - Core Data stack
    private let persistentContainer: NSPersistentContainer = {
        
        let container = NSPersistentContainer(name: "TaskList")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()
    
    private let context: NSManagedObjectContext
    
    private init() {
        context = persistentContainer.viewContext
    }
    
    // MARK: - Public methods
    func fetchData(complition: (Result<[Task], Error>) -> Void) {
        let fetchRequest = Task.fetchRequest()
        
        do {
            let tasks = try context.fetch(fetchRequest)
            complition(.success(tasks))
        } catch let error {
            complition(.failure(error))
        }
    }
    
    func fetchSearchData(_ searchText: String, complition: (Result<[Task], Error>) -> Void) {
        let fetchRequest = Task.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "title contains[c] %@", searchText)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        do {
            let filteredTasks = try context.fetch(fetchRequest)
            complition(.success(filteredTasks))
        } catch let error {
            complition(.failure(error))
            
        }
    }
    
    func save(taskName: String, compliition: (Task) -> Void) {
        guard let entityDescription = NSEntityDescription.entity(forEntityName: "Task",
                                                                 in: context) else { return }
        guard let task = NSManagedObject(entity: entityDescription,
                                         insertInto: context) as? Task else { return }
        task.title = taskName
        compliition(task)
        saveContext()
    }
    
    func updateTask(task: Task, newTaskName: String) {
        task.title = newTaskName
        saveContext()
    }
    
    func delete(task: Task) {
        context.delete(task)
        saveContext()
    }
    
    // MARK: - Core Data Saving support
    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}

