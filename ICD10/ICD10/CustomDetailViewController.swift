//
//  CustomDetailViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 10/19/15.
//  Copyright © 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class CustomDetailViewController: UIViewController {
    
    var dbManager:DatabaseManager!
    var bill:Bill!
    
    @IBOutlet weak var ICD10TextField: UITextField!
    @IBOutlet weak var ICD10DescriptionTextField: UITextField!
    var visitCodeToAddICDTo:String!
    var ICD10ID:Int?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager()
        // Do any additional setup after loading the view.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func addCodeToBill(sender: UIButton) {
        
        if ICD10TextField.text == "" {
            self.showAlert("Error!", msg: "No ICD10 code was detected Please enter an ICD10 code and try again.")
        }
        
        
        var ICD10Description = ""
        if let ICD10DescriptionValid = ICD10DescriptionTextField.text{
            ICD10Description = ICD10DescriptionValid
        }
        
        //save to the database
        dbManager.checkDatabaseFileAndOpen()
        let addICD10Result = dbManager.addICD10ToDatabase(ICD10TextField.text!, icd10Description: ICD10Description)//save ICD10
        _ = dbManager.addUserICD10ToDatabase(ICD10TextField.text!, icd10Description: ICD10Description)//save ICD9
        _ = dbManager.addICD9ToDatabase("")
        _ = dbManager.addUserICD9ToDatabase("")
        let addCharacterizedByResult = dbManager.addCharacterizedByToDatabase(addICD10Result, icd9: "")
        dbManager.closeDB()
        
        if(addICD10Result == -1 || addCharacterizedByResult == -1){
            self.showAlert("Error!", msg: "There was an error saving the ICD10 code. Please check for any errors and try again.")
        }else{
            ICD10ID = addICD10Result
            self.performSegueWithIdentifier("useCustomICD10InBill", sender: self)//perform segue
        }
    }
    
    func showAlert(title:String, msg:String) {
        let controller2 = UIAlertController(title: title,
            message: msg, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Phew!", style: .Cancel, handler: nil)
        controller2.addAction(cancelAction)
        self.presentViewController(controller2, animated: true, completion: nil)
    }
    
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "useCustomICD10InBill" {
            let controller = segue.destinationViewController as! BillViewController
            print(bill)
            
            if let icdCodes  = bill!.codesForBill[bill!.selectedVisitCodeToAddTo!] {
                
                var theICDCodes:[(icd10:String, icd9:String, icd10id:Int, extensionCode:String)] = icdCodes
                
                let tuple = (icd10: ICD10TextField.text!, icd9: "", icd10id: ICD10ID!, extensionCode:"")
                theICDCodes.append(tuple)
                
                bill.codesForBill[bill!.selectedVisitCodeToAddTo!] = theICDCodes                             //put the new icdCodes on at the right position
                controller.bill = self.bill
            }
        }
    }
}