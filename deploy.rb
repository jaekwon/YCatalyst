set :application, "1amendment"
set :repository,  "ssh://root@jaekwon.com/mnt/repo/git/1amendment.git/"

set :scm, :git
# Or: `accurev`, `bzr`, `cvs`, `darcs`, `git`, `mercurial`, `perforce`, `subversion` or `none`

set :deploy_to, "/var/www/public/1amendment"

role :web, "1amendment.com"                          # Your HTTP server, Apache/etc
role :app, "1amendment.com"                          # This may be the same as your `Web` server
role :db,  "1amendment.com", :primary => true # This is where Rails migrations will run

set :user, "ubuntu"
set :use_sudo, true 

# If you are using Passenger mod_rails uncomment this:
# if you're still using the script/reapear helper you will need
# these http://github.com/rails/irs_process_scripts

namespace :deploy do
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    #run "#{try_sudo} touch #{File.join(current_path,'','restart.txt')}"
  end
end

task :symlinks do
  run "cd #{deploy_to}/current; /usr/bin/git submodule init"
  run "cd #{deploy_to}/current; /usr/bin/git submodule update"
end

after :deploy, :symlinks
