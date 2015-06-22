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
            controller.administeringDoctor = self.billViewController?.administeringDoctor
            controller.icd10On = self.billViewController?.icd10On
        }
    }
    
    @IBAction func addToFavorites(sender: UIButton) {
        dbManager.checkDatabaseFileAndOpen()
        var lID = 0
        
        let newLocationQuery = "Insert INTO Condition_location (LID, location_name) VALUES (NULL, '\(conditionDescriptionText)')"
        var statement:COpaquePointer = nil
        if sqlite3_prepare_v2(dbManager.db, newLocationQuery, -1, &statement, nil) == SQLITE_OK {
            var result = sqlite3_step(statement)
            if result == SQLITE_DONE {
                println("Successfully created location for \(ICD10Text) \(conditionDescriptionText)")
                lID = Int(sqlite3_last_insert_rowid(dbManager.db))
                println("LID \(lID)")
            }else {
                println("Failed location creation for \(ICD10Text) with error \(result)")
            }
        }
        sqlite3_finalize(statement)
        
        let subLocationQuery = "INSERT INTO Sub_location (LID, parent_locationID) VALUES (\(lID), 0)" //link it to favorites
        var subLocationStatement:COpaquePointer = nil
        if sqlite3_prepare_v2(dbManager.db, subLocationQuery, -1, &subLocationStatement, nil) == SQLITE_OK {
            var result = sqlite3_step(subLocationStatement)
            if result == SQLITE_DONE {
                println("Successfully saved sub location for \(lID) and 0")
            }else {
                println("Failed sublocation save \(ICD10Text) with error \(result)")
            }
        }
        sqlite3_finalize(subLocationStatement)

        let favoriteQuery = "INSERT INTO Located_in (ICD10_code, LID) VALUES ('\(ICD10Text)', \(lID))"
        var favoriteStatement:COpaquePointer = nil
        if sqlite3_prepare_v2(dbManager.db, favoriteQuery, -1, &favoriteStatement, nil) == SQLITE_OK {
            var result = sqlite3_step(favoriteStatement)
            if result == SQLITE_DONE {
                println("Successfully saved \(ICD10Text) with lid: \(lID)")
            }else {
                println("Failed save \(ICD10Text) with error \(result)")
            }
        }
        sqlite3_finalize(favoriteStatement)
        dbManager.closeDB()
    }
    
    
    //MARK: Picker Data source methods
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int { return 1 }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { return extensionCodes.count }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! { return extensionCodes[row] }
    
}

