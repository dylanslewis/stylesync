
// TODO: Store in a file when SPM supports resources
extension ConsoleTemplate {
	static let newStyleTable = """
	<#@fileExtension#>log
	<attributeDeclaration>
	<#=attributeName#>:		<#=attributeValue#>
	</attributeDeclaration>

	"""
}
