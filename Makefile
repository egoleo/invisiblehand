# Set up Invisible Hand
# Author: Lorenzo Cabrini <lorenzo.cabrini@gmail.com>

SHELL = /bin/sh
SITE_NAME = invisiblehand
SITE_TITLE = Invisible Hand
PROJECTS = views cck features
MODULES = content number nodereference text userreference optionwidgets \
	  path taxonomy features views views_ui

# The following are just default settings. You can override them in local.mk.
BASE_URL = ih.lcl
VHOST_DIR = /srv/www/$(BASE_URL)
IH_ROOT = htdocs
DB_TYPE = mysql
DB_HOST = db.lcl
DB_ROOT = root
DB_ROOT_PW = password
DB_USER = ih
DB_PASS = password
DB_NAME = invisiblehand
DB_PREFIX = ih_
ADMIN = admin
ADMIN_PASS = password
ADMIN_MAIL = postmaster@ih.lcl

include local.mk

IH = $(VHOST_DIR)/$(IH_ROOT)
DRUSH = drush -r $(IH) -y

all:

install: $(IH) .db .site-install .projects-install

$(IH): $(VHOST_DIR)
	drush dl drupal --destination=$(VHOST_DIR) \
	    --drupal-project-rename=$(IH_ROOT)

$(VHOST_DIR):
	mkdir -p $(VHOST_DIR)

$(IH)/sites/default/settings.php: settings.php
	cp settings.php $(IH)/sites/default/

settings.php: settings.php.in
	sed -e 's/_DB_TYPE_/$(DB_TYPE)/' \
	    -e 's/_DB_USER_/$(DB_USER)/' \
	    -e 's/_DB_PASS_/$(DB_PASS)/' \
	    -e 's/_DB_HOST_/$(DB_HOST)/' \
	    -e 's/_DB_NAME_/$(DB_NAME)/' \
	    -e 's/_DB_PREFIX_/$(DB_PREFIX)/' settings.php.in > settings.php

.site-install: $(IH)/sites/default/settings.php
	$(DRUSH) site-install6 --account-name=$(ADMIN) \
	    --account-pass='$(ADMIN_PASS)' \
	    --account-mail='$(ADMIN_MAIL)' \
	    --site-name='$(SITE_TITLE)'
	touch .site-install

.db:
	mysqladmin --user=$(DB_ROOT) --password=$(DB_ROOT_PW) create $(DB_NAME)
	mysql --user=root --password=$(DB_ROOT_PW) \
	    --execute="grant all on $(DB_NAME).* to $(DB_USER)@$(DB_HOST) \
	    identified by '$(DB_PASS)'"
	touch .db

.projects-install:
	$(DRUSH) dl $(PROJECTS)
	$(DRUSH)  updatedb
	$(DRUSH) pm-enable $(MODULES)
	touch .projects-install

clean:
	rm -f settings.php

cleaner: clean
	mysqladmin --user=$(DB_ROOT) --password=$(DB_ROOT_PW) drop $(DB_NAME)
	rm -f .db
	rm -rf $(IH)/*
	rm -f .site-install
	rm -f .projects-install
