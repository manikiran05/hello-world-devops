# GitHub Actions workflows

This folder contains three workflows. Each has one job to do.

## 1. CI Pipeline — check code before merging

**Runs:** When a pull request targets `main`, or when started manually.

It runs tests, code quality checks, and the configured security scans. If a required check fails, do not merge the PR.

Feature-branch pushes do not start the full CI suite anymore. This avoids running the same expensive checks on every push and again on the PR.

## 2. CD Release — build and publish images

**Runs:** When application code is merged into `main`. Helm-only changes are skipped.

It builds the backend and frontend Docker images, scans both images, and pushes them only when the blocking scans pass. It then updates the Helm image tags directly on `main`, allowing Argo CD to deploy automatically. The deployment smoke-test job runs after the Helm update in the same CD workflow run.

## 3. Deploy Verify — check the deployed application

**Runs:** When Helm files are changed directly on `main`, or when started manually. The normal CD release uses its own deployment smoke-test job so the full release stays together in one run.

It waits for Argo CD to apply the expected image tags, checks that Kubernetes deployments finish rolling out, and sends HTTP requests to the frontend and backend health endpoints.

A successful image build does not mean the application is healthy. Deploy Verify checks the running application after deployment.

## Normal developer flow

1. Make changes on a feature branch.
2. Open or update a PR to `main`; CI runs.
3. Merge the PR after CI passes.
4. CD builds both images, scans them, and pushes them to Docker Hub.
5. CD automatically updates the Helm image tags on `main`; Argo CD applies the new images.
6. The deployment smoke-test job waits for the new images, checks Kubernetes rollouts, and tests the frontend and backend APIs—all in the same CD run.

## Quick Kubernetes checks

Run these on a machine that has access to the cluster:

```bash
kubectl get nodes
kubectl get pods -n hello-world-devops
kubectl get deployments -n hello-world-devops
kubectl get events -n hello-world-devops --sort-by=.lastTimestamp
```

- `Running` pods are running, but check the `READY` column too.
- `ImagePullBackOff` usually means Kubernetes cannot pull the image.
- `CrashLoopBackOff` means a container keeps crashing.
- A failed rollout means the new deployment did not become ready in time.
