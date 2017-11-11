
// TODO: Store in a file when SPM supports resources
extension ConsoleTemplate {
	static let updatedStylesTable = """
	<#@fileExtension#>log
	<attributeDeclaration>
	<#=attributeName#> changed from <#=oldValue#> to <#=newValue#>
	</attributeDeclaration>
	"""
}
