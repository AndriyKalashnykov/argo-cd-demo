# cd spring-petclinic
# git remote add upstream https://github.com/spring-projects/spring-petclinic.git
git fetch --all

git checkout main

# pulls all new commits made to upstream/main
git pull upstream main

# this will delete all your local changes to main
git reset --hard upstream/main

# take care, this will delete all your changes on your forked main
git push origin main --force