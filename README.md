# AWS Infra Repo

- It's a public repo that fored from https://github.com/kubernetes/test-infra/tree/master/prow

## GitOps Management

### GitOps Usage

##### How to update devops config with git fork operation

- install hub on your local Mac

```bash
brew install hub
```

- git fork devops repo code to your own repo (we will keep just one master branch on this repo, if you want to update config, please give a PR.)

```bash
git fork --remote-name origin
renaming existing "origin" remote to "upstream"
update origin 
from https://github.com/awsgcr/aws-infra.git
 * [New Branch]      master     -> origin/master
new remote: origin
```

- Modify/Update config on your local Mac, then git add and git commit

```bash
git add . && git commit -m "[p2][prod] change /api location"
```

```bash
p[0-4][prod|dev|qa]
```

- fetch upstream master to get lastest code from devop repo, rebase code to fast forward based on your own local changes, then push local changes to your own git repo, then create PR to devop repo from your own repo.

```bash
git fetch upstream master && git rebase upstream/master && git push -u origin master -f && git pull-request --no-edit
```
or
```bash
git stash --include-untracked && git fetch upstream master && git rebase upstream/master && git push -u origin master -f && git pull-request --no-edit
```

- check your pr, or close your pr

```bash
git prlist # get the PR link on your local, then link to PR directly.
git prclose # close your PR
```
