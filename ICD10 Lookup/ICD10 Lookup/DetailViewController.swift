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
    
    @IBOutlet weak var detailDescriptionLabel: UILabel! //Labels for the codes (update these when the view is loaded)
    @IBOutlet weak var ICD10Code: UILabel! 
    @IBOutlet weak var ICD9Code: UILabel!
    @IBOutlet weak var conditionDescription: UILabel!
    @IBOutlet weak var useInBillButton: UIButton!

    
    var ICD10Text:String!                               //Variables to update the labels with (set these before the view is loaded)
    var ICD9Text:String!
    var conditionDescriptionText:String!
    var titleName:String!
    var ICD10ID:Int?
    
    var extensionCodes:[(ExtensionCode:String, ExtensionDescription:String)] = []
    var visitCodeToAddICDTo:String!
    
    @IBOutlet weak var extensionPicker: UIPickerView?

    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.resignFirstResponder()
        dbManager = DatabaseManager()
        if ICD10Text != "" && ICD10Text != nil{
            extensionCodes = getExtensionCodes()
        }
        
        self.extensionPicker!.delegate = self
        self.extensionPicker!.dataSource = self
        
        if extensionCodes.isEmpty {
            self.extensionPicker!.removeFromSuperview()
            self.extensionPicker = nil
        }
        
        ICD10Code.text = self.ICD10Text
        ICD9Code.text = self.ICD9Text
        conditionDescription.text = self.conditionDescriptionText
        
        self.navigationItem.title = titleName
        self.navigationItem.leftItemsSupplementBackButton = true
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Locations", style:.Plain, target:nil, action:nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        println("viewWillAppear")
        self.navigationItem.title = titleName
        self.navigationItem.leftItemsSupplementBackButton = true
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title:"Locations", style:.Plain, target:nil, action:nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func getExtensionCodes() -> [(ExtensionCode:String,ExtensionDescription:String)]{
        
        var extensions:[(ExtensionCode:String,ExtensionDescription:String)] = []
        dbManager.checkDatabaseFileAndOpen()
        let extensionQuery = "SELECT Extension_code, Extension_description FROM Extension WHERE ICD10_ID=\(ICD10ID!)"
        
        var statement:COpaquePointer = nil
        var prepareResult = sqlite3_prepare_v2(dbManager.db, extensionQuery, -1, &statement, nil)
        
        if sqlite3_prepare_v2(dbManager.db, extensionQuery, -1, &statement, nil) == SQLITE_OK {

            while sqlite3_step(statement) == SQLITE_ROW {
                var extensionCode = sqlite3_column_text(statement, 0)
                var extensionCodeString = String.fromCString(UnsafePointer<CChar>(extensionCode))
                
                var extensionDescription = sqlite3_column_text(statement, 1)
                var extensionDescriptionString = String.fromCString(UnsafePointer<CChar>(extensionDescription))
                
                let tuple = (ExtensionCode:extensionCodeString!, ExtensionDescription:extensionDescriptionString!)
                
                extensions.append(tuple)
            }
        }
        
        sqlite3_finalize(statement)
        dbManager.closeDB()
        return extensions
    }
    
    //MARK: - Navigation
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
    }


    //MARK: Picker Data source methods

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int { return 1 }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return extensionCodes.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        var (extensionCode, extensionDescription) = extensionCodes[row]
        return extensionCode + " " + extensionDescription
    }
}