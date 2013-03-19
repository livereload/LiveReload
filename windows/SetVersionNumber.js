"use strict";

var USAGE =
	"Updates or queries the version number embedded in this solution.\n" +
	"\n" +
	"Usage: node SetVersionNumber.js <new-version>\n" +
	"   or: node SetVersionNumber.js -q | --query\n" +
	"\n" +
	"Options:\n" +
	"  -q, --query       display current versions without making any changes\n" +
	"  <new-version>     a four-component version number to set, e.g. 1.2.3.4";

var fs = require('fs');
var Path = require('path');

var AppRoot = __dirname;

function updateVersionNumberInFile(newVersion, fileRelPath, regexps) {
	console.log("%s", fileRelPath);
	var filePath = Path.join(AppRoot, fileRelPath);
	var originalContent = fs.readFileSync(filePath, 'utf8');
	var newContent = originalContent;
	regexps.forEach(function(regexp) {
		newContent = newContent.replace(regexp, function(original, prefix, oldVersion, suffix) {
			if (newVersion != null) {
				if (newVersion == oldVersion) {
					console.log("  * %s", oldVersion);
					return original;
				} else {
					console.log("  * %s ==> %s", oldVersion, newVersion);
					return prefix + newVersion + suffix;
				}
			} else {
				console.log("  * %s", oldVersion);
				return original;
			}
		});
	});
	if (newContent != originalContent) {
		console.log("  * file updated");
		fs.writeFileSync(filePath, newContent);
	}
}

function updateVersionNumber(newVersion) {
	updateVersionNumberInFile(newVersion, "LiveReload.csproj", [
		/(<ApplicationVersion>)(\d+\.\d+\.\d+\.\d+)(<\/ApplicationVersion>)/
	]);
	updateVersionNumberInFile(newVersion, "Properties/AssemblyInfo.cs", [
		/(assembly: AssemblyVersion\(")(\d+\.\d+\.\d+\.\d+)("\))/,
		/(assembly: AssemblyFileVersion\(")(\d+\.\d+\.\d+\.\d+)("\))/
	]);
}

function usage() {

	process.exit(0)
}

function main(args) {
	if (args.indexOf('--help') >= 0) {
		console.log(USAGE);
		return;
	}

	if (args.length != 1) {
		console.error("** Exactly one argument required. Run with --help for usage.");
		process.exit(1);
	}

	var newVersion = args.shift();
	if (newVersion == "-q" || newVersion == "--query") {
		newVersion = null;
	} else if (!newVersion.match(/^\d+\.\d+\.\d+\.\d+$/)) {
		console.error("** Incorrect <new-version> specified: %s; it must have exactly 4 numeric components. Run with --help for usage.", newVersion);
		process.exit(1);
	}

	updateVersionNumber(newVersion);
}

main(process.argv.slice(2));
