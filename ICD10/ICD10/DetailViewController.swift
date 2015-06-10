//
//  DetailViewController.swift
//  ICD10
//
//  Created by Brandon S Roberts on 5/28/15.
//  Copyright (c) 2015 Brandon S Roberts. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {

    var billViewController:BillViewController? = nil
    
    @IBOutlet weak var detailDescriptionLabel: UILabel!
    @IBOutlet weak var ICD10Code: UILabel! 
    @IBOutlet weak var ICD9Code: UILabel!
    @IBOutlet weak var conditionDescription: UILabel!
    
    var ICD10Text:String!
    var ICD9Text:String!
    var conditionDescriptionText:String!
    var titleName:String!


    var detailItem: AnyObject? {
        didSet {
            // Update the view.
            self.configureView()
        }
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let detail: AnyObject = self.detailItem {
            if let label = self.ICD10Code {
                label.text = ICD10Text
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        ICD10Code.text = self.ICD10Text
        ICD9Code.text = self.ICD9Text
        conditionDescription.text = self.conditionDescriptionText
        self.navigationItem.title = titleName
        println("Title name is \(titleName)")
        self.navigationItem.leftItemsSupplementBackButton = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    /*
@IBOutlet weak var patientTextField: UITextField!
@IBOutlet weak var patientDOBTextField: UITextField!
@IBOutlet weak var doctorTextField: UITextField!
@IBOutlet weak var siteTextField: UITextField!
@IBOutlet weak var roomTextField: UITextField!
@IBOutlet weak var cptTextField: UITextField!
@IBOutlet weak var mcTextField: UITextField!
@IBOutlet weak var pcTextField: UITextField!
@IBOutlet weak var ICD10TextField: UITextField!
*/
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "verifyBill" {
            let controller = segue.destinationViewController as! BillViewController
            
            controller.textFieldText.append(self.billViewController!.patientTextField!.text!)
            controller.textFieldText.append(self.billViewController!.patientDOBTextField!.text!)
            controller.textFieldText.append(self.billViewController!.doctorTextField!.text!)
            controller.textFieldText.append(self.billViewController!.siteTextField!.text!)
            controller.textFieldText.append(self.billViewController!.roomTextField!.text!)
            controller.textFieldText.append(self.billViewController!.cptTextField!.text!)
            controller.textFieldText.append(self.billViewController!.mcTextField!.text!)
            controller.textFieldText.append(self.billViewController!.pcTextField!.text!)
            controller.textFieldText.append(ICD10Text!)
        }
    }


    @IBAction func findPreviousBill(sender: UIButton) {
        println("Find previous bill")
        if let controllers = self.navigationController!.viewControllers {
            println("View controllers found")
            for controller in controllers {
                var controllerIsBillViewController = controller.isKindOfClass(BillViewController)
                println("Is billViewController? \(controllerIsBillViewController)")
                if let masterviewController  =  controller as? BillViewController{ //found the navigation controller we are looking for
                    println("Found the view controller")
                }
            }
        }
    }
}

