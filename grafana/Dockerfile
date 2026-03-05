ARG GRAFANA_VERSION=11.4.0
FROM grafana/grafana:${GRAFANA_VERSION}

COPY provisioning/datasources/datasources.yml /etc/grafana/provisioning/datasources/datasources.yml
COPY provisioning/grafana.ini /etc/grafana/grafana.ini

ENV GF_AUTH_ANONYMOUS_ENABLED=false
ENV GF_AUTH_DISABLE_LOGIN_FORM=false
