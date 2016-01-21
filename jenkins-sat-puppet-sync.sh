#!/bin/bash

DATE=$(date +"%d-%m-%Y_%H:%M:%S")
LOG="/var/log/jenkins-ci.log"

BRANCH=$1
JOBNAME=$2
BUILDNUMBER=$3
PUPPETCONTENTVIEW=cv-test-puppet-baseline
ORGANIZATION="Default Organization"
COMPOSITECONTENTVIEW=ccv-test-base
GITURL="git@gitlab.example.com:freimer/soe-puppet-modules.git"
PACKAGE_OUTPUT_DIR=/git/repo.puppet.puppet-os-baseline/packages/dev/
CHECKOUT_TMP_DIR=/git/tmp/dev/
PUPPET_MODULE_REPO=rep-puppet-modules-dev
PUPPET_MODULE_PRODUCT=prd-puppet-modules

if [[ $BRANCH = "dev" ]]
then
	echo "$DATE -> START Jenkins build for $JOBNAME, Git branch $BRANCH, build number $BUILDNUMBER." >> $LOG
	if [ -d $CHECKOUT_TMP_DIR ]
	then
		echo "$DATE -> Cleanup directory $CHECKOUT_TMP_DIR" >> $LOG
		rm -Rf $CHECKOUT_TMP_DIR &>/dev/null
		echo "$DATE -> Create directory $CHECKOUT_TMP_DIR"
		mkdir -p $CHECKOUT_TMP_DIR &>/dev/null
	else
		echo "$DATE -> Create directory $CHECKOUT_TMP_DIR"
		mkdir -p $CHECKOUT_TMP_DIR &>/dev/null
	fi
	cd $CHECKOUT_TMP_DIR
	echo "$DATE -> Start pulp-puppet-module-builder for branch $BRANCH" >> $LOG
	pulp-puppet-module-builder --output-dir=$PACKAGE_OUTPUT_DIR --url="$GITURL" --branch=$BRANCH $CHECKOUT_TMP_DIR &>> $LOG
	if [[ $? -eq 0 ]]
	then
		echo "$DATE -> Syncing Satellite repo $PUPPET_MODULE_REPO in product $PUPPET_MODULE_PRODUCT." >> $LOG
		hammer repository synchronize --name $PUPPET_MODULE_REPO --product $PUPPET_MODULE_PRODUCT --organization "$ORGANIZATION"
		if [[ $? -eq 0 ]]
		then
			# Publish new version of Content View
			echo "$DATE -> Publish new version of content view $PUPPETCONTENTVIEW" >> $LOG
			hammer content-view publish --name $PUPPETCONTENTVIEW --organization "$ORGANIZATION"
			# Find out latest version of Puppet Module Content View and it`s id
			echo "$DATE -> Find out ID of latest Puppet module content view version of $PUPPETCONTENTVIEW" >> $LOG
			PUPPETCONTENTVIEWID=`hammer content-view version list --organization "$ORGANIZATION" | grep -i $PUPPETCONTENTVIEW | head -1 | tr -d ' ' | cut -d '|' -f 1`
			echo "$DATE -> ID of latest Puppet module content view version of $PUPPETCONTENTVIEW is $PUPPETCONTENTVIEWID" >> $LOG
			# Print comma separated list of components which are also added to CCV except of Puppet baseline CV
			echo "$DATE -> Find out which component id's are currently attached to the Composite Content View $COMPOSITECONTENTVIEW" >> $LOG
			CCV_COMPONENT_IDS=`hammer content-view info --name $COMPOSITECONTENTVIEW --organization "$ORGANIZATION" | sed -n '/Components/,/Activation/{/Components/b;/Activation/b;p}' | tr -d ' ' | cut -d ':' -f 2 | awk 'ORS=NR%2?FS:RS' | grep -v $PUPPETCONTENTVIEW | awk '{ print $1 }' | paste -sd ','`
			echo "$DATE -> Component id's $CCV_COMPONENT_IDS are currently attached to Composite Content View $COMPOSITECONTENTVIEW" >> $LOG
			# Update Composite Content View with already attached components AND new version of uppet Module Content View
			echo "$DATE -> Update the Composite Content View $COMPOSITECONTENTVIEW with the following component id's: $PUPPETCONTENTVIEWID,$CCV_COMPONENT_IDS" >> $LOG
			hammer content-view update --name $COMPOSITECONTENTVIEW --organization "$ORGANIZATION" --component-ids $CCV_COMPONENT_IDS,$PUPPETCONTENTVIEWID
			# Publish new version of Composite Content View
			echo "$DATE -> Publish new version of Composite Content View $COMPOSITECONTENTVIEW" >> $LOG
			hammer content-view publish --name $COMPOSITECONTENTVIEW --organization "$ORGANIZATION"
			# Find out latest version of Composite Content View
			echo "$DATE -> Find out latest version of Composite Content View $COMPOSITECONTENTVIEW" >> $LOG
			CCV_LATEST_VERSION=`hammer content-view version list --organization "$ORGANIZATION" | grep -i $COMPOSITECONTENTVIEW | tr -d ' ' | cut -d '|' -f 3 | head -1`
			echo "$DATE -> Latest version of Composite Content View $COMPOSITECONTENTVIEW is $CCV_LATEST_VERSION" >> $LOG
			# Promote latest version of Composite Content View to Lifecycle Environment
			echo "$DATE -> Promote version $CCV_LATEST_VERSION of Composite Content View $COMPOSITECONTENTVIEW to Lifecycle Environment $BRANCH" >> $LOG
			hammer content-view version promote --content-view $COMPOSITECONTENTVIEW --version $CCV_LATEST_VERSION --organization "$ORGANIZATION" --to-lifecycle-environment $BRANCH --async
			echo "$DATE -> END: Successfully finished..." >> $LOG
		else
			echo "$DATE -> ERROR during hammer repository synchronization." >> $LOG
			exit 1
		fi
		exit 0
	else
		
		echo "$DATE -> ERROR during job execution." >> $LOG
		exit 1
	fi
else
	echo "Not a known branch found"
fi
