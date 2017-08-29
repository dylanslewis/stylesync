// FIXME: Add docs

import Foundation
import StyleSyncCore

let styleSync = StyleSync()
do {
	try styleSync.run()
} catch {
	print(error)
	exit(1)
}
