
// TODO: Store in a file when SPM supports resources
extension GitHubTemplate {
	static let newStyleTable = """
	| Attribute | Value |
	| :---: | :---: |
	<attributeDeclaration>
	| <#=attributeName#> | `<#=attributeValue#>` |
	</attributeDeclaration>
	"""
}
