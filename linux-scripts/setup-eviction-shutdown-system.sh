#!/usr/bin/env bash

BASE_REPO_URL="https://raw.githubusercontent.com/jpfulton/example-linux-configs/main";

# Set up eviction query and shutdown script
EVICTION_QUERY_CRON_SNIPPET_FILE="preempt-query";
EVICTION_QUERY_SCRIPT="query-for-preempt-event.sh";
echo "Setting up eviction query script...";

sudo wget -q ${BASE_REPO_URL}/usr/local/sbin/${EVICTION_QUERY_SCRIPT};
sudo chmod ug+x ./${EVICTION_QUERY_SCRIPT}
sudo mv ./${EVICTION_QUERY_SCRIPT} /usr/local/sbin/

sudo wget -q ${BASE_REPO_URL}/etc/cron.d/${EVICTION_QUERY_CRON_SNIPPET_FILE};
sudo mv ./${EVICTION_QUERY_CRON_SNIPPET_FILE} /etc/cron.d/

echo "---";
echo;