Let's encrypt
=============

Automatic installation of Let's encrypt certificates on Yunohost

**Disclaimer !** This is alpha/experimetal software, use at your own risks.
Testers / feedbacks are welcome ! So far I tested the install on a Yunohost test
VM, and a production server (RPi). It seems to work though the install takes a
while.

Features
--------

- Automatic install of Let's encrypt ACME client
- Automatic initial fetch of certificate(s) (one domain, or all domains)
- Automatic renewal of soon-to-expire certificates through weekly cron job
- Uninstall script if you want to fallback to self-signed certificates

N.B. about the install for all domains :
- if every fetch fails, install will be aborted ;
- otherwise, it will simply show a warning if one fetch failed.

To-do list
----------

- Upgrade/backup/restore ?
- ...
