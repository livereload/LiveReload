
namespace :site do
  desc "Publish the web site"
  task :publish do
    sh 'rsync', '-avz', 'site/', 'andreyvit_livereload@ssh.phx.nearlyfreespeech.net:/home/public/'
  end
end
