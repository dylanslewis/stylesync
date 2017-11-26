
enum GitHubTemplate {}

extension GitHubTemplate {
	static let deprecatedStylesTable = """
	*These styles have been removed from the style guide, but are still referenced in your project.*

	| Style name | Referenced in file |
	| --- | :---: |
	<styleDeclaration>
	| `<#=styleName#>` | <#=fileNames#> |
	</styleDeclaration>
	"""
}
