//
//  GraphViewController.swift
//  Calculator
//
//  Created by Jeff Greenberg on 6/13/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController, GraphViewDataSource, UIGestureRecognizerDelegate {
    
    var graphBrain = CalculatorBrain()
    var panGraphRecognizer:UIPanGestureRecognizer?
    var swipeRecognizerRight:UISwipeGestureRecognizer?
    var swipeFromLeftEdge:UIScreenEdgePanGestureRecognizer!
    
    // reset the origin on a layout change
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        graphView.graphOrigin = nil
    }
    
    override func viewDidLoad() {
        let panGraphRecognizer = UIPanGestureRecognizer(target: graphView, action: #selector(graphView.moveOrigin(_:)))
        graphView.addGestureRecognizer(panGraphRecognizer)
        graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: #selector(graphView.scaleGraph(_:))))
        let tapRecognizer = UITapGestureRecognizer(target: graphView, action: #selector(graphView.jumpToOrigin(_:)))
        tapRecognizer.numberOfTapsRequired = 2
        graphView.addGestureRecognizer(tapRecognizer)
        if let svc = splitViewController as? GlobalUISplitViewController {
            swipeFromLeftEdge = UIScreenEdgePanGestureRecognizer(target: svc, action: #selector(svc.showMaster))
            swipeFromLeftEdge.edges = .Left
            graphView.addGestureRecognizer(swipeFromLeftEdge)
        }
        super.viewDidLoad()
    }
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
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
