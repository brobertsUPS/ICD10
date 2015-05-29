//
//  DetailViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 5/28/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var ICD10Code: UILabel! 
    @IBOutlet weak var ICD9Code: UILabel!
    @IBOutlet weak var conditionDescription: UILabel!
    
    var ICD10Text:String!
    var ICD9Text:String!
    var conditionDescriptionText:String!


    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail: AnyObject = self.detailItem {
            if let label = self.detailDescriptionLabel {
                label.text = detail.description
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        ICD10Code.text = self.ICD10Text
        ICD9Code.text = self.ICD9Text
        conditionDescription.text = self.conditionDescriptionText
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

