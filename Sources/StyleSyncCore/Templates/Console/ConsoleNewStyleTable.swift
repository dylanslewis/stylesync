
// TODO: Do this in a better way when SPM supports resources.
extension ConsoleTemplate {
	static let newStyleTable = """
	<#@fileExtension#>log
	<attributeDeclaration>
	<#=attributeName#>:		<#=attributeValue#>
	</attributeDeclaration>
	"""
}
