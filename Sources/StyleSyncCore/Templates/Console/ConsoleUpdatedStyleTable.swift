
// TODO: Do this in a better way when SPM supports resources.
extension ConsoleTemplate {
	static let updatedStylesTable = """
	<#@fileExtension#>log
	<attributeDeclaration>
	<#=attributeName#> changed from <#=oldValue#> to <#=newValue#>
	</attributeDeclaration>
	"""
}
