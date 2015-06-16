//
//  EditPatientViewController.swift
//  A class to edit the patient information
//
//  Created by Brandon S Roberts on 6/10/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class EditPatientViewController: UIViewController {
    
    var dbManager:DatabaseManager!
    
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
        dbManager = DatabaseManager()
        
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
            var fullName = "\(firstNameField.text) \(lastNameField.text)"
            self.addPatientToDatabase(fullName, dateOfBirth: dobField.text, email: emailField.text)
        }else{
            self.updatePatient(firstNameField.text, lastName: lastNameField.text, dob: dobField.text, email: emailField.text, id: id)
        }
    }
    
    func addPatientToDatabase(inputPatient:String, dateOfBirth:String, email:String){
        dbManager.checkDatabaseFileAndOpen()
        dbManager.addPatientToDatabase(inputPatient, dateOfBirth: dateOfBirth, email:email)
        dbManager.closeDB()
    }
    
    func updatePatient(firstName:String, lastName:String, dob:String, email:String, id:Int){
        dbManager.checkDatabaseFileAndOpen()
        dbManager.updatePatient(firstName, lastName: lastName, dob: dob, email: email, id: id)
        dbManager.closeDB()
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
