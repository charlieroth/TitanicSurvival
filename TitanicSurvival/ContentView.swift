//
//  ContentView.swift
//  TitanicSurvival
//
//  Created by Charles Roth on 2024-05-25.
//

import SwiftUI
import CoreML

actor TitanicSurvivalService {
    var model: TitanicSurvivalClassifier
    
    init(model: TitanicSurvivalClassifier) {
        self.model = model
    }
    
    func predict(input: TitanicSurvivalClassifierInput) async throws -> TitanicSurvivalClassifierOutput? {
        let hasNeuralEngine = MLModel.availableComputeDevices.contains { device in
            switch device {
            case .neuralEngine:
                return true
            default:
                return false
            }
        }
        
        if hasNeuralEngine {
            let output = try await model.prediction(input: input)
            return output
        }
        
        return nil
    }
}

enum PassengerGender: String, CaseIterable, Identifiable {
    case man = "male"
    case woman = "female"
    
    var id: Self { self }
}

enum TicketClass: Int, CaseIterable, Identifiable {
    case first = 1
    case second = 2
    case third = 3
    
    var id: Self { self }
}

enum PortOfEmbarkation: String, CaseIterable, Identifiable {
    // C = Cherbourg, Q = Queenstown, S = Southampton
    case Cherbourg = "C"
    case Queenstown = "Q"
    case Southampton = "S"
    
    var id: Self { self }
}

struct FailureDetails: Identifiable {
    let id = UUID()
    var message: String
}

struct ContentView: View {
    var titanicSurvivalService: TitanicSurvivalService?
    
    @State private var failure: Bool = false
    @State private var failureDetails: FailureDetails?
    
    @State private var survivalPrediction: String?
    @State private var survivalPredictionCertainty: Double?
    
    // Pclass
    @State private var selectedTicketClass: TicketClass = .first
    // Sex
    @State private var selectedGender: PassengerGender = .man
    // Age
    @State private var age: Double = 25.0
    @State private var editingAge: Bool = false
    // SibSp
    @State private var numSibilingsAndSpouses: Double = 1.0
    @State private var editingNumSibilingsAndSpouses: Bool = false
    // Parch
    @State private var numParentsAndChildren: Double = 1.0
    @State private var editingNumParentsAndChildren: Bool = false
    // Fare
    @State private var ticketPrice: Double = 32.0
    @State private var editingTicketPrice: Bool = false
    // Embarked
    @State private var selectedPortOfEmbarkation: PortOfEmbarkation = .Cherbourg
    
    init() {
        do {
            let model = try TitanicSurvivalClassifier(configuration: MLModelConfiguration())
            self.titanicSurvivalService = TitanicSurvivalService(
                model: model
            )
        } catch {
            failure = true
            failureDetails = FailureDetails(message: "Failed to initialize prediction model")
        }
    }
    
    var body: some View {
        NavigationStack {
            
            Form {
                Section {
                    Picker("Ticket Class", selection: $selectedTicketClass) {
                        Text("1st (Upper Class)").tag(TicketClass.first)
                        Text("2nd (Middle Class)").tag(TicketClass.second)
                        Text("3 (Lower Class)").tag(TicketClass.third)
                    }
                }
                Section {
                    Picker("Gender", selection: $selectedGender) {
                        Text("Man").tag(PassengerGender.man)
                        Text("Woman").tag(PassengerGender.woman)
                    }
                }
                Section {
                    Picker("Port of Embarkation", selection: $selectedPortOfEmbarkation) {
                        Text("Cherbourg").tag(PortOfEmbarkation.Cherbourg)
                        Text("Queenstown").tag(PortOfEmbarkation.Queenstown)
                        Text("Southampton").tag(PortOfEmbarkation.Southampton)
                    }
                }
                Section {
                    Slider(
                        value: $age,
                        in: 0...80,
                        step: 0.5
                    ) {
                        Text("Age")
                    } minimumValueLabel: {
                        Text("1")
                    } maximumValueLabel: {
                        Text("100")
                    } onEditingChanged: { editing in
                        editingAge = editing
                    }
                    
                    Text("\(age, specifier: "%.1f")")
                        .foregroundColor(editingAge ? .red : .blue)
                }
                Section {
                    Slider(
                        value: $numSibilingsAndSpouses,
                        in: 0...8,
                        step: 1
                    ) {
                        Text("Siblings/Spouses on Board")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("8")
                    } onEditingChanged: { editing in
                        editingNumSibilingsAndSpouses = editing
                    }
                    
                    Text("\(numSibilingsAndSpouses, specifier: "%.0f")")
                        .foregroundColor(editingNumSibilingsAndSpouses ? .red : .blue)
                }
                Section {
                    Slider(
                        value: $numParentsAndChildren,
                        in: 0...6,
                        step: 1
                    ) {
                        Text("Parents/Children on Board")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("6")
                    } onEditingChanged: { editing in
                        editingNumParentsAndChildren = editing
                    }
                    
                    Text("\(numSibilingsAndSpouses, specifier: "%.0f")")
                        .foregroundColor(editingNumParentsAndChildren ? .red : .blue)
                }
                Section {
                    Slider(
                        value: $ticketPrice,
                        in: 0...512,
                        step: 0.5
                    ) {
                        Text("Ticket Price")
                    } minimumValueLabel: {
                        Text("0")
                    } maximumValueLabel: {
                        Text("512")
                    } onEditingChanged: { editing in
                        editingTicketPrice = editing
                    }
                    
                    Text("\(ticketPrice, specifier: "%.0f")")
                        .foregroundColor(editingTicketPrice ? .red : .blue)
                }
                Button {
                    Task {
                        try await makePrediction()
                    }
                } label: {
                    Text("Predict Survival")
                }
                
                if survivalPrediction != nil {
                    Text("Prediction: \(survivalPrediction!)")
                }
                
                if survivalPredictionCertainty != nil {
                    Text("Prediction Certainty: \(survivalPredictionCertainty!)")
                }
            }
            .navigationTitle("Titanic - Machine Learning from Disaster")
            .alert(
                "Something Went Wrong",
                isPresented: $failure,
                presenting: failureDetails
            ) { details in
                Button(role: .cancel, action: {
                    failure = false
                    failureDetails = nil
                }) {
                    Text("Close")
                }
            } message: { details in
                Text(details.message)
            }

        }
        .padding(100)
    }
    
    func makePrediction() async throws {
        let input = TitanicSurvivalClassifierInput(
            Pclass: Int64(selectedTicketClass.rawValue),
            Sex: selectedGender.rawValue,
            Age: age,
            SibSp: Int64(numSibilingsAndSpouses),
            Parch: Int64(numParentsAndChildren),
            Fare: ticketPrice,
            Embarked: selectedPortOfEmbarkation.rawValue
        )
        
        let output = try await titanicSurvivalService?.predict(input: input)
        
        guard let predictionOutput = output else {
            failure = true
            failureDetails = FailureDetails(message: "Device must have Neural Engine for prediction")
            return
        }
        
        if predictionOutput.Survived == 0 {
            survivalPrediction = "Survive"
            survivalPredictionCertainty = predictionOutput.SurvivedProbability[0]
        } else {
            survivalPrediction = "Does not survive"
            survivalPredictionCertainty = predictionOutput.SurvivedProbability[1]
        }
    }
}

#Preview {
    ContentView()
}
