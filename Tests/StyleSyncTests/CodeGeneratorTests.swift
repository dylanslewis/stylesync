//
//  CodeGeneratorTests.swift
//  StyleSyncTests
//
//  Created by Dylan Lewis on 12/11/2017.
//

import XCTest
import StyleSyncCore

class CodeGeneratorTests: XCTestCase {
	// MARK: - Subtypes
	
	private struct SimpleCodeTemplateReplaceable: CodeTemplateReplacable {
		var declarationName: String
		var replacementDictionary: [String: String]
		var ignoredUpdateAttributes: [String] = []
		var isDeprecated: Bool
		
		init(declarationName: String, replacementDictionary: [String: String], isDeprecated: Bool = false) {
			self.declarationName = declarationName
			self.replacementDictionary = replacementDictionary
			self.isDeprecated = isDeprecated
		}
	}
	
	// MARK: - Tests
	
	func testInitializingCodeGeneratorWithATemplateWithNoFileExtensionThrowsAnError() {
		let template = """
			<#@fileName#>fileName
			"""
		
		XCTAssertThrowsError(try CodeGenerator(template: template))
	}
	
	func testInitializingCodeGeneratorWithATemplateWithAFileExtensionExtractsTheFileExtension() {
		let template = """
			<#@fileExtension#>fileExtension
			"""
		
		let codeGenerator = self.codeGenerator(for: template)
		XCTAssertEqual(codeGenerator.fileExtension, "fileExtension")
	}
	
	func testInitializingCodeGeneratorWithATemplateWithAFileNameExtractsTheFileName() {
		let template = """
			<#@fileName#>fileName
			<#@fileExtension#>fileExtension
			"""
		
		let codeGenerator = self.codeGenerator(for: template)
		XCTAssertEqual(codeGenerator.fileName, "fileName")
	}
	
	func testGeneratedCodeDoesNotContainAnyMetadataReferences() {
		let template = """
			<#@fileExtension#>fileExtension
			"""
		
		let codeGenerator = self.codeGenerator(for: template)
		let generatedCode = codeGenerator.generatedCode(for: [[]])
		
		let expectedGeneratedCode = ""
		XCTAssertEqual(generatedCode, expectedGeneratedCode)
	}
	
	func testGeneratingCodeForATemplateWithOneReferenceReplacesPlaceholder() {
		let template = """
			<#@fileExtension#>fileExtension
			<placeholderDeclaration>
			replacedReference = <#=placeholder#>
			</placeholderDeclaration>
			"""
		
		let codeGenerator = self.codeGenerator(for: template)
		
		let codeTemplateReplacable = SimpleCodeTemplateReplaceable(
			declarationName: "placeholderDeclaration",
			replacementDictionary: ["placeholder": "replacedPlaceholder"]
		)
		
		let generatedCode = codeGenerator.generatedCode(for: codeTemplateReplacable)
		let expectedGeneratedCode = """
			replacedReference = replacedPlaceholder
			"""
		XCTAssertEqual(generatedCode, expectedGeneratedCode)
	}
	
	func testGeneratedCodeForTemplateWithTwoIdenticalReferencesReplacesAllPlaceholders() {
		let template = """
			<#@fileExtension#>fileExtension
			<placeholderDeclaration>
			replacedReference = <#=placeholder#>
			</placeholderDeclaration>

			<placeholderDeclaration>
			replacedReference = <#=placeholder#>
			</placeholderDeclaration>
			"""
		
		let codeGenerator = self.codeGenerator(for: template)
		
		let codeTemplateReplacable = SimpleCodeTemplateReplaceable(
			declarationName: "placeholderDeclaration",
			replacementDictionary: ["placeholder": "replacedPlaceholder"]
		)
		
		let generatedCode = codeGenerator.generatedCode(for: [[codeTemplateReplacable]])
		let expectedGeneratedCode = """
			replacedReference = replacedPlaceholder

			replacedReference = replacedPlaceholder
			"""
		XCTAssertEqual(generatedCode, expectedGeneratedCode)
	}
	
	func testGeneratedCodeForTemplateWithTwoDifferentReferencesReplacesAllPlaceholders() {
		let template = """
			<#@fileExtension#>fileExtension
			<placeholderDeclarationOne>
			replacedReferenceOne = <#=placeholderOne#>
			</placeholderDeclarationOne>

			<placeholderDeclarationTwo>
			replacedReferenceTwo = <#=placeholderTwo#>
			</placeholderDeclarationTwo>
			"""
		
		let codeGenerator = self.codeGenerator(for: template)
		
		let codeTemplateReplacableOne = SimpleCodeTemplateReplaceable(
			declarationName: "placeholderDeclarationOne",
			replacementDictionary: ["placeholderOne": "replacedPlaceholderOne"]
		)
		let codeTemplateReplacableTwo = SimpleCodeTemplateReplaceable(
			declarationName: "placeholderDeclarationTwo",
			replacementDictionary: ["placeholderTwo": "replacedPlaceholderTwo"]
		)
		
		let generatedCode = codeGenerator.generatedCode(for: [[codeTemplateReplacableOne], [codeTemplateReplacableTwo]])
		let expectedGeneratedCode = """
			replacedReferenceOne = replacedPlaceholderOne

			replacedReferenceTwo = replacedPlaceholderTwo
			"""
		XCTAssertEqual(generatedCode, expectedGeneratedCode)
	}
	
	func testGeneratingCodeWithADeprecatedReferenceReplacesDeprecationPlaceholder() {
		let template = """
			<#@fileExtension#>fileExtension
			<placeholderDeclaration>
			<#?deprecated=true#>Deprecated
			replacedReference = <#=placeholder#>
			</placeholderDeclaration>
			"""
		
		let codeGenerator = self.codeGenerator(for: template)
		
		let codeTemplateReplacable = SimpleCodeTemplateReplaceable(
			declarationName: "placeholderDeclaration",
			replacementDictionary: ["placeholder": "replacedPlaceholder"],
			isDeprecated: true
		)
		
		let generatedCode = codeGenerator.generatedCode(for: [[codeTemplateReplacable]])
		let expectedGeneratedCode = """
			Deprecated
			replacedReference = replacedPlaceholder
			"""
		XCTAssertEqual(generatedCode, expectedGeneratedCode)
	}
	
	func testGeneratingCodeWithAnUndeprecatedReferenceRemovesDeprecationPlaceholder() {
		let template = """
			<#@fileExtension#>fileExtension
			<placeholderDeclaration>
			<#?deprecated=true#>Deprecated
			replacedReference = <#=placeholder#>
			</placeholderDeclaration>
			"""
		
		let codeGenerator = self.codeGenerator(for: template)
		
		let codeTemplateReplacable = SimpleCodeTemplateReplaceable(
			declarationName: "placeholderDeclaration",
			replacementDictionary: ["placeholder": "replacedPlaceholder"],
			isDeprecated: false
		)
		
		let generatedCode = codeGenerator.generatedCode(for: [[codeTemplateReplacable]])
		let expectedGeneratedCode = """
			replacedReference = replacedPlaceholder
			"""
		XCTAssertEqual(generatedCode, expectedGeneratedCode)
	}
	
	func testGeneratingCodeWithAnUndeprecatedReferenceAndAFalseConditionReplacesDeprecationPlaceholder() {
		let template = """
			<#@fileExtension#>fileExtension
			<placeholderDeclaration>
			<#?deprecated=false#>Deprecated
			replacedReference = <#=placeholder#>
			</placeholderDeclaration>
			"""
		
		let codeGenerator = self.codeGenerator(for: template)
		
		let codeTemplateReplacable = SimpleCodeTemplateReplaceable(
			declarationName: "placeholderDeclaration",
			replacementDictionary: ["placeholder": "replacedPlaceholder"],
			isDeprecated: false
		)
		
		let generatedCode = codeGenerator.generatedCode(for: [[codeTemplateReplacable]])
		let expectedGeneratedCode = """
			Deprecated
			replacedReference = replacedPlaceholder
			"""
		XCTAssertEqual(generatedCode, expectedGeneratedCode)
	}
	
	// MARK: - Helpers
	
	private func codeGenerator(for template: Template) -> CodeGenerator {
		do {
			return try CodeGenerator(template: template)
		} catch {
			XCTFailAndAbort(error.localizedDescription)
		}
	}
}
