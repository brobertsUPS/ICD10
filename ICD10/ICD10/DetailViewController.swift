/*
//  DetailViewController.swift
//  A class to represent the medical codes (ICD10 and ICD9) and a description of the condition
//
//  Created by Brandon S Roberts on 5/28/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
*/

import UIKit

class DetailViewController: UIViewController {

    var database:COpaquePointer!
    var billViewController:BillViewController?     //A bill that is passed along to hold all of the codes for the final bill
    
    @IBOutlet weak var detailDescriptionLabel: UILabel! //Labels for the codes (update these when the view is loaded)
    @IBOutlet weak var ICD10Code: UILabel! 
    @IBOutlet weak var ICD9Code: UILabel!
    @IBOutlet weak var conditionDescription: UILabel!
    
    var ICD10Text:String!                               //Variables to update the labels with (set these before the view is loaded)
    var ICD9Text:String!
    var conditionDescriptionText:String!
    var titleName:String!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.resignFirstResponder()
        
        var databaseManager = DatabaseManager()
        database = databaseManager.checkDatabaseFileAndOpen()
        
        ICD10Code.text = self.ICD10Text
        ICD9Code.text = self.ICD9Text
        conditionDescription.text = self.conditionDescriptionText
        self.navigationItem.title = titleName
        self.navigationItem.leftItemsSupplementBackButton = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    /**
    *   Fill the text fields with the current information we have and pass them along
    **/
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "verifyBill" {
            var controller = segue.destinationViewController as! BillViewController
            
            controller.textFieldText.append(self.billViewController!.patientTextField!.text!)
            controller.textFieldText.append(self.billViewController!.patientDOBTextField!.text!)
            controller.textFieldText.append(self.billViewController!.doctorTextField!.text!)
            controller.textFieldText.append(self.billViewController!.siteTextField!.text!)
            controller.textFieldText.append(self.billViewController!.roomTextField!.text!)
            controller.textFieldText.append(self.billViewController!.cptTextField!.text!)
            controller.textFieldText.append(self.billViewController!.mcTextField!.text!)
            controller.textFieldText.append(self.billViewController!.pcTextField!.text!)
            
            controller.icdCodes = self.billViewController!.icdCodes //carry the codes
            
            
            let tuple = (icd10: ICD10Text!,icd9: ICD9Text!)
            controller.icdCodes.append(tuple)
        }
    }
}

