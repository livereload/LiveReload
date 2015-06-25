desc "Push everything including tags"
task "push" do |t, args|
  sh 'git', 'push', '--follow-tags'

  Dir.chdir 'LiveReload/Compilers' do
    sh 'git', 'push', '--follow-tags'
  end
end
