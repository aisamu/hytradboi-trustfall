WITH hn_stories AS (
    SELECT
        ((regexp_match(url, '^.*//github.com/([^/]+/[^/]+)'))[1]) AS repository_full_name,
        score
    FROM
        hackernews_top
    WHERE
        score >= 10
        AND type = 'story'
        AND url ILIKE 'https://github.com/%'
    LIMIT 10
),
workflows AS (
    SELECT
        gw.name,
        gw.path,
        workflow_file_content_json AS json_content
    FROM
        hn_stories,
        github_workflow AS gw
    WHERE
        gw.repository_full_name = hn_stories.repository_full_name
),
jobs AS (
    SELECT
        key AS name,
        value
    FROM
        workflows,
        jsonb_each(workflows.json_content -> 'jobs')
),
steps AS (
    SELECT
        steps.value -> 'name' AS name,
        steps.value -> 'uses' AS action
    FROM
        jobs,
        jsonb_array_elements(jobs.value -> 'steps') AS steps
)
SELECT DISTINCT ON (steps.action)
    hn_stories.score AS hn_score,
    concat('https://github.com/', hn_stories.repository_full_name) AS repo_url,
    workflows.name AS workflow,
    workflows.path AS workflow_path,
    jobs.name AS job,
    steps.name AS step,
    steps.action
FROM
    steps,
    jobs,
    workflows,
    hn_stories
WHERE
    steps.action IS NOT NULL
