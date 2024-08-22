//
//  ProjectViewController.swift
//  ARC
//
//  Created by Tobias Schwandt on 23.05.22.
//

import Foundation
import UIKit
import AVKit

class ProjectViewController : AVPlayerViewController {
    var relatedProject: Project?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
                
        // Load video
        let videoURL = relatedProject!.path().appendingPathComponent("color.mov")
        
        // Play video on start
        self.player = AVPlayer(url: videoURL)
        self.player!.play()
    }
}
