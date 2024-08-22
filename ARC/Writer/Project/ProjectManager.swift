//
//  ProjectManager.swift
//  ARC
//
//  Created by Tobias Schwandt on 16.05.22.
//

import Foundation
import UIKit

class ProjectManager {
    
    static let shared = ProjectManager()
    
    var projects: [Project] = []
    
    private var documents: URL!
    
    private init() {
        documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let resourceKeys : [URLResourceKey] = [.isDirectoryKey]
        
        let enumerator = FileManager.default.enumerator(at: documents,
                                    includingPropertiesForKeys: resourceKeys)!
        
        for case let fileURL as URL in enumerator {
            // Check if it is a directory
            do {
                let ressourceAttributes = try fileURL.resourceValues(forKeys:[.isDirectoryKey])
                
                if (!ressourceAttributes.isDirectory!) {
                    continue
                }
            }
            catch {
                continue
            }
            
            // Load project
            let project:Project? = load(path: fileURL)
            
            if (project != nil) {
                projects.append(project!)
            }
        }
        
        sortProjects()
    }

    func allocate() -> Project? {
        let newProject = Project()
        
        newProject.name = "New recording"
        newProject.numberOfFrames = -1
        newProject.modelName = UIDevice().model
        newProject.viewportSize = UIScreen.main.bounds.size
        
        do {
            try FileManager.default.createDirectory(atPath: newProject.path().path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print(error.localizedDescription)
            return nil
        }
        
        projects.append(newProject)
        
        sortProjects()
        
        return newProject
    }
    
    func remove(project: Project) {
        let index = projects.firstIndex(where: {$0 === project}) ?? nil
        
        if (index == nil) { return }
        
        projects.remove(at: index!)
        
        try? FileManager.default.removeItem(at: project.path())
    }
    
    func save(project: Project) -> Bool {
        // Save project JSON
        let jsonProject = project.toJSONString()
        
        let fileURL = project.path().appendingPathComponent("project.json")
        
        do {
            try jsonProject.write(to: fileURL, atomically: false, encoding: .utf8)
        }
        catch {
            return false
        }
        
        return true
    }
    
    func load(path: URL) -> Project? {
        do {
            let fileURL = path.appendingPathComponent("project.json")
            
            let projectString = try String(contentsOf: fileURL, encoding: .utf8)
            
            let project:Project? = instantiate(jsonString: projectString)
            
            return project
        }
        catch {
            return nil
        }
    }
    
    private func sortProjects() {
        projects.sort { a, b in
            return a.creationDate > b.creationDate
        }
    }
}
