
desc "Package the backend from cli/ into interim/backend/"
task :backend do
    mkdir_p "interim"
    rm_rf 'interim/node_modules/livereload'
    sh "cd interim; npm install ../cli pathspec"

    # for 1.3: '!**/sugar/release' '!**/sugar/lib' '**/sugar/release/1.3/sugar-1.3-full.development.js'
    files = `cd interim/node_modules/livereload; ../pathspec/bin/pathspec-find.js . '*.js' '*.node' '*.json' '*.md' '!**/ws/examples' '!test' '!tests' '!unit_tests' '!**/sugar/release' '!example' '!examples' '!pyyaml-src' '!*.tmbundle' '!.bin' '!mocha'`.split("\n").sort
    rm_rf 'interim/backend'
    for file in files
        dst = "interim/backend/#{file}"
        mkdir_p File.dirname(dst)
        cp "interim/node_modules/livereload/#{file}", dst
    end
end
