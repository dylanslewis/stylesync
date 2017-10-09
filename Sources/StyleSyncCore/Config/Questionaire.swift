//
//  Questionaire.swift
//  StyleSync
//
//  Created by Dylan Lewis on 09/10/2017.
//

import Foundation
import Files

struct Questionaire {
	private var creatable: Creatable
	private var didFinishQuestionaire: (Creatable) -> Void
	
	init(creatable: Creatable, didFinishQuestionaire: @escaping (Creatable) -> Void) {
		self.creatable = creatable
		self.didFinishQuestionaire = didFinishQuestionaire
	}
	
	func startQuestionaire() {
		var creatable: Creatable = self.creatable
		defer {
			didFinishQuestionaire(creatable)
		}

		var nextQuestion: Question? = creatable.firstQuestion
		repeat {
			guard let question = nextQuestion else {
				return
			}
			print(question.question)
			let answer = "./Package.swift" // TODO: get user input
			(creatable, nextQuestion) = question.didAnswerQuestion(answer)
		} while nextQuestion != nil
	}
}

struct Question {
	typealias DidAnswerQuestion = (String) -> (Creatable, Question?)
	
	var question: String
	var didAnswerQuestion: DidAnswerQuestion
	
	init(question: String, didAnswerQuestion: @escaping DidAnswerQuestion) {
		self.question = question
		self.didAnswerQuestion = didAnswerQuestion
	}
}

protocol Creatable: Codable {
	var firstQuestion: Question { get }
}
