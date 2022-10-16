with hn_stories as (
select
  ((regexp_match(url, '^.*//github.com/([^/]+/[^/]+)'))[1]) as repository_full_name,
  score
from
  hackernews_top
where
  score >= 10
  and type = 'story'
  and url ilike 'https://github.com/%'
limit 10
)
, workflows as (
select
  gw.name,
  gw.path,
  workflow_file_content_json as json_content
from
  hn_stories,
  github_workflow as gw
where
  gw.repository_full_name = hn_stories.repository_full_name
)
, jobs as (
select
  key as name,
  value
from
  workflows,
  jsonb_each(workflows.json_content -> 'jobs')
)
, steps as (
select
  steps.value -> 'name' as name,
  steps.value -> 'uses' as action
from
  jobs,
  jsonb_array_elements(jobs.value -> 'steps') as steps
)
select distinct on (steps.action)
  hn_stories.score as hn_score,
  concat('https://github.com/', hn_stories.repository_full_name) as repo_url,
  workflows.name as workflow,
  workflows.path as workflow_path,
  jobs.name as job,
  steps.name as step,
  steps.action
from
  steps,
  jobs,
  workflows,
  hn_stories
where
  steps.action is not null
