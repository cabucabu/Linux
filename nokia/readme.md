
test

Git global setup

git config --global user.name "chatchai sittiwong"
git config --global user.email "chats435@topti.postbox.in.th"

Create a new repository

git clone http://10.104.249.101/OSS/2G_Modernize.git
cd 2G_Modernize
touch README.md
git add README.md
git commit -m "add README"
git push -u origin master

Existing folder

cd existing_folder
git init
git remote add origin http://10.104.249.101/OSS/2G_Modernize.git
git add .
git commit -m "Initial commit"
git push -u origin master

Existing Git repository

cd existing_repo
git remote add origin http://10.104.249.101/OSS/2G_Modernize.git
git push -u origin --all
git push -u origin --tags

