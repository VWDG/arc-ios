//
//  ProjectOverviewViewController.swift
//  ARC
//
//  Created by Tobias Schwandt on 16.05.22.
//

import Foundation
import UIKit

class ProjectCellController : UITableViewCell, UITextFieldDelegate {
    @IBOutlet var title: UITextField!
    @IBOutlet var date: UILabel!
    @IBOutlet var time: UILabel!
    
    var project: Project? = nil
    var parentVC: UIViewController? = nil
    
    override class func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @IBAction func changedProjectName(_ sender: UITextField) {
        if project != nil {
            project?.name = sender.text ?? "Unnamed project"
            
            _ = ProjectManager.shared.save(project: project!)
        }
    }
    
    // MARK: - TextField Delegates
    func textFieldShouldReturn(_ textField: UITextField) -> Bool // called when 'return' key pressed. return NO to ignore.
    {
        textField.resignFirstResponder()
        return true;
    }
}

class ProjectOverviewController : UITableViewController, RecordViewControllerDelegate {
    override func viewDidLoad() {
        super.viewDidLoad();
    }
    
    override func viewDidAppear(_ animated: Bool) {
        tableView.beginUpdates()
        tableView.endUpdates()
    }
    
    // MARK: - Record view behavior
    @IBAction func presentARView(_ sender: Any) {
        let nextView = storyboard?.instantiateViewController(withIdentifier: "RecordViewController") as? RecordViewController
        
        nextView?.delegate = self
        
        nextView?.modalPresentationStyle = .automatic
        
        self.present(nextView!, animated: true)
    }
    
    func didDismissViewController(vc: UIViewController?) {
        tableView.reloadData()
    }
    
    // MARK: - TableView Delegates
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ProjectManager.shared.projects.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProjectCell", for: indexPath) as! ProjectCellController
        
        let project = ProjectManager.shared.projects[indexPath.row]
        
        let dateFormatter = DateFormatter()
        
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        cell.project = project
        
        cell.parentVC = self
        
        cell.title.delegate = cell
        
        cell.title?.text = project.name
        
        cell.date?.text = dateFormatter.string(from: project.creationDate)
        
        cell.time?.text = Int(roundf(Float((project.numberOfFrames / 60)))).description + " s"
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return nil
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let nextView = storyboard?.instantiateViewController(withIdentifier: "ProjectViewController") as? ProjectViewController
        
        nextView?.relatedProject = ProjectManager.shared.projects[indexPath.row]
        
        nextView?.modalPresentationStyle = .automatic
        
        self.present(nextView!, animated: true)
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteItemAction = UIContextualAction(style: .destructive, title: "Delete", handler: {_,_,_ in
            ProjectManager.shared.remove(project: ProjectManager.shared.projects[indexPath.row])
            
            tableView.deleteRows(at: [indexPath], with: .fade)
        })
        
        let shareItemAction = UIContextualAction(style: .normal, title: "Share", handler: {_,_,_ in
            let project = ProjectManager.shared.projects[indexPath.row]
            
            // Show loading indicator
            let sharingZipVC = self.storyboard?.instantiateViewController(withIdentifier: "SharingZipViewController") as? SharingZipViewController
            
            sharingZipVC!.project = project

            sharingZipVC!.modalPresentationStyle = .overCurrentContext

            sharingZipVC!.modalTransitionStyle = .crossDissolve
                   
            self.present(sharingZipVC!, animated: true, completion: nil)
        })
        
        let swipeActions = UISwipeActionsConfiguration(actions: [deleteItemAction, shareItemAction])
        
        return swipeActions
    }
}
