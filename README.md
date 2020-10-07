# Running instructions

## 1. Dependencies

### Linux

```
apt update
apt install curl git libpq-dev gnupg2 postgresql-11
gpg2 --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
\curl -sSL https://get.rvm.io | bash -s stable --rails
source /usr/local/rvm/scripts/rvm
```

### MacOS

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
\curl -sSL https://get.rvm.io | bash -s stable --rails
brew install postgresql yarn
```

## 2. Repo

```
mkdir TodoLegal
cd TodoLegal/
git init
git remote add origin https://github.com/TodoLegal/TodoLegal.git
git pull origin master
bundle install
```

## 3. Database

### Linux

```
sudo -u postgres psql
postgres=# create database TodoLegalDB_Development;
postgres=# alter user postgres with encrypted password 'MyPassword';
postgres=# CREATE TEXT SEARCH CONFIGURATION public.tl_config ( COPY = pg_catalog.spanish );
postgres=# CREATE TEXT SEARCH DICTIONARY public.tl_dict ( TEMPLATE = pg_catalog.simple, STOPWORDS = russian);
postgres=# ALTER TEXT SEARCH CONFIGURATION public.tl_config ALTER MAPPING FOR asciiword, asciihword, hword_asciipart, hword, hword_part, word WITH tl_dict;
\q
```

### MacOS

```
initdb /usr/local/var/postgres
/usr/local/opt/postgres/bin/createuser -s postgres
pg_ctl -D /usr/local/var/postgres start
```

Next, we setup the database:

### Linux and MacOS

```
rails db:create
rails db:migrate
# optional: rails db:seed
```


## 4. Launch the server

### In development mode

```
rails s
```

Stop the server with `Ctrl + C`.
