use AI_Jobs_Analytics;
go

-- сколько всего записей, на всякий
select count(*) as total from ai_jobs;

-- 1. топ по деньгам среди востребованных
select top 20
    job_title,
    industry,
    round(average_salary_usd, 0) as salary_usd,
    round(future_demand_score, 2) as demand,
    round(ai_replacement_risk, 2) as ai_risk,
    hiring_trend_2026
from ai_jobs
where future_demand_score > 0.7
order by average_salary_usd desc;

-- 2. кто под угрозой: высокий риск ИИ или падение роста
select top 20
    job_title,
    industry,
    round(ai_replacement_risk, 2) as ai_risk,
    round(job_growth_2030, 1) as growth_2030,
    round(future_demand_score, 2) as demand,
    hiring_trend_2026
from ai_jobs
where ai_replacement_risk > 0.6
   or job_growth_2030 < 0
order by ai_replacement_risk desc, job_growth_2030 asc;

-- 3. низ зарплатной сетки
select top 20
    job_title,
    industry,
    round(average_salary_usd, 0) as salary_usd,
    round(future_demand_score, 2) as demand,
    round(ai_replacement_risk, 2) as ai_risk
from ai_jobs
order by average_salary_usd asc;

-- 4. общие цифры по всему датасету
select
    count(*)                                as total_jobs,
    round(avg(average_salary_usd), 0)       as avg_salary,
    round(min(average_salary_usd), 0)       as min_salary,
    round(max(average_salary_usd), 0)       as max_salary,
    round(avg(future_demand_score), 2)      as avg_demand,
    round(avg(ai_replacement_risk), 2)      as avg_ai_risk,
    round(avg(job_growth_2030), 1)          as avg_growth_2030
from ai_jobs;

-- 5. разрез по отраслям
select
    industry,
    count(*)                                as jobs_cnt,
    round(avg(average_salary_usd), 0)       as avg_salary,
    round(avg(ai_replacement_risk), 2)      as avg_ai_risk,
    round(avg(future_demand_score), 2)      as avg_demand,
    round(avg(job_growth_2030), 1)          as avg_growth
from ai_jobs
group by industry
order by avg_salary desc;

-- 6. какие навыки чаще всего просят (разбиваем строку по запятым)
with skills as (
    select
        trim(value) as skill,
        average_salary_usd,
        ai_replacement_risk
    from ai_jobs
    cross apply string_split(required_skills, ',')
)
select top 15
    skill,
    count(*)                              as freq,
    round(avg(average_salary_usd), 0)     as avg_salary,
    round(avg(ai_replacement_risk), 2)    as avg_ai_risk
from skills
group by skill
having count(*) >= 5
order by freq desc;

-- 7. "звёзды": спрос и деньги выше 70-го перцентиля, риск низкий
-- (тут пришлось повозиться с перцентилями, пороги считаю один раз)
with thresholds as (
    select
        percentile_cont(0.70) within group (order by future_demand_score)
            over () as demand_cut,
        percentile_cont(0.70) within group (order by average_salary_usd)
            over () as salary_cut
    from ai_jobs
),
stars as (
    select distinct
        j.job_title,
        j.industry,
        j.average_salary_usd,
        j.future_demand_score,
        j.ai_replacement_risk,
        j.hiring_trend_2026
    from ai_jobs j
    cross join thresholds t
    where j.future_demand_score >= t.demand_cut
      and j.average_salary_usd >= t.salary_cut
      and j.ai_replacement_risk < 0.35
)
select top 15
    job_title,
    industry,
    round(average_salary_usd, 0)     as salary_usd,
    round(future_demand_score, 2)    as demand,
    round(ai_replacement_risk, 2)    as ai_risk,
    hiring_trend_2026
from stars
order by average_salary_usd desc;

-- 8. по странам
select top 10
    country,
    count(*)                            as jobs_cnt,
    round(avg(average_salary_usd), 0)   as avg_salary,
    round(avg(ai_replacement_risk), 2)  as avg_ai_risk,
    round(avg(future_demand_score), 2)  as avg_demand
from ai_jobs
group by country
order by avg_salary desc;

-- 9. зависит ли зарплата от уровня образования
select
    education_level,
    count(*)                            as jobs_cnt,
    round(avg(average_salary_usd), 0)   as avg_salary,
    round(avg(ai_replacement_risk), 2)  as avg_ai_risk,
    round(avg(future_demand_score), 2)  as avg_demand
from ai_jobs
group by education_level
order by avg_salary desc;

-- 10. то же по опыту, бьём на корзины
select
    case
        when years_experience <= 3  then 'junior (0-3)'
        when years_experience <= 7  then 'mid- (4-7)'
        when years_experience <= 12 then 'mid (8-12)'
        when years_experience <= 18 then 'senior (13-18)'
        else 'expert (19+)'
    end                                 as exp_band,
    count(*)                            as jobs_cnt,
    round(avg(average_salary_usd), 0)   as avg_salary,
    round(avg(ai_replacement_risk), 2)  as avg_ai_risk
from ai_jobs
group by
    case
        when years_experience <= 3  then 'junior (0-3)'
        when years_experience <= 7  then 'mid- (4-7)'
        when years_experience <= 12 then 'mid (8-12)'
        when years_experience <= 18 then 'senior (13-18)'
        else 'expert (19+)'
    end
order by avg_salary desc;

-- 11. удалёнка и её связь с деньгами / риском
select
    remote_work_possibility,
    count(*)                            as jobs_cnt,
    round(avg(average_salary_usd), 0)   as avg_salary,
    round(avg(job_satisfaction), 2)     as avg_satisfaction,
    round(avg(ai_replacement_risk), 2)  as avg_ai_risk
from ai_jobs
group by remote_work_possibility
order by avg_salary desc;

-- 12. выводы для HR — просто как шпаргалка, не из таблицы
select 'Инвестировать в "звёзд"' as recommendation,
       'бюджет в первую очередь на профессии с высоким спросом и низким риском ИИ'
union all
select 'Переобучение группы риска',
       'upskilling для профессий, где ИИ-риск высокий, но спрос сохраняется'
union all
select 'Автоматизация вымирающих',
       'профессии с высоким риском ИИ и отрицательным ростом — под замену/сокращение';