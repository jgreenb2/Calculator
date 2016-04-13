//
//  GlobalUISplitViewController.swift
//  Calculator
//
//  Created by jeff greenberg on 6/17/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//
//
// forces the split view to show the master when collapsed at startup
//
import UIKit

class GlobalUISplitViewController: UISplitViewController, UISplitViewControllerDelegate {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
        // for wide displays we use PrimaryOverlay as the display mode
        //
        // a trivial delay keeps iOS from being confused and issuing an unmatched begin/end
        // transition warning
        if traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Regular {
            delay(0.02){self.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryOverlay}
        }
        //presentsWithGesture = false
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool{
        return true
    }    
}
