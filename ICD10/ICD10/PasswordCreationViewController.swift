//
//  PasswordCreationViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 7/21/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class PasswordCreationViewController: UIViewController {
    
    
    @IBOutlet weak var passWordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!
    
    var dbManager:DatabaseManager!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        dbManager = DatabaseManager()
        
        passWordTextField.secureTextEntry = true
        confirmPasswordTextField.secureTextEntry = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func savePasswordAndStart(sender: UIButton) {
        
        if passWordTextField.text == confirmPasswordTextField.text {
            //set password for database 
            self.performSegueWithIdentifier("enterPassword", sender: self)
        }else {
            self.showAlert("The passwords entered did not match. Please enter your passwords again")
        }
    }

    func showAlert(msg:String) {
        let controller2 = UIAlertController(title: msg,
            message: "", preferredStyle: .Alert)
        let cancelAction = UIAlertAction(title: "Ok", style: .Cancel, handler: nil)
        controller2.addAction(cancelAction)
        self.presentViewController(controller2, animated: true, completion: nil)
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "enterPassword" {
            let controller = segue.destinationViewController as! EnterPasswordViewController
            
        }
    }
    

}
