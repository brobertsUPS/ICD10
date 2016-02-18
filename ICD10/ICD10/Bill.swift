//
//  Bill.swift
//  ICD10
//
//  Created by Administrator on 2/12/16.
//  Copyright © 2016 Brandon S Roberts. All rights reserved.
//

import UIKit

class Bill {
    
    
        //MAKR: - Bill Data
        var administeringDoctor:String?
        var icd10On:Bool!
        
        /*
        patientTextField.text = Bill.CurrentBill.textFieldText[0]
        patientDOBTextField.text = Bill.CurrentBill.textFieldText[1]
        doctorTextField.text = Bill.CurrentBill.textFieldText[2]
        siteTextField.text = Bill.CurrentBill.textFieldText[3]
        roomTextField.text = Bill.CurrentBill.textFieldText[4]
        */
        
        var textFieldText:[String] = ["","","","","", "", ""]                                         //A list of saved items for the bill
        var codesForBill:[String:[(icd10:String, icd9:String, icd10id:Int, extensionCode:String)]] = [:]
        var visitCodePriority:[String] = []
        var modifierCodes:[String:Int] = [:]                                    //visitCode -> modifierCode
        
        
        //MARK: - Optional Data
        var appointmentID:Int?                                                  //The appointment id if this is a saved bill
        var billComplete:Bool?
        var newPatient:String?
        var newPatientDOB:String?
        var selectedVisitCodeToAddTo:String?
        var shouldRemoveBackButton:Bool?
    
}
