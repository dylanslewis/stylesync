
// TODO: Do this in a better way when SPM supports resources.
extension ConsoleTemplate {
	static let heading = """
	<#@fileExtension#>log
	<headingDeclaration>
	<#=headingName#>
	--------------------------------------------------------------------------------

	</headingDeclaration>
	"""
}
