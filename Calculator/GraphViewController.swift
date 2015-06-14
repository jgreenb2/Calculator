//
//  GraphViewController.swift
//  Calculator
//
//  Created by Jeff Greenberg on 6/13/15.
//  Copyright (c) 2015 Jeff Greenberg. All rights reserved.
//

import UIKit

class GraphViewController: UIViewController {
    var program: AnyObject? {
        didSet {
            println("program set! \(program)")
        }
    }
    
    @IBOutlet weak var graphView: GraphVIew! {
        didSet {
            
        }
    }
}
