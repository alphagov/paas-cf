#!/usr/bin/env bash

cat <<EOF
== FOR SECRETS, SEE "make [ENV] credhub" ==

Here are some useful facts about your environment:
$(column -t -s "|" <<FACTS
  DEPLOY ENV | ${DEPLOY_ENV}
  CONCOURSE DEPLOYER | https://deployer.${SYSTEM_DNS_ZONE_NAME}
  PROMETHEUS | https://prometheus-1.${SYSTEM_DNS_ZONE_NAME}, https://prometheus-2.${SYSTEM_DNS_ZONE_NAME}
  GRAFANA | https://grafana-1.${SYSTEM_DNS_ZONE_NAME}, https://grafana-2.${SYSTEM_DNS_ZONE_NAME}
  PAAS ADMIN | https://admin.${SYSTEM_DNS_ZONE_NAME}
  API ENDPOINT | https://api.${SYSTEM_DNS_ZONE_NAME}
  UAA | https://uaa.${SYSTEM_DNS_ZONE_NAME}
  AWS REGION | ${AWS_DEFAULT_REGION}
  MORNING DEPLOYMENT ENABLED? | $([[ $ENABLE_MORNING_DEPLOYMENT = true ]] && echo "Yes" || echo "No")
  AUTO DELETE ENABLED? | $([[ $ENABLE_AUTODELETE = true ]] && echo "Yes" || echo "No")
  SLIM DEPLOYMENT? | $([[ $SLIM_DEV_DEPLOYMENT = true ]] && echo "Yes" || echo "No")
FACTS
)
EOF
