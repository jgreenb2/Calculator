//
//  GraphingCalculatorViewController.swift
//  Calculator
//
//  Created by Jeff Greenberg on 6/13/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

class GraphingCalculatorViewController: CalculatorViewController {

    
    private struct Segues {
        static let segueToGraph = "Show Graph"
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        var destination = segue.destinationViewController as? UIViewController
        if let navController = destination as? UINavigationController {
            destination = navController.visibleViewController
        }
        if let graphViewController = destination as? GraphViewController {
            if let identifier = segue.identifier {
                switch identifier {
                case Segues.segueToGraph:
                    graphViewController.program = brain.program

                default: break
                }

            }
        }
    }
    


}
