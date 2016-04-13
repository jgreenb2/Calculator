//
//  GraphViewController.swift
//  Calculator
//
//  Created by Jeff Greenberg on 6/13/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource {
    
    var graphBrain = CalculatorBrain()
    
    // reset the origin on a layout change
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        graphView.graphOrigin = nil
    }
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
            graphView.addGestureRecognizer(UIPanGestureRecognizer(target: graphView, action: #selector(graphView.moveOrigin(_:))))
            graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: #selector(graphView.scaleGraph(_:))))
            let tapRecognizer = UITapGestureRecognizer(target: graphView, action: #selector(graphView.jumpToOrigin(_:)))
            tapRecognizer.numberOfTapsRequired = 2
            graphView.addGestureRecognizer(tapRecognizer)
        }
    }
    
    func functionValue(sender: GraphView, atXEquals: Double) -> Double? {
        if let result = graphBrain.setVariable("M", value: atXEquals) {
            if result.isNormal || result.isZero {
                return result
            }
        }
        return nil
    }
}
