//
//  Bill.swift
//  ICD10
//
//  Created by Administrator on 2/12/16.
//  Copyright © 2016 Brandon S Roberts. All rights reserved.
//

import UIKit

class Bill {
    
    struct CurrentBill{
        //MAKR: - Bill Data
        static var administeringDoctor:String?
        static var icd10On:Bool!
        
        /*
        patientTextField.text = Bill.CurrentBill.textFieldText[0]
        patientDOBTextField.text = Bill.CurrentBill.textFieldText[1]
        doctorTextField.text = Bill.CurrentBill.textFieldText[2]
        siteTextField.text = Bill.CurrentBill.textFieldText[3]
        roomTextField.text = Bill.CurrentBill.textFieldText[4]
        */
        
        static var textFieldText:[String] = ["","","","","", "", ""]                                         //A list of saved items for the bill
        static var codesForBill:[String:[(icd10:String, icd9:String, icd10id:Int, extensionCode:String)]] = [:]
        static var visitCodePriority:[String] = []
        static var modifierCodes:[String:Int] = [:]                                    //visitCode -> modifierCode
        
        
        //MARK: - Optional Data
        static var appointmentID:Int?                                                  //The appointment id if this is a saved bill
        static var billComplete:Bool?
        static var newPatient:String?
        static var newPatientDOB:String?
        static var selectedVisitCodeToAddTo:String?
        static var shouldRemoveBackButton:Bool?
    }
    
}
