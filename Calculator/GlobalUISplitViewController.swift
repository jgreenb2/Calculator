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
        if traitCollection.horizontalSizeClass == UIUserInterfaceSizeClass.regular {
            delay(0.02){self.preferredDisplayMode = UISplitViewControllerDisplayMode.primaryOverlay}
        }
        
        let minimumWidth = min(view.bounds.width,view.bounds.height);
        minimumPrimaryColumnWidth = minimumWidth / 2;
        maximumPrimaryColumnWidth = minimumWidth;
        
    }

    func splitViewController(_ splitViewController: UISplitViewController, collapseSecondary secondaryViewController: UIViewController, onto primaryViewController: UIViewController) -> Bool {
        return true
    }  
    
    func showMaster() {
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: {
            self.preferredDisplayMode = .primaryOverlay
            }, completion: nil)
    }
}



func delay(_ delay:Double, closure:@escaping ()->()) {
   let later = DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
   DispatchQueue.main.asyncAfter(deadline: later, execute: closure)
}
