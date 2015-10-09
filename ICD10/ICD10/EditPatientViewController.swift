//
//  EditPatientViewController.swift
//  A class to edit the patient information
//
//  Created by Brandon S Roberts on 6/10/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

protocol DidBeginBillWithPatientInformationDelegate {
    func userEnteredPatientInformationForBill(fName:String, lName:String, dateOfBirth:String)
}

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
    
    var beginBillWithPatientInformationDelegate:DidBeginBillWithPatientInformationDelegate? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        dbManager = DatabaseManager()
        
        firstNameField.text = firstName
        lastNameField.text = lastName
        dobField.text = dob
        emailField.text = email
    }
    
    override func viewWillAppear(animated: Bool) {
        
        if (self.tabBarController!.viewControllers!.first! as! UINavigationController).topViewController is AdminDocViewController{
            beginBillWithPatientInformationDelegate = (self.tabBarController!.viewControllers!.first! as! UINavigationController).topViewController as! AdminDocViewController
        }
        
        if (self.tabBarController!.viewControllers!.first! as! UINavigationController).topViewController is BillViewController{
            beginBillWithPatientInformationDelegate = (self.tabBarController!.viewControllers!.first! as! UINavigationController).topViewController as! BillViewController
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func showAlert(msg:String) {
        let controller2 = UIAlertController(title: "",
            message: msg, preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Phew!", style: .Cancel, handler: nil)
        controller2.addAction(cancelAction)
        self.presentViewController(controller2, animated: true, completion: nil)
    }
    
    //MARK: - Patient Database Interaction
    
    @IBAction func savePatientInfo(sender: UIButton) {
        firstName = firstNameField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        lastName = lastNameField.text!.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())

        if newPatient {
            let fullName = firstName + " " + lastName
            showAlert(self.addPatientToDatabase(fullName, dateOfBirth: dobField.text!, email: emailField.text!))
        }else{
            showAlert(self.updatePatient(firstName, lastName: lastName, dob: dobField.text!, email: emailField.text!, id: id))
        }
    }
    
    func addPatientToDatabase(inputPatient:String, dateOfBirth:String, email:String) -> String{
        dbManager.checkDatabaseFileAndOpen()
        let result = dbManager.addPatientToDatabase(inputPatient, dateOfBirth: dateOfBirth, email:email)
        dbManager.closeDB()
        return result
    }
    
    func updatePatient(firstName:String, lastName:String, dob:String, email:String, id:Int) -> String{
        
        dbManager.checkDatabaseFileAndOpen()
        let result = dbManager.updatePatient(firstName, lastName: lastName, dob: dob, email: email, id: id)
        dbManager.closeDB()
        return result
    }
    
    //MARK: - Delegate Tab Change
    
    @IBAction func beginBill(sender: UIButton) {
        self.tabBarController!.selectedIndex = 0;
        if let beginBillDelegate = beginBillWithPatientInformationDelegate {
            beginBillDelegate.userEnteredPatientInformationForBill(firstNameField.text!, lName: lastNameField.text!, dateOfBirth: dobField.text!)
        }
    }
    
    // MARK: - TextBox Interaction
    
    @IBAction func textFieldDoneEditing(sender:UITextField){
        sender.resignFirstResponder()
    }
    
    @IBAction func backgroundTap(sender: UIControl){
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
