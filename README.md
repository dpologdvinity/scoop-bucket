# scoop-bucket

Scoop manifests for [yonder](https://github.com/dpologdvinity/yonder) and
[depwhy](https://github.com/dpologdvinity/depwhy). `update.sh` refreshes them from each
project's latest GitHub release; a scheduled workflow runs it every hour.

```powershell
scoop bucket add dpologdvinity https://github.com/dpologdvinity/scoop-bucket
scoop install yonder
scoop install depwhy
```
