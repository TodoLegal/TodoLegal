# Running instructions

## 1. Install the dependencies

Install Rails 6.0 and other tools needed.

### In development Mode

#### Linux

```
apt update
apt install curl git libpq-dev gnupg2 postgresql-11
gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -sSL https://get.rvm.io | bash -s stable --rails
source /usr/local/rvm/scripts/rvm
```

#### MacOS

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
\curl -sSL https://get.rvm.io | bash -s stable --rails
brew install postgresql yarn
```

### In Production Mode

```
apt update
apt install curl git libpq-dev gnupg2 postgresql-11 nginx software-properties-common python-certbot-nginx
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
```

Add the following at the end of the file

```
export TodoLegalDB_Password=MyPassword
export RAILS_SERVE_STATIC_FILES=yes
export EXCEPTION_BOT_TOKEN=YOURDISCORDTOKEN
export STRIPE_SECRET_KEY=YOURSTRIPEKEY
```

And then back to the terminal

```
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
upstream thin {
  server 127.0.0.1:3000;
}
server {
    server_name www.todolegal.app;
    return 301 $scheme://todolegal.app$request_uri;
}
server {
  server_name  todolegal.app; # or test.todolegal.app for the testing server
  
  listen 80;
  listen [::]:80;

  access_log /var/log/nginx/reverse-access.log;
  error_log /var/log/nginx/reverse-error.log;

  location / {
    proxy_pass        http://thin;
    proxy_set_header  Host $host;
    proxy_set_header  X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header  X-Forwarded-Proto $scheme;
    proxy_set_header  X-Forwarded-Ssl on; # Optional
    proxy_set_header  X-Forwarded-Port $server_port;
    proxy_set_header  X-Forwarded-Host $host;
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


##### Linux

```
sudo -u postgres psql
postgres=# create database TodoLegalDB_Development;
postgres=# alter user postgres with encrypted password 'MyPassword';
postgres=# CREATE TEXT SEARCH CONFIGURATION public.tl_config ( COPY = pg_catalog.spanish );
postgres=# CREATE TEXT SEARCH DICTIONARY public.tl_dict ( TEMPLATE = pg_catalog.simple, STOPWORDS = russian);
postgres=# ALTER TEXT SEARCH CONFIGURATION public.tl_config ALTER MAPPING FOR asciiword, asciihword, hword_asciipart, hword, hword_part, word WITH tl_dict;
\q
```

#### MacOS

```
initdb /usr/local/var/postgres
/usr/local/opt/postgres/bin/createuser -s postgres
pg_ctl -D /usr/local/var/postgres start
```

#### In production mode

```
sudo -u postgres psql
postgres=# create database TodoLegalDB_Production;
postgres=# alter user postgres with encrypted password 'MyPassword';
postgres=# CREATE TEXT SEARCH CONFIGURATION public.tl_config ( COPY = pg_catalog.spanish );
postgres=# CREATE TEXT SEARCH DICTIONARY public.tl_dict ( TEMPLATE = pg_catalog.simple, STOPWORDS = russian);
postgres=# ALTER TEXT SEARCH CONFIGURATION public.tl_config ALTER MAPPING FOR asciiword, asciihword, hword_asciipart, hword, hword_part, word WITH tl_dict;
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
