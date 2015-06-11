//
//  EditDoctorViewController.swift
//  A class to edit the doctor information and save it
//
//  Created by Brandon S Roberts on 6/10/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class EditDoctorViewController: UIViewController {

    var database:COpaquePointer = nil
    
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    var firstName:String = ""
    var lastName:String = ""
    var email:String = ""
    var id:Int!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var dbManager = DatabaseManager()
        database = dbManager.checkDatabaseFileAndOpen()
        
        firstNameField.text = firstName
        lastNameField.text = lastName
        emailField.text = email
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveDoctorInfo(sender: UIButton) {
        let query = "UPDATE Doctor SET email='\(emailField.text)', f_name='\(firstNameField.text)', l_name='\(lastNameField.text)' WHERE dID='\(id)';"
        var statement:COpaquePointer = nil
        println("Selected")
        if sqlite3_prepare_v2(database, query, -1, &statement, nil) == SQLITE_OK {
            sqlite3_step(statement)
            //popup saying it worked
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
