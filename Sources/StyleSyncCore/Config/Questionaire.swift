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
			print("\n" + question.question)
			let answer = readLine()
			if let (newCreatable, newNextQuestion) = question.didAnswerQuestion(creatable, answer) {
				creatable = newCreatable
				nextQuestion = newNextQuestion
			}
			print(creatable)
		} while nextQuestion != nil
	}
}

struct Question {
	typealias DidAnswerQuestion = (Creatable, String?) -> (Creatable, Question?)?
	
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
