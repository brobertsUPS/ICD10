//
//  EditPatientViewController.swift
//  A class to edit the patient information
//
//  Created by Brandon S Roberts on 6/10/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class EditPatientViewController: UIViewController {
    
    var database:COpaquePointer = nil
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var dobField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    var firstName:String = ""
    var lastName:String = ""
    var dob:String = ""
    var email:String = ""
    var id:Int!
    var newPatient:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        var dbManager = DatabaseManager()
        database = dbManager.checkDatabaseFileAndOpen()
        
        firstNameField.text = firstName
        lastNameField.text = lastName
        dobField.text = dob
        emailField.text = email
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func savePatientInfo(sender: UIButton) {
        
        if newPatient {
            let query = "INSERT INTO Patient (pID,date_of_birth,f_name,l_name, email) VALUES (NULL, '\(dobField.text)', '\(firstNameField.text)', '\(lastNameField.text)', '\(emailField.text)')"
            var statement:COpaquePointer = nil
            if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_step(statement)
                //popup saying it worked
                println("Added \(firstNameField.text)")
            }
        }else{
            //save all info to the database
            let query = "UPDATE Patient SET date_of_birth='\(dobField.text)', f_name='\(firstNameField.text)', l_name='\(lastNameField.text)', email='\(emailField.text)' WHERE pID='\(id)';"
            
            var statement:COpaquePointer = nil
            println("Selected")
            if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
                sqlite3_step(statement)
                //popup saying it worked
                println("GOOD")
            }
        }
    }
    
    /**
    *   Registers clicking return and resigns the keyboard
    **/
    @IBAction func textFieldDoneEditing(sender:UITextField){
        sender.resignFirstResponder()
    }
    
    /**
    *   Registers clicking the background and resigns any responder that could possibly be up
    **/
    @IBAction func backgroundTap(sender: UIControl){
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
