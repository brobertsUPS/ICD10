//
//  EditDoctorViewController.swift
//  A class to edit the doctor information and save it
//
//  Created by Brandon S Roberts on 6/10/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class EditDoctorViewController: UIViewController {

    var dbManager:DatabaseManager!
    
    @IBOutlet weak var firstNameField: UITextField!
    @IBOutlet weak var lastNameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    
    var firstName:String = ""
    var lastName:String = ""
    var email:String = ""
    var id:Int!
    
    var newDoctor = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager()
        
        firstNameField.text = firstName
        lastNameField.text = lastName
        emailField.text = email
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func saveDoctorInfo(sender: UIButton) {
        
        if newDoctor {
            showAlert(self.addDoctorToDatabase(firstNameField.text, lastName: lastNameField.text, email: emailField.text))
        }else{
            showAlert(self.updateDoctor(firstNameField.text, lastName: lastNameField.text, email: emailField.text, id: id))
        }
    }
    
    func addDoctorToDatabase(firstName:String, lastName:String, email:String) -> String {
        var fullName = "\(firstName) \(lastName)"
        dbManager.checkDatabaseFileAndOpen()
        var result = dbManager.addDoctorToDatabase(fullName, email: email)
        dbManager.closeDB()
        return result
    }
    
    func updateDoctor(firstName:String, lastName:String, email:String, id:Int) -> String{
        dbManager.checkDatabaseFileAndOpen()
        var result = dbManager.updateDoctor(firstName, lastName: lastName, email: email, id: id)
        dbManager.closeDB()
        return result
    }
    
    func showAlert(msg:String) {
        let controller2 = UIAlertController(title: msg,
            message: "", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Phew!", style: .Cancel, handler: nil)
        controller2.addAction(cancelAction)
        self.presentViewController(controller2, animated: true, completion: nil)
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
