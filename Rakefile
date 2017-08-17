
task :release do
    # reednj@popacular.com:~/code/redditgold.git
    sh "git push prod master"
    sh "git describe"
    sh "url-status gold.reddit-stream.com"
end
