//
//  Constants.swift
//  CareKit Demo
//
//  Created by devansh.vyas on 06/07/18.
//  Copyright © 2018 Solution Analysts. All rights reserved.
//

import UIKit

struct TabBarConstants {
  
  //MARK: Main
  let carePlanStorePathComponent = "carePlanStore"
  let careCardVCTitle = "Care"
  let symtomsTrackerVCTitle = "Symtoms Tracker"
  let startYear = 2018
  let startMonth = 6
  let startDay = 1
  let dailyTaskOccurrence = UInt(1)
  
  //MARK: Interventions
  let waterTaskOccurrence = UInt(8)
  let waterTaskId = "WaterIntervention"
  let waterTaskTitle = "Water:"
  let waterTaskText = "You should intake atleast 8 glass of Water per Day"
  let waterTaskTintColor = UIColor.blue
  
  let exerciseTaskOccurrence = UInt(2)
  let exerciseTaskId = "ExerciseIntervention"
  let exerciseTaskTitle = "Exercise:"
  let exerciseTaskText = "You should do atleast 2 times exercise per Day"
  let exerciseTaskTintColor = UIColor.cyan

  //MARK: Assessment
  let sleepTaskId = "SleepAssessment"
  let sleepTaskTitle = "Sleep:"
  let sleepTaskText = "Amount of sleep you take?"
  let sleepTaskTintColor = UIColor.green
  
  let weightTaskId = "WeightAssessment"
  let weightTaskTitle = "Weight:"
  let weightTaskText = "Your Current Weight?1"
  let weightTaskTintColor = UIColor.orange

  //MARK: Alert
  let doneActionTitle = "Done"
  let cancelAlertTitle = "Cancel"
  
  let sleepAlertTitle = "Sleep"
  let sleepAlertMessage = "Amount of sleep(in HRs):"
  let sleepUnit = "Hrs"

  let weightAlertTitle = "Weight"
  let weightAlertMessage = "Current weight(in Kg):"
  let weightUnit = "Kgs"

  //MARK: Insights
  let insightVCTitle = "Insights"
}

