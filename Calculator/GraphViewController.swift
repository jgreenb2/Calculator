//
//  GraphViewController.swift
//  Calculator
//
//  Created by Jeff Greenberg on 6/13/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource {
    
    var program: AnyObject? {
        didSet {
            println("program set! \(program)")
        }
    }
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
            graphView.addGestureRecognizer(UIPanGestureRecognizer(target: graphView, action: "moveOrigin:"))
            graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: "scaleGraph:"))
            let tapRecognizer = UITapGestureRecognizer(target: graphView, action: "jumpToOrigin:")
            tapRecognizer.numberOfTapsRequired = 2
            graphView.addGestureRecognizer(tapRecognizer)
        }
    }
    
    func functionValue(sender: GraphView, atXEquals: Double) -> Double? {
        return sin(atXEquals)
    }
}
