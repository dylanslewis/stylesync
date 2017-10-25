
// TODO: Store in a file when SPM supports resources
extension GitHubTemplate {
	static let updatedStylesTable = """
	<#@fileExtension#>md
	| | Before | After |
	| --- | :---: | :---: |
	<attributeDeclaration>
	| <#=attributeName#> | `<#=oldValue#>` | `<#=newValue#>` |
	</attributeDeclaration>
	"""
}
