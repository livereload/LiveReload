.DEFAULT: build
.PHONY: build

build:
	xcodebuild -project LiveReload.xcodeproj -scheme LRCommons -configuration Debug build
	xcodebuild -project LiveReload.xcodeproj -scheme ATPathSpec -configuration Debug build
	xcodebuild -project LiveReload.xcodeproj -scheme EditorKit -configuration Debug build
	xcodebuild -project LiveReload.xcodeproj -scheme FileSystemMonitoringKit -configuration Debug build
	xcodebuild -project LiveReload.xcodeproj -scheme PiiVersionKit -configuration Debug build
	xcodebuild -project LiveReload.xcodeproj -scheme PackageManagerKit -configuration Debug build
	xcodebuild -project LiveReload.xcodeproj -scheme VariableKit -configuration Debug build
	xcodebuild -project LiveReload.xcodeproj -scheme LRActionKit -configuration Debug build
	xcodebuild -project LiveReload.xcodeproj -scheme LiveReload -configuration Debug build
