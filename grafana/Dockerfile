ARG GRAFANA_VERSION=11.4.0

FROM grafana/grafana:${GRAFANA_VERSION}
USER root
RUN apk add --no-cache git && mkdir -p /home/grafana/bin
USER grafana
COPY provisioning/datasources/datasources.yml /etc/grafana/provisioning/datasources/datasources.yml
COPY provisioning/dashboards/dashboards.yml /etc/grafana/provisioning/dashboards/dashboards.yml
COPY provisioning/grafana.ini /etc/grafana/grafana.ini
COPY dashboards/ /etc/grafana/dashboards/
COPY bin/fetch-dashboards.sh /home/grafana/bin/fetch-dashboards.sh

ENV GF_AUTH_ANONYMOUS_ENABLED=false
ENV GF_AUTH_DISABLE_LOGIN_FORM=false
