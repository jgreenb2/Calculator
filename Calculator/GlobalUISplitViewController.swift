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
        presentsWithGesture = false // MUST be set before splitViewController delegate is set
        
        self.delegate = self
        // for wide displays we use PrimaryOverlay as the display mode
        //
        // a trivial delay keeps iOS from being confused and issuing an unmatched begin/end
        // transition warning
        if traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.Regular {
            delay(0.02){self.preferredDisplayMode = UISplitViewControllerDisplayMode.PrimaryOverlay}
        }
        
        let minimumWidth = min(view.bounds.width,view.bounds.height);
        minimumPrimaryColumnWidth = minimumWidth / 2;
        maximumPrimaryColumnWidth = minimumWidth;
    }
    
    func splitViewController(splitViewController: UISplitViewController, collapseSecondaryViewController secondaryViewController: UIViewController, ontoPrimaryViewController primaryViewController: UIViewController) -> Bool {
        return true
    }  
    
    func showMaster() {
        UIView.animateWithDuration(0.3, delay: 0, options: .CurveEaseOut, animations: {
            self.preferredDisplayMode = .PrimaryOverlay
            }, completion: nil)
    }
}



func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}
