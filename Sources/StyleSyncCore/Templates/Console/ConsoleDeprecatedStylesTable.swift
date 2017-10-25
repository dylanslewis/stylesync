
enum ConsoleTemplate {}

// TODO: Do this in a better way when SPM supports resources.
extension ConsoleTemplate {
	static let deprecatedStylesTable = """
	<#@fileExtension#>log
	These styles have been removed from the style guide, but are still referenced in
	your project.

	<styleDeclaration>
	`<#=styleName#>` is still used in the following files: <#=fileNames#>
	</styleDeclaration>
	"""
}
