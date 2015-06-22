//
//  AdminDocViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 6/18/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class AdminDocViewController: UIViewController {

    @IBOutlet weak var administeringDoctor: UITextField!
    var dbManager = DatabaseManager()
    
    var adminDoc = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.hidesBackButton = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "beginBill" {
            let controller = segue.destinationViewController as! BillViewController
            controller.administeringDoctor = self.administeringDoctor.text
        }
    }
    

}
