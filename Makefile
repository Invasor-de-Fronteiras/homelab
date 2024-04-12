SHELL := /bin/bash

.PHONY:
setup-argocd:
	@kubectl create namespace argocd
	@kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

.PHONY:
setup-argocd-apps:
	helm repo add argo https://argoproj.github.io/argo-helm
	helm install argo-apps argo/argocd-apps -f ./provision/argocd.yaml --version 2.0.0
