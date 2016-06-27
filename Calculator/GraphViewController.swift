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
    var swipeFromLeftEdge:UIScreenEdgePanGestureRecognizer!
    
    // reset the origin on a layout change
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        graphView.graphOrigin = nil
    }
    
    override func viewDidLoad() {
        // add pan, pinch and tap recognizers
        let panGraphRecognizer = UIPanGestureRecognizer(target: graphView, action: #selector(graphView.moveOrigin(byGesture:)))
        graphView.addGestureRecognizer(panGraphRecognizer)
        graphView.addGestureRecognizer(UIPinchGestureRecognizer(target: graphView, action: #selector(graphView.scaleGraph(byGesture:))))
        let tapRecognizer = UITapGestureRecognizer(target: graphView, action: #selector(graphView.jumpToOrigin(byGesture:)))
        tapRecognizer.numberOfTapsRequired = 2
        graphView.addGestureRecognizer(tapRecognizer)
        
        // set the animator that implements inertial scrolling to use the screen
        // associated with the graphView
        graphView.animator().set(screen: graphView.window?.screen)
        
        // you can reveal the master view by swiping from the left edge...
        if let svc = splitViewController as? GlobalUISplitViewController {
            swipeFromLeftEdge = UIScreenEdgePanGestureRecognizer(target: svc, action: #selector(svc.showMaster))
            swipeFromLeftEdge.edges = .left
            graphView.addGestureRecognizer(swipeFromLeftEdge)
        }
        
        // ...or by using the bar button
        navigationItem.leftBarButtonItem = splitViewController?.displayModeButtonItem()
        navigationItem.leftItemsSupplementBackButton = true
        super.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        graphView.cancelAnimation()
    }
    
    @IBOutlet weak var graphView: GraphView! {
        didSet {
            graphView.dataSource = self
        }
    }
        
    func functionValue(atXEquals x: Double) -> Double? {
        if let result = graphBrain.set(variableName: "M", toValue: x) {
            if result.isNormal || result.isZero {
                return result
            }
        }
        return nil
    }
}
