desc "Publish the web site"
task :publish do
    sh 'rsync', '-avz', 'data/html/', 'andreyvit_livereload@ssh.phx.nearlyfreespeech.net:/home/public/stats/'
    puts "http://livereload.com/stats/"
end
