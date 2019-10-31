# Running instructions

## 1. Install the dependencies

Install Rails 6.0 and other tools needed.

### In development Mode

```
apt update
apt install curl git libpq-dev gnupg2 postgresql-11
gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -sSL https://get.rvm.io | bash -s stable --rails
source /usr/local/rvm/scripts/rvm
```

### In Production Mode

```
apt update
apt install curl git libpq-dev gnupg2 postgresql-11 nginx software-properties-common
add-apt-repository ppa:certbot/certbot
apt-get update
apt-get install python-certbot-nginx
gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -sSL https://get.rvm.io | bash -s stable --rails
source /usr/local/rvm/scripts/rvm
```

## 2. Setup the repo

```
mkdir TodoLegal
cd TodoLegal/
git init
git remote add origin https://github.com/TodoLegal/TodoLegal.git
git pull origin master
bundle install
```

### Production only configuration

#### a. Setup the credentials

```
EDITOR="nano" rails credentials:edit
```

#### b. Setup config some environment variables needed

```
nano ~/.bashrc
# add the following at the end of the file
# export TodoLegalDB_Password=MyPassword
# export RAILS_SERVE_STATIC_FILES=yes
source ~/.bashrc
. ~/.bashrc
```

#### c. Setup Nginx Proxy With SSL

```
unlink /etc/nginx/sites-enabled/default
cd /etc/nginx/sites-available
nano reverse-proxy.conf
```

And paste the following

```
server {
  server_name  todolegal.app; # or test.todolegal.app for the testing server
  
  listen 80;
  listen [::]:80;

  access_log /var/log/nginx/reverse-access.log;
  error_log /var/log/nginx/reverse-error.log;

  location / {
    proxy_pass http://127.0.0.1:3000;
  }
}
```

Then

```
ln -s /etc/nginx/sites-available/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf
certbot --nginx
```

Finally, fill the form with

* whatever@mail.com (your email or whatever)
* a (agree)
* n (no)
* 1 (select the domain)
* 2 (enable redirect)

## 2. Create and setup the database

### Create the postgre database

#### In development mode

```
sudo -u postgres psql
postgres=# create database TodoLegalDB_Development;
postgres=# alter user postgres with encrypted password 'MyPassword';
\q
```

#### In production mode

```
sudo -u postgres psql
postgres=# create database TodoLegalDB_Production;
postgres=# alter user postgres with encrypted password 'MyPassword';
\q
```

### Database setup

#### In development mode

```
rails db:create
rails db:migrate
# optional: rails db:seed
```

#### In production mode

```
cd ~/TodoLegal
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate
# optional: RAILS_ENV=production rails db:seed
```

## 4. Launch the server

### In development mode

```
rails s
```

Stop the server with `Ctrl + C`.

### In production mode

```
thin start -C config/thin.yml
thin stop -C config/thin.yml
```
