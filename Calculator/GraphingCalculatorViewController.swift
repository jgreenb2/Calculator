//
//  GraphingCalculatorViewController.swift
//  Calculator
//
//  Created by Jeff Greenberg on 6/13/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit
import Foundation

class GraphingCalculatorViewController: CalculatorViewController {

    private struct Segues {
        static let segueToGraph = "Show Graph"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        var destination = segue.destination as UIViewController
        if let navController = destination as? UINavigationController {
            destination = navController.visibleViewController!
        }
        if let graphViewController = destination as? GraphViewController {
            if let identifier = segue.identifier {
                switch identifier {
                case Segues.segueToGraph:
                    graphViewController.graphBrain.program = brain.program
                    graphViewController.graphBrain.degMode(brain.degMode)
                    var infixRep = graphViewController.graphBrain.description
                    let lastComma = infixRep.range(of: ",", options: NSString.CompareOptions.backwards)
                    if let lastCommaIndex = lastComma?.upperBound {
                        infixRep = infixRep.substring(from: lastCommaIndex)
                    }
                    graphViewController.title = infixRep

                default: break
                }
            }
        }
    }
    


}
