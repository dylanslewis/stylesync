//
//  stylesync
//  Created by Dylan Lewis
//  Licensed under the MIT license. See LICENSE file.
//

import XCTest
@testable import StyleSyncCore
import Files

class CodeGeneratorTests: XCTestCase {
	private var currentFolder: Folder = .current
	
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
	
	func testInitializingCodeGeneratorWithATemplateFileWithNoFileExtensionThrowsAnError() throws {
		let template = ""
		let templateFile = try currentFolder.createFile(named: "Test", contents: template)
		
		XCTAssertThrowsError(try CodeGenerator(templateFile: templateFile))
		try templateFile.delete()
	}
	
	func testInitializingCodeGeneratorWithATemplateFileWithAnInvalidFileExtensionThrowsAnError() throws {
		let template = ""
		let templateFile = try currentFolder.createFile(named: "Test.txt", contents: template)
		
		XCTAssertThrowsError(try CodeGenerator(templateFile: templateFile))
		try templateFile.delete()
	}
	
	func testInitializingCodeGeneratorWithATemplateFileWithAValidFileExtensionExtractsTheFileExtension() throws {
		let template = ""
		let templateFile = try currentFolder.createFile(named: "Test.fileExtension-template.txt", contents: template)
		
		let codeGenerator = self.codeGenerator(forTemplateFile: templateFile)
		XCTAssertEqual(codeGenerator.fileExtension, "fileExtension")
		try templateFile.delete()
	}
	
	func testInitializingCodeGeneratorWithATemplateWithAFileNameExtractsTheFileName() throws {
		let template = ""
		let templateFile = try currentFolder.createFile(named: "FileName.fileExtension-template.txt", contents: template)

		let codeGenerator = self.codeGenerator(forTemplateFile: templateFile)
		XCTAssertEqual(codeGenerator.fileName, "FileName")
		try templateFile.delete()
	}
	
	func testGeneratingCodeForATemplateWithOneReferenceReplacesPlaceholder() {
		let template = """
			<placeholderDeclaration>
			replacedReference = <#=placeholder#>
			</placeholderDeclaration>
			"""
		
		let codeGenerator = self.codeGenerator(forTemplate: template)

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
			<placeholderDeclaration>
			replacedReference = <#=placeholder#>
			</placeholderDeclaration>

			<placeholderDeclaration>
			replacedReference = <#=placeholder#>
			</placeholderDeclaration>
			"""
		
		let codeGenerator = self.codeGenerator(forTemplate: template)

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
			<placeholderDeclarationOne>
			replacedReferenceOne = <#=placeholderOne#>
			</placeholderDeclarationOne>

			<placeholderDeclarationTwo>
			replacedReferenceTwo = <#=placeholderTwo#>
			</placeholderDeclarationTwo>
			"""
		
		let codeGenerator = self.codeGenerator(forTemplate: template)

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
			<placeholderDeclaration>
			<#?deprecated=true#>Deprecated
			replacedReference = <#=placeholder#>
			</placeholderDeclaration>
			"""
		
		let codeGenerator = self.codeGenerator(forTemplate: template)
		
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
			<placeholderDeclaration>
			<#?deprecated=true#>Deprecated
			replacedReference = <#=placeholder#>
			</placeholderDeclaration>
			"""
		
		let codeGenerator = self.codeGenerator(forTemplate: template)
		
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
			<placeholderDeclaration>
			<#?deprecated=false#>Deprecated
			replacedReference = <#=placeholder#>
			</placeholderDeclaration>
			"""
		
		let codeGenerator = self.codeGenerator(forTemplate: template)

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
	
	private func codeGenerator(forTemplateFile templateFile: File) -> CodeGenerator {
		do {
			return try CodeGenerator(templateFile: templateFile)
		} catch {
			XCTFailAndAbort(error.localizedDescription)
		}
	}
	
	private func codeGenerator(forTemplate template: Template) -> CodeGenerator {
		return CodeGenerator(template: template, fileExtension: "fileExtension")
	}
}
