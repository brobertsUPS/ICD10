//
//  EnterPasswordViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 7/21/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class EnterPasswordViewController: UIViewController {
    
    
    @IBOutlet weak var passwordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func enterApplication(sender: UIButton) {
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        //open with password text field
        //if result is good
            //set pass in app delegate
            self.performSegueWithIdentifier("enterApplication", sender: self)//navigate to app
        //else
            //show alert
    }
    
    @IBAction func changePassword(sender: UIButton) {
        
        //open with password text field
        //if result is good
            self.performSegueWithIdentifier("changePassword", sender: self) //navigate to create password
        //else
            //show alert
        
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
        
        if segue.identifier == "enterApplication" {
            
        }
        
        if segue.identifier == "changePassword" {
            
        }
    }
    

}
