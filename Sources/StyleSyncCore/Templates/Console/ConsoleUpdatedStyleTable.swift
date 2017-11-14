
// TODO: Store in a file when SPM supports resources
extension ConsoleTemplate {
	static let updatedStylesTable = """
	<attributeDeclaration>
	<#=attributeName#> changed from <#=oldValue#> to <#=newValue#>
	</attributeDeclaration>

	"""
}
