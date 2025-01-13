-- game table: 
   -- ----------------clean data---------------------------
SELECT * 
FROM Project_NBA.dbo.game;


-- ------------------------------------remove duplicates of game_id with CTE ---------------------------------------
with ordergames as (
Select *, 
ROW_NUMBER() Over( Partition By game_id ORDER BY (game_id)
) as row_num 
from Project_NBA.dbo.game
)
--delete 
Delete 
From ordergames
where row_num >1;
 --------------------------------- drop unused columns --------------------------------------
SELECT * 
FROM Project_NBA.Project_NBA.dbo.game;

Alter table Project_NBA.dbo.game
drop column video_available_away, video_available_home, plus_minus_home, plus_minus_away

SELECT * 
FROM Project_NBA.dbo.game;

-------------- ----- change datatype of columns ---------------------------------------------------

Alter table Project_NBA.dbo.game alter column game_date Date
Alter table Project_NBA.dbo.game alter column fgm_home int
Alter table Project_NBA.dbo.game alter column fga_home int
Alter table Project_NBA.dbo.game alter column fg3m_home int
Alter table Project_NBA.dbo.game alter column fg3a_home int

Alter table Project_NBA.dbo.game alter column fgm_away int
Alter table Project_NBA.dbo.game alter column fga_away int
Alter table Project_NBA.dbo.game alter column fg3m_away int
Alter table Project_NBA.dbo.game alter column fg3a_away int

------------------------------------------------- clean Null values in "W/L" column should only be W or L  -------------------------------------
with null_results as 
(select *
from Project_NBA.dbo.game
where wl_home is null or wl_away is null)

-- populate wl_home, wl away based on 
update null_results 
Set wl_home = (
case when pts_home > pts_away
then 'W'
else 'L'
end),
wl_away = (
case when pts_home > pts_away
then 'L'
else 'W'
end);

-- check if there is still null
select *
from Project_NBA.dbo.game
where wl_home is null or wl_away is null





----------------------------------------------- create stats per team per game table-------------------------------------
drop table if exists per_team_game_analy
go
Create table per_team_game_analy (
game_team_id nvarchar(255),
game_id nvarchar(50),
season_id nvarchar(50),
team_id nvarchar(50),
team nvarchar(50),
matchup_home nvarchar(50),
game_date date,
fg3_a int,
fg3_pct float,
fta float,
season_type nvarchar(50));

insert into per_team_game_analy
select CONCAT(game_id,team_id_home) as game_team_id, game_id, season_id, team_id_home as team_id,team_abbreviation_home as team, matchup_home, game_date, fg3a_home as fg3_a, fg3_pct_home as fg3_pct, fta_home as fta, season_type 
from Project_NBA.dbo.game 
UNION ALL 
select CONCAT(game_id,team_id_away) as game_team_id ,game_id, season_id, team_id_away as team_id, team_abbreviation_away as team, matchup_home, game_date, fg3a_away as fg3_a, fg3_pct_away as fg3_pct, fta_away as fta, season_type 
from Project_NBA.dbo.game;

select * 
from per_team_game_analy
order by game_date asc;

---- rolling average 3 season---
select *, AVG(fg3_a) OVER (Partition by season_id) as avg_3_season
from dbo.per_team_game_analy
order by game_date asc

select *
from dbo.other_stats


----------------------- PLAYOFFF ANALYSIS: compare between games of play-off and non-play-offs--------------------------

select g.season_id, g.game_id, matchup_home, game_date, fga_home, fga_away, fg_pct_home, fg_pct_away, pts_home, pts_away, lead_changes, times_tied, season_type
from Project_NBA.dbo.game g
LEFT JOIN Project_NBA.dbo.other_stats os
on g.game_id = os.game_id


-------------------------------- CREATE VIEW TABLES----------------------------------
--- 3pts table ---
drop view if exists analy_3pts
go
Create view analy_3pts as
select *, AVG(fg3_a) OVER (Partition by season_id) as avg_3_season
from dbo.per_team_game_analy
where fg3_a is not null;

select  *
from analy_3pts;

--- freethrow table ---
drop view if exists analy_free_thr
go
Create view analy_free_thr as
select *
from dbo.per_team_game_analy
where fta is not null


select *
from analy_free_thr;

--- playoff-diff-intense ------ 
drop view if exists analy_playoff_intense
go
create view analy_playoff_intense  as
select g.season_id, g.game_id, matchup_home, game_date, fga_home, fga_away, fg_pct_home, fg_pct_away, pts_home, pts_away, lead_changes, times_tied, season_type
from Project_NBA.dbo.game g
LEFT JOIN Project_NBA.dbo.other_stats os
on g.game_id = os.game_id

select * from analy_playoff_intense