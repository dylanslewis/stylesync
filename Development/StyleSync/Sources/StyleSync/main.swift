// FIXME: Add docs

import Foundation
import StyleSyncCore

do {
	try StyleSync().run()
} catch {
	// FIXME: Parse StyleSync.Errors properly
	print(error)
	exit(1)
}
