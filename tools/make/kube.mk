##@ Kubernetes Development

.PHONY: manifests
manifests: $(tools/controller-gen) ## Generate WebhookConfiguration, ClusterRole and CustomResourceDefinition objects.
	$(tools/controller-gen) rbac:roleName=envoy-gateway-role crd webhook paths="./..." output:crd:artifacts:config=pkg/provider/kubernetes/config/crd/bases

.PHONY: generate
generate: $(tools/controller-gen) ## Generate code containing DeepCopy, DeepCopyInto, and DeepCopyObject method implementations.
	$(tools/controller-gen) object paths="./..."

.PHONY: kube-test
kube-test: manifests generate lint $(tools/setup-envtest) ## Run Kubernetes provider tests.
	KUBEBUILDER_ASSETS="$(shell $(tools/setup-envtest) use $(ENVTEST_K8S_VERSION) -p path)" go test ./... -coverprofile cover.out


##@ Kubernetes Deployment

ifndef ignore-not-found
  ignore-not-found = false
endif

.PHONY: kube-install
kube-install: manifests $(tools/kustomize) ## Install CRDs into the Kubernetes cluster specified in ~/.kube/config.
	$(tools/kustomize) build pkg/provider/kubernetes/config/crd | kubectl apply -f -

.PHONY: kube-uninstall
kube-uninstall: manifests $(tools/kustomize) ## Uninstall CRDs from the K8s cluster specified in ~/.kube/config. Call with ignore-not-found=true to ignore resource not found errors during deletion.
	$(tools/kustomize) build pkg/provider/kubernetes/config/crd | kubectl delete --ignore-not-found=$(ignore-not-found) -f -
