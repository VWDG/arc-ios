//
//  SharingZipViewController.swift
//  ARC
//
//  Created by Tobias Schwandt on 09.09.22.
//

import Foundation
import UIKit
import ZipArchive

class SharingZipViewController : UIViewController {
    @IBOutlet var loadingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var loadingViewDescriptor: UILabel!
    
    var project: Project? = nil
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if project == nil {
            navigationController?.popViewController(animated: true)

            dismiss(animated: true, completion: nil)
            
            return
        }
        
        do {
            let cacheFolder = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            
            // Generate name for archive
            let filename = project!.uuid().replacingOccurrences(of: ":", with: "-")
            
            let zipFile = cacheFolder.appendingPathComponent("\(filename).zip")
            
            // Check if file exist and delete it
            if FileManager.default.fileExists(atPath: zipFile.path) {
                try FileManager.default.removeItem(atPath: zipFile.path)
            }
            
            // Zip project
            SSZipArchive.createZipFile(atPath: zipFile.path, withContentsOfDirectory: (project!.path().path))
            
            // Share new generated file
            let activityVC = UIActivityViewController(activityItems: [ zipFile ], applicationActivities: nil)
            activityVC.popoverPresentationController?.sourceView = self.view
            
            // exclude some activity types from the list (optional)
            // activityViewController.excludedActivityTypes = [ none ]
            
            // On sharing complete we pop this view
            activityVC.completionWithItemsHandler = { activity, success, items, error in
                self.navigationController?.popViewController(animated: true)

                self.dismiss(animated: true, completion: nil)
            }
        
            // Hide indicator and text
            UIView.animate(withDuration: 0.2, delay: 1.5, animations: {
                self.loadingViewDescriptor.alpha = 0
                self.loadingActivityIndicator.alpha = 0
            })

            // Present the share view controller
            self.present(activityVC, animated: true, completion: nil
            )
        }
        catch {
            print (error)
        }
    }
}
