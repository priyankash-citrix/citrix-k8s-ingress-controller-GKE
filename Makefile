include ../app.Makefile
include ../crd.Makefile
include ../gcloud.Makefile
include ../var.Makefile


TAG ?= 1.1.1
$(info ---- TAG = $(TAG))

APP_DEPLOYER_IMAGE ?= $(REGISTRY)/citrix-k8s-ingress-controller/deployer:$(TAG)
NAME ?= citrix-k8s-ingress-controller-1

ifdef IMAGE_CITRIX_CONTROLLER
  IMAGE_CITRIX_CONTROLLER_FIELD = , "cicimage.image": "$(IMAGE_CITRIX_CONTROLLER)" endif
endif

ifdef CITRIX_NSIP
  CITRIX_NSIP_FIELD = , "nsIP": "$(CITRIX_NSIP)"
endif

ifdef CITRIX_NSVIP
  CITRIX_NSVIP_FIELD = , "nsVIP": "$(CITRIX_NSVIP)"
endif

APP_PARAMETERS ?= { \
  "name": "$(NAME)", \
  "namespace": "$(NAMESPACE)" \
  $(IMAGE_CITRIX_CONTROLLER_FIELD) \
  $(CITRIX_NSIP_FIELD) \
  $(CITRIX_NSVIP_FIELD) \
}

TESTER_IMAGE ?= $(REGISTRY)/citrix-k8s-ingress-controller/tester:$(TAG)


app/build:: .build/citrix-k8s-ingress-controller/debian9  \
            .build/citrix-k8s-ingress-controller/deployer \
            .build/citrix-k8s-ingress-controller/citrix-k8s-ingress-controller \
            .build/citrix-k8s-ingress-controller/tester


.build/citrix-k8s-ingress-controller: | .build
	mkdir -p "$@"


.build/citrix-k8s-ingress-controller/debian9: .build/var/REGISTRY \
                      .build/var/TAG \
                      | .build/citrix-k8s-ingress-controller
	docker pull marketplace.gcr.io/google/debian9
	docker tag marketplace.gcr.io/google/debian9 "$(REGISTRY)/citrix-k8s-ingress-controller/debian9:$(TAG)"
	docker push "$(REGISTRY)/citrix-k8s-ingress-controller/debian9:$(TAG)"
	@touch "$@"


.build/citrix-k8s-ingress-controller/deployer: deployer/* \
                       chart/citrix-k8s-ingress-controller/* \
                       chart/citrix-k8s-ingress-controller/templates/* \
                       schema.yaml \
                       .build/var/APP_DEPLOYER_IMAGE \
                       .build/var/MARKETPLACE_TOOLS_TAG \
                       .build/var/REGISTRY \
                       .build/var/TAG \
                       | .build/citrix-k8s-ingress-controller
	docker build \
	    --build-arg REGISTRY="$(REGISTRY)/citrix-k8s-ingress-controller" \
	    --build-arg TAG="$(TAG)" \
	    --build-arg MARKETPLACE_TOOLS_TAG="$(MARKETPLACE_TOOLS_TAG)" \
	    --tag "$(APP_DEPLOYER_IMAGE)" \
	    -f deployer/Dockerfile \
	    .
	docker push "$(APP_DEPLOYER_IMAGE)"
	@touch "$@"


.build/citrix-k8s-ingress-controller/citrix-k8s-ingress-controller: .build/var/REGISTRY \
                    .build/var/TAG \
                    | .build/citrix-k8s-ingress-controller
	docker pull quay.io/citrix/citrix-k8s-ingress-controller:$(TAG)
	docker tag quay.io/citrix/citrix-k8s-ingress-controller:$(TAG) \
	    "$(REGISTRY)/citrix-k8s-ingress-controller:$(TAG)"
	docker push "$(REGISTRY)/citrix-k8s-ingress-controller:$(TAG)"
	@touch "$@"


.build/citrix-k8s-ingress-controller/tester: .build/var/TESTER_IMAGE \
                     $(shell find apptest -type f) \
                     | .build/citrix-k8s-ingress-controller
	$(call print_target,$@)
	cd apptest/tester \
	    && docker build --tag "$(TESTER_IMAGE)" .
	docker push "$(TESTER_IMAGE)"
	@touch "$@"