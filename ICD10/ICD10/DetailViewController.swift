/*
//  DetailViewController.swift
//  A class to represent the medical codes (ICD10 and ICD9) and a description of the condition
//
//  Created by Brandon S Roberts on 5/28/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
*/

import UIKit

class DetailViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    var dbManager:DatabaseManager!

    var billViewController:BillViewController?     //A bill that is passed along to hold all of the codes for the final bill
    
    @IBOutlet weak var detailDescriptionLabel: UILabel! //Labels for the codes (update these when the view is loaded)
    @IBOutlet weak var ICD10Code: UILabel! 
    @IBOutlet weak var ICD9Code: UILabel!
    @IBOutlet weak var conditionDescription: UILabel!
    
    var ICD10Text:String!                               //Variables to update the labels with (set these before the view is loaded)
    var ICD9Text:String!
    var conditionDescriptionText:String!
    var titleName:String!
    
    var extensionCodes:[String] = []
    
    @IBOutlet weak var extensionPicker: UIPickerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.resignFirstResponder()
        dbManager = DatabaseManager()
        
        extensionCodes = getExtensionCodes()
        
        
        ICD10Code.text = self.ICD10Text
        ICD9Code.text = self.ICD9Text
        conditionDescription.text = self.conditionDescriptionText
        
        println("ICD10Text \(ICD10Text)")
        self.navigationItem.title = titleName
        self.navigationItem.leftItemsSupplementBackButton = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func getExtensionCodes() -> [String]{
        
        var extensions:[String] = []
        dbManager.checkDatabaseFileAndOpen()
        
        let extensionQuery = "SELECT Extension_code FROM Extension WHERE ICD10_code='\(ICD10Text)'"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(dbManager.db, extensionQuery, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var extensionCode = sqlite3_column_text(statement, 0)
                var extensionCodeString = String.fromCString(UnsafePointer<CChar>(extensionCode))
                extensions.append(extensionCodeString!)
            }
        }
        
        sqlite3_finalize(statement)
        dbManager.closeDB()
        return extensions
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "verifyBill" {
            
            var controller = segue.destinationViewController as! BillViewController
            
            controller.textFieldText.append(self.billViewController!.patientTextField!.text!)
            controller.textFieldText.append(self.billViewController!.patientDOBTextField!.text!)
            controller.textFieldText.append(self.billViewController!.doctorTextField!.text!)
            controller.textFieldText.append(self.billViewController!.siteTextField!.text!)
            controller.textFieldText.append(self.billViewController!.roomTextField!.text!)
            
            controller.cptCodes = self.billViewController!.cptCodes
            controller.mcCodes = self.billViewController!.mcCodes
            controller.pcCodes = self.billViewController!.pcCodes
            
            controller.icdCodes = self.billViewController!.icdCodes //carry the codes
            
            
            let tuple = (icd10: ICD10Text!,icd9: ICD9Text!)
            controller.icdCodes.append(tuple)
            controller.administeringDoctor = self.billViewController?.administeringDoctor
            controller.icd10On = self.billViewController?.icd10On
        }
    }
    
    //MARK: Picker Data source methods
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int { return 1 }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return extensionCodes.count }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! { return extensionCodes[row] }
    
}

