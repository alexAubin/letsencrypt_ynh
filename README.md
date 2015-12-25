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
- Automatic initial fetch of certificate (one domain only at the moment)
- Automatic renewal of soon-to-expire certificates through weekly cron job

To-do list
----------

- Multi domain support
- Finish remove script ?
- Upgrade/backup/restore ?
- ...
