//
//  TabBarController.swift
//  CareKit Demo
//
//  Created by devansh.vyas on 06/07/18.
//  Copyright © 2018 Solution Analysts. All rights reserved.
//

import UIKit
import CareKit

class TabBarController: UITabBarController {

  //MARK: variables
  let obj = TabBarConstants()
  
  lazy var carePlanStore: OCKCarePlanStore = {
    let fileManager = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    let urlPath = fileManager[0].appendingPathComponent(obj.carePlanStorePathComponent)
    print(urlPath)
    if !FileManager.default.fileExists(atPath: "\(urlPath)"){
      try! FileManager.default.createDirectory(at: urlPath, withIntermediateDirectories: true, attributes: nil)
    }
    
    let store = OCKCarePlanStore(persistenceDirectoryURL: urlPath)
    store.delegate = self
    return store
  }()

  let activityStartDate = DateComponents(year: TabBarConstants().startYear , month: TabBarConstants().startMonth, day: TabBarConstants().startDay)
  let calendar = Calendar(identifier: .gregorian)
  
  var insights: OCKInsightsViewController!
  var insightItems = [OCKInsightItem](){
    didSet{
      insights.items = insightItems
    }
  }
  
  //MARK: LifeCycle Methods
  override func viewDidLoad() {
    super.viewDidLoad()
    let careCardVC = OCKCareCardViewController(carePlanStore: carePlanStore)
    careCardVC.title = obj.careCardVCTitle
    
    let symtomsTrackerVC = OCKSymptomTrackerViewController(carePlanStore: carePlanStore)
    symtomsTrackerVC.title = obj.symtomsTrackerVCTitle
    symtomsTrackerVC.delegate = self
    
    let insightVC = OCKInsightsViewController(insightItems: insightItems)
    insightVC.title = obj.insightVCTitle
    updateInsights()
    
    viewControllers = [UINavigationController(rootViewController: careCardVC), UINavigationController(rootViewController: symtomsTrackerVC), UINavigationController(rootViewController: insightVC)]
    
    addActivity()
  }
  
  //MARK: Interventions
  func interventions() -> [OCKCarePlanActivity]{
    let waterSchedule = OCKCareSchedule.dailySchedule(withStartDate: activityStartDate, occurrencesPerDay: obj.waterTaskOccurrence)
    let waterIntervention = OCKCarePlanActivity(identifier: obj.waterTaskId, groupIdentifier: nil, type: .intervention, title: obj.waterTaskTitle, text: obj.waterTaskText, tintColor: obj.waterTaskTintColor, instructions: nil, imageURL: nil, schedule: waterSchedule, resultResettable: true, userInfo: nil)
    let exerciseSchedule = OCKCareSchedule.dailySchedule(withStartDate: activityStartDate, occurrencesPerDay: obj.exerciseTaskOccurrence)
    let exerciseInterventions = OCKCarePlanActivity(identifier: obj.exerciseTaskId, groupIdentifier: nil, type: .intervention, title: obj.exerciseTaskTitle, text: obj.exerciseTaskText, tintColor: obj.exerciseTaskTintColor, instructions: nil, imageURL: nil, schedule: exerciseSchedule, resultResettable: true, userInfo: nil)
    return [waterIntervention,exerciseInterventions]
  }

  //MARK: Assessments
  func assessments() -> [OCKCarePlanActivity]{
    let dailySchedule = OCKCareSchedule.dailySchedule(withStartDate: activityStartDate, occurrencesPerDay: obj.dailyTaskOccurrence)
    let sleepAssessment = OCKCarePlanActivity(identifier: obj.sleepTaskId, groupIdentifier: nil, type: .assessment, title: obj.sleepTaskTitle, text: obj.sleepTaskText, tintColor: obj.sleepTaskTintColor, instructions: nil, imageURL: nil, schedule: dailySchedule, resultResettable: true, userInfo: nil)
    let weightAssessment = OCKCarePlanActivity(identifier: obj.weightTaskId, groupIdentifier: nil, type: .assessment, title: obj.weightTaskTitle, text: obj.weightTaskText, tintColor: obj.weightTaskTintColor, instructions: nil, imageURL: nil, schedule: dailySchedule, resultResettable: true, userInfo: nil)
    return [sleepAssessment,weightAssessment]
  }

  //MARK: adding activities
  func addActivity(){
    carePlanStore.activities { [unowned self](_, activities, error) in
      if let err = error{
        print(err.localizedDescription)
      }
      guard activities.count == 0 else{return}
      
      for activity in self.interventions() + self.assessments(){
        self.carePlanStore.add(activity) { (_, err) in
          guard let errors = err else {return}
          print(errors.localizedDescription)
        }
      }
    }
  }
  
  func updateInsights(){
    insightItems = []
    
    var sleep = [DateComponents: Int]()
    var interventionCompletion = [DateComponents: Int]()
    let activitiesDispatchGroup = DispatchGroup()
    
    activitiesDispatchGroup.enter()
    fetchSleep { sleepDict in
      sleep = sleepDict
      activitiesDispatchGroup.leave()
    }
    
    activitiesDispatchGroup.enter()
    fetchInterventionCompletion { interventionCompletionDict in
      interventionCompletion = interventionCompletionDict
      activitiesDispatchGroup.leave()
    }
  }
  
}


extension TabBarController: OCKSymptomTrackerViewControllerDelegate{
  func symptomTrackerViewController(_ viewController: OCKSymptomTrackerViewController, didSelectRowWithAssessmentEvent assessmentEvent: OCKCarePlanEvent) {
    let alert: UIAlertController
    if assessmentEvent.activity.identifier == obj.sleepTaskId{
      alert = sleepAlert(event: assessmentEvent)
    }
    else if assessmentEvent.activity.identifier == obj.weightTaskId{
      alert = weightAlert(event: assessmentEvent)
    }
    else{
      return
    }
    
    let cancelAction = UIAlertAction(title: obj.cancelAlertTitle, style: .cancel, handler: nil)
    alert.addAction(cancelAction)
    
    present(alert, animated: true, completion: nil)
  }
  
  //MARK: Alerts
  func sleepAlert(event: OCKCarePlanEvent) -> UIAlertController{
    let alert = UIAlertController(title: obj.sleepAlertTitle, message: obj.sleepAlertMessage, preferredStyle: .alert)
    alert.addTextField { UITextField in
      UITextField.keyboardType = .numberPad
    }
    
    let doneAction = UIAlertAction(title: obj.doneActionTitle, style: .default) { _ in
      let sleepFieldText = alert.textFields?[0].text ?? ""
      let result = OCKCarePlanEventResult(valueString: sleepFieldText, unitString: self.obj.sleepUnit, userInfo: nil)
      self.carePlanStore.update(event, with: result, state: .completed, completion: { (_, _, error) in
        guard let err = error else {return}
        print(err.localizedDescription)
      })
    }
    
    alert.addAction(doneAction)
    
    return alert
  }
  
  func weightAlert(event: OCKCarePlanEvent) -> UIAlertController{
    let alert = UIAlertController(title: obj.weightAlertTitle, message: obj.weightAlertMessage, preferredStyle: .alert)
    alert.addTextField { UITextField in
      UITextField.keyboardType = .numberPad
    }
    
    let doneAction = UIAlertAction(title: obj.doneActionTitle, style: .default) { _ in
      let weightFieldText = alert.textFields?[0].text ?? ""
      let result = OCKCarePlanEventResult(valueString: weightFieldText, unitString: self.obj.weightUnit, userInfo: nil)
      self.carePlanStore.update(event, with: result, state: .completed, completion: { (_, _, error) in
        guard let err = error else {return}
        print(err.localizedDescription)
      })
    }
    
    alert.addAction(doneAction)
    
    return alert
  }
  
}

extension TabBarController: OCKCarePlanStoreDelegate{
  func carePlanStore(_ store: OCKCarePlanStore, didReceiveUpdateOf event: OCKCarePlanEvent) {
    updateInsights()
  }
  
  func fetchSleep(_ completion: @escaping ([DateComponents: Int]) -> ()){
    var sleep = [DateComponents: Int]()
    
    let sleepStartDate = calendar.dateComponents([.year,.month,.day], from: calendar.date(byAdding: DateComponents(day: -7), to: Date())!)
    let sleepEndDate = calendar.dateComponents([.year,.month,.day], from: calendar.date(byAdding: DateComponents(day: -1), to: Date())!)
    
    carePlanStore.activity(forIdentifier: obj.sleepTaskId) { (_, activity, error) in
      guard let err = error else{return}
      print(err)
      
      guard let sleepAssessment = activity else {return}
      self.carePlanStore.enumerateEvents(of: sleepAssessment, startDate: sleepStartDate, endDate: sleepEndDate, handler: { (event, _) in
        guard let event = event else {return}
        if let result = event.result{
          sleep[event.date] = Int(result.valueString)
        }
        else{
          sleep[event.date] = 0
        }
      }, completion: { (_, error) in
        if let error = error{
          print(error)
        }
        completion(sleep)
      })
    
    }
  }
  
  func fetchInterventionCompletion(completion: @escaping ([DateComponents: Int]) -> ()) {
    var interventionCompletion = [DateComponents: Int]()
    
    let interventionStartDate = calendar.dateComponents([.year, .month, .day], from: calendar.date(byAdding: DateComponents(day: -7), to: Date())!)
    let interventionEndDate = calendar.dateComponents([.year, .month, .day], from: calendar.date(byAdding: DateComponents(day: -1), to: Date())!)
    
    carePlanStore.dailyCompletionStatus(with: .intervention, startDate: interventionStartDate, endDate: interventionEndDate, handler: { (date, completed, total) in
      interventionCompletion[date] = lround((Double(completed) / Double(total)) * 100)
    }, completion: { (_, error) in
      if let error = error {
        print(error.localizedDescription)
      }
      completion(interventionCompletion)
    })
  }

  func sleepMessage(sleep: [DateComponents: Int]) -> OCKMessageItem? {
    let sleepAverage = Double(sleep.values.reduce(0) { $0 + $1 }) / Double(sleep.count)
    let sleepAverageInt = lround(sleepAverage)
    if sleepAverage < 6 {
      let averageAlert = OCKMessageItem(title: "Sleep More", text: "You only got an average of \(sleepAverageInt) hours of sleep this week.", tintColor: .purple, messageType: .alert)
      return averageAlert
    } else if sleep.values.max()! - sleep.values.min()! >= 3 {
      let consistentAlert = OCKMessageItem(title: "Be More Consistent", text: "Try to get the same amount of sleep each night to stay healthy.", tintColor: .purple, messageType: .alert)
      return consistentAlert
    } else if sleepAverage > 7.5 {
      let averageTip = OCKMessageItem(title: "Maintain Sleep Habits", text: "Nice job getting a lot of sleep last week. Keep it up!", tintColor: .purple, messageType: .tip)
      return averageTip
    }
    return nil
  }

}
