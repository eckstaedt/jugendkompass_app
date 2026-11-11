-- The Bible reading plan is hidden in the app for now: no reminder pushes.
-- Re-enable with: select cron.alter_job(jobid, active := true) from cron.job where jobname = 'send-bible-plan-notifications';
select cron.alter_job(jobid, active := false) from cron.job where jobname = 'send-bible-plan-notifications';
