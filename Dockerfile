#ARG MARKETPLACE_TOOLS_TAG
FROM marketplace.gcr.io/google/debian9 AS build

RUN apt-get update \
    && apt-get install -y --no-install-recommends gettext

ADD chart/citrix-k8s-ingress-controller /tmp/chart/
RUN cd /tmp && tar -czvf /tmp/cic.tar.gz chart

ADD apptest/deployer/citrix-k8s-ingress-controller-GKE /tmp/test/chart
RUN cd /tmp/test \
    && tar -czvf /tmp/test/cic.tar.gz chart/

ADD schema.yaml /tmp/schema.yaml

ARG REGISTRY
ARG TAG
ARG APP_NAME

RUN cat /tmp/schema.yaml \
    | env -i "REGISTRY=$REGISTRY" "APP_NAME=$APP_NAME" "TAG=$TAG" envsubst \
    > /tmp/schema.yaml.new \
    && mv /tmp/schema.yaml.new /tmp/schema.yaml

ADD apptest/deployer/schema.yaml /tmp/apptest/schema.yaml
RUN cat /tmp/apptest/schema.yaml \
    | env -i "REGISTRY=$REGISTRY" "APP_NAME=$APP_NAME" "TAG=$TAG" envsubst \
    > /tmp/apptest/schema.yaml.new \
    && mv /tmp/apptest/schema.yaml.new /tmp/apptest/schema.yaml

#FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm:$MARKETPLACE_TOOLS_TAG
FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm:latest
#FROM gcr.io/cloud-marketplace-tools/k8s/deployer_helm/onbuild
COPY --from=build /tmp/cic.tar.gz /data/chart/
COPY --from=build /tmp/test/cic.tar.gz /data-test/chart/
COPY --from=build /tmp/apptest/schema.yaml /data-test/
COPY --from=build /tmp/schema.yaml /data/
