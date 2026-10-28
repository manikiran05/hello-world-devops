# GitHub Actions workflows

This folder contains three workflows. Each has one job to do.

## 1. CI Pipeline — check code before merging

**Runs:** When a pull request targets `main`, or when started manually.

It runs tests, code quality checks, and the configured security scans. If a required check fails, do not merge the PR.

Feature-branch pushes do not start the full CI suite anymore. This avoids running the same expensive checks on every push and again on the PR.

## 2. CD Release — build and publish images

**Runs:** When application code is merged into `main`. Helm-only changes are skipped.

It builds the backend and frontend Docker images, scans both images, and pushes them only when the blocking scans pass. Then it opens or updates one PR with the new image tags in Helm values.

## 3. Deploy Verify — check the deployed application

**Runs:** When Helm files change on `main`, or when started manually.

It waits for Argo CD to apply the expected image tags, checks that Kubernetes deployments finish rolling out, and sends HTTP requests to the frontend and backend health endpoints.

A successful image build does not mean the application is healthy. Deploy Verify checks the running application after deployment.

## Normal developer flow

1. Make changes on a feature branch.
2. Open or update a PR to `main`; CI runs.
3. Merge the PR after CI passes.
4. CD builds and scans images, then opens a Helm image-tag PR.
5. Merge the image-tag PR; Argo CD applies the new images.
6. Deploy Verify checks rollout and application responses.

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
